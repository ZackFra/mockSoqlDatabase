/**
 * @description : utilities for a MockDatabase, contains methods that don't mutate the database
 */
public with sharing class MockDatabaseUtils {

    private MockDatabase db;
    public MockDatabaseUtils(MockDatabase db) {
        this.db = db;
    }


    public Map<String, Object> getAggrNodeValue(Node aggrNode, Node selectNode) {

        if(aggrNode.nodeType == 'field') {
            Map<String, Object> aggrNodeValue = new Map<String, Object> {
                'field' => aggrNode.id
            };

            if(aggrNode.right == null) {
                Map<String, Object> comparables = ComparableService.getComparableDataFromNodes(aggrNode, selectNode);
                String comparableField = (String) comparables.get('comparableField');
                aggrNodeValue.put('alias', comparableField);
            } else {
                String alias = aggrNode.right.id;
                aggrNodeValue.put('alias', alias);
            }
            return aggrNodeValue;
        }


        Integer exprNumber = 0;
        String alias = 'expr' + exprNumber;
        
        Node curr = selectNode;
        while(curr != null) {
            if(curr.nodeType != 'aggregate function') {
                curr = curr.left;
                continue;
            }

            if(curr.id != aggrNode.id) {
                exprNumber++;
                curr = curr.left;
                continue;
            }

            Node foundFieldNode = curr.right;
            Node aliasNode = foundFieldNode.left;

            if(aliasNode == null) {
                exprNumber++;
                curr = curr.left;
                continue;
            }
            
            alias = aliasNode.id;
            break;
        }

        // if we're here, we should have an alias
        if(alias == null) {
            throw new QueryException('Invalid alias');
        }

        Node fieldNode = aggrNode.right;
        return new Map<String, Object> {
            'field' => fieldNode.id,
            'alias' => alias
        };
    }

    public sObject sObjectFromMap(Map<String, Object> sObjMap, String sObjApiName) {
        sObject sObj = (sObject) JSON.deserialize(JSON.serialize(sObjMap), Type.forName(sObjApiName));
        return sObj;
    }

    public Map<String, Object> mapFromSObject(sObject sObj) {
        Map<String, Object> sObjMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(sObj));
        return sObjMap;
    }


    public Object getFieldNodeValue(Node valueNode, sObject sObj, Map<String, Object> params) {

        Boolean isBindVar = (valueNode.nodeType == 'bind variable');
        Boolean isParamsNull = (params == null);
        Boolean isValueInParams = (!isParamsNull && params.containsKey(valueNode.id));
        

        if(isBindVar && isParamsNull || isBindVar && !isValueInParams) {
            throw new QueryException('Missing bind variable: ' + valueNode.id);
        }

        if(isBindVar) {
            return params.get(valueNode.id);
        }

        if(valueNode.nodeType == 'value list') {
            List<Object> values = new List<Object>();
            Node valueListNode = valueNode.left;
            while(valueListNode != null) {
                values.add(getFieldNodeValue(valueListNode, sObj, params));
                valueListNode = valueListNode.left;
            }
            return values;
        }

        if(valueNode.nodeType == 'subquery') {
            Node subquerySelectNode = valueNode.right;
            Node subqueryFieldNode = subquerySelectNode.left;
            Integer fieldsList = 0;

            Node curr = subqueryFieldNode;
            while(curr != null) {
                fieldsList++;
                curr = curr.left;
            }
            if(fieldsList > 1) {
                throw new QueryException('Subquery must select only one field');
            }

            Node subqueryFromNode = subquerySelectNode.right;
            Node subqueryObjNode = subqueryFromNode.left;

            String fieldName = subqueryFieldNode.id;
            String objName = subqueryObjNode.id;

            String objApiName = SchemaService.getSObjectName(objName);
            sObject childObj = SchemaService.blankSObjectFrom(objApiName);
            if(childObj == null) {
                throw new QueryException('Invalid object name: ' + objName);
            }
            String fieldApiName = null;
            Schema.SObjectType childObjSot = SchemaService.getSObjectType(childObj);
            List<Schema.SObjectField> childObjFields = SchemaService.getFields(childObjSot);
            for(Schema.SObjectField field : childObjFields) {
                fieldApiName = SchemaService.getFieldName(field);
                if(fieldApiName == fieldName) {
                    fieldApiName = fieldApiName;
                    break;
                }
            }
            if(fieldApiName == null) {
                throw new QueryException('Invalid field name: ' + fieldName);
            }

            Schema.SObjectField childObjField = SchemaService.getField(childObjSot, fieldApiName);
            if(childObjField == null) {
                throw new QueryException('Invalid field name: ' + fieldName);
            }

            Schema.DisplayType childObjFieldType = SchemaService.getFieldType(childObjField);

            if(childObjFieldType != Schema.DisplayType.REFERENCE && childObjFieldType != Schema.DisplayType.ID) {
                throw new QueryException('Subquery must select an ID field');
            }
            String parentFieldApiName = SchemaService.getFieldName(childObj, fieldName);
            Schema.SObjectField parentField = SchemaService.getField(childObj, parentFieldApiName);
            
            String childObjFieldName = SchemaService.getFieldName(childObjField);
            String childObjApiName = SchemaService.getSObjectName(childObj);

            Boolean isSameType = SchemaService.idsReferenceSameSObject(parentField, childObjField);

            if(!isSameType) {
                throw new QueryException('Subquery must select a field of the same type as the parent object');
            }

            List<SObject> subQueryObjects = (List<SObject>) this.db.doQuery(subquerySelectNode, params);
            List<Id> subQueryIds = new List<Id>();
            for(sObject subQueryObj : subQueryObjects) {
                subQueryIds.add((Id) subQueryObj.get(fieldApiName));
            }
            return subQueryIds;
        }

        return valueNode.Id;
    }

    // @description : return a parent sObject from a field name and a child sObject
    // @param sObj : the child sObject
    // @param fieldName : the field name of the parent sObject from the child
    //                  : ex. OpportunityLineItem, the field is Opportunity
    public Map<String, Object> getParentObjectData(SObject sObj, String fieldName) {
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
        for (SObjectField f : t.getDescribe().fields.getMap().values()) {
            if (f.getDescribe().getType() == DisplayType.Reference && f.getDescribe().getRelationshipName().toLowerCase() == fieldName) {
                List<Schema.sObjectType> objTypeList = f.getDescribe().getReferenceTo();
            
                if(objTypeList.size() == 1) {
                    parentObjApiName = objTypeList[0].getDescribe().getName();
                } else {
                    Schema.SObjectType sot = SchemaService.getFieldSObjectType(f);
                    parentObjApiName = SchemaService.getSObjectName(sot);
                }

                fieldApiName = f.getDescribe().getName();
                fieldRelationshipName = f.getDescribe().getRelationshipName();
                isPolymorphic = (objTypeList.size() > 1);

                sObject parentRecord = ((sObject) Type.forName(parentObjApiName).newInstance()).getSObjectType().newSObject();
                
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
}