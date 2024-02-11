public with sharing class WhereLogicHandler extends BooleanLogicHandler {

    public WhereLogicHandler(MockDatabase db, Node head, SObject sObj, Map<String, Object> params) {
        super(db, head, sObj, params);
    }

    public override Boolean isCompareConditionMet(Node operatorNode) {
        Node fieldNode = operatorNode.left;
        Node valueNode = operatorNode.right;
        SObject sObj = (SObject) this.obj;
        Map<String, Object> params = this.params;
        
        Object fieldValue = this.db.utils.getFieldNodeValue(valueNode, sObj, params);
        
        String fieldName = fieldNode.id;
        Object sObjectFieldValue;

        Boolean isParentField = fieldName.contains('.');

        // if the field is a parent field, we need to get the parent record
        // further down, we can't say for sure whether the field is a parent field or not
        // so we'll need to store our object and field name in a variable
        sObject parentRecord = sObj;
        String finalField = fieldName;

        // the Type field on a polymorphic relationship is a special case
        Boolean isPolyType = false;

        if(!isParentField) {
            sObjectFieldValue = sObj.get(fieldName);
        } else {
            List<String> fieldParts = fieldName.split('\\.');
            finalField = fieldParts[fieldParts.size()-1];
            fieldParts.remove(fieldParts.size()-1);
            
            Map<String, Object> parentInfo;
            String parentObjApiName;
            SObject childRecord;
            do {
                String field = fieldParts[0];
                childRecord = parentRecord;
                parentInfo = this.db.utils.getParentObject(parentRecord, field);
                parentRecord = (sObject) parentInfo.get('parentRecord');
                parentObjApiName = (String) parentInfo.get('parentObjApiName');
                fieldParts.remove(0);
            } while(!fieldParts.isEmpty());
            
            String finalFieldApiName;
            String fieldRelationshipName = (String) parentInfo.get('fieldRelationshipName');

            Schema.SObjectType childRecordSObjType = SchemaService.getSObjectType(childRecord);
            Boolean isPolymorphic = SchemaService.isRelationshipPolymorphic(childRecordSObjType, fieldRelationshipName);
            Boolean isPolyField = MockDatabaseUtils.POLYMORPHIC_FIELDS.containsKey(finalField);
            
            if(isPolymorphic && isPolyField) {
                finalFieldApiName = MockDatabaseUtils.POLYMORPHIC_FIELDS.get(finalField);
            } else {
                Schema.SObjectType parentSot = SchemaService.getSObjectType(parentRecord);
                Schema.SObjectField parentField = SchemaService.getField(parentSot, finalField);
                finalFieldApiName = SchemaService.getFieldName(parentField);
            }

            if(finalFieldApiName == 'Type') {
                isPolyType = true;
                sObjectFieldValue = SchemaService.getSObjectName(parentRecord);
            } else if(isPolymorphic && isPolyField) {
                try {
                    sObjectFieldValue = parentRecord.get(finalField);
                } catch(Exception e) {
                    sObjectFieldValue = null;
                }
            } else {
                parentRecord = this.db.get(parentObjApiName).get(parentRecord.Id);
                sObjectFieldValue = parentRecord.get(finalFieldApiName);
            }
        }

        MockDatabaseUtils.OperatorHandlerFactory handlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();

        MockDatabaseUtils.OperatorHandler handler = handlerFactory.getHandler(operatorNode.id);
        if(isPolyType) {
            return handler.handle(sObjectFieldValue, fieldValue);
        }
        
        Schema.SObjectType parentSot = SchemaService.getSObjectType(parentRecord);
        Schema.DisplayType fieldType = SchemaService.getFieldType(parentSot, finalField);
        
        if(handler instanceof MockDatabaseUtils.IncludesHandler) {
            if(fieldType != Schema.DisplayType.MULTIPICKLIST) {
                throw new QueryException('Invalid field type for INCLUDES operator');
            }
        }

        if(handler instanceof MockDatabaseUtils.ExcludesHandler) {
            if(fieldType != Schema.DisplayType.MULTIPICKLIST) {
                throw new QueryException('Invalid field type for EXCLUDES operator');
            }
        }

        return handler.handle(sObjectFieldValue, fieldValue);
    }
}