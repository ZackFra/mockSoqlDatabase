public with sharing class LimitHandlerFactory {

    private LimitOptions options = new LimitOptions();

    Node limitNode;
    Map<String, Object> params;

    public LimitHandlerFactory setType(MockDatabase.QueryType type) {
        options.setType(type);
        return this;
    }

    public LimitHandlerFactory setObj(Object obj) {
        options.setObj(obj);
        return this;
    }

    public LimitHandlerFactory setLimitNode(Node limitNode) {
        this.limitNode = limitNode;
        return this;
    }

    public LimitHandlerFactory setParams(Map<String, Object> params) {
        this.params = params;
        return this;
    }

    private Integer calculateLimitSize() {
        Node limitSizeNode = limitNode.left;

        if(limitSizeNode.nodeType == 'bind variable' && (params == null || !params.containsKey(limitSizeNode.id))) {
            throw new QueryException('Missing bind variable: ' + limitSizeNode.id);
        }

        if(limitSizeNode.nodeType == 'bind variable') {
            return (Integer) params.get(limitSizeNode.id);
        }
        return Integer.valueOf(limitSizeNode.id);      
    }

    private class LimitHandlerException extends Exception {}

    public ILimitHandler createHandler() {
        Map<String, Object> args = new Map<String, Object> {
            'type' => options.getType(),
            'limitNode' => limitNode,
            'obj' => options.getObj()
        };
        Common.nullCheck(args);

        options.setLimitSize(
            calculateLimitSize()
        );

        switch on options.type {
            when RECORD {
                return new RecordLimitHandler(options);
            }
            when AGGREGATE {
                return new AggregateLimitHandler(options);
            }
            when COUNT {
                return new CountLimitHandler(options);
            }
            when else {
                throw new LimitHandlerException('Unsupported limit type');
            }
        }
    }
}