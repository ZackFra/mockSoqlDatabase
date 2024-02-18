public with sharing class MockDatabase {

    public Map<String, Map<Id, sObject>> db = new Map<String, Map<Id, sObject>>();
    public MockDatabaseUtils utils = new MockDatabaseUtils(this);

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

    private Boolean checkWhereClause(BooleanLogicOptions whereLogicOptions) {
        WhereLogicHandler whereLogicHandler = new WhereLogicHandler(whereLogicOptions);
        return whereLogicHandler.evaluate();
    }

    private sObject buildObjWithRelations(sObject sObj, List<String> fieldParts, String finalField) {
        fieldParts = new List<String>(fieldParts);
        String fieldPart = fieldParts[0];

        Map<String, Object> parentInfo = this.utils.getParentObject(findRecord(sObj.Id), fieldPart);

        sObject parentRecord = (sObject) parentInfo.get('parentRecord');
        String fieldApiName = (String) parentInfo.get('fieldApiName');
        String fieldRelationshipName = (String) parentInfo.get('fieldRelationshipName');
        String objApiName = (String) parentInfo.get('objApiName');

        Map<String, Object> sObjClone = this.utils.mapFromSObject(sObj);
        String parentRecordApiName = (String) parentInfo.get('parentObjApiName');
        fieldParts.remove(0);
        if(!fieldParts.isEmpty()) {
            if(sObjClone.containsKey(fieldRelationshipName)) {
                parentRecord = this.utils.sObjectFromMap((Map<String, Object>)sObjClone.get(fieldRelationshipName), parentRecordApiName);
            }
            sObject nextParent = buildObjWithRelations(parentRecord, fieldParts, finalField);
            sObjClone.put(fieldApiName, nextParent.Id);
            sObjClone.put(fieldRelationshipName, nextParent);
        } else {
            Map<Id, sObject> mockRecords = this.db.get(parentRecordApiName);
            
            Schema.SObjectType parentRecordSObjType = SchemaService.getSObjectType(parentRecord);
            Boolean isRelationshipPolymorphic = (Boolean) parentInfo.get('isPolymorphic');
            Map<String, String> polymorphicFieldMap = SchemaService.getPolymorphicFieldMap();
            Boolean isNameField = polymorphicFieldMap.containsKey(finalField);
            String finalFieldApiName;
            if(isRelationshipPolymorphic && isNameField)  {
                finalFieldApiName = polymorphicFieldMap.get(finalField);
            } else {
                finalFieldApiName = SchemaService.getFieldName(parentRecordSObjType, finalField);
            }

            Map<String, Object> parentRecordData = this.utils.mapFromSObject(parentRecord);

            if(sObjClone.containsKey(fieldRelationshipName)) {
                parentRecordData = (Map<String, Object>) sObjClone.get(fieldRelationshipName);
            } 
            
            if(isRelationshipPolymorphic) {
                if(finalFieldApiName == 'Type') {
                    parentRecordData.put(finalFieldApiName, parentRecordApiName);
                } else {
                    SObject parentRecordFromDatabase = mockRecords.get(parentRecord.Id);
                    try {
                        parentRecordData.put(finalFieldApiName, parentRecordFromDatabase.get(finalFieldApiName));
                    } catch(System.SObjectException e) {
                        parentRecordData.put(finalFieldApiName, null);
                    } catch(Exception e) {
                        throw e;
                    }
                }

                // the "Name" object is a hidden SF object for polymorphic relationships
                Schema.SObjectType polymorphicSObjectSot = SchemaService.getPolymorphicSObjectType();
                String polymorphicSObjectName = SchemaService.getSObjectName(polymorphicSObjectSot);

                Map<String, String> attributes = new Map<String, String> {
                    'type' => polymorphicSObjectName,
                    'url' => '/' + parentRecord.Id
                };
                
                parentRecordData.put('attributes', attributes);
            } else {
                parentRecordData.put(finalFieldApiName, mockRecords.get(parentRecord.Id).get(finalFieldApiName));
            }
            sObjClone.put(fieldApiName, parentRecord.Id);
            sObjClone.put(fieldRelationshipName, parentRecordData);
        }
        return this.utils.sObjectFromMap(sObjClone, objApiName);
    }

    private SObject findRecord(Id recordId) {
        String objApiName = recordId.getSObjectType().getDescribe().getName();
        try {
            return this.db.get(objApiName).get(recordId);
        } catch(Exception e) {
            throw new QueryException('No record found for ' + recordId);
        }
    }

    private SObject handleTypeOfQuery(FieldSelector fSelector) {
        SObject databaseRecord = fSelector.databaseRecord;
        SObject queriedRecord = fSelector.queriedRecord;
        Node fieldNode = fSelector.fieldNode;
        Map<String, Object> params = fSelector.params;

        if(fieldNode.nodeType != 'typeof') {
            throw new QueryException('Unexpected error');
        }

        Node whenNode = fieldNode.right;
        String relName = fieldNode.id;

        Schema.SObjectType sot = SchemaService.getSObjectType(queriedRecord);
        String fieldApiName = SchemaService.getFieldNameForRelationship(sot, relName);
        String objApiName = SchemaService.getSObjectName(queriedRecord);
        Schema.SObjectField field = SchemaService.getField(sot, fieldApiName);

        if(!SchemaService.isFieldPolymorphic(field)) {
            throw new QueryException('TYPEOF operand "' + fieldApiName + '" is not a polymorphic relationship field');
        }

        Id parentRecordId = (Id) databaseRecord.get(fieldApiName);

        if(parentRecordId == null) {
            return queriedRecord;
        }
        SObject parentRecord = findRecord(parentRecordId);
        String parentObjApiName = SchemaService.getSObjectName(parentRecord).toLowerCase();

        Node curr = whenNode;
        Node fieldListNode;
        while(true) {
            if(curr == null) {
                fieldListNode = null;
                break;
            }

            Node objNode = curr.left;
            Node thenNode = curr.right;
            if(curr.nodeType == 'else') {
                fieldListNode = curr.right;
                break;
            }

            String expectedObjName = objNode.id;
            if(expectedObjName == parentObjApiName) {
                fieldListNode = thenNode;
                break;
            }

            curr = curr.right.right;
        }

        if(fieldListNode == null) {
            return queriedRecord;
        }

        curr = fieldListNode;
        List<String> selectFields = new List<String>();
        while(curr != null) {
            Schema.SObjectType parentRecordSot = SchemaService.getSObjectType(parentRecord);
            String parentRecordFieldApiName = SchemaService.getFieldName(parentRecordSot, curr.id);
            selectFields.add(parentRecordFieldApiName);
            curr = curr.left;
        }

        Map<String, Object> parentRecordData = new Map<String, Object>();
        if(queriedRecord.getSObject(relName) != null) {
            parentRecordData = this.utils.mapFromSObject(queriedRecord.getSObject(relName));
        }

        for(String parentRecordFieldApiName : selectFields) {
            parentRecordData.put(parentRecordFieldApiName, parentRecord.get(parentRecordFieldApiName));
        }
        parentRecordData.put('Id', parentRecord.Id);
        
        Map<String, String> attributes = new Map<String, String> {
            'type' => SchemaService.getSObjectName(parentRecord),
            'url' => '/' + parentRecord.Id
        };
        parentRecordData.put('attributes', attributes);
        Map<String, Object> sObjClone = this.utils.mapFromSObject(queriedRecord);

        Schema.DescribeFieldResult dfr = SchemaService.describeField(objApiName, fieldApiName);
        String relApiName = dfr.getRelationshipName();

        sObjClone.put(relApiName, parentRecordData);
        sObjClone.put(fieldApiName, parentRecord.Id);
        return this.utils.sObjectFromMap(sObjClone, objApiName);

    }

    private sObject handleParentSubQuery(FieldSelector fSelector) {
        SObject queriedRecord = fSelector.queriedRecord;
        Node fieldNode = fSelector.fieldNode;
        Map<String, Object> params = fSelector.params;

        String fieldName = fieldNode.id;

        List<String> fieldParts = fieldName.split('\\.');
        String finalField = fieldParts[fieldParts.size()-1];
        fieldParts.remove(fieldParts.size()-1);
        return buildObjWithRelations(queriedRecord, fieldParts, finalField);
    }

    private SObject handleChildSubQuery(FieldSelector fSelector) {
        SObject queriedRecord = fSelector.queriedRecord;
        Node fieldNode = fSelector.fieldNode;
        Map<String, Object> params = fSelector.params;

        String objApiName = SchemaService.getSObjectName(queriedRecord);
        Node subquerySelectNode = fieldNode.right;
        Node subqueryFromNode = subquerySelectNode.right;

        Node subqueryObjNode = subqueryFromNode.left;
        String subqueryChildRelationshipName = subqueryObjNode.id;

        Schema.SObjectType childObjectType = SchemaService.getSObjectType(objApiName);
        List<Schema.ChildRelationship> childRelationships = SchemaService.getChildRelationships(childObjectType);

        Schema.ChildRelationship subqueryChildRelationship = null;
        for (Schema.ChildRelationship childRelationship : childRelationships) {
            if(!SchemaService.isChildRelationship(childRelationship, subqueryChildRelationshipName)) {
                continue;
            }
            subqueryChildRelationship = childRelationship;
            break;
        }

        if(subqueryChildRelationship == null) {
            throw new QueryException('Invalid relationship name: ' + subqueryChildRelationshipName);
        }

        String subQueryObjName = SchemaService.getChildRelationshipChildSObjectName(subQueryChildRelationship);
        String subQueryFieldName = SchemaService.getChildRelationshipFieldName(subQueryChildRelationship);
        subqueryChildRelationshipName = SchemaService.getChildRelationshipName(subQueryChildRelationship);

        // clone the tree so we can modify it
        Node subqueryCloneSelectNode = subQuerySelectNode.deepClone();
        TopLevelNodes subqueryCloneTopLevelNodes = new TopLevelNodes(subqueryCloneSelectNode);

        Node subqueryCloneFromNode = subqueryCloneTopLevelNodes.fromNode;
        Node subqueryCloneWhereNode = subqueryCloneTopLevelNodes.whereNode;

        subqueryCloneFromNode.left.id = subqueryObjName.toLowerCase();
        if(subqueryCloneWhereNode == null) {
            subqueryCloneWhereNode = new NodeBuilder()
                .setId('where')
                .setNodeType('where')
                .build();
            
            // need to account for something being to the right of the from node
            Node usingScopeNode = subqueryCloneTopLevelNodes.usingScopeNode;
            if(usingScopeNode != null) {
                Node nodeToRightOfUsingScopeNode = usingScopeNode.right;
                usingScopeNode.right = subqueryCloneWhereNode;
                subqueryCloneWhereNode.right = nodeToRightOfUsingScopeNode;
            } else {
                Node nodeToRightOfFromNode = subqueryCloneFromNode.right;
                subqueryCloneFromNode.right = subqueryCloneWhereNode;
                subqueryCloneWhereNode.right = nodeToRightOfFromNode;
            }
        }

        Node queryConditionNode = new NodeBuilder()
            .setId('=')
            .setNodeType('operator')
            .setLeft(new NodeBuilder()
                .setId(subQueryFieldName.toLowerCase())
                .setNodeType('field')
                .build())
            .setRight(new NodeBuilder()
                .setId(((String) queriedRecord.Id).toLowerCase())
                .setNodeType('string')
                .build())
            .build();

        if(subqueryCloneWhereNode.left == null) {
            subqueryCloneWhereNode.left = queryConditionNode;
        } else {
            subqueryCloneWhereNode.left = new NodeBuilder()
                .setId('and')
                .setNodeType('and')
                .setLeft(queryConditionNode)
                .setRight(subqueryCloneWhereNode.left)
                .build();
        }

        List<SObject> subQueryRecords = (List<SObject>) doQuery(subqueryCloneSelectNode, params);

        // so we can't mock the subquery results directly, but we can serialize them and then deserialize them
        // here we serialize the subquery results, which can't be instaniated,
        // then deserialize them into a map, then add the map to the parent object
        Map<String, Object> objMap = this.utils.mapFromSObject(queriedRecord);
        Map<String, Object> subQueryResultMap = new Map<String, Object>();
        
        subQueryResultMap.put('records', subQueryRecords);
        subQueryResultMap.put('totalSize', subQueryRecords.size());
        subQueryResultMap.put('done', true);

        objMap.put(subQueryChildRelationshipName, subQueryResultMap);

        return this.utils.sObjectFromMap(objMap, ObjApiName);
    }

    private SObject handleFieldQuery(FieldSelector fSelector) {
        SObject queriedRecord = fSelector.queriedRecord;
        SObject databaseRecord = fSelector.databaseRecord;
        Node fieldNode = fSelector.fieldNode;

        String fieldName = fieldNode.id;
        Object fieldValue = databaseRecord.get(fieldName);

        Schema.SObjectType sot = SchemaService.getSObjectType(databaseRecord);
        String sObjectName = SchemaService.getSObjectName(sot);
        if(fieldValue != null) {
            Map<String, Object> objMap = this.utils.mapFromSObject(queriedRecord);
            objMap.put(fieldName, fieldValue);
            
            queriedRecord = this.utils.sObjectFromMap(objMap, SObjectName);
        }
        return queriedRecord;
    }

    private SObject handleSelectQuery(FieldSelector fSelector) {
        Node fieldNode = fSelector.fieldNode;
        SObject queriedRecord = fSelector.queriedRecord;

        if(fieldNode == null) {
            return queriedrecord;
        }

        Boolean isTypeOf = (fieldNode.nodeType == 'typeof');
        Boolean isChildSubQuery = (fieldNode.nodeType == 'subquery');
        Boolean isParentSubQuery = (fieldNode.id.contains('.'));
        
        // Could use a strategy pattern here, but it's a bit overkill for now
        if(isTypeOf) {
            queriedRecord = handleTypeOfQuery(fSelector);
        } else if(isChildSubQuery) {
            queriedRecord = handleChildSubQuery(fSelector);
        } else if(isParentSubQuery) {
            queriedRecord = handleParentSubQuery(fSelector);
        } else {
            queriedRecord = handleFieldQuery(fSelector);
        }

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
            .setParams(params);

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

    private Object handleLimitNode(String typeOfQuery, Node limitNode, Object results, Map<String, Object> params) {
        if(limitNode == null) {
            return results;
        }

        Node limitSizeNode = limitNode.left;
        Integer limitSize;

        if(limitSizeNode.nodeType == 'bind variable' && (params == null || !params.containsKey(limitSizeNode.id))) {
            throw new QueryException('Missing bind variable: ' + limitSizeNode.id);
        }

        if(limitSizeNode.nodeType == 'bind variable') {
            limitSize = (Integer) params.get(limitSizeNode.id);
        } else {
            limitSize = Integer.valueOf(limitSizeNode.id);
        }

        if(typeOfQuery == 'count') {
            Integer count = (Integer) results;
            if(count > limitSize) {
                return limitSize;
            }
            return count;
        }

        if(typeOfQuery == 'aggregate') {
            List<ProtoAggregate> resultsList = new List<ProtoAggregate>((List<ProtoAggregate>) results);
            while(resultsList.size() > limitSize) {
                resultsList.remove(resultsList.size()-1);
            }
            return resultsList;
        }

        if(typeOfQuery == 'sObject') {
            List<SObject> resultsList = new List<SObject>((List<SObject>) results);
            while(resultsList.size() > limitSize) {
                resultsList.remove(resultsList.size()-1);
            }
            return resultsList;
        }

        throw new QueryException('Invalid query type');
    }

    /**
     * @description : given a select node, return a map with the fields to group by and the fields to select
     * @param selectNode : the select node
     * @param groupByNode : the group by node
     * @return : a map with the fields to group by and the fields to select
     */
    Map<String, List<String>> getAggregateFields(Node selectNode) {
        TopLevelNodes topLevelNodes = getTopLevelNodes(selectNode);
        Node groupByNode = topLevelNodes.groupByNode;

        if(groupByNode == null) {
            return new Map<String, List<String>> {
                'groupByFields' => new List<String>(),
                'selectFields' => new List<String>()
            };
        }
        List<String> groupByFields = new List<String>();
        List<String> selectFields = new List<String>();

        if(groupByNode != null) {
            Node currGroupByNode = groupByNode.left;
            while(currGroupByNode != null) {
                groupByFields.add(currGroupByNode.id);
                currGroupByNode = currGroupByNode.left;
            }
        }

        Node currSelectNode = selectNode.left;
        Set<String> aliases = new Set<String>();
        while(currSelectNode != null) {
            // begin with error-handling for the aggregate query

            if(currSelectNode.nodeType == 'field') {
                // check that selected fields are grouped or aggregated
                if(!groupByFields.contains(currSelectNode.id)) {
                    throw new QueryException('Field must be grouped or aggregated: ' + currSelectNode.id);
                }

                // check for duplicate aliases
                Node aliasNode = currSelectNode.right;
                String alias;
                if(aliasNode != null) {
                    alias = aliasNode.id;
                } else if(currSelectNode.id.contains('.')){
                    List<String> aliasParts = currSelectNode.id.split('\\.');
                    alias = aliasParts[aliasParts.size()-1];
                } else {
                    alias = currSelectNode.id;
                }

                Integer initAliasSize = aliases.size();
                aliases.add(alias);
                
                if(initAliasSize == aliases.size()) {
                    throw new QueryException('Duplicate alias: ' + alias);
                }

                selectFields.add(currSelectNode.id);
            } else if(currSelectNode.nodeType == 'aggregate function') {
                // check that aggregated fields are not grouped
                Node fieldNode = currSelectNode.right;
                if(groupByFields.contains(fieldNode.id)) {
                    throw new QueryException('Grouped field should not be aggregated: ' + fieldNode.id);
                }
            }
            currSelectNode = currSelectNode.left;
        }
        
        Map<String, List<String>> aggregateFields = new Map<String, List<String>> {
            'groupByFields' => groupByFields,
            'selectFields' => selectFields
        };
        return aggregateFields;
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

    /** scary function, needs refactor */
    private Map<String, String> getRollupFieldOrAlias(Node selectNode, Node rollupNode) {
        String fieldApiName;
        String relationshipName;
        Map<String, Object> aliasData;

        for(Node currSelect = selectNode.left; currSelect != null; currSelect = currSelect.left) {
            if(currSelect.id == rollupNode.id) {
                try {
                    aliasData = getAlias(selectNode, currSelect);
                    fieldApiName = (String) aliasData.get('fieldApiName');
                    relationshipName = (String) aliasData.get('relationshipName');
                    break;
                } catch(QueryException ex) {
                    aliasData = this.utils.getComparableDataFromNodes(currSelect, selectNode);
                    fieldApiName = (String) aliasData.get('comparableField');
                    relationshipName = (String) aliasData.get('relationshipName');
                    break;
                } catch(Exception ex) {
                    throw new QueryException('Invalid field or relationship name');
                }
            }
        }

        if(fieldApiName == null) {
            aliasData = this.utils.getComparableDataFromNodes(rollupNode, selectNode);
            fieldApiName = (String) aliasData.get('comparableField');
            relationshipName = (String) aliasData.get('relationshipName');
            if(fieldApiName == null) {
                throw new QueryException('Invalid field or relationship name');
            }
        }

        return new Map<String, String> {
            'fieldOrAlias' => fieldApiName,
            'relationshipName' => relationshipName
        };
    }

    private List<ProtoAggregate> replaceWithAliases(Node selectNode, List<ProtoAggregate> aggregates) {
        List<ProtoAggregate> aggregateResults = new List<ProtoAggregate>(aggregates);
        
        for(ProtoAggregate aggr : aggregateResults) {
            for(Node currSelect = selectNode.left; currSelect != null; currSelect = currSelect.left) {
                String fieldOrAliasFromSelect = getAlias(selectNode, currSelect).get('fieldApiName');
                for(String key : aggr.keySet()) {
                    if(key.toLowerCase() == currSelect.id && key != fieldOrAliasFromSelect) {
                        aggr.put(fieldOrAliasFromSelect, aggr.get(key));
                        aggr.remove(key);
                        break;
                    }
                }
            }
        }

        return aggregateResults;
    }

    private Boolean isRollup(Node groupByNode) {
        return (
            groupByNode != null && 
            groupByNode.id == 'rollup'
        );
    }

    private List<String> buildRollupFields(Node selectNode) {
        TopLevelNodes topLevelNodes = getTopLevelNodes(selectNode);
        Node groupByNode = topLevelNodes.groupByNode;

        List<String> fields = new List<String>();
        for(Node rollupNode = groupByNode.left; rollupNode != null; rollupNode = rollupNode.left) {
            Map<String, String> rollupFieldOrAlias = getRollupFieldOrAlias(selectNode, rollupNode);
            String fieldOrAlias = rollupFieldOrAlias.get('fieldOrAlias');
            fields.add(
                fieldOrAlias
            );
        }
        return fields;
    }

    private List<ProtoAggregate> buildSummaryList(List<String> fields, Node selectNode, List<ProtoAggregate> aggregates) {
        List<ProtoAggregate> summaryList = new List<ProtoAggregate>();
        for(Integer i = 0; i < fields.size(); i++) {

            String field1 = null;
            if(i > 0) {
                field1 = fields[0];
            }
            String field2 = null;
            if(i > 1) {
                field2 = fields[1];
            }

            List<ProtoAggregate> rollupAggregates = calculateRollup(selectNode, aggregates, field1, field2);
            for(ProtoAggregate ra : rollupAggregates) {
                for(String key : aggregates[0].keySet()) {
                    if(!ra.containsKey(key)) {
                        ra.put(key, null);
                    }
                }
            }
            summaryList.addAll(rollupAggregates);
            rollupAggregates.clear();
        } 
        return summaryList;
    }

    public AggregateComparator buildRollupComparator(Node selectNode) {
        TopLevelNodes topLevelNodes = getTopLevelNodes(selectNode);
        Node groupByNode = topLevelNodes.groupByNode;

        Map<String, Map<String, String>> fieldsSortData = new Map<String, Map<String, String>>();
        for(Node currNode = groupByNode.left; currNode != null; currNode = currNode.left) {
            Map<String, String> rollupFieldOrAlias = getRollupFieldOrAlias(selectNode, currNode);
            String fieldOrAlias = rollupFieldOrAlias.get('fieldOrAlias');
            String relationshipName = rollupFieldOrAlias.get('relationshipName');
        
            Map<String, String> fieldData = new Map<String, String> {
                'fieldApiName' => fieldOrAlias,
                'relationshipName' => relationshipName,
                'order' => 'asc',
                'nullDir' => 'last'
            };
            fieldsSortData.put(fieldOrAlias, fieldData);
        }

        AggregateComparator comparator = new AggregateComparator(fieldsSortData);
        return comparator;
    }

    // I'ma be shook if this works
    private List<ProtoAggregate> handleGroupByRollup(List<ProtoAggregate> aggregates, Node selectNode) {
        TopLevelNodes topLevelNodes = getTopLevelNodes(selectNode);
        Node groupByNode = topLevelNodes.groupByNode;
        if(!isRollup(groupByNode)) {
            return aggregates;
        }

        List<String> fields = buildRollupFields(selectNode);
        List<ProtoAggregate> summaryList = buildSummaryList(fields, selectNode, aggregates);
        aggregates.addAll(summaryList);

        AggregateComparator comparator = buildRollupComparator(selectNode);
        aggregates.sort(comparator);

        return aggregates;
    }

    // no PMD because this is a big boi
    private List<ProtoAggregate> calculateRollup( // NOPMD
        Node selectNode, 
        List<ProtoAggregate> rollupAggregates, 
        String field1,
        String field2
    ) {
        Node fieldNode = selectNode.left;
        List<ProtoAggregate> aggregateResults = new List<ProtoAggregate>();

        for(Node currSelect = selectNode.left; currSelect != null; currSelect = currSelect.left) {
            Boolean isAggregateFunc = (currSelect.nodeType == 'aggregate function');
            Boolean isAggrSum = (isAggregateFunc && currSelect.id == 'sum');
            Boolean isAggrCount = (isAggregateFunc && currSelect.id == 'count');
            Boolean isAggrMax = (isAggregateFunc && currSelect.id == 'max');
            Boolean isAggrMin = (isAggregateFunc && currSelect.id == 'min');
            Boolean isAggrAvg = (isAggregateFunc && currSelect.id == 'avg');
            Boolean isAggrCountDistinct = (isAggregateFunc && currSelect.id == 'count_distinct');

            if(!isAggregateFunc) {
                continue;
            }
            String alias = getAlias(selectNode, currSelect).get('fieldApiName');
            for(ProtoAggregate currAggr : rollupAggregates) {
                ProtoAggregate aggr = null;

                // find the aggregate result that matches the current rollup aggregate
                for(ProtoAggregate ar : aggregateResults) {
                    // if field == null, there's only the grand total in the list
                    if(field1 == null) {
                        aggr = ar;
                        break;
                    } else if(ar.get(field1) == currAggr.get(field1) && field2 == null) {
                        aggr = ar;
                        break;
                    } else if(ar.get(field1) == currAggr.get(field1) && ar.get(field2) == currAggr.get(field2)) {
                        aggr = ar;
                        break;
                    }
                }

                // if the aggregate result doesn't exist, create it
                if(aggr == null) {
                    aggr = new ProtoAggregate();
                    if(field1 != null) {
                        aggr.put(field1, currAggr.get(field1));
                    }
                    if(field2 != null) {
                        aggr.put(field2, currAggr.get(field2));
                    }
                    aggregateResults.add(aggr);
                }

                // count's a little diff. the original calc just added 1, but we need to add the count of the rollup aggregate
                if(isAggrCount) {
                    Integer count = (Integer) aggr.get(alias);
                    if(count == null) {
                        count = 0;
                    }

                    if(currAggr.get(alias) != null) {
                        count += (Integer) currAggr.get(alias);
                    }
                    
                    aggr.put(alias, count);
                } else {
                    calculateAggregate(
                        currSelect, 
                        alias, 
                        aggr,
                        currAggr.get(alias)
                    );
                }
            }
        }
        return aggregateResults;
    }

    /**
     * @description calculates the aggregate result for the current proto aggregate
     *              mutates the aggregate, returns the mutated aggregate as well
     * @param currSelect : the current select node
     * @param alias : the alias for the aggregated field
     * @param aggregateResult : the current aggregate result
     * @param value : the value to calculate the aggregate with
     * @return the mutated aggregate
     */
    private ProtoAggregate calculateAggregate(
        Node currSelect, 
        String alias, 
        ProtoAggregate aggregateResult,
        Object value
    ) {

        AggregateCalculatorOptions options = new AggregateCalculatorOptions()
            .setAlias(alias)
            .setAggregateResult(aggregateResult)
            .setValue(value);


        IAggregateCalculator calculator = AggregateCalculatorFactory.getCalculator(currSelect.id, options);
        return calculator.calculate();
    }

    /**
     * @description : find the grouped aggregate
     * @param databaseRecord : the database record
     * @param aggregateResults : the aggregate results list to search
     * @param groupByFields : the fields to group by
     * @return : the grouped aggregate
     */
    private ProtoAggregate findGroupedAggregate(SObject databaseRecord, List<ProtoAggregate> aggregateResults, List<String> groupByFields) {
        for(ProtoAggregate ar : aggregateResults) {
            Boolean isSame = true;
            for(String groupByField : groupByFields) {
                Map<String, Object> comparableInfo = this.utils.getComparables(databaseRecord, groupByField);
                sObject comparableRecord = (sObject) comparableInfo.get('comparableRecord');
                String comparableField = (String) comparableInfo.get('comparableField');

                Schema.SObjectType sot = SchemaService.getSObjectType(comparableRecord);
                Schema.SObjectField comparableSObjField = SchemaService.getField(sot, comparableField);
                Boolean isPolymorphic = (Boolean) comparableInfo.get('isPolymorphic');
                Boolean isType = (comparableField == 'Type');
                if(isPolymorphic && isType) {
                    String type = SchemaService.getSObjectName(comparableRecord);
                    isSame = (isSame && (type == ar.get(comparableField)));
                } else {
                    isSame = (isSame && (comparableRecord.get(comparableField) == ar.get(comparableField)));
                }
            }
            if(isSame) {
                return ar;
            }
        }
        return null;
    }

    /**
     * @description create a new aggregate result for the grouped aggregate
     * @param databaseRecord the database record
     * @param groupByFields the fields to group by
     * @return the new aggregate result
     */
    private ProtoAggregate createGroupedAggregate(SObject databaseRecord, List<String> groupByFields) {
        ProtoAggregate aggregateResult = new ProtoAggregate();
        for(String groupByField : groupByFields) {
            Map<String, Object> comparableInfo = this.utils.getComparables(databaseRecord, groupByField);
            sObject comparableRecord = (sObject) comparableInfo.get('comparableRecord');
            String comparableField = (String) comparableInfo.get('comparableField');

            Boolean isPolymorphic = (Boolean) comparableInfo.get('isPolymorphic');
            Boolean isType = (comparableField == 'Type');
            if(isPolymorphic && isType) {
                String type = SchemaService.getSObjectName(comparableRecord);
                aggregateResult.put(comparableField, type);
            } else if(isPolymorphic) {
                try {
                    aggregateResult.put(comparableField, comparableRecord.get(comparableField));
                } catch(System.SObjectException e) {
                    aggregateResult.put(comparableField, null);
                } catch(Exception e) {
                    throw e;
                }
            } else {
                aggregateResult.put(comparableField, comparableRecord.get(comparableField));
            }
        }
        return aggregateResult; 
    }

    // only called when there are three fields to group by
    ProtoAggregate findSummaryAggregateFieldTwo(
        SObject databaseRecord, 
        List<ProtoAggregate> summarySubResults, 
        Node selectNode
    ) {
        TopLevelNodes topLevelNodes = getTopLevelNodes(selectNode);
        Node groupByNode = topLevelNodes.groupByNode;

        List<String> fields = buildRollupFields(selectNode);
        String field1 = fields[0];
        String alias1 = getRollupFieldOrAlias(selectNode, groupByNode.left).get('fieldOrAlias');
        String field2 = fields[1];
        String alias2 = getRollupFieldOrAlias(selectNode, groupByNode.left.left).get('fieldOrAlias');
        String alias3 = getRollupFieldOrAlias(selectNode, groupByNode.left.left.left).get('fieldOrAlias');

        // find the aggregate result that matches the current rollup aggregate
        for(ProtoAggregate sr : summarySubResults) {
            if(
                sr.get(alias1) == databaseRecord.get(field1) && 
                sr.get(alias2) == databaseRecord.get(field2) && 
                sr.get(alias3) == null
            ) {
                return sr;
            }
        }
        return null;
    }

    // expects there are two fields to group by
    ProtoAggregate findSummaryAggregateFieldOne(SObject databaseRecord, List<ProtoAggregate> summaryResults, Node selectNode) {
        TopLevelNodes topLevelNodes = getTopLevelNodes(selectNode);
        Node groupByNode = topLevelNodes.groupByNode;

        List<String> fields = buildRollupFields(selectNode);
        String field1 = fields[0];
        String alias1 = getRollupFieldOrAlias(selectNode, groupByNode.left).get('fieldOrAlias');
        String alias2 = getRollupFieldOrAlias(selectNode, groupByNode.left.left).get('fieldOrAlias');

        // find the aggregate result that matches the current rollup aggregate
        for(ProtoAggregate sr : summaryResults) {
            // if field == null, there's only the grand total in the list
            if(
                sr.get(alias1) == databaseRecord.get(field1) && 
                sr.get(alias2) == null
            ) {
                return sr;
            }
        }
        return null;
    }

    private ProtoAggregate createSummaryAggregateFieldTwo(SObject databaseRecord, Node selectNode) {
        TopLevelNodes topLevelNodes = getTopLevelNodes(selectNode);
        Node groupByNode = topLevelNodes.groupByNode;

        List<String> fields = buildRollupFields(selectNode);

        ProtoAggregate aggregateResult = new ProtoAggregate();

        String field1 = fields[0];
        String alias1 = getRollupFieldOrAlias(selectNode, groupByNode.left).get('fieldOrAlias');
        String field2 = fields[1];
        String alias2 = getRollupFieldOrAlias(selectNode, groupByNode.left.left).get('fieldOrAlias');
        String field3 = fields[2];
        String alias3 = getRollupFieldOrAlias(selectNode, groupByNode.left.left.left).get('fieldOrAlias');
        aggregateResult.put(alias1, databaseRecord.get(field1));
        aggregateResult.put(alias2, databaseRecord.get(field2));
        aggregateResult.put(alias3, null);

        return aggregateResult;        
    }

    private ProtoAggregate createSummaryAggregateFieldOne(SObject databaseRecord, Node selectNode) {
        TopLevelNodes topLevelNodes = getTopLevelNodes(selectNode);
        Node groupByNode = topLevelNodes.groupByNode;

        List<String> fields = buildRollupFields(selectNode);

        ProtoAggregate aggregateResult = new ProtoAggregate();

        String field1 = fields[0];
        String alias1 = getRollupFieldOrAlias(selectNode, groupByNode.left).get('fieldOrAlias');
        String field2 = fields[1];
        String alias2 = getRollupFieldOrAlias(selectNode, groupByNode.left.left).get('fieldOrAlias');
        aggregateResult.put(alias1, databaseRecord.get(field1));
        aggregateResult.put(alias2, null);

        return aggregateResult;
    }

    private ProtoAggregate createGrandSummaryAggregate(Node selectNode) {
        TopLevelNodes topLevelNodes = getTopLevelNodes(selectNode);
        Node groupByNode = topLevelNodes.groupByNode;

        List<String> fields = buildRollupFields(selectNode);
        ProtoAggregate aggregateResult = new ProtoAggregate();

        if(fields.size() == 1) {
            String alias1 = getRollupFieldOrAlias(selectNode, groupByNode.left).get('fieldOrAlias');
            aggregateResult.put(alias1, null);
        }

        if(fields.size() == 2) {
            String alias1 = getRollupFieldOrAlias(selectNode, groupByNode.left).get('fieldOrAlias');
            String alias2 = getRollupFieldOrAlias(selectNode, groupByNode.left.left).get('fieldOrAlias');
            aggregateResult.put(alias1, null);
            aggregateResult.put(alias2, null);
        }

        if(fields.size() == 3) {
            String alias1 = getRollupFieldOrAlias(selectNode, groupByNode.left).get('fieldOrAlias');
            String alias2 = getRollupFieldOrAlias(selectNode, groupByNode.left.left).get('fieldOrAlias');
            String alias3 = getRollupFieldOrAlias(selectNode, groupByNode.left.left.left).get('fieldOrAlias');
            aggregateResult.put(alias1, null);
            aggregateResult.put(alias2, null);
            aggregateResult.put(alias3, null);
        }
        return aggregateResult;
    }

    private ProtoAggregate findGrandSummaryAggregate(Node selectNode, List<ProtoAggregate> summaryResults) {
        TopLevelNodes topLevelNodes = getTopLevelNodes(selectNode);
        Node groupByNode = topLevelNodes.groupByNode;

        List<String> fields = buildRollupFields(selectNode);
        ProtoAggregate aggregateResult = new ProtoAggregate();

        String alias1 = null;
        String alias2 = null;
        String alias3 = null;

        if(fields.size() == 1) {
            alias1 = getRollupFieldOrAlias(selectNode, groupByNode.left).get('fieldOrAlias');
        }

        if(fields.size() == 2) {
            alias2 = getRollupFieldOrAlias(selectNode, groupByNode.left.left).get('fieldOrAlias');
        }

        if(fields.size() == 3) {
            alias3 = getRollupFieldOrAlias(selectNode, groupByNode.left.left.left).get('fieldOrAlias');
        }

        for(ProtoAggregate sr : summaryResults) {
            if(
                fields.size() == 1 && 
                sr.get(alias1) == null
            ) {
                return sr;
            }

            if(
                fields.size() == 2 && 
                sr.get(alias1) == null && 
                sr.get(alias2) == null
            ) {
                return sr;
            }

            if(
                fields.size() == 3 && 
                sr.get(alias1) == null && 
                sr.get(alias2) == null && 
                sr.get(alias3) == null
            ) {
                return sr;
            }
        }
        return null;
    }

    private Map<String, List<ProtoAggregate>> handleAggregateQuery(
        SObject databaseRecord,
        Node selectNode, 
        List<ProtoAggregate> aggregateResults,
        List<ProtoAggregate> summaryResults,
        List<ProtoAggregate> summarySubResults,
        ProtoAggregate grandSummaryResult
    ) {

        aggregateResults = new List<ProtoAggregate>(aggregateResults);
        summaryResults = new List<ProtoAggregate>(summaryResults);
        
        Map<String, List<String>> aggrFields = getAggregateFields(selectNode);
        List<String> groupByFields = aggrFields.get('groupByFields');
        
        ProtoAggregate aggregateResult = findGroupedAggregate(databaseRecord, aggregateResults, groupByFields);
        if(aggregateResult == null) {
            aggregateResult = createGroupedAggregate(databaseRecord, groupByFields);
            aggregateResults.add(aggregateResult);
        }

        // if it's not a rollup, then we don't need to calculate the summary results
        // if there's only one field, the grand summary is the same as the grouped aggregate
        TopLevelNodes topLevelNodes = getTopLevelNodes(selectNode);
        Node groupByNode = topLevelNodes.groupByNode;

        ProtoAggregate summaryResult = null;
        ProtoAggregate summarySubResult = null;
        

        if(isRollup(groupByNode)) {

            if(groupByFields.size() >= 2) {
                summaryResult = findSummaryAggregateFieldOne(databaseRecord, summaryResults, selectNode);
                if(summaryResult == null) {
                    summaryResult = createSummaryAggregateFieldOne(databaseRecord, selectNode);
                    summaryResults.add(summaryResult);
                }
            } 
            
            if(groupByFields.size() == 3) {
                summarySubResult = findSummaryAggregateFieldTwo(databaseRecord, summarySubResults, selectNode);
                if(summarySubResult == null) {
                    summarySubResult = createSummaryAggregateFieldTwo(databaseRecord, selectNode);
                    summarySubResults.add(summarySubResult);
                }
            }
        }

        Integer exprNumber = 0;
        for(Node currSelect = selectNode.left; currSelect != null; currSelect = currSelect.left) {
            Boolean isAggregateFunc = (currSelect.nodeType == 'aggregate function');

            if(!isAggregateFunc) {
                continue;
            }


            Node fieldNode = currSelect.right;
            Node aliasNode = fieldNode.left;
            String fieldName = fieldNode.id;

            Map<String, Object> comparableInfo = this.utils.getComparables(databaseRecord, fieldName);
            sObject comparableRecord = (sObject) comparableInfo.get('comparableRecord');
            String comparableField = (String) comparableInfo.get('comparableField');

            Schema.SObjectType sot = SchemaService.getSObjectType(comparableRecord);
            Schema.DisplayType fieldType = SchemaService.getFieldType(sot, comparableField);
            
            String alias = 'expr' + exprNumber;

            if(aliasNode != null) {
                alias = aliasNode.id;
            } else {
                exprNumber++;
            }

            Boolean isFieldNumeric = SchemaService.isFieldNumeric(fieldType);

            List<String> numericFuncs = new List<String> {
                'sum', 'max', 'min', 'avg'
            };

            Boolean isExpectingNumeric = (numericFuncs.contains(currSelect.id));
            if(isExpectingNumeric && !isFieldNumeric) {
                throw new QueryException('Invalid field type');
            }

            System.debug(comparableField);
            System.debug(comparableRecord.get(comparableField));

            // mutates aggregate result
            calculateAggregate(
                currSelect, 
                alias, 
                aggregateResult,
                comparableRecord.get(comparableField)
            );

            // mutates summary result
            if(summaryResult != null) {
                calculateAggregate(
                    currSelect, 
                    alias, 
                    summaryResult,
                    comparableRecord.get(comparableField)
                );
            }

            if(summarySubResult != null) {
                calculateAggregate(
                    currSelect, 
                    alias, 
                    summarySubResult,
                    comparableRecord.get(comparableField)
                );
            }

            // grand summary result
            if(grandSummaryResult != null) {
                calculateAggregate(
                    currSelect, 
                    alias, 
                    grandSummaryResult,
                    comparableRecord.get(comparableField)
                );
            }
        }
        return new Map<String, List<ProtoAggregate>> {
            'aggregateResults' => aggregateResults,
            'summaryResults' => summaryResults,
            'summarySubResults' => summarySubResults
        };
    }

    private ProtoAggregate cleanUpAggregateResult(
        ProtoAggregate aggr, 
        List<String> groupByFields, 
        List<String> selectFields
    ) {
        aggr = aggr.clone();

        for(String groupByField : groupByFields) {
            if(selectFields.contains(groupByField)) {
                continue;
            }

            for(String key : aggr.keySet()) {
                if(key.toLowerCase() == groupByField) {
                    aggr.remove(key);
                }
            }
        }
        
        for(String key : aggr.keySet()) {
            Boolean isAvg = key.endsWith('__n');
            Boolean isDistinct = key.endsWith('__distinct');
            if(isAvg || isDistinct) {
                aggr.remove(key);
            }
        }
        return aggr;
    }

    /**
     * @description Remove the fields that are not in the select clause
     * @param aggregateResults : the aggregate result list
     * @param selectNode : the select node
     * @return : the cleaned up aggregate result list
     */
    private List<Aggregate> createAggregates(
        List<ProtoAggregate> aggregateResults, 
        Node selectNode,
        Map<String, Object> params
    ) {
        // get list of all fields to group by, if is aggregate query
        Map<String, List<String>> aggregateFields = getAggregateFields(selectNode);
        List<String> groupByFields = aggregateFields.get('groupByFields');
        List<String> selectFields = aggregateFields.get('selectFields');

        List<Aggregate> aggregateResultsList = new List<Aggregate>();
        for(Integer i = 0; i < aggregateResults.size(); i++) {
            ProtoAggregate ar = aggregateResults[i];

            ar = cleanUpAggregateResult(ar, groupByFields, selectFields);
            Aggregate arp = new Aggregate(ar);
            aggregateResultsList.add(arp);
        }
        return aggregateResultsList;
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

    private Map<String, String> getFieldAlias(Node curr, Node fieldNode, Node selectNode) {
        Node aliasNode = curr.right;
        String fieldApiName;
        String relationshipName;
        if(aliasNode != null) {
            fieldApiName = aliasNode.id;
            relationshipName = null;
        } else {
            Map<String, Object> comparables = this.utils.getComparableDataFromNodes(fieldNode, selectNode);
            relationshipName = (String) comparables.get('relationshipName');
            fieldApiName = (String) comparables.get('comparableField');
        }

        return new Map<String, String> {
            'fieldApiName' => fieldApiName,
            'relationshipName' => relationshipName
        };       
    }

    private Map<String, String> getAggrFuncAlias(Node curr, Integer exprNumber) {
        Node aggrFieldNode = curr.right;
        Node aliasNode = aggrFieldNode.left;
        String fieldApiName;
        if(aliasNode != null) {
            fieldApiName = aliasNode.id;
        } else {
            fieldApiName = 'expr' + exprNumber;
        }

        return new Map<String, String> {
            'fieldApiName' => fieldApiName,
            'relationshipName' => null
        };
    }
    
    private Map<String, String> getAlias(Node selectNode, Node fieldNode) {
        Integer exprNumber = 0;

        Node curr = selectNode.left;
        while(curr != null) {
            Boolean isField = (curr.nodeType == 'field');
            Boolean isSameId = (curr.id == fieldNode.id);
            
            Boolean isAggregateFunc = (curr.nodeType == 'aggregate function');
            Boolean isSameAggrField = (isAggregateFunc && curr.right.id == fieldNode?.right?.id);

            if(isField && isSameId) {
                return getFieldAlias(curr, fieldNode, selectNode);
            } else if(isAggregateFunc && isSameAggrField && isSameId) {
                return getAggrFuncAlias(curr, exprNumber);
            } else if(isAggregateFunc) {
                exprNumber++;
            }
            curr = curr.left;
        }
        throw new QueryException('No alias found');
    }

    private Object handleOrderByNode(
        String typeOfQuery, 
        Object results, 
        Node selectNode, 
        Node orderByNode
    ) {
        if(results == null) {
            return results;
        }

        if(typeOfQuery == 'aggregate') {
            return sortByOrderBy((List<ProtoAggregate>) results, selectNode, orderByNode);
        } else if(typeOfQuery == 'sObject') {
            return sortByOrderBy((List<SObject>) results, selectNode, orderByNode);
        } else {
            throw new QueryException('Invalid results type');
        }
    }

    /**
     * @description : given an offset node, return the offset value
     */
    private Object handleOffsetNode(
        String typeOfQuery, 
        Node offsetNode, 
        Object results, 
        Map<String, Object> params
    ) {
        if(offsetNode == null) {
            return results;
        }
        Integer offset;
        Node offsetSizeNode = offsetNode.left;
    
        if(offsetNode.nodeType == 'bind variable' && (params == null || !params.containsKey(offsetSizeNode.id))) {
            throw new QueryException('Missing bind variable: ' + offsetSizeNode.id);
        }
        if(offsetSizeNode.nodeType == 'bind variable') {
            offset = (Integer) params.get(offsetSizeNode.id);
        } else {
            offset = Integer.valueOf(offsetSizeNode.id);
        }

        if(typeOfQuery == 'aggregate') {
            List<ProtoAggregate> aggrResults = new List<ProtoAggregate>((List<ProtoAggregate>) results);
            while(offset > 0) {
                aggrResults.remove(0);
                offset--;
            }
            return aggrResults;
        } else if(typeOfQuery == 'sObject') {
            List<SObject> sObjResults = new List<SObject>((List<SObject>) results);
            while(offset > 0) {
                sObjResults.remove(0);
                offset--;
            }
            return sObjResults;
        } else if(typeOfQuery == 'count') {
            Integer value = (Integer) results - offset;
            if(value < 0) {
                value = 0;
            }
            return value;
        } else {
            throw new QueryException('Invalid query type');
        }
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

            Map<String, String> aliasData = getAlias(selectNode, orderByField);
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
            Map<String, Object> comparables = this.utils.getComparableDataFromNodes(orderByField, selectNode);
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
        String objName = obj.getSObjectType().getDescribe().getName();
        Map<Id, sObject> mockObjects = this.db.get(objName);

        String fakeId = fflib_IDGenerator.generate(obj.getSObjectType());
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

        // process the query, whether it's a count, aggregate, or regular query
        for(sObject databaseRecord : mockObjects.values()) {
            BooleanLogicOptions whereLogicOptions = new BooleanLogicOptions()
                .setDatabase(this)
                .setHead(whereNode)
                .setObj(databaseRecord)
                .setParams(params);

            if(!checkWhereClause(whereLogicOptions)) {
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
            Map<String, List<ProtoAggregate>> aggregateData = handleAggregateQuery(
                databaseRecord, 
                selectNode, 
                aggregateResults,
                summaryResults,
                summarySubResults,
                grandSummaryResult
            );
            aggregateResults = aggregateData.get('aggregateResults');
            summaryResults = aggregateData.get('summaryResults');
            summarySubResults = aggregateData.get('summarySubResults');
        }

        if(isRollup(groupByNode)) {
            aggregateResults.addAll(summaryResults);
            aggregateResults.addAll(summarySubResults);
            aggregateResults.add(grandSummaryResult);
            AggregateComparator comparator = buildRollupComparator(selectNode);
            aggregateResults.sort(comparator);
        }

        // handle the ORDER BY and LIMIT logic here
        if(isAggregateQuery) {
            replaceWithAliases(selectNode, aggregateResults);
            aggregateResults = (List<ProtoAggregate>) handleHavingNode(aggregateResults, selectNode, params);
            aggregateResults = (List<ProtoAggregate>) handleOrderByNode('aggregate', aggregateResults, selectNode, orderByNode);
            aggregateResults = (List<ProtoAggregate>) handleOffsetNode('aggregate', offsetNode, aggregateResults, params);
            aggregateResults = (List<ProtoAggregate>) handleLimitNode('aggregate', limitNode, aggregateResults, params);

            // Remove internal fields from the aggregate result proto-records and return the list of aggregates
            List<Aggregate> aggregateResultsList = createAggregates(aggregateResults, selectNode, params);
            results = aggregateResultsList;
        } else if(isCount) {
            count = (Integer) handleOffsetNode('count', offsetNode, count, params);
            count = (Integer) handleLimitNode('count', limitNode, count, params);
            results = count;
        } else {
            sObjects = (List<SObject>) handleOrderByNode('sObject', sObjects, selectNode, orderByNode);
            sObjects = (List<SObject>) handleOffsetNode('sObject', offsetNode, sObjects, params);
            sObjects = (List<SObject>) handleLimitNode('sObject', limitNode, sObjects, params);
            results = sObjects;
        }
        this.topLevelNodes.remove(selectNode);
        return results;
    }
}