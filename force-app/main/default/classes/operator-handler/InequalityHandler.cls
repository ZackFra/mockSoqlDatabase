public class InequalityHandler implements IOperatorHandler {
    public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
        Boolean isSObjNull = (sObjectFieldValue == null);
        Boolean isFieldNull = (fieldValue == null);

        if(isSObjNull && isFieldNull) {
            return false;
        } else if(isSObjNull || isFieldNull) {
            return true;
        }

        if(sObjectFieldValue instanceof Date) {
            fieldValue = (Object) Common.parseDate((String) fieldValue).toString();
        } else if(SObjectFieldValue instanceof DateTime) {
            fieldValue = (Object) Common.parseDateTime((String) fieldValue).toString();
        } else if(SObjectFieldValue instanceof Time) {
            fieldValue = (Object) Common.parseTime((String) fieldValue).toString();
        }

        return (String.valueOf(sObjectFieldValue).toLowerCase() != ((String)fieldValue).toLowerCase());
    }
}