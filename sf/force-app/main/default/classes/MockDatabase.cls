public with sharing class MockDatabase {

    @TestVisible
    Map<String, Map<String, sObject>> db;
    
    Integer sObjnum = 1;
    public String getFakeId(Schema.SObjectType sot) {
        String result = String.valueOf(sObjNum++);
        String fakeId = result + sot.getDescribe().getKeyPrefix().rightPad(15 - result.length(), '0');
        return fakeId;
    }

    private String getSObjectApiName(String objName) {
        Type t = type.forName(objName);
        if(t == null) {
            throw new QueryException('Invalid object name: ' + objName);
        }
        DescribeSObjectResult dsor = (((SObject)t.newInstance()).getSObjectType()).getDescribe();
        String objApiName = dsor.getName();
        return objApiName;
    }


    public MockDatabase() {
        this.db = new Map<String, Map<String, sObject>>();
    }

    private String getFieldApiName(Schema.SObjectType sObjType, String fieldName) {
        Schema.DescribeSObjectResult fieldDsor = sObjType.getDescribe();
        String fieldApiName = null;
        for(Schema.SObjectField field : fieldDsor.fields.getMap().values()) {
            if(field.getDescribe().getName() == fieldName) {
                return field.getDescribe().getName();
            }
        }

        throw new QueryException('Invalid field name: ' + fieldName);
    }

    private Boolean idsReferenceSameSObject(String sObj1ApiName, String field1, String sObj2ApiName, String field2) {

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

    private Object getFieldNodeValue(Tokenizer.Node valueNode, sObject sObj, Map<String, Object> params) {

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
            Tokenizer.Node valueListNode = valueNode.left;
            while(valueListNode != null) {
                values.add(getFieldNodeValue(valueListNode, sObj, params));
                valueListNode = valueListNode.left;
            }
            return values;
        }

        if(valueNode.nodeType == 'subquery') {
            Tokenizer.Node subquerySelectNode = valueNode.right;
            Tokenizer.Node subqueryFieldNode = subquerySelectNode.left;
            Integer fieldsList = 0;

            Tokenizer.Node curr = subqueryFieldNode;
            while(curr != null) {
                fieldsList++;
                curr = curr.left;
            }
            if(fieldsList > 1) {
                throw new QueryException('Subquery must select only one field');
            }

            Tokenizer.Node fromNode = subquerySelectNode.right;
            Tokenizer.Node objNode = fromNode.left;

            String fieldName = subqueryFieldNode.id;
            String objName = objNode.id;
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
            String parentFieldApiName = getFieldApiName(sObj.getSObjectType(), fieldName);
            Schema.SObjectField parentField = sObj.getSObjectType().getDescribe().fields.getMap().get(parentFieldApiName);
            if(parentField == null) {
                throw new QueryException('Invalid field name: ' + fieldName);
            }

            Schema.DisplayType parentFieldType = parentField.getDescribe().getType();
            String childObjFieldName = childObjField.getDescribe().getName();
            String childObjApiName = childObj.getSObjectType().getDescribe().getName();
            Boolean isSameType = idsReferenceSameSObject(objApiName, fieldName, childObjApiName, childObjfieldName);

            if(!isSameType) {
                throw new QueryException('Subquery must select a field of the same type as the parent object');
            }

            List<sObject> subQueryObjects = (List<sObject>) doQuery(subquerySelectNode, params);
            List<Id> subQueryIds = new List<Id>();
            for(sObject subQueryObj : subQueryObjects) {
                subQueryIds.add((Id) subQueryObj.get(fieldApiName));
            }
            return subQueryIds;
        }

        return valueNode.Id;
    }

    private Boolean isWhereAndConditionMet(Tokenizer.Node andNode, sObject sObj, Map<String, Object> params) {
        Tokenizer.Node leftNode = andNode.left;
        Tokenizer.Node rightNode = andNode.right;

        return (
            isWhereConditionMet(leftNode, sObj, params) &&
            isWhereConditionMet(rightNode, sObj, params)
        );
    }

    private Boolean isWhereOrConditonMet(Tokenizer.Node orNode, sObject sObj, Map<String, Object> params) {
        Tokenizer.Node leftNode = orNode.left;
        Tokenizer.Node rightNode = orNode.right;

        return (
            isWhereConditionMet(leftNode, sObj, params) ||
            isWhereConditionMet(rightNode, sObj, params)
        );
    }

    private Boolean isWhereCompareConditionMet(Tokenizer.Node operatorNode, sObject sObj, Map<String, Object> params) {
        Tokenizer.Node fieldNode = operatorNode.left;
        Tokenizer.Node valueNode = operatorNode.right;
        
        Object fieldValue = getFieldNodeValue(valueNode, sObj, params);
        
        String fieldName = fieldNode.id;
        Object sObjectFieldValue;

        Boolean isParentField = fieldName.contains('.');
        if(!isParentField) {
            sObjectFieldValue = sObj.get(fieldName);
        } else {
            List<String> fieldParts = fieldName.split('\\.');
            String finalField = fieldParts[fieldParts.size()-1];
            fieldParts.remove(fieldParts.size()-1);
            
            Map<String, Object> parentInfo;
            sObject parentRecord = sObj;
            String parentObjApiName;
            do {
                String field = fieldParts[0];
                parentInfo = getParentObject(parentRecord, field);
                parentRecord = (sObject) parentInfo.get('parentRecord');
                parentObjApiName = (String) parentInfo.get('parentObjApiName');
                fieldParts.remove(0);
            } while(!fieldParts.isEmpty());
            parentRecord = this.db.get(parentObjApiName).get(parentRecord.Id);
            sObjectFieldValue = parentRecord.get(finalField);
        }
        
        switch on operatorNode.id {
            when '=' {
                if(sObjectFieldValue instanceof String) {
                    return ((String) sObjectFieldValue).toLowerCase() == ((String)fieldValue).toLowerCase();
                }
                return sObjectFieldValue == fieldValue;
            }
            when '!=', '<>' {
                if(sObjectFieldValue instanceof String) {
                    return ((String) sObjectFieldValue).toLowerCase() != ((String)fieldValue).toLowerCase();
                }
                return sObjectFieldValue != fieldValue;
            }
            when 'like' {
                String regexPattern = String.valueOf(fieldValue)
                    .toLowerCase()
                    .replaceAll('%', '.*')
                    .replaceAll('_', '.');
                Pattern regex = Pattern.compile(regexPattern);
                Matcher regexMatcher = regex.matcher(String.valueOf(sObjectFieldValue).toLowerCase());
                return regexMatcher.matches();
            }
            when 'in' {
                List<Object> values = (List<Object>) fieldValue;
                for(Integer i = 0; i < values.size(); i++) {
                    if(values[i] instanceof String) {
                        values[i] = (Object) ((String) values[i]).toLowerCase();
                    }
                }
                if(sObjectFieldValue instanceof String) {
                    String nodeValue = ((String) sObjectFieldValue).toLowerCase();
                    return values.contains(nodeValue);
                }
                return values.contains(sObjectFieldValue);
            }
            when 'not in' {
                List<Object> values = (List<Object>) fieldValue;
                for(Integer i = 0; i < values.size(); i++) {
                    if(values[i] instanceof String) {
                        values[i] = (Object) ((String) values[i]).toLowerCase();
                    }
                }
                if(sObjectFieldValue instanceof String) {
                    String nodeValue = ((String) sObjectFieldValue).toLowerCase();
                    return !values.contains(nodeValue);
                }
                return !values.contains(sObjectFieldValue);
            }
            when '>' {
                if(fieldValue instanceOf Date) {
                    Date fieldDate = (Date) fieldValue;
                    Date sObjDate = (Date) sObjectFieldValue;
                    return fieldDate > sObjDate;
                } else if(fieldValue instanceOf DateTime) {
                    DateTime fieldDateTime = (DateTime) fieldValue;
                    DateTime sObjDateTime = (DateTime) sObjectFieldValue;
                    return fieldDateTime > sObjDateTime;
                } else if(fieldValue instanceOf Time) {
                    Time fieldTime = (Time) fieldValue;
                    Time sObjTime = (Time) sObjectFieldValue;
                    return fieldTime > sObjTime;
                } else if(fieldValue instanceOf Integer) {
                    Integer fieldInt = (Integer) fieldValue;
                    Integer sObjInt = (Integer) sObjectFieldValue;
                    return fieldInt > sObjInt;
                } else if(fieldValue instanceOf Decimal) {
                    Decimal fieldDec = (Decimal) fieldValue;
                    Decimal sObjDec = (Decimal) sObjectFieldValue;
                    return fieldDec > sObjDec;
                } else if(fieldValue instanceOf Double) {
                    Double fieldDouble = (Double) fieldValue;
                    Double sObjDouble = (Double) sObjectFieldValue;
                    return fieldDouble > sObjDouble;
                } else if(fieldValue instanceOf Long) {
                    Long fieldLong = (Long) fieldValue;
                    Long sObjLong = (Long) sObjectFieldValue;
                    return fieldLong > sObjLong;
                } else if(fieldValue instanceOf String) {
                    String fieldString = ((String) fieldValue).toLowerCase();
                    String sObjString = ((String) sObjectFieldValue).toLowerCase();
                    return fieldString > sObjString;
                } else {
                    throw new QueryException('Invalid field type');
                }
            }
            when '<' {
                if(fieldValue instanceOf Date) {
                    Date fieldDate = (Date) fieldValue;
                    Date sObjDate = (Date) sObjectFieldValue;
                    return fieldDate.daysBetween(sObjDate) < 0;
                } else if(fieldValue instanceOf DateTime) {
                    DateTime fieldDateTime = (DateTime) fieldValue;
                    DateTime sObjDateTime = (DateTime) sObjectFieldValue;
                    return fieldDateTime < sObjDateTime;
                } else if(fieldValue instanceOf Time) {
                    Time fieldTime = (Time) fieldValue;
                    Time sObjTime = (Time) sObjectFieldValue;
                    return fieldTime < sObjTime;
                } else if(fieldValue instanceOf Integer) {
                    Integer fieldInt = (Integer) fieldValue;
                    Integer sObjInt = (Integer) sObjectFieldValue;
                    return fieldInt < sObjInt;
                } else if(fieldValue instanceOf Decimal) {
                    Decimal fieldDec = (Decimal) fieldValue;
                    Decimal sObjDec = (Decimal) sObjectFieldValue;
                    return fieldDec < sObjDec;
                } else if(fieldValue instanceOf Double) {
                    Double fieldDouble = (Double) fieldValue;
                    Double sObjDouble = (Double) sObjectFieldValue;
                    return fieldDouble < sObjDouble;
                } else if(fieldValue instanceOf Long) {
                    Long fieldLong = (Long) fieldValue;
                    Long sObjLong = (Long) sObjectFieldValue;
                    return fieldLong < sObjLong;
                } else if(fieldValue instanceOf String) {
                    String fieldString = ((String) fieldValue).toLowerCase();
                    String sObjString = ((String) sObjectFieldValue).toLowerCase();
                    return fieldString < sObjString;
                } else {
                    throw new QueryException('Invalid field type');
                }
            }
            when '>=' {
                if(fieldValue instanceOf Date) {
                    Date fieldDate = (Date) fieldValue;
                    Date sObjDate = (Date) sObjectFieldValue;
                    return fieldDate >= sObjDate;
                } else if(fieldValue instanceOf DateTime) {
                    DateTime fieldDateTime = (DateTime) fieldValue;
                    DateTime sObjDateTime = (DateTime) sObjectFieldValue;
                    return fieldDateTime >= sObjDateTime;
                } else if(fieldValue instanceOf Time) {
                    Time fieldTime = (Time) fieldValue;
                    Time sObjTime = (Time) sObjectFieldValue;
                    return fieldTime >= sObjTime;
                } else if(fieldValue instanceOf Integer) {
                    Integer fieldInt = (Integer) fieldValue;
                    Integer sObjInt = (Integer) sObjectFieldValue;
                    return fieldInt >= sObjInt;
                } else if(fieldValue instanceOf Decimal) {
                    Decimal fieldDec = (Decimal) fieldValue;
                    Decimal sObjDec = (Decimal) sObjectFieldValue;
                    return fieldDec >= sObjDec;
                } else if(fieldValue instanceOf Double) {
                    Double fieldDouble = (Double) fieldValue;
                    Double sObjDouble = (Double) sObjectFieldValue;
                    return fieldDouble >= sObjDouble;
                } else if(fieldValue instanceOf Long) {
                    Long fieldLong = (Long) fieldValue;
                    Long sObjLong = (Long) sObjectFieldValue;
                    return fieldLong >= sObjLong;
                } else if(fieldValue instanceOf String) {
                    String fieldString = ((String) fieldValue).toLowerCase();
                    String sObjString = ((String) sObjectFieldValue).toLowerCase();
                    return fieldString >= sObjString;
                } else {
                    throw new QueryException('Invalid field type');
                }
            } when '<=' {
                if(fieldValue instanceOf Date) {
                    Date fieldDate = (Date) fieldValue;
                    Date sObjDate = (Date) sObjectFieldValue;
                    return fieldDate <= sObjDate;
                } else if(fieldValue instanceOf DateTime) {
                    DateTime fieldDateTime = (DateTime) fieldValue;
                    DateTime sObjDateTime = (DateTime) sObjectFieldValue;
                    return fieldDateTime <= sObjDateTime;
                } else if(fieldValue instanceOf Time) {
                    Time fieldTime = (Time) fieldValue;
                    Time sObjTime = (Time) sObjectFieldValue;
                    return fieldTime <= sObjTime;
                } else if(fieldValue instanceOf Integer) {
                    Integer fieldInt = (Integer) fieldValue;
                    Integer sObjInt = (Integer) sObjectFieldValue;
                    return fieldInt <= sObjInt;
                } else if(fieldValue instanceOf Decimal) {
                    Decimal fieldDec = (Decimal) fieldValue;
                    Decimal sObjDec = (Decimal) sObjectFieldValue;
                    return fieldDec <= sObjDec;
                } else if(fieldValue instanceOf Double) {
                    Double fieldDouble = (Double) fieldValue;
                    Double sObjDouble = (Double) sObjectFieldValue;
                    return fieldDouble <= sObjDouble;
                } else if(fieldValue instanceOf Long) {
                    Long fieldLong = (Long) fieldValue;
                    Long sObjLong = (Long) sObjectFieldValue;
                    return fieldLong <= sObjLong;
                } else if(fieldValue instanceOf String) {
                    String fieldString = ((String) fieldValue).toLowerCase();
                    String sObjString = ((String) sObjectFieldValue).toLowerCase();
                    return fieldString <= sObjString;
                } else {
                    throw new QueryException('Invalid field type');
                }
            } when 'includes' {
                List<Object> values = (List<Object>) fieldValue;
                return values.contains(sObjectFieldValue);
            } when 'excludes' {
                List<Object> values = (List<Object>) fieldValue;
                return !values.contains(sObjectFieldValue);
            }
        }

        throw new QueryException('Invalid where condition');
    }

    private Boolean isConditionalSubExprMet(Tokenizer.Node subExprNode, sObject sObj, Map<String, Object> params) {
        return isWhereConditionMet(subExprNode.left, sObj, params);
    }

    private Boolean isWhereConditionMet(Tokenizer.Node whereField, sObject sObj, Map<String, Object> params) {
        if(whereField.nodeType == 'operator') {
            return isWhereCompareConditionMet(whereField, sObj, params);
        } else if(whereField.nodeType == 'and') {
            return isWhereAndConditionMet(whereField, sObj, params);
        } else if(whereField.nodeType == 'or') {
            return isWhereOrConditonMet(whereField, sObj, params);
        } else if(whereField.nodeType == 'conditional subexpression') {
            return isConditionalSubExprMet(whereField, sObj, params);
        } if(whereField.nodeType == 'not') {
            return !isWhereConditionMet(whereField.left, sObj, params);
        }

        throw new QueryException('Invalid where condition');
    }

    private Boolean checkWhereCondition(sObject sObj, Tokenizer.Node whereNode, Map<String, Object> params) {
        if(whereNode == null) {
            return true;
        }

        Tokenizer.Node whereField = whereNode.left;

        return isWhereConditionMet(whereField, sObj, params);
    }

    // @description : return a parent sObject from a field name and a child sObject
    // @param sObj : the child sObject
    // @param fieldName : the field name of the parent sObject from the child
    //                  : ex. OpportunityLineItem, the field is Opportunity
    private Map<String, Object> getParentObject(sObject sObj, String fieldName) {
        // api name of the child sObject
        String objApiName = sObj.getSObjectType().getDescribe().getName();
        // api name of the id object on the child (i.e. OpportunityId)
        String fieldApiName;
        // api name of the relationship field on the child (i.e. Opportunity)
        String fieldRelationshipName;
        // api name of the parent sObject
        String parentObjApiName;


        String sObjApiName = sObj.getSObjectType().getDescribe().getName();
        SObjectType t = ((SObject)Type.forName(sObjApiName).newInstance()).getSObjectType();
        String relatedApiName = t.getDescribe().getName();
        for (SObjectField f : t.getDescribe().fields.getMap().values()) {
            if (f.getDescribe().getType() == DisplayType.Reference && f.getDescribe().getRelationshipName().toLowerCase() == fieldName) {
                List<Schema.sObjectType> objTypeList = f.getDescribe().getReferenceTo();
            
                if(objTypeList.size() == 1) {
                    parentObjApiName = objTypeList[0].getDescribe().getName();
                } else {
                    // TODO: handle polymorphic
                }

                fieldApiName = f.getDescribe().getName();
                fieldRelationshipName = f.getDescribe().getRelationshipName();

                sObject parentRecord = ((sObject) Type.forName(parentObjApiName).newInstance()).getSObjectType().newSObject();
                
                Map<String, sObject> mockRecordsChild = this.db.get(objApiName);
                Id parentId = (Id) mockRecordsChild.get(sObj.Id).get(fieldApiName);

                parentRecord.put('Id', parentId);
                Map<String, Object> objInfo = new Map<String, Object> {
                    'fieldApiName' => fieldApiName,
                    'fieldRelationshipName' => fieldRelationshipName,
                    'parentObjApiName' => parentObjApiName,
                    'objApiName' => objApiName,
                    'parentRecord' => parentRecord
                };
                return objInfo;
            }
        }

        throw new QueryException('Invalid relationship name: ' + fieldName);
    }

    private sObject sObjectFromMap(Map<String, Object> sObjMap, String sObjApiName) {
        sObject sObj = (sObject) JSON.deserialize(JSON.serialize(sObjMap), Type.forName(sObjApiName));
        return sObj;
    }

    private Map<String, Object> mapFromSObject(sObject sObj) {
        Map<String, Object> sObjMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(sObj));
        return sObjMap;
    }

    private sObject buildObjWithRelations(sObject sObj, List<String> fieldParts, String finalField) {
        fieldParts = new List<String>(fieldParts);
        String fieldPart = fieldParts[0];

        Map<String, Object> parentInfo = getParentObject(sObj, fieldPart);
        sObject parentRecord = (sObject) parentInfo.get('parentRecord');
        String fieldApiName = (String) parentInfo.get('fieldApiName');
        String fieldRelationshipName = (String) parentInfo.get('fieldRelationshipName');
        String objApiName = (String) parentInfo.get('objApiName');

        Map<String, Object> sObjClone = mapFromSObject(sObj);
        String parentRecordApiName = (String) parentInfo.get('parentObjApiName');
        fieldParts.remove(0);
        if(!fieldParts.isEmpty()) {
            if(sObjClone.containsKey(fieldRelationshipName)) {
                parentRecord = sObjectFromMap((Map<String, Object>)sObjClone.get(fieldRelationshipName), parentRecordApiName);
            }
            sObject nextParent = buildObjWithRelations(parentRecord, fieldParts, finalField);
            sObjClone.put(fieldApiName, nextParent.Id);
            sObjClone.put(fieldRelationshipName, nextParent);
        } else {
            Map<String, sObject> mockRecords = this.db.get(parentRecordApiName);
            String finalFieldApiName = getFieldApiName(parentRecord.getSObjectType(), finalField);
            if(sObjClone.containsKey(fieldRelationshipName)) {
                parentRecord = sObjectFromMap((Map<String, Object>)sObjClone.get(fieldRelationshipName), parentRecordApiName);
            }

            parentRecord.put(finalFieldApiName, mockRecords.get(parentRecord.Id).get(finalFieldApiName));
            sObjClone.put(fieldApiName, parentRecord.Id);
            sObjClone.put(fieldRelationshipName, parentRecord);
        }
        return sObjectFromMap(sObjClone, objApiName);
    }

    private sObject handleParentSubQuery(sObject sObj, String sObjApiName, Tokenizer.Node field, Map<String, Object> params) {
        String fieldName = field.id;

        List<String> fieldParts = fieldName.split('\\.');
        String finalField = fieldParts[fieldParts.size()-1];
        fieldParts.remove(fieldParts.size()-1);
        return buildObjWithRelations(sObj, fieldParts, finalField);
    }

    private Map<String, Object> handleChildSubQuery(sObject obj, String objApiName, Tokenizer.Node field, Map<String, Object> params) {
        Tokenizer.Node subquerySelectNode = field.right;
        Tokenizer.Node subqueryFromNode = subquerySelectNode.right;

        Tokenizer.Node subqueryObjNode = subqueryFromNode.left;
        String subqueryChildRelationshipName = subqueryObjNode.id;

        Boolean isValidRelationship = false;
        String subQueryObjName;
        String subQueryFieldName;
        SObjectType childObjectType = ((SObject)Type.forName(objApiName).newInstance()).getSObjectType();
        for (ChildRelationship relation : childObjectType.getDescribe().getChildRelationships()) {
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
        Tokenizer.Node subqueryCloneSelectNode = Tokenizer.clone(subquerySelectNode);
        Tokenizer.Node subqueryCloneFromNode = subqueryCloneSelectNode.right;
        Tokenizer.Node subqueryCloneWhereNode = subqueryCloneFromNode.right;

        subqueryCloneFromNode.left.id = subqueryObjName.toLowerCase();
        if(subqueryCloneWhereNode == null) {
            subqueryCloneWhereNode = new Tokenizer.NodeBuilder()
                .setId('where')
                .setNodeType('where')
                .build();
            subqueryCloneFromNode.right = subqueryCloneWhereNode;
        }

        Tokenizer.Node queryConditionNode = new Tokenizer.NodeBuilder()
            .setId('=')
            .setNodeType('operator')
            .setLeft(new Tokenizer.NodeBuilder()
                .setId(subQueryFieldName.toLowerCase())
                .setNodeType('field')
                .build())
            .setRight(new Tokenizer.NodeBuilder()
                .setId(((String) obj.Id).toLowerCase())
                .setNodeType('string')
                .build())
            .build();

        if(subqueryCloneWhereNode.left == null) {
            subqueryCloneWhereNode.left = queryConditionNode;
        } else {
            subqueryCloneWhereNode.left = new Tokenizer.NodeBuilder()
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

    private sObject copyWithFields(sObject obj, Tokenizer.Node selectNode, Map<String, Object> params) {
        Tokenizer.Node field = selectNode.left;
        sObject sObj = (sObject) Type.forName(obj.getSObjectType().getDescribe().getName()).newInstance();
        String objApiName = obj.getSObjectType().getDescribe().getName();
        sObj.put('Id', obj.Id);
        while(field != null) {
            Boolean isChildSubQuery = (field.nodeType == 'subquery');
            Boolean isParentSubQuery = (field.id.contains('.'));

            if(isChildSubQuery) {
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

    private Boolean hasDuplicateFields(Tokenizer.Node selectNode) {
        Tokenizer.Node curr = selectNode;
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

    private Boolean hasDuplicateSubQueries(Tokenizer.Node selectNode) {
        Tokenizer.Node curr = selectNode;
        Set<String> subQueryRelationshipNames = new Set<String>();
        while(curr != null) {
            if(curr.nodeType == 'subquery') {
                Tokenizer.Node subQuerySelectNode = curr.right;
                Tokenizer.Node subQueryFromNode = subQuerySelectNode.right;
                Tokenizer.Node subQueryObjectNode = subQueryFromNode.left;
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

    private Object doQuery(Tokenizer.Node selectNode, Map<String, Object> params) {
        Tokenizer.Node fromNode = selectNode.right;
        Tokenizer.Node whereNode;
        Tokenizer.Node groupByNode;

        Tokenizer.Node curr = fromNode.right;

        if(curr != null && curr.nodeType == 'where') {
            whereNode = curr;
            curr = curr.right;
        }

        if(curr != null && curr.nodeType == 'group by') {
            groupByNode = curr;
            curr = curr.right;
        }

        Tokenizer.Node objNode = fromNode.left;
        String objName = objNode.id;
        String objApiName = getSObjectApiName(objName);

        Map<String, sObject> mockObjects = this.db.get(objApiName);
        if (mockObjects == null) {
            return new List<sObject>();
        }

        if(hasDuplicateSubQueries(selectNode)) {
            throw new QueryException('Cannot follow the same aggregate relationship twice');
        }

        if(hasDuplicateFields(selectNode)) {
            throw new QueryException('Duplicate field selected');
        }

        Object results;
        List<sObject> sObjects = new List<sObject>();
        Integer count = 0;
        Boolean isAggregateQuery = (groupByNode != null);
        Boolean isCount = isSingularCount(selectNode);

        List<Map<String, Object>> aggregateResults = new List<Map<String, ObjecT>>();
        
        // get list of all fields to group by, if is aggregate query
        List<String> groupByFields = new List<String>();
        if(isAggregateQuery) {
            Tokenizer.Node currGroupByNode = groupByNode.left;
            while(currGroupByNode != null) {
                groupByFields.add(currGroupByNode.id);
                currGroupByNode = currGroupByNode.left;
            }
        }

        for(sObject obj : mockObjects.values()) {
            if(!checkWhereCondition(obj, whereNode, params)) {
                continue;
            }

            if(isCount && !isAggregateQuery) {
                count++;
                continue;
            }

            if(isAggregateQuery) {
                Boolean isAccountedFor = false;
                for(Map<String, Object> ar : aggregateResults) {
                    Boolean isSame = true;
                    for(String groupByField : groupByFields) {
                        isSame = (isSame && (obj.get(groupByField) == ar.get(groupByField)));
                    }
                    if(isSame) {
                        isAccountedFor = true;
                        break;
                    }
                }

                if(isAccountedFor) {
                    continue;
                }

                Map<String, Object> aggregateResult = new Map<String, Object>();
                for(String groupByField : groupByFields) {
                    aggregateResult.put(groupByField, obj.get(groupByField));
                }
                aggregateResults.add(aggregateResult);
                // save the whole object for further processing
                sObjects.add(obj);
            } else {
                sObject sObj = copyWithFields(obj, selectNode, params);
                sObjects.add(sObj);
            }
        }

        if(isCount) {
            results = count;
        } else if(isAggregateQuery) {

            throw new QueryException('Aggregate queries are not supported');
            // TODO: figure out how to do aggregates
        } else {
            results = sObjects;
        }

        return results;
    }

    // if all we're doing is counting, no other aggregate funcs
    private Boolean isSingularCount(Tokenizer.Node selectNode) {
        return (selectNode.left.id == 'count' && selectNode.left.right == null && selectNode.left.left == null);
    } 

    // @description: This method is used to query the mock database by traversing the AST
    private Object doQuery(String query, Map<String, Object> params) {
        Tokenizer parser = new Tokenizer();
        Tokenizer.Node selectNode = parser.parse(query);
        return doQuery(selectNode, params);
    }

    /** DML methods **/

    public void doInsert(sObject obj) {
        if(obj.Id != null) {
            throw new DmlException('Cannot insert an object with an Id');
        }
        String objName = obj.getSObjectType().getDescribe().getName();
        Map<String, sObject> mockObjects = this.db.get(objName);

        String fakeId = getFakeId(obj.getSObjectType());
        obj.put('Id', fakeId);
        mockObjects = this.db.get(objName);
        if(mockObjects == null) {
            mockObjects = new Map<String, sObject>();
            this.db.put(objName, mockObjects);
        }
        mockObjects.put(obj.Id, obj);
    }

    public void doInsert(List<sObject> objList) {
        for(sObject obj : objList) {
            doInsert(obj);
        }
    }

    public void doUpdate(sObject obj) {
        String objName = obj.getSObjectType().getDescribe().getName();
        Map<String, sObject> mockObjects = this.db.get(objName);

        if (mockObjects == null) {
            throw new DmlException('Object does not exist');
        } else if (mockObjects.get(obj.Id) == null) {
            throw new DmlException('Object does not exist');
        }

        mockObjects.put(obj.Id, obj);
    }

    public void doUpdate(List<sObject> objList) {
        for(sObject obj : objList) {
            doUpdate(obj);
        }
    }

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

    public void doDelete(List<sObject> objList) {
        for(sObject obj : objList) {
            doDelete(obj);
        }
    }


    /** SOQL methods **/

    // @description: This method is used to query the mock database by traversing the AST
    public Object query(String query) {
        return doQuery(query, null);
    }

    // @description: This method is used to query the mock database by traversing the AST with bind variables
    public Object queryWithBinds(String query, Map<String, Object> params) {
        System.debug('');
        Map<String, Object> lowerCaseParams = new Map<String, Object>();
        for(String key : params.keySet()) {
            lowerCaseParams.put(key.toLowerCase(), params.get(key));
        }

        return doQuery(query, lowerCaseParams);       
    }
}