/**
 * @description This class is used to compare two SObjects based on the fields provided in the constructor.
 */
public with sharing class SObjectComparator implements Comparator<SObject> {
    private Map<String, Map<String, String>> fields;

    /**
     * @description Constructor
     * @param fields A map of field names and whether they're ASC or DESC
     */
    public SObjectComparator(Map<String, Map<String, String>> fields) {
        this.fields = fields;
    }

    private Object getFieldValue(SObject sObj, Map<String, String> fieldData) {
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
     * @description Check for null values and return the appropriate result, 
     *              returns null if both are not null
     * @param a The first value
     * @param b The second value
     * @param nullDir The direction to sort null values
     * @return Integer
     */
    private Integer checkForNull(Object a, Object b, String nullDir) {
        if(a == null && b == null) {
            return 0;
        } else if(a == null && b != null) {
            if(nullDir == 'first') {
                return -1;
            } else {
                return 1;
            }
        } else if(a != null && b == null) {
            if(nullDir == 'first') {
                return 1;
            } else {
                return -1;
            }
        }

        return null;
    }

    private Integer adjustForOrder(Integer result, String order) {
        if(order == 'desc') {
            return result * -1;
        } else {
            return result;
        }
    }

    /**
     * @description Compare two SObjects based on the fields provided in the constructor
     * @param a The first SObject
     * @param b The second SObject
     * @return Integer
     */
    public Integer compare(SObject a, SObject b) {
        for (String field : fields.keySet()) {
            Map<String, String> fieldData = fields.get(field);

            String order = fieldData.get('order');
            String nullDir = fieldData.get('nullDir');

            Object aFieldValue = getFieldValue(a, fieldData);
            Object bFieldValue = getFieldValue(b, fieldData);


            if (aFieldValue != bFieldValue) {
                ObjectComparator comparator = new ObjectComparator(aFieldValue);
                Integer result;

                Integer nullResult = checkForNull(aFieldValue, bFieldValue, nullDir);
                if(nullResult != null && nullResult != 0) {
                    return nullResult;
                } else if(nullResult == 0) {
                    continue;
                }

                result = comparator.compareTo(bFieldValue);
                result = adjustForOrder(result, order);

                if(result != 0) {
                    return result;
                }
            }
        }

        return 0;
    }
}