public with sharing class MockDatabase {

    public Map<String, Map<String, sObject>> db = new Map<String, Map<String, sObject>>();
    public MockDatabaseUtils utils = new MockDatabaseUtils(this);
    /**
     * @description map of the top-level nodes of select nodes, is a map to account for subqueries
     */
    private final Map<Node, TopLevelNodes> topLevelNodes = new Map<Node, TopLevelNodes>();

    /**
     * @description return all SObjects of a given type
     */
    public Map<String, sObject> get(String objApiName) {
        return this.db.get(objApiName);
    }
    
    private Boolean checkHavingCondition(
        Map<String, Object> aggr, 
        Node selectNode,
        Node havingNode,
        Map<String, Object> params
    ) {
        HavingLogicHandler havingLogicHandler = new HavingLogicHandler(this, havingNode, selectNode, aggr, params);
        return havingLogicHandler.evaluate();
    }

    private Boolean checkWhereCondition(
        sObject sObj, 
        Node whereNode, 
        Map<String, Object> params
    ) {
        WhereLogicHandler whereLogicHandler = new WhereLogicHandler(this, whereNode, sObj, params);
        return whereLogicHandler.evaluate();
    }

    private sObject buildObjWithRelations(sObject sObj, List<String> fieldParts, String finalField) {
        fieldParts = new List<String>(fieldParts);
        String fieldPart = fieldParts[0];

        Map<String, Object> parentInfo = this.utils.getParentObject(sObj, fieldPart);
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
            Map<String, sObject> mockRecords = this.db.get(parentRecordApiName);
            String finalFieldApiName = this.utils.getFieldApiName(parentRecord.getSObjectType(), finalField);
            if(sObjClone.containsKey(fieldRelationshipName)) {
                parentRecord = this.utils.sObjectFromMap((Map<String, Object>)sObjClone.get(fieldRelationshipName), parentRecordApiName);
            }

            parentRecord.put(finalFieldApiName, mockRecords.get(parentRecord.Id).get(finalFieldApiName));
            sObjClone.put(fieldApiName, parentRecord.Id);
            sObjClone.put(fieldRelationshipName, parentRecord);
        }
        return this.utils.sObjectFromMap(sObjClone, objApiName);
    }

    private SObject findRecord(Id recordId) {
        Set<String> sObjectApiNames = this.db.keySet();
        for(String sObjectApiName : sObjectApiNames) {
            Map<String, sObject> records = this.db.get(sObjectApiName);
            if(records.containsKey(recordId)) {
                return records.get(recordId);
            }
        }
        return null;
    }

    private SObject handlePolymorphicQuery(SObject sObj, Node fieldNode, Map<String, Object> params) {
        if(fieldNode.nodeType != 'typeof') {
            throw new QueryException('Unexpected error');
        }

        Node whenNode = fieldNode.right;
        String relName = fieldNode.id;

        String fieldApiName = this.utils.getFieldApiNameFromRel(sObj, relName);
        String objApiName = sObj.getSObjectType().getDescribe().getName();

        if(!this.utils.isFieldPolymorphic(objApiName, fieldApiName)) {
            throw new QueryException('TYPEOF operand "' + fieldApiName + '" is not a polymorphic relationship field');
        }

        Id parentRecordId = (Id) sObj.get(fieldApiName);
        System.debug(parentRecordId);
        System.debug(sObj);
        if(parentRecordId == null) {
            return sObj;
        }

        SObject parentRecord = findRecord(parentRecordId);
        if(parentRecord == null) {
            throw new QueryException('No record found for ' + parentRecordId);
        }
        String parentObjApiName = parentRecord.getSObjectType().getDescribe().getName().toLowerCase();

        Node curr = whenNode;
        Node fieldListNode;
        while(curr != null) {
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

        curr = fieldListNode;
        List<String> selectFields = new List<String>();
        while(curr != null) {
            String parentRecordFieldApiName = this.utils.getFieldApiName(parentRecord.getSObjectType(), curr.id);
            selectFields.add(parentRecordFieldApiName);
            curr = curr.left;
        }

        Map<String, Object> parentRecordData = new Map<String, Object>();
        if(sObj.getSObject(relName) != null) {
            parentRecordData = this.utils.mapFromSObject(sObj.getSObject(relName));
        }

        for(String parentRecordFieldApiName : selectFields) {
            parentRecordData.put(parentRecordFieldApiName, parentRecord.get(parentRecordFieldApiName));
        }
        parentRecordData.put('Id', parentRecord.Id);
        Map<String, String> attributes = new Map<String, String> {
            'type' => parentRecord.getSObjectType().getDescribe().getName(),
            'url' => '/' + parentRecord.Id
        };
        parentRecordData.put('attributes', attributes);
        Map<String, Object> sObjClone = this.utils.mapFromSObject(sObj);

        Map<String, Object> fieldData = this.utils.getFieldData(objApiName, fieldApiName);
        String relApiName = (String) fieldData.get('relationshipName');
        sObjClone.put(relApiName, parentRecordData);
        sObjClone.put(fieldApiName, parentRecord.Id);
        return this.utils.sObjectFromMap(sObjClone, objApiName);

    }

    private sObject handleParentSubQuery(sObject sObj, String sObjApiName, Node field, Map<String, Object> params) {
        String fieldName = field.id;

        List<String> fieldParts = fieldName.split('\\.');
        String finalField = fieldParts[fieldParts.size()-1];
        fieldParts.remove(fieldParts.size()-1);
        return buildObjWithRelations(sObj, fieldParts, finalField);
    }

    private Map<String, Object> handleChildSubQuery(sObject obj, String objApiName, Node field, Map<String, Object> params) {
        Node subquerySelectNode = field.right;
        Node subqueryFromNode = subquerySelectNode.right;

        Node subqueryObjNode = subqueryFromNode.left;
        String subqueryChildRelationshipName = subqueryObjNode.id;

        Boolean isValidRelationship = false;
        String subQueryObjName;
        String subQueryFieldName;
        SObjectType childObjectType = ((SObject)Type.forName(objApiName).newInstance()).getSObjectType();
        for (Schema.ChildRelationship relation : childObjectType.getDescribe().getChildRelationships()) {
            if(relation.getRelationshipName()?.toLowerCase() == subqueryChildRelationshipName) {
                subQueryObjName = relation.getChildSObject().getDescribe().getName();
                subQueryFieldName = relation.getField().getDescribe().getName();
                subqueryChildRelationshipName = relation.getRelationshipName();
                isValidRelationship = true;
                break;
            }
        }
        if(!isValidRelationship) {
            throw new QueryException('Invalid relationship name: ' + subqueryChildRelationshipName);
        }

        // clone the tree so we can modify it
        Node subqueryCloneSelectNode = subQuerySelectNode.deepClone();
        Node subqueryCloneFromNode = subqueryCloneSelectNode.right;
        Node subqueryCloneWhereNode = subqueryCloneFromNode.right;

        subqueryCloneFromNode.left.id = subqueryObjName.toLowerCase();
        if(subqueryCloneWhereNode == null) {
            subqueryCloneWhereNode = new NodeBuilder()
                .setId('where')
                .setNodeType('where')
                .build();
            subqueryCloneFromNode.right = subqueryCloneWhereNode;
        }

        Node queryConditionNode = new NodeBuilder()
            .setId('=')
            .setNodeType('operator')
            .setLeft(new NodeBuilder()
                .setId(subQueryFieldName.toLowerCase())
                .setNodeType('field')
                .build())
            .setRight(new NodeBuilder()
                .setId(((String) obj.Id).toLowerCase())
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

        List<sObject> subQueryObjects = (List<sObject>) doQuery(subqueryCloneSelectNode, params);
        Map<String, Object> subQueryResults = new Map<String, Object> {
            'records' => subQueryObjects,
            'subqueryRelationshipName' => subqueryChildRelationshipName,
            'done' => true,
            'totalSize' => subQueryObjects.size()
        };
        return subQueryResults;
    }

    private sObject copyWithFields(sObject obj, Node selectNode, Map<String, Object> params) {
        Node field = selectNode.left;
        sObject sObj = (sObject) Type.forName(obj.getSObjectType().getDescribe().getName()).newInstance();
        String objApiName = obj.getSObjectType().getDescribe().getName();
        sObj.put('Id', obj.Id);
        while(field != null) {
            Boolean isTypeOf = (field.nodeType == 'typeof');
            Boolean isChildSubQuery = (field.nodeType == 'subquery');
            Boolean isParentSubQuery = (field.id.contains('.'));
            
            if(isTypeOf) {
                sObj = handlePolymorphicQuery(obj, field, params);
            } else if(isChildSubQuery) {
                Map<String, Object> subQueryResults = handleChildSubQuery(obj, objApiName, field, params);

                String subQueryChildRelationshipName = (String) subQueryResults.get('subqueryRelationshipName');
                List<sObject> subQueryRecords = (List<sObject>) subQueryResults.get('records');

                // so we can't mock the subquery results directly, but we can serialize them and then deserialize them
                // here we serialize the subquery results, which can't be instaniated,
                // then deserialize them into a map, then add the map to the parent object
                Map<String, Object> objMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(sObj));
                Map<String, Object> subQueryResultMap = new Map<String, Object>();
                
                subQueryResultMap.put('records', subQueryRecords);
                subQueryResultMap.put('totalSize', subQueryRecords.size());
                subQueryResultMap.put('done', true);

                objMap.put(subQueryChildRelationshipName, subQueryResultMap);
                sObj = (sObject) JSON.deserialize(JSON.serialize(objMap), Type.forName(objApiName));
            } else if(isParentSubQuery) {
                sObj = handleParentSubQuery(sObj, objApiName, field, params);
            } else {
                String fieldName = field.id;
                Object fieldValue = obj.get(fieldName);
                if(fieldValue != null) {
                    Map<String, Object> objMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(sObj));
                    objMap.put(fieldName, fieldValue);
                    sObj = (sObject) JSON.deserialize(JSON.serialize(objMap), Type.forName(objApiName));
                }
            }
            field = field.left;
        }
        return sObj;
    }

    private Boolean hasDuplicateFields(Node selectNode) {
        Node curr = selectNode;
        Set<String> fieldNames = new Set<String>();
        while(curr != null) {
            if(curr.nodeType == 'field') {
                String fieldName = curr.id;
                if(fieldNames.contains(fieldName)) {
                    return true;
                }
                fieldNames.add(fieldName);
            }
            curr = curr.left;
        }
        return false;
    }

    private Boolean hasDuplicateSubQueries(Node selectNode) {
        Node curr = selectNode;
        Set<String> subQueryRelationshipNames = new Set<String>();
        while(curr != null) {
            if(curr.nodeType == 'subquery') {
                Node subQuerySelectNode = curr.right;
                Node subQueryFromNode = subQuerySelectNode.right;
                Node subQueryObjectNode = subQueryFromNode.left;
                String subQueryRelationshipName = subQueryObjectNode.id;

                if(subQueryRelationshipNames.contains(subQueryRelationshipName)) {
                    return true;
                }
                subQueryRelationshipNames.add(subQueryRelationshipName);
            }
            curr = curr.left;
        }
        return false;
    }

    private Boolean isAggregateQuery(Node selectNode) {
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
            List<Map<String, Object>> resultsList = new List<Map<String, Object>>((List<Map<String, Object>>) results);
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

    private Map<String, Object> handleAggregateQuery(
        Node selectNode,
        SObject obj, 
        List<Map<String, Object>> aggregateResults
    ) {
        aggregateResults = new List<Map<String, Object>>(aggregateResults);
        
        Map<String, List<String>> aggrFields = getAggregateFields(selectNode);
        List<String> groupByFields = aggrFields.get('groupByFields');

        Map<String, Object> aggregateResult;

        for(Map<String, Object> ar : aggregateResults) {
            Boolean isSame = true;
            for(String groupByField : groupByFields) {
                Map<String, Object> comparableInfo = this.utils.getComparables(obj, groupByField);
                sObject comparableRecord = (sObject) comparableInfo.get('comparableRecord');
                String comparableField = (String) comparableInfo.get('comparableField');
                isSame = (isSame && (comparableRecord.get(comparableField) == ar.get(comparableField)));
            }
            if(isSame) {
                aggregateResult = ar;
                break;
            }
        }

        if(aggregateResult == null) {
            aggregateResult = new Map<String, Object>();
            for(String groupByField : groupByFields) {
                Map<String, Object> comparableInfo = this.utils.getComparables(obj, groupByField);
                sObject comparableRecord = (sObject) comparableInfo.get('comparableRecord');
                String comparableField = (String) comparableInfo.get('comparableField');

                aggregateResult.put(comparableField, comparableRecord.get(comparableField));
            }
            // pointer logic, we won't have to add this again
            aggregateResults.add(aggregateResult);
        }

        Node currSelect = selectNode.left;
        Integer exprNumber = 0;
        while(currSelect != null) {
            Boolean isAggregateFunc = (currSelect.nodeType == 'aggregate function');
            Boolean isAggrSum = (isAggregateFunc && currSelect.id == 'sum');
            Boolean isAggrCount = (isAggregateFunc && currSelect.id == 'count');
            Boolean isAggrMax = (isAggregateFunc && currSelect.id == 'max');
            Boolean isAggrMin = (isAggregateFunc && currSelect.id == 'min');
            Boolean isAggrAvg = (isAggregateFunc && currSelect.id == 'avg');
            Boolean isAggrCountDistinct = (isAggregateFunc && currSelect.id == 'count_distinct');

            if(currSelect.nodeType == 'field') {
                currSelect = currSelect.left;
                continue;
            }


            Node fieldNode = currSelect.right;
            Node aliasNode = fieldNode.left;
            String fieldName = fieldNode.id;

            Map<String, Object> comparableInfo = this.utils.getComparables(obj, fieldName);
            sObject comparableRecord = (sObject) comparableInfo.get('comparableRecord');
            String comparableField = (String) comparableInfo.get('comparableField');

            Map<String, Schema.SObjectField> fieldMap = comparableRecord.getSObjectType().getDescribe().fields.getMap();
            Schema.DisplayType fieldType = fieldMap
                .get(comparableField)
                .getDescribe()
                .getType();
            
            String alias = 'expr' + exprNumber;

            if(aliasNode != null) {
                alias = aliasNode.id;
            } else {
                exprNumber++;
            }

            if(isAggrCountDistinct) {
                Integer currValue = (Integer) aggregateResult.get(alias);
                if(currValue == null) {
                    currValue = 0;
                }
                Set<Object> distinctValues = (Set<Object>) aggregateResult.get(alias + '__distinct');
                if(distinctValues == null) {
                    distinctValues = new Set<Object>();
                }
                aggregateResult.put(alias + '__distinct', distinctValues);
                Object value = comparableRecord.get(comparableField);
                if(value != null) {
                    distinctValues.add(value);
                }
                aggregateResult.put(alias, distinctValues.size());
            } else if(isAggrAvg) {
                if(!this.utils.isFieldNumeric(fieldType)) {
                    throw new QueryException('Invalid field type');
                }

                Decimal currValue = (Decimal) aggregateResult.get(alias);
                Decimal newValue = (Decimal) comparableRecord.get(comparableField);
                Decimal n = (Decimal) aggregateResult.get(alias + '__n');
                if(n == null) {
                    n = 1;
                }

                if(currValue == null) {
                    currValue = newValue;
                } else {
                    currValue = currValue + (newValue - currValue) / n;
                }

                aggregateResult.put(alias, currValue);
                aggregateResult.put(alias + '__n', n + 1);
            } if(isAggrMin) {
                if(!this.utils.isFieldNumeric(fieldType)) {
                    throw new QueryException('Invalid field type');
                }

                Decimal currValue = (Decimal) aggregateResult.get(alias);
                Decimal newValue = (Decimal) comparableRecord.get(comparableField);

                if(currValue == null) {
                    currValue = newValue;
                } else {
                    currValue = Math.min(currValue, newValue);
                }

                aggregateResult.put(alias, currValue);
            } else if(isAggrMax) {
                if(!this.utils.isFieldNumeric(fieldType)) {
                    throw new QueryException('Invalid field type');
                }

                Decimal currValue = (Decimal) aggregateResult.get(alias);
                Decimal newValue = (Decimal) comparableRecord.get(comparableField);
                if(currValue == null) {
                    currValue = newValue;
                } else {
                    currValue = Math.max(currValue, newValue);
                }

                aggregateResult.put(alias, currValue);
            } else if(isAggrCount) {
                Integer currValue = (Integer) aggregateResult.get(alias);
                if(currValue == null) {
                    currValue = 0;
                }
                aggregateResult.put(alias, currValue + 1);
            } else if(isAggrSum) {

                if(!this.utils.isFieldNumeric(fieldType)) {
                    throw new QueryException('Invalid field type');
                }

                Decimal currValue = (Decimal) aggregateResult.get(alias);
                Decimal newValue = (Decimal) comparableRecord.get(comparableField);
                Decimal sum;
                if(currValue == null) {
                    sum = newValue;
                } else {
                    sum = currValue + newValue;
                }

                aggregateResult.put(alias, sum);
            }
            currSelect = currSelect.left;
        }

        Map<String, Object> results = new Map<String, Object> {
            'aggregateResults' => aggregateResults,
            'aggregateResult' => aggregateResult
        };

        return results;
    }

    private Map<String, Object> cleanUpAggregateResult(
        Map<String, Object> aggr, 
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
        List<Map<String, Object>> aggregateResults, 
        Node selectNode,
        Map<String, Object> params
    ) {
        // get list of all fields to group by, if is aggregate query
        Map<String, List<String>> aggregateFields = getAggregateFields(selectNode);
        List<String> groupByFields = aggregateFields.get('groupByFields');
        List<String> selectFields = aggregateFields.get('selectFields');

        List<Aggregate> aggregateResultsList = new List<Aggregate>();
        for(Integer i = 0; i < aggregateResults.size(); i++) {
            Map<String, Object> ar = aggregateResults[i];

            ar = cleanUpAggregateResult(ar, groupByFields, selectFields);
            Aggregate arp = new Aggregate(ar);
            aggregateResultsList.add(arp);
        }
        return aggregateResultsList;
    }

    private List<Map<String, Object>> handleHavingNode(
        List<Map<String, Object>> aggregateResults, 
        Node selectNode, 
        Map<String, Object> params
    ) {
        TopLevelNodes topLevelNodes = getTopLevelNodes(selectNode);
        Node havingNode = topLevelNodes.havingNode;
        if(havingNode == null) {
            return aggregateResults;
        }

        List<Map<String, Object>> results = new List<Map<String, Object>>();
        for(Map<String, Object> ar : aggregateResults) {
            if(checkHavingCondition(ar, selectNode, havingNode, params)) {
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

    private Object handleOrderByNode(String typeOfQuery, Object results, Node selectNode, Node orderByNode) {
        if(results == null) {
            return results;
        }

        if(typeOfQuery == 'aggregate') {
            return sortByOrderBy((List<Map<String, Object>>) results, selectNode, orderByNode);
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
            List<Map<String, Object>> aggrResults = new List<Map<String, Object>>((List<Map<String, Object>>) results);
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

    private List<Map<String, Object>> sortByOrderBy(List<Map<String, Object>> aggregates, Node selectNode, Node orderByNode) {
        // clone the list so we don't modify the original
        aggregates = new List<Map<String, Object>>(aggregates);

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

    private Boolean isTypeOfQuery(Node selectNode) {
        Node curr = selectNode;
        while(curr != null) {
            if(curr.nodeType == 'typeof') {
                return true;
            }
            curr = curr.left;
        }
        return false;
    }

    /**
     * @description : given a select node, validate whether this query can be performed
     * @param selectNode : the select node
     * @throws QueryException : if the query is invalid
     */
    private void handleValidation(Node selectNode) {
        TopLevelNodes topLevelNodes = getTopLevelNodes(selectNode);
        Node groupByNode = topLevelNodes.groupByNode;
        Node orderByNode = topLevelNodes.orderByNode;
        Node limitNode = topLevelNodes.limitNode;
        Node offsetNode = topLevelNodes.offsetNode;
        Node forUpdateNode = topLevelNodes.forUpdateNode;

        Boolean isAggregateQuery = isAggregateQuery(selectNode);
        Boolean isCount = isSingularCount(selectNode);

        if(hasDuplicateSubQueries(selectNode)) {
            throw new QueryException('Cannot follow the same aggregate relationship twice');
        }

        if(hasDuplicateFields(selectNode)) {
            throw new QueryException('Duplicate field selected');
        }

        if(isCount && orderByNode != null) {
            throw new QueryException('COUNT() and ORDER BY may not be used together');
        }

        if(isAggregateQuery && groupByNode == null && limitNode != null) {
            throw new QueryException('Non-grouped query that uses overall aggregate functions cannot also use LIMIT');
        }

        if(isAggregateQuery && groupByNode == null && offsetNode != null) {
            throw new QueryException('Non-grouped query that uses overall aggregate functions cannot also use OFFSET');
        }

        if(isAggregateQuery && forUpdateNode != null) {
            throw new QueryException('FOR UPDATE not allowed in this context');
        }

        if(isCount && forUpdateNode != null) {
            throw new QueryException('FOR UPDATE not allowed in this context');
        }
    }

    /**
     * @description Given a record id, verify it exists in the database
     * @param recordId : the record id
     * @return : whether the record exists in the database
     */
    private Boolean isRecordInDatabase(Id recordId) {
        String recordApiName = this.utils.getSObjectApiName(recordId.getSObjectType().getDescribe().getName()).toLowerCase();
        Map<String, sObject> mockObjects = this.db.get(recordApiName);
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
        Map<String, sObject> mockObjects = this.db.get(objName);

        String fakeId = this.utils.getFakeId(obj.getSObjectType());
        obj.put('Id', fakeId);
        /**
        Map<String, Object> sObjMap = this.utils.mapFromSObject(obj);
        sObjMap.put('Id', fakeId);
        sObjMap.put('CreatedDate', DateTime.now());
        sObjMap.put('LastModifiedDate', DateTime.now());
        sObjMap.put('IsDeleted', false);
        sObjMap.put('SystemModstamp', DateTime.now());
        obj = this.utils.sObjectFromMap(sObjMap, objName);
        **/

        mockObjects = this.db.get(objName);
        if(mockObjects == null) {
            mockObjects = new Map<String, sObject>();
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
        Map<String, sObject> mockObjects = this.db.get(objName);

        if (mockObjects == null) {
            throw new DmlException('Object does not exist');
        } else if (mockObjects.get(obj.Id) == null) {
            throw new DmlException('Object does not exist');
        }

        
        for(String field : obj.getPopulatedFieldsAsMap().keySet()) {

            // check for foreign key references
            Schema.DisplayType fieldType = this.utils.getFieldType(obj, field);
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
        String objName = obj.getSObjectType().getDescribe().getName();
        Map<String, sObject> mockObjects = this.db.get(objName);

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

        // validate the query, throws exception if invalid
        handleValidation(selectNode);

        Node objNode = fromNode.left;
        String objName = objNode.id;
        String objApiName = this.utils.getSObjectApiName(objName);

        Map<String, sObject> mockObjects = this.db.get(objApiName);
        if (mockObjects == null) {
            return new List<sObject>();
        }

        Boolean isAggregateQuery = isAggregateQuery(selectNode);
        Boolean isCount = isSingularCount(selectNode);

        Object results;

        // results will either be a count, a list of sObjects, or a list of aggregates
        Integer count = 0;
        List<Map<String, Object>> aggregateResults = new List<Map<String, Object>>();
        List<sObject> sObjects = new List<sObject>();

        // process the query, whether it's a count, aggregate, or regular query
        for(sObject obj : mockObjects.values()) {
            if(!checkWhereCondition(obj, whereNode, params)) {
                continue;
            }

            if(isCount && !isAggregateQuery) {
                count++;
                continue;
            }

            // handle fields
            if(!isAggregateQuery) {
                SObject sObj = copyWithFields(obj, selectNode, params);
                sObjects.add(sObj);
                continue;
            }

            Map<String, Object> aggrResultValues = handleAggregateQuery(
                selectNode, 
                obj, 
                aggregateResults
            );
            aggregateResults = (List<Map<String, Object>>) aggrResultValues.get('aggregateResults');
        }

        // handle the ORDER BY and LIMIT logic here
        if(isAggregateQuery) {
            aggregateResults = (List<Map<String, Object>>) handleHavingNode(aggregateResults, selectNode, params);
            aggregateResults = (List<Map<String, Object>>) handleOrderByNode('aggregate', aggregateResults, selectNode, orderByNode);
            aggregateResults = (List<Map<String, Object>>) handleOffsetNode('aggregate', offsetNode, aggregateResults, params);
            aggregateResults = (List<Map<String, Object>>) handleLimitNode('aggregate', limitNode, aggregateResults, params);

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