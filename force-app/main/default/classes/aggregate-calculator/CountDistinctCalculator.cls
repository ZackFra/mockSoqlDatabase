public with sharing class CountDistinctCalculator implements IAggregateCalculator {
    AggregateCalculatorOptions options;
    public CountDistinctCalculator(AggregateCalculatorOptions options) {
        this.options = options;
    }

    public ProtoAggregate calculate() {
        return calculate(
            options.aggregateResult,
            options.alias,
            options.value
        );
    }

    private ProtoAggregate calculate(ProtoAggregate aggregateResult, String alias, Object value) {
        Integer currValue = (Integer) aggregateResult.get(alias);
        if(currValue == null) {
            currValue = 0;
        }
        Set<Object> distinctValues = (Set<Object>) aggregateResult.get(alias + '__distinct');
        if(distinctValues == null) {
            distinctValues = new Set<Object>();
        }
        aggregateResult.put(alias + '__distinct', distinctValues);
        if(value != null) {
            distinctValues.add(value);
        }
        aggregateResult.put(alias, distinctValues.size());
        return aggregateResult;
    }
}