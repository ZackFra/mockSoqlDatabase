public with sharing class AggregateCalculatorOptions {
    public ProtoAggregate aggregateResult;
    public String alias;
    public Object value;

    public AggregateCalculatorOptions setAggregateResult(ProtoAggregate aggregateResult) {
        this.aggregateResult = aggregateResult;
        return this;
    }

    public AggregateCalculatorOptions setAlias(String alias) {
        this.alias = alias;
        return this;
    }

    public AggregateCalculatorOptions setValue(Object value) {
        this.value = value;
        return this;
    }
}