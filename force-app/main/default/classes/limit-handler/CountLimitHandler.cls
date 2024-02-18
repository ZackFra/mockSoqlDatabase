public with sharing class CountLimitHandler implements ILimitHandler {
    LimitOptions options;
    public CountLimitHandler(LimitOptions options) {
        this.options = options;
    }

    public Object handleLimit() {
        Integer limitSize = options.limitSize;
        Object obj = options.obj;

        Integer count = (Integer) obj;
        if(count > limitSize) {
            return limitSize;
        }
        return count;
    }
}