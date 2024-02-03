public with sharing class AggregateComparator implements Comparator<Map<String, Object>>{
    private Map<String, Map<String, String>> fields;

    /**
     * @description Constructor
     * @param fields A map of field names and whether they're ASC or DESC
     */
    public AggregateComparator(Map<String, Map<String, String>> fields) {
        this.fields = fields;
    }

    private Object getFieldValue(Map<String, Object> sObj, Map<String, String> fieldData) {
        String relationshipName = fieldData.get('relationshipName');
        String fieldApiName = fieldData.get('fieldApiName');

        Object fieldValue;
        if(relationshipName != null) {
            List<String> fieldParts = fieldApiName.split('\\.');
            for(String part : fieldParts) {
                fieldValue = sObj.get(part);
            }
        } else {
            fieldValue = sObj.get(fieldApiName);
        }

        return fieldValue;
    }

    /**
     * @description Compare two SObjects based on the fields provided in the constructor
     * @param a The first SObject
     * @param b The second SObject
     * @return Integer
     */
    public Integer compare(Map<String, Object> a, Map<String, Object> b) {
        for (String field : this.fields.keySet()) {

            Map<String, String> fieldData = this.fields.get(field);
            
            String fieldApiName = (String) fieldData.get('fieldApiName');
            String order = (String) fieldData.get('order');
            Object aFieldValue = getFieldValue(a, fieldData);
            Object bFieldValue = getFieldValue(b, fieldData);

            if (aFieldValue != bFieldValue) {
                ObjectComparator comparator = new ObjectComparator(aFieldValue);
                Integer result;
                if(order == 'desc') {
                    result = (comparator.compareTo(bFieldValue) * -1);
                } else {
                    result = (comparator.compareTo(bFieldValue));
                }
                if(result != 0) {
                    return result;
                }
            }
        }
        return 0;
    }
}