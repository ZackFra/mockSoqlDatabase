/**
 * @description Comparator for two reference fields, checks if they reference the same object
 */
public class ReferenceFieldComparator implements Comparator<Schema.SObjectField> {
    public Integer compare(Schema.SObjectField field1, Schema.SObjectField field2) {
        Schema.DisplayType fieldType1 = SchemaService.getFieldType(field1);
        Schema.DisplayType fieldType2 = SchemaService.getFieldType(field2);

        List<Schema.sObjectType> sObj1FieldRefs = SchemaService.getReferenceTo(field1);
        List<Schema.sObjectType> sObj2FieldRefs = SchemaService.getReferenceTo(field2);

        for(Schema.SObjectType ref1 : sObj1FieldRefs) {
            for(Schema.SObjectType ref2 : sObj2FieldRefs) {
                if(ref1 == ref2) {
                    return 0;
                }
            }
        }
        return -1;
    }
}