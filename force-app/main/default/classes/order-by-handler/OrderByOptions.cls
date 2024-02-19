public with sharing class OrderByOptions {
    private Object obj;
    private TopLevelNodes topLevelNodes;
    private MockDatabase.QueryType type;

    public MockDatabase.QueryType getType() {
        return type;
    }

    public OrderByOptions setType(MockDatabase.QueryType type) {
        this.type = type;
        return this;
    }
    
    public OrderByOptions setObj(Object obj) {
        this.obj = obj;
        return this;
    }

    public Object getObj() {
        return obj;
    }

    public OrderByOptions setTopLevelNodes(TopLevelNodes topLevelNodes) {
        this.topLevelNodes = topLevelNodes;
        return this;
    }

    public TopLevelNodes getTopLevelNodes() {
        return topLevelNodes;
    }
}