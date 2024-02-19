public with sharing class LimitOptions {
    public Integer limitSize;
    public MockDatabase.QueryType type;
    public Object obj;

    public LimitOptions setType(MockDatabase.QueryType type) {
        this.type = type;
        return this;
    }

    public MockDatabase.QueryType getType() {
        return this.type;
    }

    public LimitOptions setObj(Object obj) {
        this.obj = obj;
        return this;
    }

    public Object getObj() {
        return this.obj;
    }

    public LimitOptions setLimitSize(Integer limitSize) {
        this.limitSize = limitSize;
        return this;
    }

    public Integer getLimitSize() {
        return this.limitSize;
    }
}