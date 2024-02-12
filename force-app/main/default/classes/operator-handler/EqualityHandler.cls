public class EqualityHandler implements IOperatorHandler {
    public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
        Boolean isSObjNull = (sObjectFieldValue == null);
        Boolean isFieldNull = (fieldValue == null);
        if(isSObjNull && isFieldNull) {
            return true;
        } else if(isSObjNull || isFieldNull) {
            return false;
        }

        if(sObjectFieldValue instanceof Date) {
            fieldValue = Common.parseDate((String) fieldValue);
            return fieldValue == (Date) sObjectFieldValue;
        } else if(SObjectFieldValue instanceof DateTime) {
            fieldValue = Common.parseDateTime((String) fieldValue);
            return fieldValue == (DateTime) sObjectFieldValue;
        } else if(SObjectFieldValue instanceof Time) {
            fieldValue = Common.parseTime((String) fieldValue);
            return fieldValue == (Time) sObjectFieldValue;
        }

        return (String.valueOf(sObjectFieldValue).toLowerCase() == ((String)fieldValue).toLowerCase());
    }
}