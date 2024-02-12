public class LikeHandler implements IOperatorHandler {
    public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
        if(sObjectFieldValue == null) {
            return false;
        }

        String regexPattern = String.valueOf(fieldValue)
            .toLowerCase()
            .replaceAll('%', '.*')
            .replaceAll('_', '.');
        Pattern regex = Pattern.compile(regexPattern);
        Matcher regexMatcher = regex.matcher(String.valueOf(sObjectFieldValue).toLowerCase());
        return regexMatcher.matches();
    }
}