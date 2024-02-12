public class IncludesHandler implements IOperatorHandler {
    public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
        List<String> values = new List<String>();
        try {
            List<Object> objList = (List<Object>) fieldValue;
            for(Object obj : objList) {
                values.add(
                    ((String) obj).toLowerCase() + ';'
                );
            }
        } catch(Exception ex) {
            throw new QueryException('Includes expects a list of strings');
        }
        String fieldString = ((String) sObjectFieldValue).toLowerCase();
        for(String value : values) {
            if(fieldString.contains(value)) {
                return true;
            }
        }
        return false;
    }
}