public with sharing class RecordLimitHandler implements ILimitHandler {
    LimitOptions options;
    public RecordLimitHandler(LimitOptions options) {
        this.options = options;
    }

    public Object handleLimit() {
        Object obj = options.obj;
        Integer limitSize = options.limitSize;

        List<SObject> resultsList = new List<SObject>((List<SObject>) obj);
        while(resultsList.size() > limitSize) {
            resultsList.remove(resultsList.size()-1);
        }
        return resultsList;
    }
}