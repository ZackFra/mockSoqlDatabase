public with sharing class OffsetHandlerFactory {
    OffsetOptions options;
    public OffsetHandlerFactory(OffsetOptions options) {
        this.options = options;
    }

    private class OffsetHandlerException extends Exception {}

    public IOffsetHandler createHandler() {
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