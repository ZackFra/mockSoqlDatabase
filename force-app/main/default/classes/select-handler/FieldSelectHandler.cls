public with sharing class FieldSelectHandler implements ISelectHandler {
    FieldSelector fSelector;
    public FieldSelectHandler(FieldSelector fSelector) {
        this.fSelector = fSelector;
    }

    public SObject handleSelect() {
        SObject queriedRecord = fSelector.queriedRecord;
        SObject databaseRecord = fSelector.databaseRecord;
        Node fieldNode = fSelector.fieldNode;

        String fieldName = fieldNode.id;
        Object fieldValue = databaseRecord.get(fieldName);

        Schema.SObjectType sot = SchemaService.getSObjectType(databaseRecord);
        String sObjectName = SchemaService.getSObjectName(sot);
        if(fieldValue != null) {
            Map<String, Object> objMap = SObjectService.mapFromSObject(queriedRecord);
            objMap.put(fieldName, fieldValue);
            
            queriedRecord = SObjectService.sObjectFromMap(objMap, SObjectName);
        }
        return queriedRecord;
    }
}