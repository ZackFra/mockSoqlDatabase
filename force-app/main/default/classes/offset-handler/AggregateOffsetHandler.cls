public with sharing class AggregateOffsetHandler implements IOffsetHandler {
    OffsetOptions options;
    public AggregateOffsetHandler(OffsetOptions options) {
        this.options = options;
    }

    public Object handleOffset() {
        Integer offset = options.offset;
        Object obj = options.obj;

        List<ProtoAggregate> aggrResults = new List<ProtoAggregate>((List<ProtoAggregate>) obj);
        while(offset > 0) {
            aggrResults.remove(0);
            offset--;
        }
        return aggrResults;
    }
}