public abstract class AggregateProcessor {

    public abstract void processRecord(SObject databaseRecord);
    public abstract List<ProtoAggregate> finish();

    protected MockDatabase db;
    protected TopLevelNodes topLevelNodes;

    public AggregateProcessor setDatabase(MockDatabase db) {
        this.db = db;
        return this;
    }

    public AggregateProcessor setTopLevelNodes(TopLevelNodes topLevelNodes) {
        this.topLevelNodes = topLevelNodes;
        return this;
    }

    protected ProtoAggregate calculateAggregate(
        Node currSelect,
        String alias, 
        ProtoAggregate aggregateResult,
        Object value
    ) {
        AggregateCalculatorOptions options = new AggregateCalculatorOptions()
            .setAlias(alias)
            .setAggregateResult(aggregateResult)
            .setValue(value);


        IAggregateCalculator calculator = AggregateCalculatorFactory.getCalculator(currSelect.id, options);
        return calculator.calculate();
    }
}