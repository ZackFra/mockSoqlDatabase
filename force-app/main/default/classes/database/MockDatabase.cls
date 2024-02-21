public with sharing class MockDatabase {

    public Map<String, Map<Id, sObject>> db = new Map<String, Map<Id, sObject>>();
    public MockDatabaseUtils utils = new MockDatabaseUtils(this);
    public enum QueryType {
        RECORD, AGGREGATE, COUNT
    }

    Boolean enforceRequiredFields = false;
    public MockDatabase setEnforceRequiredFields(Boolean isEnforced) {
        this.enforceRequiredFields = isEnforced;
        return this;
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

    /**
     * @description Given a recor id, return the database record for it
     * @param recordId : the record id
     * @return : the database record
     * @throws QueryException : if the record does not exist
     */
    public SObject findRecord(Id recordId) {
        return this.utils.findRecord(recordId);
    }

    /**
     * @description Given a record and a field, return the parent record (i.e. the record that field looks up to)
     * @param sObj : the record
     * @param fieldName : the field name
     * @return : the parent record
     * @throws QueryException : if the parent record does not exist
     */
    public Map<String, Object> findParentRecord(sObject sObj, String fieldName) {
        return this.utils.findParentRecord(sObj, fieldName);
    }

    /**
     * @description Wrapper aroung the ComparableService.getComparables method
     * @param record : the record
     * @param field : the field
     * @return : the comparables
     * @throws QueryException : if the comparables cannot be found
     */
    public Map<String, Object> getComparables(SObject record, String field) {
        return ComparableService.getComparables(this, record, field);
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

    private Object handleLimitNode(QueryType typeOfQuery, Node limitNode, Object results, Map<String, Object> params) {
        if(limitNode == null) {
            return results;
        }

        ILimitHandler limitHandler = new LimitHandlerFactory()
            .setLimitNode(limitNode)
            .setParams(params)
            .setType(typeOfQuery)
            .setObj(results)
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
        Node selectNode
    ) {
        if(results == null) {
            return results;
        }

        TopLevelNodes topLevelNodes = getTopLevelNodes(selectNode);

        OrderByHandler orderByHandler = new OrderByHandlerFactory()
            .setObj(results)
            .setTopLevelNodes(topLevelNodes)
            .setType(typeOfQuery)
            .createHandler();
        return orderByHandler.handleOrderBy();
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
        
        IOffsetHandler offsetHandler = new OffsetHandlerFactory()
            .setType(typeOfQuery)
            .setObj(results)
            .setOffsetNode(offsetNode)
            .setParams(params)
            .createHandler();
        
        return offsetHandler.handleOffset();
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

    /** DML methods **/

    /**
     * @description: This method is used to insert an sObject into the mock database
     * @param obj : the sObject to insert
     */
    public void doInsert(SObject record) {
        if(record.Id != null) {
            throw new DmlException('Cannot insert an object with an Id');
        }

        if(enforceRequiredFields) {
            this.utils.checkForRequiredFieldsOnInsert(record);
        }

        String objName = SchemaService.getSObjectName(record);
        Map<Id, sObject> mockObjects = this.db.get(objName);

        Schema.SObjectType sot = SchemaService.getSObjectType(record);
        String fakeId = fflib_IDGenerator.generate(sot);
        record.put('Id', fakeId);

        mockObjects = this.db.get(objName);
        if(mockObjects == null) {
            mockObjects = new Map<Id, sObject>();
            this.db.put(objName, mockObjects);
        }
        mockObjects.put(record.Id, record);
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
    public void doUpdate(SObject record) {
        if(record == null) {
            throw new DmlException('Argument cannot be null');
        }

        String objName = SchemaService.getSObjectName(record);
        Map<Id, sObject> mockObjects = this.db.get(objName);

        if (mockObjects == null) {
            throw new DmlException('Object does not exist');
        } else if (mockObjects.get(record.Id) == null) {
            throw new DmlException('Object does not exist');
        }

        if(enforceRequiredFields) {
            this.utils.checkForRequiredFieldsOnUpdate(record);
        }

        SObject databaseRecord = mockObjects.get(record.Id);
        
        for(String field : record.getPopulatedFieldsAsMap().keySet()) {

            // check for foreign key references
            Schema.SObjectType  sot = SchemaService.getSObjectType(record);
            Schema.DisplayType fieldType = SchemaService.getFieldType(sot, field);
            Boolean isRef = (fieldType == Schema.DisplayType.REFERENCE);
            if(!isRef) {
                databaseRecord.put(field, record.get(field));
                continue;
            }

            Id parentRecordId = (Id) record.get(field);

            if(isRef && !this.utils.isRecordInDatabase(parentRecordId)) {
                throw new DmlException('Foreign key reference does not exist');
            }
            databaseRecord.put(field, record.get(field));
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

        Boolean isAggregateQuery = NodeService.isAggregateQuery(topLevelNodes);
        Boolean isCount = NodeService.isSingularCount(topLevelNodes);

        Map<Id, sObject> mockObjects = this.db.get(objApiName);
        if (mockObjects == null) {
            return this.utils.emptyResponse(topLevelNodes);
        }

        Object results;

        // results will either be a count, a list of sObjects, or a list of aggregates
        Integer count = 0;
        List<ProtoAggregate> aggregateResults = new List<ProtoAggregate>();
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
            aggregateResults = (List<ProtoAggregate>) handleOrderByNode(QueryType.AGGREGATE, aggregateResults, selectNode);
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
            sObjects = (List<SObject>) handleOrderByNode(QueryType.RECORD, sObjects, selectNode);
            sObjects = (List<SObject>) handleOffsetNode(QueryType.RECORD, offsetNode, sObjects, params);
            sObjects = (List<SObject>) handleLimitNode(QueryType.RECORD, limitNode, sObjects, params);
            results = sObjects;
        }
        this.topLevelNodes.remove(selectNode);
        return results;
    }
}