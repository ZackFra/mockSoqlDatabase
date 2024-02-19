public with sharing class OrderByHandlerFactory {
    private class OrderByException extends Exception {}

    OrderByOptions options = new OrderByOptions();

    public OrderByHandlerFactory setType(MockDatabase.QueryType type) {
        options.setType(type);
        return this;
    }

    public OrderByHandlerFactory setObj(Object obj) {
        options.setObj(obj);
        return this;
    }

    public OrderByHandlerFactory setTopLevelNodes(TopLevelNodes topLevelNodes) {
        options.setTopLevelNodes(topLevelNodes);
        return this;
    }

    public OrderByHandler createHandler() {
        Map<String, Object> args = new Map<String, Object> {
            'type' => options.getType(),
            'obj' => options.getObj(),
            'topLevelNodes' => options.getTopLevelNodes()
        };
        Common.nullCheck(args);

        MockDatabase.QueryType type = options.getType();
        switch on type {
            when RECORD {
                return new RecordOrderByHandler(options);
            }
            when AGGREGATE {
                return new AggregateOrderByHandler(options);
            }
            when else {
                throw new OrderByException('Unsupported OrderByOptions type');
            }
        }
    }
}