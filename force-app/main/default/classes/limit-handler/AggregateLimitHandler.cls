public with sharing class AggregateLimitHandler implements ILimitHandler {
    LimitOptions options;
    public AggregateLimitHandler(LimitOptions options) {
        this.options = options;
    }

    public Object handleLimit() {
        Object obj = options.obj;
        Integer limitSize = options.limitSize;

        List<ProtoAggregate> resultsList = new List<ProtoAggregate>((List<ProtoAggregate>) obj);
        while(resultsList.size() > limitSize) {
            resultsList.remove(resultsList.size()-1);
        }
        return resultsList;
    }
}