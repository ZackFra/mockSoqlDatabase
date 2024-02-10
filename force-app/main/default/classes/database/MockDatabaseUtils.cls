/**
 * @description : utilities for a MockDatabase, contains methods that don't mutate the database
 */
public with sharing class MockDatabaseUtils {

    /**
     * @description : a map of lowercase "Name" fields to their actual field names, "Name" being the hidden SObject for polymorphism
     */
    public final static Map<String, String> POLYMORPHIC_FIELDS = new Map<String, String> {
        'alias' => 'Alias',
        'email' => 'Email',
        'firstname' => 'FirstName',
        'isactive' => 'IsActive',
        'lastname' => 'LastName',
        'lastreferenceddata' => 'LastReferencedDate',
        'lastvieweddate' => 'LastViewedDate',
        'middlename' => 'MiddleName',
        'name' => 'Name',
        'phone' => 'Phone',
        'profile' => 'Profile',
        'profileid' => 'ProfileId',
        'suffix' =>'Suffix',
        'title' => 'Title',
        'type' => 'Type',
        'username' => 'Username',
        'userrole' => 'UserRole',
        'userroleid' => 'UserRoleId'
    };

    private MockDatabase db;
    public MockDatabaseUtils(MockDatabase db) {
        this.db = db;
    }

    /**
     * @description Given an sObject and a lowercase relationship name, case-insensitive, return the relationship api name
     * @param sObjType : the child sObject
     * @param relationshipName : the relationship name
     * @return : the field api name
     * @throws QueryException : if the relationship name is invalid
     */
    public String getRelationshipApiName(Schema.SObjectType sObjType, String relationshipName) {
        Map<String, Object> args = new Map<String, Object> {
            'sObjType' => sObjType,
            'relationshipName' => relationshipName
        };
        Common.nullCheck(args);

        relationshipName = relationshipName.toLowerCase();
        List<Schema.SObjectField> sObjFields = sObjType.getDescribe().fields.getMap().values();
        for(Schema.SObjectField field : sObjFields) {
            Schema.DescribeFieldResult dfr = field.getDescribe();
            List<Schema.sObjectType> relatedSObjs = dfr.getReferenceTo();
            if(relatedSObjs.isEmpty()) {
                continue;
            }
            String fieldRelationshipApiName = dfr.getRelationshipName();
            if(fieldRelationshipApiName == null) {
                continue;
            }

            if(fieldRelationshipApiName.toLowerCase() != relationshipName) {
                continue;
            }
            return fieldRelationshipApiName;
        }
        throw new QueryException('Invalid relationship name: ' + relationshipName);
    }

    /**
     * @description : given an sObject and a field name (which may be a relationon i.e. Account.Name),
     *              : return a map with the comparable sObject (i.e. the parent), the field api name of that object, 
     *              : and the relationship name
     * @param obj : the sObject
     * @param field : the field name
     * @return : a map with the comparable sObject, the field api name, and the relationship name, and whether the field is polymorphic
     * @throws QueryException : if the field name is invalid
     */
    public Map<String, Object> getComparables(sObject obj, String field) {
        sObject comparableRecord = obj;
        String comparableField = field;

        if(!comparableField.contains('.')) {
            comparableField = getFieldApiName(comparableRecord.getSObjectType(), comparableField);
            return new Map<String, Object> {
                'comparableRecord' => comparableRecord,
                'comparableField' => comparableField,
                'relationshipName' => comparableField,
                'isPolymorphic' => false
            };
        }

        List<String> fieldParts = comparableField.split('\\.');
        String finalField = fieldParts[fieldParts.size()-1];
        fieldParts.remove(fieldParts.size()-1);
        String parentField = fieldParts[0];
        sObject parentRecord;
        String relationshipName = '';
        String parentObjApiName;
        String fieldRelationshipName;
        Boolean isPolymorphic = false;
        SObject priorRecord = obj;
        while(!fieldParts.isEmpty()) {
            if(parentRecord != null) {
                priorRecord = parentRecord;
            }
            Map<String, Object> parentInfo = getParentObject(obj, parentField);
            parentRecord = (sObject) parentInfo.get('parentRecord');
            parentObjApiName = (String) parentInfo.get('parentObjApiName');
            fieldRelationshipName = (String) parentInfo.get('fieldRelationshipName');
            relationshipName += fieldRelationshipName + '.';
            isPolymorphic = (Boolean) parentInfo.get('isPolymorphic');
            
            parentRecord = this.db.get(parentObjApiName).get(parentRecord.Id);
            

            fieldParts.remove(0);
            if(!fieldParts.isEmpty()) {
                parentField = fieldParts[0];
            }
        }
        comparableRecord = parentRecord;

        Map<String, Object> comparables = new Map<String, Object> {
            'isPolymorphic' => false
        };
        if(isPolymorphic) {
            Boolean isPolyField = (MockDatabaseUtils.POLYMORPHIC_FIELDS.containsKey(finalField.toLowerCase()));
            if(isPolyField) {
                comparableField = MockDatabaseUtils.POLYMORPHIC_FIELDS.get(finalField.toLowerCase());
                comparables.put('isPolymorphic', true);
            } else {
                comparableField = getFieldApiName(comparableRecord.getSObjectType(), finalField);
            }
        } else {
            comparableField = getFieldApiName(comparableRecord.getSObjectType(), finalField);
        }
        relationshipName += comparableField;
        comparables.put('comparableRecord', comparableRecord);
        comparables.put('comparableField', comparableField);
        comparables.put('relationshipName', relationshipName);
        return comparables;
    }

    /** 
     * @description : given a field node and a select node, return a map with the comparable sObject data, 
     *                the field api name, and the relationship name, builds on getComparables
     * @param fieldNode : the field node
     * @param selectNode : the select node
     * @return : a map with the comparable sObject, the field api name, and the relationship name
     * @throws QueryException : if the field name is invalid
     * @see getComparables
     */
    public Map<String, Object> getComparableDataFromNodes(Node fieldNode, Node selectNode) {
        String fieldName = fieldNode.id;
        Node fromNode = selectNode.right;
        Node objNode = fromNode.left;
        String objName = objNode.id;

        String objApiName = getSObjectApiName(objName);
        Type t = type.forName(objApiName);
        if(t == null) {
            throw new QueryException('Invalid object name: ' + objName);
        }
        sObject sObj = (sObject) t.newInstance();
        return getComparableData(sObj, fieldName);
    }

    /**
     * @description : getComparables, except we don't return the comparable sObject, we return a blank sObject of that type
     * @param obj : the sObject
     * @param field : the field name
     * @return : a map with the comparable sObject, the field api name, and the relationship name
     * @throws QueryException : if the field name is invalid
     */
    public Map<String, Object> getComparableData(sObject obj, String field) {
        sObject comparableRecord = obj;
        String comparableField = field;
        if(!comparableField.contains('.')) {
            comparableField = getFieldApiName(comparableRecord.getSObjectType(), comparableField);
            return new Map<String, Object> {
                'comparableRecord' => comparableRecord,
                'comparableField' => comparableField,
                'relationshipName' => comparableField
            };
        }

        List<String> fieldParts = comparableField.split('\\.');
        String finalField = fieldParts[fieldParts.size()-1];
        fieldParts.remove(fieldParts.size()-1);
        String parentField = fieldParts[0];
        sObject parentRecord;
        String relationshipName = '';
        while(!fieldParts.isEmpty()) {
            Map<String, Object> parentInfo = getParentObjectData(obj, parentField);

            parentRecord = (sObject) parentInfo.get('parentRecord');
            relationshipName += (String) parentInfo.get('fieldRelationshipName') + '.';
            

            fieldParts.remove(0);
            if(!fieldParts.isEmpty()) {
                parentField = fieldParts[0];
            }
        }
        comparableRecord = parentRecord;
        comparableField = getFieldApiName(comparableRecord.getSObjectType(), finalField);
        relationshipName += comparableField;

        return new Map<String, Object> {
            'comparableRecord' => comparableRecord,
            'comparableField' => comparableField,
            'relationshipName' => relationshipName
        };
    }

    /**
     * @description : given a field node return whether it is numeric or not
     * @param fieldType : the field type
     * @return : whether the field is numeric or not
     */
    public Boolean isFieldNumeric(Schema.DisplayType fieldType) {
        Boolean isCurrency = (fieldType == Schema.DisplayType.CURRENCY);
        Boolean isDouble = (fieldType == Schema.DisplayType.DOUBLE);
        Boolean isInteger = (fieldType == Schema.DisplayType.INTEGER);
        Boolean isPercent = (fieldType == Schema.DisplayType.PERCENT);
        
        return (isCurrency || isDouble || isInteger || isPercent);
    }


    public Map<String, Object> getAggrNodeValue(Node aggrNode, Node selectNode) {

        if(aggrNode.nodeType == 'field') {
            Map<String, Object> aggrNodeValue = new Map<String, Object> {
                'field' => aggrNode.id
            };

            if(aggrNode.right == null) {
                Map<String, Object> comparables = getComparableDataFromNodes(aggrNode, selectNode);
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
            String objApiName = getSObjectApiName(objName);
            Type t = type.forName(objApiName);
            if(t == null) {
                throw new QueryException('Invalid object name: ' + objName);
            }
            sObject childObj = ((SObject)t.newInstance()).getSObjectType().newSObject();
            if(childObj == null) {
                throw new QueryException('Invalid object name: ' + objName);
            }
            Schema.DescribeSObjectResult fieldDsor = childObj.getSObjectType().getDescribe();
            String fieldApiName = null;
            for(Schema.SObjectField field : fieldDsor.fields.getMap().values()) {
                if(field.getDescribe().getName() == fieldName) {
                    fieldApiName = field.getDescribe().getName();
                    break;
                }
            }
            if(fieldApiName == null) {
                throw new QueryException('Invalid field name: ' + fieldName);
            }

            Schema.SObjectField childObjField = childObj.getSObjectType().getDescribe().fields.getMap().get(fieldApiName);
            if(childObjField == null) {
                throw new QueryException('Invalid field name: ' + fieldName);
            }



            Schema.DisplayType childObjFieldType = childObjField.getDescribe().getType();

            if(childObjFieldType != Schema.DisplayType.REFERENCE && childObjFieldType != Schema.DisplayType.ID) {
                throw new QueryException('Subquery must select an ID field');
            }
            String parentFieldApiName = getFieldApiName(childObj.getSObjectType(), fieldName);
            Schema.SObjectField parentField = childObj.getSObjectType().getDescribe().fields.getMap().get(parentFieldApiName);
            if(parentField == null) {
                throw new QueryException('Invalid field name: ' + fieldName);
            }
            
            String childObjFieldName = childObjField.getDescribe().getName();
            String childObjApiName = childObj.getSObjectType().getDescribe().getName();
            Boolean isSameType = idsReferenceSameSObject(objApiName, fieldName, childObjApiName, childObjfieldName);

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

    /**
     * @description given an object name, return the api name of the object
     * @param objName : the name of the object
     */
    public String getSObjectApiName(String objName) {
        objName = objName.toLowerCase();
        Type t = type.forName(objName);
        if(t == null) {
            throw new QueryException('Invalid object name: ' + objName);
        }
        DescribeSObjectResult dsor = (((SObject)t.newInstance()).getSObjectType()).getDescribe();
        String objApiName = dsor.getName();
        return objApiName;
    }

    public Schema.DisplayType getFieldType(SObject sObj, String fieldName) {
        Schema.SObjectType sObjType = sObj.getSObjectType();
        Schema.DescribeSObjectResult dsor = sObjType.getDescribe();
        Schema.SObjectField field = dsor.fields.getMap().get(fieldName);
        if(field == null) {
            throw new QueryException('Invalid field name: ' + fieldName);
        }
        return field.getDescribe().getType();
    }

    /**
     * @description Given an sObject and a field name, return the field api name
     *              DOES NOT worth with polymorphic fields
     * @param sObj the sObject
     * @param fieldName the field name
     * @return the field api name
     */
    public String getFieldApiName(Schema.SObjectType sObjType, String fieldName) {
        Map<String, Object> args = new Map<String, Object> {
            'sObjType' => sObjType,
            'fieldName' => fieldName
        };
        Common.nullCheck(args);

        fieldName = fieldName.toLowerCase();
        Schema.DescribeSObjectResult fieldDsor = sObjType.getDescribe();
        for(Schema.SObjectField field : fieldDsor.fields.getMap().values()) {
            if(field.getDescribe().getName().toLowerCase() == fieldName) {
                return field.getDescribe().getName();
            }
        }

        throw new QueryException('Invalid field name: ' + fieldName);
    }

    public Boolean idsReferenceSameSObject(String sObj1ApiName, String field1, String sObj2ApiName, String field2) {

        Type t1 = type.forName(sObj1ApiName);
        Type t2 = type.forName(sObj2ApiName);

        if(t1 == null || t2 == null) {
            throw new QueryException('Invalid object name');
        }

        sObject sObj1Instance = (sObject) t1.newInstance();
        sObject sObj2Instance = (sObject) t2.newInstance();

        Schema.DescribeSObjectResult sObj1Dsor = sObj1Instance.getSObjectType().getDescribe();
        Schema.DescribeSObjectResult sObj2Dsor = sObj2Instance.getSObjectType().getDescribe();

        Schema.SObjectField sObj1Field = sObj1Dsor.fields.getMap().get(field1);
        Schema.SObjectField sObj2Field = sObj2Dsor.fields.getMap().get(field2);

        if(sObj1Field == null || sObj2Field == null) {
            throw new QueryException('Invalid field name');
        }

        Schema.DisplayType sObj1FieldType = sObj1Field.getDescribe().getType();
        Schema.DisplayType sObj2FieldType = sObj2Field.getDescribe().getType();

        List<Schema.DisplayType> validTypes = new List<Schema.DisplayType> {
            Schema.DisplayType.REFERENCE,
            Schema.DisplayType.ID
        };

        if(!validTypes.contains(sObj1FieldType) || !validTypes.contains(sObj2FieldType)) {
            throw new QueryException('Invalid field type');
        }

        // if both are IDs, check that they refer to the same object type
        if(sObj1FieldType == Schema.DisplayType.ID && sObj2FieldType == Schema.DisplayType.ID) {
            // NOTE: as the code exists now, we shouldn't get here, but I'm leaving this here in case we change the code
            // a query where both fields are IDs should throw an exception before getting here
            return sObj1Instance.getSObjectType() == sObj2Instance.getSObjectType();
        }

        // if one is a reference and the other is an ID, check that the ID is a reference to the reference's object type
        if(sObj1FieldType == Schema.DisplayType.REFERENCE && sObj2FieldType == Schema.DisplayType.ID) {
            List<Schema.sObjectType> sObj1FieldRefs = sObj1Field.getDescribe().getReferenceTo();
            for(Schema.SObjectType ref : sObj1FieldRefs) {
                if(ref == sObj2Instance.getSObjectType()) {
                    return true;
                }
            }
            return false;
        }

        // check that for the other way around too
        if(sObj1FieldType == Schema.DisplayType.ID && sObj2FieldType == Schema.DisplayType.REFERENCE) {
            List<Schema.sObjectType> sObj2FieldRefs = sObj2Field.getDescribe().getReferenceTo();
            for(Schema.SObjectType ref : sObj2FieldRefs) {
                if(ref == sObj1Instance.getSObjectType()) {
                    return true;
                }
            }
            return false;
        }

        // if they're both references then check that they can refer to the same object type
        if(sObj1FieldType == Schema.DisplayType.REFERENCE && sObj2FieldType == Schema.DisplayType.REFERENCE) {
            List<Schema.sObjectType> sObj1FieldRefs = sObj1Field.getDescribe().getReferenceTo();
            List<Schema.sObjectType> sObj2FieldRefs = sObj2Field.getDescribe().getReferenceTo();

            for(Schema.SObjectType ref1 : sObj1FieldRefs) {
                for(Schema.SObjectType ref2 : sObj2FieldRefs) {
                    if(ref1 == ref2) {
                        return true;
                    }
                }
            }
            return false;
        }

        return false;
    }

    /** @description : return a parent sObject from a field name and a child sObject
      * @param sObj : the child sObject
      * @param fieldName : the field name of the parent sObject from the child
      *                  : ex. OpportunityLineItem, the field is Opportunity
      */
    public Map<String, Object> getParentObject(sObject sObj, String fieldName) {
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
                    String childFieldApiName = f.getDescribe().getName();
                    parentObjApiName = ((Id) sObj.get(childFieldApiName)).getSobjectType().getDescribe().getName();
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

    /**
     * @description : given an sObject and a relationship name, return the field api name
     * @param sObj : the sObject
     * @param relName : the relationship name
     * @return : the field api name
     * @throws QueryException : if the relationship name is invalid
     */
    public String getFieldApiNameFromRelationship(SObjectType sObjType, String relName) {
        for (SObjectField f : sObjType.getDescribe().fields.getMap().values()) {
            if (f.getDescribe().getType() == DisplayType.Reference && f.getDescribe().getRelationshipName().toLowerCase() == relName) {
                return f.getDescribe().getName();
            }
        }
        throw new QueryException('Invalid relationship name: ' + relName);
    }

    public Boolean isRelationshipPolymorphic(SObjectType sObjType, String relationshipName) {
        Map<String, Object> args = new Map<String, Object> {
            'sObjType' => sObjType,
            'relationshipName' => relationshipName
        };
        Common.nullCheck(args);

        String relationshipApiName = getRelationshipApiName(sObjType, relationshipName);
        String relationshipFieldApiName = getFieldApiNameFromRelationship(sObjType, relationshipApiName);
        List<Schema.SObjectType> relatedSObjs = sObjType.getDescribe().fields.getMap().get(relationshipFieldApiName).getDescribe().getReferenceTo();
        return relatedSObjs.size() > 1;
    }

    public Boolean isFieldPolymorphic(String objApiName, String fieldApiName) {
        /**
         * 1. If relationshipName is not null, the field is a relationship field. 
         * 2. If, in addition, namePointing is true, polymorphicForeignKey is true, 
         *    and referenceTo has more than one referenced object type, then the field is polymorphic.
         */
        Map<String, Object> args = new Map<String, Object> {
            'objApiName' => objApiName,
            'fieldApiName' => fieldApiName
        };
        Common.nullCheck(args);

        Map<String, Object> fieldData = getFieldData(objApiName, fieldApiName);
        Boolean isNamePointing = (Boolean) fieldData.get('isNamePointing');
        List<Schema.sObjectType> referenceTo = (List<Schema.sObjectType>) fieldData.get('referenceTo');
        return isNamePointing && referenceTo.size() > 1;
    }

    /**
     * @description This method is used primarily to discover if a field is polymorphic, 
     * @param objApiName : the api name of the sObject
     * @param fieldApiName : the api name of the field
     * @return : a map with the field data
     */
    public Map<String, Object> getFieldData(String objApiName, String fieldApiName) {
        Map<String, Object> args = new Map<String, Object> {
            'objApiName' => objApiName,
            'fieldApiName' => fieldApiName
        };
        Common.nullCheck(args);

        Schema.DescribeFieldResult dfr = (
                (SObject) Type.forName(objApiName)
                .newInstance()
            )
            .getSObjectType()
            .getDescribe()
            .fields
            .getMap()
            .get(fieldApiName)
            .getDescribe();
        Map<String, Object> fieldData = new Map<String, Object> {
            'name' => dfr.getName(),
            'isNamePointing' => dfr.isNamePointing(),
            'relationshipName' => dfr.getRelationshipName(),
            'referenceTo' => dfr.getReferenceTo()
        };
        return fieldData;
    }

    // @description : return a parent sObject from a field name and a child sObject
    // @param sObj : the child sObject
    // @param fieldName : the field name of the parent sObject from the child
    //                  : ex. OpportunityLineItem, the field is Opportunity
    public Map<String, Object> getParentObjectData(sObject sObj, String fieldName) {
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
                    String childFieldApiName = f.getDescribe().getName();
                    parentObjApiName = ((Id) sObj.get(childFieldApiName)).getSobjectType().getDescribe().getName();
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


    /** comparison handlers for WHERE and HAVING clauses */
    public interface OperatorHandler {
        Boolean handle(Object sObjectFieldValue, Object fieldValue);
    }

    public class EqualityHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            Boolean isSObjNull = (sObjectFieldValue == null);
            Boolean isFieldNull = (fieldValue == null);
            if(isSObjNull && isFieldNull) {
                return true;
            } else if(isSObjNull || isFieldNull) {
                return false;
            }

            if(sObjectFieldValue instanceof Date) {
                fieldValue = parseDate((String) fieldValue);
                return fieldValue == (Date) sObjectFieldValue;
            } else if(SObjectFieldValue instanceof DateTime) {
                fieldValue = parseDateTime((String) fieldValue);
                return fieldValue == (DateTime) sObjectFieldValue;
            } else if(SObjectFieldValue instanceof Time) {
                fieldValue = parseTime((String) fieldValue);
                return fieldValue == (Time) sObjectFieldValue;
            }

            return (String.valueOf(sObjectFieldValue).toLowerCase() == ((String)fieldValue).toLowerCase());
        }
    }

    public class InequalityHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            Boolean isSObjNull = (sObjectFieldValue == null);
            Boolean isFieldNull = (fieldValue == null);

            if(isSObjNull && isFieldNull) {
                return false;
            } else if(isSObjNull || isFieldNull) {
                return true;
            }

            if(sObjectFieldValue instanceof Date) {
                fieldValue = (Object) parseDate((String) fieldValue).toString();
            } else if(SObjectFieldValue instanceof DateTime) {
                fieldValue = (Object) parseDateTime((String) fieldValue).toString();
            } else if(SObjectFieldValue instanceof Time) {
                fieldValue = (Object) parseTime((String) fieldValue).toString();
            }

            return (String.valueOf(sObjectFieldValue).toLowerCase() != ((String)fieldValue).toLowerCase());
        }
    }

    public class LikeHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            if(sObjectFieldValue == null) {
                return false;
            }

            String regexPattern = String.valueOf(fieldValue)
                .toLowerCase()
                .replaceAll('%', '.*')
                .replaceAll('_', '.');
            Pattern regex = Pattern.compile(regexPattern);
            Matcher regexMatcher = regex.matcher(String.valueOf(sObjectFieldValue).toLowerCase());
            return regexMatcher.matches();
        }
    }

    public class InHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            if(sObjectFieldValue == null) {
                return false;
            }

            List<Object> values = (List<Object>) fieldValue;
            for(Integer i = 0; i < values.size(); i++) {
                if(values[i] instanceof String) {
                    values[i] = (Object) ((String) values[i]).toLowerCase();
                }
            }
            String nodeValue = String.valueOf(sObjectFieldValue).toLowerCase();
            return values.contains(nodeValue);
        }
    }

    public class NotInHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            if(sObjectFieldValue == null) {
                return false;
            }

            List<Object> values = (List<Object>) fieldValue;
            for(Integer i = 0; i < values.size(); i++) {
                if(values[i] instanceof String) {
                    values[i] = (Object) ((String) values[i]).toLowerCase();
                }
            }
            String nodeValue = String.valueOf(sObjectFieldValue).toLowerCase();
            return !values.contains(nodeValue);
        }
    }

    private static Time parseTime(String timeString) {
        Pattern timePattern = Pattern.compile('([0-9]{2}):([0-9]{2}):([0-9]{2})\\.([0-9]{3})Z');
        Matcher timeMatcher = timePattern.matcher(timeString);
        if(!timeMatcher.matches()) {
            throw new QueryException('Invalid time format');
        }
        return Time.newInstance( 
            Integer.valueOf(timeMatcher.group(1)),
            Integer.valueOf(timeMatcher.group(2)),
            Integer.valueOf(timeMatcher.group(3)),
            Integer.valueOf(timeMatcher.group(4))
        );
    }

    private static Date parseDate(String dateString) {
        Pattern datePattern = Pattern.compile('([0-9]{4})\\-([0-9]{2})\\-([0-9]{2})');
        Matcher dateMatcher = datePattern.matcher(dateString);
        if(!dateMatcher.matches()) {
            throw new QueryException('Invalid date format');
        }
        return Date.newInstance(
            Integer.valueOf(dateMatcher.group(1)),
            Integer.valueOf(dateMatcher.group(2)),
            Integer.valueOf(dateMatcher.group(3))
        );
    }

    private static DateTime parseDateTime(String dateTimeString) {
        // YYYY-MM-DDThh:mm:ss+hh:mm
        Pattern datePattern1 = Pattern.compile('([0-9]{4})\\-([0-9]{2})\\-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})\\+([0-9]{2}):([0-9]{2})');
        Matcher dateMatcher1 = datePattern1.matcher(dateTimeString);
        if(dateMatcher1.matches()) {
            Integer year = Integer.valueOf(dateMatcher1.group(1));
            Integer month = Integer.valueOf(dateMatcher1.group(2));
            Integer day = Integer.valueOf(dateMatcher1.group(3));
            Integer hour = Integer.valueOf(dateMatcher1.group(4));
            Integer min = Integer.valueOf(dateMatcher1.group(5));
            Integer sec = Integer.valueOf(dateMatcher1.group(6));
            Integer offsetHour = Integer.valueOf(dateMatcher1.group(7));
            Integer offsetMin = Integer.valueOf(dateMatcher1.group(8));
            return DateTime.newInstanceGmt(year, month, day, hour, min, sec)
                .addHours(offsetHour)
                .addMinutes(offsetMin);
        }
        // YYYY-MM-DDThh:mm:ss-hh:mm
        Pattern datePattern2 = Pattern.compile('([0-9]{4})\\-([0-9]{2})\\-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})\\-([0-9]{2}):([0-9]{2})');
        Matcher dateMatcher2 = datePattern2.matcher(dateTimeString);
        if(dateMatcher2.matches()) {
            Integer year = Integer.valueOf(dateMatcher2.group(1));
            Integer month = Integer.valueOf(dateMatcher2.group(2));
            Integer day = Integer.valueOf(dateMatcher2.group(3));
            Integer hour = Integer.valueOf(dateMatcher2.group(4));
            Integer min = Integer.valueOf(dateMatcher2.group(5));
            Integer sec = Integer.valueOf(dateMatcher2.group(6));
            Integer offsetHour = Integer.valueOf(dateMatcher2.group(7));
            Integer offsetMin = Integer.valueOf(dateMatcher2.group(8));
            return DateTime.newInstanceGmt(year, month, day, hour, min, sec)
                .addHours(-offsetHour)
                .addMinutes(-offsetMin);
        }
        // YYYY-MM-DDThh:mm:ssZ
        Pattern datePattern3 = Pattern.compile('([0-9]{4})\\-([0-9]{2})\\-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})Z');
        Matcher dateMatcher3 = datePattern3.matcher(dateTimeString);
        if(dateMatcher3.matches()) {
            Integer year = Integer.valueOf(dateMatcher3.group(1));
            Integer month = Integer.valueOf(dateMatcher3.group(2));
            Integer day = Integer.valueOf(dateMatcher3.group(3));
            Integer hour = Integer.valueOf(dateMatcher3.group(4));
            Integer min = Integer.valueOf(dateMatcher3.group(5));
            Integer sec = Integer.valueOf(dateMatcher3.group(6));
            return DateTime.newInstanceGmt(year, month, day, hour, min, sec);
        }

        throw new QueryException('Invalid date time format');
    }

    public class GreaterThanHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            if(sObjectFieldValue == null) {
                return false;
            }

            if(sObjectFieldValue instanceOf Date) {
                Date fieldDate = parseDate((String) fieldValue);
                Date sObjDate = (Date) sObjectFieldValue;
                return sObjDate > fieldDate;
            } else if(sObjectFieldValue instanceOf DateTime) {
                DateTime fieldDateTime = parseDateTime((String) fieldValue);
                DateTime sObjDateTime = (DateTime) sObjectFieldValue;
                return sObjDateTime > fieldDateTime;
            } else if(sObjectFieldValue instanceOf Time) {
                Time sObjTime = (Time) sObjectFieldValue;
                return sObjTime > parseTime((String) fieldValue);
            } else if(sObjectFieldValue instanceOf Integer) {
                Integer fieldInt = Integer.valueOf((String)fieldValue);
                Integer sObjInt = (Integer) sObjectFieldValue;
                return sObjInt > fieldInt;
            }  else if(sObjectFieldValue instanceOf Long) {
                Long fieldLong = Long.valueOf((String) fieldValue);
                Long sObjLong = (Long) sObjectFieldValue;
                return sObjLong > fieldLong;
            } else if(sObjectFieldValue instanceOf String) {
                String fieldString = ((String) fieldValue).toLowerCase();
                String sObjString = ((String) sObjectFieldValue).toLowerCase();
                return sObjString > fieldString;
            } else if(sObjectFieldValue instanceOf Decimal) {
                // Doubles are 64-bit floating point numbers, Decimals are 128-bit floating point numbers
                // i.e. it's safe to compare a Decimal to a Double, and all Decimals and Doubles are instances of each other.
                // i.e. (Double instanceof Decimal) == (Decimal instanceof Double) == true
                // it's dumb as fuck
                Decimal fieldDec = Decimal.valueOf((String)fieldValue);
                Decimal sObjDec = (Decimal) sObjectFieldValue;
                return sObjDec > fieldDec;
            } else {
                throw new QueryException('Invalid field type');
            }
        }
    }

    public class LessThanHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            if(sObjectFieldValue == null) {
                return false;
            }

            if(sObjectFieldValue instanceOf Date) {
                Date fieldDate = parseDate((String) fieldValue);
                Date sObjDate = (Date) sObjectFieldValue;
                return sObjDate < fieldDate;
            } else if(sObjectFieldValue instanceOf DateTime) {
                DateTime fieldDateTime = parseDateTime((String) fieldValue);
                DateTime sObjDateTime = (DateTime) sObjectFieldValue;
                return sObjDateTime < fieldDateTime;
            } else if(sObjectFieldValue instanceOf Time) {
                Time sObjTime = (Time) sObjectFieldValue;
                return sObjTime < parseTime((String) fieldValue);
            } else if(sObjectFieldValue instanceOf Integer) {
                Integer fieldInt = Integer.valueOf((String)fieldValue);
                Integer sObjInt = (Integer) sObjectFieldValue;
                return sObjInt < fieldInt;
            }  else if(sObjectFieldValue instanceOf Long) {
                Long fieldLong = Long.valueOf((String) fieldValue);
                Long sObjLong = (Long) sObjectFieldValue;
                return sObjLong < fieldLong;
            } else if(sObjectFieldValue instanceOf String) {
                String fieldString = ((String) fieldValue).toLowerCase();
                String sObjString = ((String) sObjectFieldValue).toLowerCase();
                return sObjString < fieldString;
            } else if(sObjectFieldValue instanceOf Decimal) {
                Decimal fieldDec = Decimal.valueOf((String)fieldValue);
                Decimal sObjDec = (Decimal) sObjectFieldValue;
                return sObjDec < fieldDec;
            } else {
                throw new QueryException('Invalid field type');
            }
        }
    }

    public class GreaterThanOrEqualHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            if(sObjectFieldValue == null) {
                return false;
            }

            if(sObjectFieldValue instanceOf Date) {
                Date fieldDate = parseDate((String) fieldValue);
                Date sObjDate = (Date) sObjectFieldValue;
                return sObjDate >= fieldDate;
            } else if(sObjectFieldValue instanceOf DateTime) {
                DateTime fieldDateTime = parseDateTime((String) fieldValue);
                DateTime sObjDateTime = (DateTime) sObjectFieldValue;
                return sObjDateTime >= fieldDateTime;
            } else if(sObjectFieldValue instanceOf Time) {
                Time sObjTime = (Time) sObjectFieldValue;
                return sObjTime >= parseTime((String) fieldValue);
            } else if(sObjectFieldValue instanceOf Integer) {
                Integer fieldInt = Integer.valueOf((String)fieldValue);
                Integer sObjInt = (Integer) sObjectFieldValue;
                return sObjInt >= fieldInt;
            }  else if(sObjectFieldValue instanceOf Long) {
                Long fieldLong = Long.valueOf((String) fieldValue);
                Long sObjLong = (Long) sObjectFieldValue;
                return sObjLong >= fieldLong;
            } else if(sObjectFieldValue instanceOf String) {
                String fieldString = ((String) fieldValue).toLowerCase();
                String sObjString = ((String) sObjectFieldValue).toLowerCase();
                return sObjString >= fieldString;
            } else if(sObjectFieldValue instanceOf Decimal) {
                Decimal fieldDec = Decimal.valueOf((String)fieldValue);
                Decimal sObjDec = (Decimal) sObjectFieldValue;
                return sObjDec >= fieldDec;
            } else {
                throw new QueryException('Invalid field type');
            }
        }
    }

    public class LessThanOrEqualHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            if(sObjectFieldValue == null) {
                return false;
            }

            if(sObjectFieldValue instanceOf Date) {
                Date fieldDate = parseDate((String) fieldValue);
                Date sObjDate = (Date) sObjectFieldValue;
                return sObjDate <= fieldDate;
            } else if(sObjectFieldValue instanceOf DateTime) {
                DateTime fieldDateTime = parseDateTime((String) fieldValue);
                DateTime sObjDateTime = (DateTime) sObjectFieldValue;
                return sObjDateTime <= fieldDateTime;
            } else if(sObjectFieldValue instanceOf Time) {
                Time sObjTime = (Time) sObjectFieldValue;
                return sObjTime <= parseTime((String) fieldValue);
            } else if(sObjectFieldValue instanceOf Integer) {
                Integer fieldInt = Integer.valueOf((String)fieldValue);
                Integer sObjInt = (Integer) sObjectFieldValue;
                return sObjInt <= fieldInt;
            }  else if(sObjectFieldValue instanceOf Long) {
                Long fieldLong = Long.valueOf((String) fieldValue);
                Long sObjLong = (Long) sObjectFieldValue;
                return sObjLong <= fieldLong;
            } else if(sObjectFieldValue instanceOf String) {
                String fieldString = ((String) fieldValue).toLowerCase();
                String sObjString = ((String) sObjectFieldValue).toLowerCase();
                return sObjString <= fieldString;
            } else if(sObjectFieldValue instanceOf Decimal) {
                Decimal fieldDec = Decimal.valueOf((String)fieldValue);
                Decimal sObjDec = (Decimal) sObjectFieldValue;
                return sObjDec <= fieldDec;
            } else {
                throw new QueryException('Invalid field type');
            }
        }
    }

    public class IncludesHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            List<String> values = new List<String>();
            try {
                List<Object> objList = (List<Object>) fieldValue;
                for(Object obj : objList) {
                    values.add(
                        ((String) obj).toLowerCase() + ';'
                    );
                }
            } catch(Exception ex) {
                throw new QueryException('Includes expects a list of strings');
            }
            String fieldString = ((String) sObjectFieldValue).toLowerCase();
            for(String value : values) {
                if(fieldString.contains(value)) {
                    return true;
                }
            }
            return false;
        }
    }

    public class ExcludesHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            IncludesHandler includesHandler = new IncludesHandler();
            return !includesHandler.handle(sObjectFieldValue, fieldValue);
        }
    }

    public class OperatorHandlerFactory {
        public OperatorHandler getHandler(String operator) {
            switch on operator {
                when '=' {
                    return new EqualityHandler();
                }
                when '<>' {
                    return new InequalityHandler();
                } 
                when '!=' {
                    return new InequalityHandler();
                }
                when 'like' {
                    return new LikeHandler();
                }
                when 'in' {
                    return new InHandler();
                }
                when 'not in' {
                    return new NotInHandler();
                }
                when '>' {
                    return new GreaterThanHandler();
                }
                when '<' {
                    return new LessThanHandler();
                }
                when '>=' {
                    return new GreaterThanOrEqualHandler();
                }
                when '<=' {
                    return new LessThanOrEqualHandler();
                }
                when 'includes' {
                    return new IncludesHandler();
                }
                when 'excludes' {
                    return new ExcludesHandler();
                }
                when else {
                    throw new QueryException('Invalid operator');
                }
            }
        }
    }
}