public with sharing class LimitOptions {
    public Integer limitSize;
    public MockDatabase.QueryType type;
    public Object obj;

    public LimitOptions(Node limitNode, Map<String, Object> params) {
        this.setLimitSize(limitNode, params);
    }

    public LimitOptions setType(MockDatabase.QueryType type) {
        this.type = type;
        return this;
    }

    public LimitOptions setObj(Object obj) {
        this.obj = obj;
        return this;
    }


    private LimitOptions setLimitSize(Node limitNode, Map<String, Object> params) {
        Node limitSizeNode = limitNode.left;

        if(limitSizeNode.nodeType == 'bind variable' && (params == null || !params.containsKey(limitSizeNode.id))) {
            throw new QueryException('Missing bind variable: ' + limitSizeNode.id);
        }

        if(limitSizeNode.nodeType == 'bind variable') {
            this.limitSize = (Integer) params.get(limitSizeNode.id);
        } else {
            this.limitSize = Integer.valueOf(limitSizeNode.id);
        }
        return this;
    }
}