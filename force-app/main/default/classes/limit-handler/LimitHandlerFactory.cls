public with sharing class LimitHandlerFactory {

    private final LimitOptions options;
    public LimitHandlerFactory(LimitOptions options) {
        this.options = options;
    }

    private class LimitHandlerException extends Exception {}

    public ILimitHandler createHandler() {
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