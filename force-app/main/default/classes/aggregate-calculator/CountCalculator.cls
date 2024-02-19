public with sharing class CountCalculator implements IAggregateCalculator {
    AggregateCalculatorOptions options;

    public CountCalculator(AggregateCalculatorOptions options) {
        this.options = options;
    }

    public ProtoAggregate calculate() {
        return calculate(
            options.aggregateResult, 
            options.alias
        );
    }

    private ProtoAggregate calculate(ProtoAggregate aggregateResult, String alias) {
        Integer currValue = (Integer) aggregateResult.get(alias);
        if(currValue == null) {
            currValue = 0;
        }
        aggregateResult.put(alias, currValue + 1);
        return aggregateResult;
    }
}