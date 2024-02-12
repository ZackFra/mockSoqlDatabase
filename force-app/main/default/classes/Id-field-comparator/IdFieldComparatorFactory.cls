/**
 * @description Returns a comparator for the given field types, compares ID fields (i.e. ID, Reference)
 */
public class IdFieldComparatorFactory {
    public static Comparator<Schema.SObjectField> create(Schema.SObjectField field1, Schema.SObjectField field2) {
        Schema.DisplayType field1Type = SchemaService.getFieldType(field1);
        Schema.DisplayType field2Type = SchemaService.getFieldType(field1);
        if(field1Type == Schema.DisplayType.ID && field2Type == Schema.DisplayType.ID) {
            return new IdFieldComparator();
        }
        if(field1Type == Schema.DisplayType.ID && field2Type == Schema.DisplayType.REFERENCE) {
            return new IdAndReferenceFieldComparator();
        }
        if(field1Type == Schema.DisplayType.REFERENCE && field2Type == Schema.DisplayType.ID) {
            return new IdAndReferenceFieldComparator();
        }
        if(field1Type == Schema.DisplayType.REFERENCE && field2Type == Schema.DisplayType.REFERENCE) {
            return new ReferenceFieldComparator();
        }
        throw new IllegalArgumentException('Invalid field types');
    }
}