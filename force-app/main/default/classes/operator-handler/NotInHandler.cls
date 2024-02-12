public class NotInHandler implements IOperatorHandler {
    public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
        if(sObjectFieldValue == null) {
            return false;
        }

        List<Object> values = (List<Object>) fieldValue;
        for(Integer i = 0; i < values.size(); i++) {
            if(values[i] instanceof String) {
                values[i] = (Object) ((String) values[i]).toLowerCase();
            }
        }
        String nodeValue = String.valueOf(sObjectFieldValue).toLowerCase();
        return !values.contains(nodeValue);
    }
}