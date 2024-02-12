/** comparison handlers for WHERE and HAVING clauses */
public interface IOperatorHandler {
    Boolean handle(Object sObjectFieldValue, Object fieldValue);
}