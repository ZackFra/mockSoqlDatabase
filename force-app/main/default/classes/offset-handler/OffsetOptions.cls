public with sharing class OffsetOptions {
    public Integer offset;
    public MockDatabase.QueryType type;
    public Object obj;

    public OffsetOptions setOffset(Integer offset) {
        this.offset = offset;
        return this;
    }

    public Integer getOffset() {
        return this.offset;
    }

    public OffsetOptions setType(MockDatabase.QueryType type) {
        this.type = type;
        return this;
    }

    public MockDatabase.QueryType getType() {
        return this.type;
    }

    public OffsetOptions setObj(Object obj) {
        this.obj = obj;
        return this;
    }

    public Object getObj() {
        return this.obj;
    }
}