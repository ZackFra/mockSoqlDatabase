public with sharing class MockDatabase {

    public Map<String, Map<Id, sObject>> db = new Map<String, Map<Id, sObject>>();
    public MockDatabaseUtils utils = new MockDatabaseUtils(this);
    public enum QueryType {
        RECORD, AGGREGATE, COUNT
    }

    /**
     * @description map of the top-level nodes of select nodes, is a map to account for subqueries
     */
    private final Map<Node, TopLevelNodes> topLevelNodes = new Map<Node, TopLevelNodes>();

    /**
     * @description return all SObjects of a given type
     */
    public Map<Id, sObject> get(String objApiName) {
        return this.db.get(objApiName);
    }
    
    private Boolean checkHavingClause(BooleanLogicOptions havingLogicOptions) {
        HavingLogicHandler havingLogicHandler = new HavingLogicHandler(havingLogicOptions);
        return havingLogicHandler.evaluate();
    }

    private Boolean checkWhereClause(SObject databaseRecord, node whereNode, Map<String, Object> params) {
        BooleanLogicOptions whereLogicOptions = new BooleanLogicOptions()
            .setDatabase(this)
            .setHead(whereNode)
            .setObj(databaseRecord)
            .setParams(params);
        WhereLogicHandler whereLogicHandler = new WhereLogicHandler(whereLogicOptions);
        return whereLogicHandler.evaluate();
    }

    /** @description : return a parent sObject from a field name and a child sObject
      * @param sObj : the child sObject
      * @param fieldName : the field name of the parent sObject from the child
      *                  : ex. OpportunityLineItem, the field is Opportunity
      */
      public Map<String, Object> getParentRecord(sObject sObj, String fieldName) {
        // api name of the child sObject
        String objApiName = sObj.getSObjectType().getDescribe().getName();
        // api name of the id object on the child (i.e. OpportunityId)
        String fieldApiName;
        // api name of the relationship field on the child (i.e. Opportunity)
        String fieldRelationshipName;
        // api name of the parent sObject
        String parentObjApiName;
        // whether this field is a polymorphic relationship
        Boolean isPolymorphic = false;


        String sObjApiName = sObj.getSObjectType().getDescribe().getName();
        SObjectType t = ((SObject)Type.forName(sObjApiName).newInstance()).getSObjectType();
        
        List<Schema.SObjectField> fields = SchemaService.getFields(t);
        for (SObjectField f : t.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult dfr = f.getDescribe();
            Schema.DisplayType dfrFieldType = dfr.getType();
            String dfrRelationshipName = dfr.getRelationshipName();
            String lowercaseDfrRelationshipName = null;
            if(dfrRelationshipName != null) {
                lowercaseDfrRelationshipName = dfrRelationshipName.toLowerCase();
            }

            if (dfrFieldType == Schema.DisplayType.REFERENCE && lowerCaseDfrRelationshipName == fieldName) {
                List<Schema.sObjectType> objTypeList = dfr.getReferenceTo();

                if(objTypeList.size() == 1) {
                    parentObjApiName = objTypeList[0].getDescribe().getName();
                } else {
                    String parentFieldApiName = SchemaService.getFieldName(f);
                    Id parentRecordId = (Id) sObj.get(parentFieldApiName);
                    parentObjApiName = SchemaService.getSObjectName(parentRecordId);
                    isPolymorphic = true;
                }
                
                if(parentObjApiName == null) {
                    throw new QueryException('Invalid relationship name: ' + fieldName);
                }

                fieldApiName = dfr.getName();
                fieldRelationshipName = dfr.getRelationshipName();

                sObject parentRecord = ((sObject) Type.forName(parentObjApiName).newInstance()).getSObjectType().newSObject();
                
                Map<Id, sObject> mockRecordsChild = this.db.get(objApiName);
                Id parentId = (Id) mockRecordsChild.get(sObj.Id).get(fieldApiName);

                parentRecord.put('Id', parentId);
                Map<String, Object> objInfo = new Map<String, Object> {
                    'fieldApiName' => fieldApiName,
                    'fieldRelationshipName' => fieldRelationshipName,
                    'parentObjApiName' => parentObjApiName,
                    'objApiName' => objApiName,
                    'parentRecord' => parentRecord,
                    'isPolymorphic' => isPolymorphic
                };
                return objInfo;
            }
        }

        throw new QueryException('Invalid relationship name: ' + fieldName);
    }

    public SObject findRecord(Id recordId) {
        String objApiName = SchemaService.getSObjectName(recordId);
        try {
            return this.db.get(objApiName).get(recordId);
        } catch(Exception e) {
            throw new QueryException('No record found for ' + recordId);
        }
    }

    private SObject handleSelectQuery(FieldSelector fSelector) {
        Node fieldNode = fSelector.fieldNode;

        SObject queriedRecord = fSelector.queriedRecord;
        if(fieldNode == null) {
            return queriedrecord;
        }

        ISelectHandler selectHandler = new SelectHandlerFactory(fSelector)
            .createHandler();
        queriedRecord = selectHandler.handleSelect();

        // to check the next field node in the list, 
        // the only changes are the queriedRecord and the fieldNode
        fSelector
            .setQueriedRecord(queriedRecord)
            .setFieldNode(fieldNode.left);

        // Recursion, baby!
        return handleSelectQuery(fSelector);
    }

    private SObject handleSelectQuery(sObject databaseRecord, Node selectNode, Map<String, Object> params) {
        Node fieldNode = selectNode.left;
        
        String sObjApiName = SchemaService.getSObjectName(databaseRecord);
        SObject queriedRecord = SchemaService.blankSObjectFrom(sObjApiName);
        queriedRecord.put('Id', databaseRecord.Id);

        FieldSelector fSelector = new FieldSelector()
            .setDatabaseRecord(databaseRecord)
            .setQueriedRecord(queriedRecord)
            .setFieldNode(fieldNode)
            .setParams(params)
            .setDatabase(this);

        return handleSelectQuery(fSelector);
    }

    private Boolean isAggregateQuery(Node selectNode) {
        TopLevelNodes topLevelNodes = getTopLevelNodes(selectNode);
        Node groupByNode = topLevelNodes.groupByNode;

        if(isSingularCount(selectNode)) {
            return false;
        }

        Node curr = selectNode;
        while(curr != null) {
            if(curr.nodeType == 'aggregate function') {
                return true;
            }
            curr = curr.left;
        }

        if(groupByNode != null) {
            return true;
        }

        return false;
    }

    private Object handleLimitNode(QueryType typeOfQuery, Node limitNode, Object results, Map<String, Object> params) {
        if(limitNode == null) {
            return results;
        }

        LimitOptions options = new LimitOptions(limitNode, params)
            .setType(typeOfQuery)
            .setObj(results);

        ILimitHandler limitHandler = new LimitHandlerFactory(options)
            .createHandler();
        
        return limitHandler.handleLimit();
    }

    private TopLevelNodes getTopLevelNodes(Node selectNode) {
        TopLevelNodes topLevelNodes = this.topLevelNodes.get(selectNode);
        if(topLevelNodes == null) {
            topLevelNodes = new TopLevelNodes(selectNode);
            this.topLevelNodes.put(selectNode, topLevelNodes);
            return topLevelNodes;
        }
        return this.topLevelNodes.get(selectNode);
    }

    private List<ProtoAggregate> handleHavingNode(
        List<ProtoAggregate> aggregateResults, 
        Node selectNode, 
        Map<String, Object> params
    ) {
        TopLevelNodes topLevelNodes = getTopLevelNodes(selectNode);
        Node havingNode = topLevelNodes.havingNode;
        if(havingNode == null) {
            return aggregateResults;
        }

        List<ProtoAggregate> results = new List<ProtoAggregate>();
        for(ProtoAggregate ar : aggregateResults) {

            BooleanLogicOptions havingLogicOptions = new BooleanLogicOptions()
                .setDatabase(this)
                .setHead(havingNode)
                .setSelectNode(selectNode)
                .setObj(ar)
                .setParams(params);
            
            if(checkHavingClause(havingLogicOptions)) {
                results.add(ar);
            }
        }
        return results;
    }

    private Object handleOrderByNode(
        QueryType typeOfQuery, 
        Object results, 
        Node selectNode, 
        Node orderByNode
    ) {
        if(results == null) {
            return results;
        }

        switch on typeOfQuery {
            when AGGREGATE {
                return sortByOrderBy((List<ProtoAggregate>) results, selectNode, orderByNode);
            }
            when RECORD {
                return sortByOrderBy((List<SObject>) results, selectNode, orderByNode);
            }
            when else {
                throw new QueryException('Invalid results type');
            }
        }
    }

    /**
     * @description : given an offset node, return the offset value
     */
    private Object handleOffsetNode(
        QueryType typeOfQuery, 
        Node offsetNode, 
        Object results, 
        Map<String, Object> params
    ) {
        if(offsetNode == null) {
            return results;
        }

        OffsetOptions offsetOptions = new OffsetOptions(offsetNode, params)
            .setType(typeOfQuery)
            .setObj(results);
        
        IOffsetHandler offsetHandler = new OffsetHandlerFactory(offsetOptions)
            .createHandler();
        
        return offsetHandler.handleOffset();
    }

    public Map<String, Object> getComparables(SObject record, String field) {
        return ComparableService.getComparables(this, record, field);
    }

    private List<ProtoAggregate> sortByOrderBy(List<ProtoAggregate> aggregates, Node selectNode, Node orderByNode) {
        // clone the list so we don't modify the original
        aggregates = new List<ProtoAggregate>(aggregates);

        if(orderByNode == null) {
            return aggregates;
        }
        Node orderByField = orderByNode.left;
        
        Map<String, Map<String, String>> fields = new Map<String, Map<String, String>>();
        while(orderByField != null) {
            String relationshipName;
            String fieldApiName;

            Map<String, String> aliasData = AliasService.getAlias(selectNode, orderByField);
            fieldApiName = aliasData.get('fieldApiName');
            relationshipName = aliasData.get('relationshipName');
            
            String nullDir = 'first';
            String order = 'asc';
            Node curr = orderByField.right;
            if(curr != null && curr.nodeType == 'direction') {
                order = orderByField.right.id;
                curr = curr.right;
            }
            if(curr != null && curr.nodeType == 'nulls direction') {
                if(curr.id == 'nulls last') {
                    nullDir = 'last';
                }
            }


            Map<String, String> fieldData = new Map<String, String> {
                'fieldApiName' => fieldApiName,
                'relationshipName' => relationshipName,
                'order' => order,
                'nullDir' => nullDir
            };
            fields.put(fieldApiName, fieldData);
            orderByField = orderByField.left;
        }
        AggregateComparator comparator = new AggregateComparator(fields);
        aggregates.sort(comparator);
        return aggregates;
    }

    /**
     * @description If orderByNode is not null, sort the list of sObjects by the fields in the orderByNode
     * @param sObjects : the list of sObjects
     * @param orderByNode : the orderByNode
     * @return : the sorted list of sObjects
     */
    private List<SObject> sortByOrderBy(List<SObject> sObjects, Node selectNode, Node orderByNode) {
        // clone the list so we don't modify the original
        sObjects = new List<SObject>(sObjects);

        if(orderByNode == null) {
            return sObjects;
        }
        Node orderByField = orderByNode.left;

        Map<String, Map<String, String>> fields = new Map<String, Map<String, String>>();
        while(orderByField != null) {
            String fieldName = orderByField.id;
            Map<String, Object> comparables = ComparableService.getComparableDataFromNodes(orderByField, selectNode);
            String relationshipName = (String) comparables.get('relationshipName');
            String fieldApiName = (String) comparables.get('comparableField');

            String order = 'asc';
            String nullDir = 'first';
            Node curr = orderByField.right;
            if(curr != null && curr.nodeType == 'direction') {
                order = orderByField.right.id;
                curr = curr.right;
            }

            if(curr != null && curr.nodeType == 'nulls direction') {
                if(curr.id == 'nulls last') {
                    nullDir = 'last';
                }
            }
            Map<String, String> fieldData = new Map<String, String> {
                'fieldApiName' => fieldApiName,
                'relationshipName' => relationshipName,
                'order' => order,
                'nullDir' => nullDir
            };
            fields.put(fieldName, fieldData);
            orderByField = orderByField.left;
        }
        SObjectComparator comparator = new SObjectComparator(fields);
        sObjects.sort(comparator);
        return sObjects;
    }

    // if all we're doing is counting, no other aggregate funcs
    private Boolean isSingularCount(Node selectNode) {
        return (selectNode.left.id == 'count' && selectNode.left.right == null && selectNode.left.left == null);
    }

    /**
     * @description Filter on the "USING SCOPE" clause
     * @param sObject The SObject to filter
     * @param usingScopeNode The "USING SCOPE" node
     * @param params The query parameters
     * @return Whether the SObject passes the filter
     */
     private Boolean handleUsingScopeNode(SObject sObj, Node usingScopeNode, Map<String, Object> params) {
        // Salesforce at some point will support evaluating formulas in Apex
        // that day is not today, so until then we're just assuming the scope is good
        // https://help.salesforce.com/s/articleView?id=release-notes.rn_apex_formulaeval.htm&release=248&type=5
        return true;
     }


    /**
     * @description Given a record id, verify it exists in the database
     * @param recordId : the record id
     * @return : whether the record exists in the database
     */
    private Boolean isRecordInDatabase(Id recordId) {
        String recordApiName = SchemaService.getSObjectName(recordId);
        Map<Id, sObject> mockObjects = this.db.get(recordApiName);
        return mockObjects.containsKey(recordId);
    }

    /** DML methods **/

    /**
     * @description: This method is used to insert an sObject into the mock database
     * @param obj : the sObject to insert
     */
    public void doInsert(SObject obj) {
        if(obj.Id != null) {
            throw new DmlException('Cannot insert an object with an Id');
        }
        String objName = SchemaService.getSObjectName(obj);
        Map<Id, sObject> mockObjects = this.db.get(objName);

        Schema.SObjectType sot = SchemaService.getSObjectType(obj);
        String fakeId = fflib_IDGenerator.generate(sot);
        obj.put('Id', fakeId);

        mockObjects = this.db.get(objName);
        if(mockObjects == null) {
            mockObjects = new Map<Id, sObject>();
            this.db.put(objName, mockObjects);
        }
        mockObjects.put(obj.Id, obj);
    }

    /**
     * @description: This method is used to insert a list of sObjects into the mock database
     * @param objList : the list of sObjects to insert
     */
    public void doInsert(List<sObject> objList) {
        for(sObject obj : objList) {
            doInsert(obj);
        }
    }

    /**
     * @description: This method is used to update an sObject in the mock database
     * @param obj : the sObject to update
     */
    public void doUpdate(sObject obj) {
        if(obj == null) {
            throw new DmlException('Argument cannot be null');
        }

        String objName = obj.getSObjectType().getDescribe().getName();
        Map<Id, sObject> mockObjects = this.db.get(objName);

        if (mockObjects == null) {
            throw new DmlException('Object does not exist');
        } else if (mockObjects.get(obj.Id) == null) {
            throw new DmlException('Object does not exist');
        }

        
        for(String field : obj.getPopulatedFieldsAsMap().keySet()) {

            // check for foreign key references
            Schema.SObjectType  sot = SchemaService.getSObjectType(obj);
            Schema.DisplayType fieldType = SchemaService.getFieldType(sot, field);
            Boolean isRef = (fieldType == Schema.DisplayType.REFERENCE);
            if(!isRef) {
                mockObjects.get(obj.Id).put(field, obj.get(field));
                continue;
            }

            Id recordId = (Id) obj.get(field);

            if(isRef && !isRecordInDatabase(recordId)) {
                throw new DmlException('Foreign key reference does not exist');
            }
            mockObjects.get(obj.Id).put(field, obj.get(field));
        }
    }

    /**
     * @description: This method is used to update a list of sObjects in the mock database
     * @param objList : the list of sObjects to update
     */
    public void doUpdate(List<sObject> objList) {
        for(sObject obj : objList) {
            doUpdate(obj);
        }
    }

    /**
     * @description: This method is used to delete an sObject from the mock database
     * @param obj : the sObject to delete
     */
    public void doDelete(sObject obj) {
        String objName = SchemaService.getSObjectName(obj);
        Map<Id, sObject> mockObjects = this.db.get(objName);

        if (mockObjects == null) {
            throw new DmlException('Object does not exist');
        } else if (mockObjects.get(obj.Id) == null) {
            throw new DmlException('Object does not exist');
        }

        mockObjects.remove(obj.Id);
    }

    /**
     * @description: This method is used to delete a list of sObjects from the mock database
     * @param objList : the list of sObjects to delete
     */
    public void doDelete(List<sObject> objList) {
        for(sObject obj : objList) {
            doDelete(obj);
        }
    }


    /** SOQL methods **/

    /**
     * @description: This method is used to query the mock database by traversing the AST
     * @param query : the query string
     * @return : the query results
     */
    public Object query(String query) {
        return doQuery(query, null);
    }

    /**
     * @description: This method is used to query the mock database by traversing the AST
     * @param query : the query string
     * @param params : the query parameters
     * @return : the query results
     */
    public Object queryWithBinds(String query, Map<String, Object> params) {
        Map<String, Object> lowerCaseParams = new Map<String, Object>();
        for(String key : params.keySet()) {
            lowerCaseParams.put(key.toLowerCase(), params.get(key));
        }
        return doQuery(query, lowerCaseParams);       
    }

    /**
     * @description: This method is used to query the mock database by traversing the AST
     * @param query : the query string
     * @param params : the query parameters
     * @param access : the access level
     * @return : the query results
     */
    public Object queryWithBinds(String query, Map<String, Object> params, AccessLevel access) {
        return queryWithBinds(query, params);
    }

    // @description: This method is used to query the mock database by traversing the AST
    private Object doQuery(String query, Map<String, Object> params) {
        Lexer parser = new Lexer();
        Node selectNode = parser.parse(query);
        return doQuery(selectNode, params);
    }

    /**
     * @description Used internally, do not use this method
     * @param selectNode : the select node
     * @param params : the query parameters
     * @return : the query results
     * @throws QueryException : if the query is invalid
     */
    public Object doQuery(Node selectNode, Map<String, Object> params) {
        TopLevelNodes topLevelNodes = getTopLevelNodes(selectNode);
        Node fromNode = topLevelNodes.fromNode;
        Node whereNode = topLevelNodes.whereNode;
        Node orderByNode = topLevelNodes.orderByNode;
        Node limitNode = topLevelNodes.limitNode;
        Node offsetNode = topLevelNodes.offsetNode;
        Node usingScopeNode = topLevelNodes.usingScopeNode;
        Node groupByNode = topLevelNodes.groupByNode;

        // validate the query, throws exception if invalid
        QueryValidator validator = new QueryValidator(topLevelNodes);
        validator.validate();

        Node objNode = fromNode.left;
        String objName = objNode.id;
        String objApiName = SchemaService.getSObjectName(objName);

        Map<Id, sObject> mockObjects = this.db.get(objApiName);
        if (mockObjects == null) {
            return new List<sObject>();
        }

        Boolean isAggregateQuery = isAggregateQuery(selectNode);
        Boolean isCount = isSingularCount(selectNode);

        Object results;

        // results will either be a count, a list of sObjects, or a list of aggregates
        Integer count = 0;
        List<ProtoAggregate> aggregateResults = new List<ProtoAggregate>();

        List<ProtoAggregate> summaryResults = new List<ProtoAggregate>();
        List<ProtoAggregate> summarySubResults = new List<ProtoAggregate>();
        ProtoAggregate grandSummaryResult = new ProtoAggregate();

        List<sObject> sObjects = new List<sObject>();

        AggregateQueryHandler aggrHandler = new AggregateQueryHandler(this, topLevelNodes);

        // process the query, whether it's a count, aggregate, or regular query
        for(sObject databaseRecord : mockObjects.values()) {

            if(!checkWhereClause(databaseRecord, whereNode, params)) {
                continue;
            }

            if(!handleUsingScopeNode(databaseRecord, usingScopeNode, params)) {
                continue;
            }

            if(isCount && !isAggregateQuery) {
                count++;
                continue;
            }

            // handle fields
            if(!isAggregateQuery) {
                SObject queriedRecord = handleSelectQuery(databaseRecord, selectNode, params);
                sObjects.add(queriedRecord);
                continue;
            }

            aggrHandler.processRecord(databaseRecord);
        }
        aggregateResults = aggrHandler.finish();

        // handle the ORDER BY and LIMIT logic here
        if(isAggregateQuery) {
            aggregateResults = (List<ProtoAggregate>) handleHavingNode(aggregateResults, selectNode, params);
            aggregateResults = (List<ProtoAggregate>) handleOrderByNode(QueryType.AGGREGATE, aggregateResults, selectNode, orderByNode);
            aggregateResults = (List<ProtoAggregate>) handleOffsetNode(QueryType.AGGREGATE, offsetNode, aggregateResults, params);
            aggregateResults = (List<ProtoAggregate>) handleLimitNode(QueryType.AGGREGATE, limitNode, aggregateResults, params);

            // Remove internal fields from the aggregate result proto-records and return the list of aggregates
            List<Aggregate> aggregateResultsList = new AggregateBuilder()
                .setParams(params)
                .setProtoAggregates(aggregateResults)
                .setTopLevelNodes(topLevelNodes)
                .build();
            
            results = aggregateResultsList;
        } else if(isCount) {
            count = (Integer) handleOffsetNode(QueryType.COUNT, offsetNode, count, params);
            count = (Integer) handleLimitNode(QueryType.COUNT, limitNode, count, params);
            results = count;
        } else {
            sObjects = (List<SObject>) handleOrderByNode(QueryType.RECORD, sObjects, selectNode, orderByNode);
            sObjects = (List<SObject>) handleOffsetNode(QueryType.RECORD, offsetNode, sObjects, params);
            sObjects = (List<SObject>) handleLimitNode(QueryType.RECORD, limitNode, sObjects, params);
            results = sObjects;
        }
        this.topLevelNodes.remove(selectNode);
        return results;
    }
}