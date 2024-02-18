public with sharing class OffsetHandlerFactory {
    OffsetOptions options = new OffsetOptions();
    
    Node offsetNode;
    Map<String, Object> params;

    public OffsetHandlerFactory setOffsetNode(Node offsetNode) {
        this.offsetNode = offsetNode;
        return this;
    }

    public OffsetHandlerFactory setParams(Map<String, Object> params) {
        this.params = params;
        return this;
    }

    public OffsetHandlerFactory setType(MockDatabase.QueryType type) {
        this.options.setType(type);
        return this;
    }

    public OffsetHandlerFactory setObj(Object obj) {
        this.options.setObj(obj);
        return this;
    }

    private class OffsetHandlerException extends Exception {}


    private Integer calculateOffset() {
        Node offsetSizeNode = offsetNode.left;
    
        if(offsetNode.nodeType == 'bind variable' && (params == null || !params.containsKey(offsetSizeNode.id))) {
            throw new QueryException('Missing bind variable: ' + offsetSizeNode.id);
        }
        if(offsetSizeNode.nodeType == 'bind variable') {
            return (Integer) params.get(offsetSizeNode.id);
        }
        return Integer.valueOf(offsetSizeNode.id);
    }

    public IOffsetHandler createHandler() {
        Map<String, Object> args = new Map<String, Object> {
            'obj' => options.getObj(),
            'type' => options.getType(),
            'offsetNode' => offsetNode
        };
        Common.nullCheck(args);

        options.setOffset(
            calculateOffset()
        );

        switch on options.type {
            when RECORD {
                return new RecordOffsetHandler(options);
            }
            when COUNT {
                return new CountOffsetHandler(options);
            }
            when Aggregate {
                return new AggregateOffsetHandler(options);
            }
            when else {
                throw new OffsetHandlerException('Invalid type of query');
            }

        }
    }
}