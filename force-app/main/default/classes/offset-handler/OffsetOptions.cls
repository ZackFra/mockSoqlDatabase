public with sharing class OffsetOptions {
    public Integer offset;
    public MockDatabase.QueryType type;
    public Object obj;

    /**
     * @description Consturctor for OffsetOptions
     * @param offsetNode - The node that contains the offset
     * @param params - The bind variables for the query
     * @throws QueryException - If the bind variable is missing
     */
    public OffsetOptions(Node offsetNode, Map<String, Object> params) {
        this.setOffset(offsetNode, params);
    }

    private OffsetOptions setOffset(Node offsetNode, Map<String, Object> params) {
        Node offsetSizeNode = offsetNode.left;
    
        if(offsetNode.nodeType == 'bind variable' && (params == null || !params.containsKey(offsetSizeNode.id))) {
            throw new QueryException('Missing bind variable: ' + offsetSizeNode.id);
        }
        if(offsetSizeNode.nodeType == 'bind variable') {
            this.offset = (Integer) params.get(offsetSizeNode.id);
        } else {
            this.offset = Integer.valueOf(offsetSizeNode.id);
        }
        return this;
    }

    /**
     * @description Set the type of query
     * @param type - The type of query
     * @return OffsetOptions - The current instance of the class
     */
    public OffsetOptions setType(MockDatabase.QueryType type) {
        this.type = type;
        return this;
    }

    /**
     * @description Set the object being offsetted
     * @param obj - The object being offsetted
     * @return OffsetOptions - The current instance of the class
     */
    public OffsetOptions setObj(Object obj) {
        this.obj = obj;
        return this;
    }
}