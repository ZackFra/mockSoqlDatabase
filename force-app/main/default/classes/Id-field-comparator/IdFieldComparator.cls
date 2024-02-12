public with sharing class IdFieldComparator implements Comparator<Schema.SObjectField> {
    public Integer compare(Schema.SObjectField field1, Schema.SObjectField field2) {
        Schema.DisplayType fieldType1 = SchemaService.getFieldType(field1);
        Schema.DisplayType fieldType2 = SchemaService.getFieldType(field2);

        Boolean isBothIds = (fieldType1 == Schema.DisplayType.ID) && (fieldType2 == Schema.DisplayType.ID);
        if(!isBothIds) {
            throw new IllegalArgumentException('Both fields must be of type ID');
        }
        
        Schema.SObjectType field1Sot = SchemaService.getFieldSObjectType(field1);
        Schema.SObjectType field2Sot = SchemaService.getFieldSObjectType(field2);

        if(field1Sot == field2Sot) {
            return 0;
        }
        return -1;
    }
}