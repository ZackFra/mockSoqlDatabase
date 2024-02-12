public class ExcludesHandler implements IOperatorHandler {
    public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
        IncludesHandler includesHandler = new IncludesHandler();
        return !includesHandler.handle(sObjectFieldValue, fieldValue);
    }
}