public with sharing class CountLimitHandler implements ILimitHandler {
    LimitOptions options;
    public CountLimitHandler(LimitOptions options) {
        this.options = options;
    }

    public Object handleLimit() {
        Object obj = options.getObj();
        Integer limitSize = options.getLimitSize();

        Integer count = (Integer) obj;
        if(count > limitSize) {
            return limitSize;
        }
        return count;
    }
}