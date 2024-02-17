public with sharing class MaxCalculator implements IAggregateCalculator {
    AggregateCalculatorOptions options;
    public MaxCalculator(AggregateCalculatorOptions options) {
        this.options = options;
    }
    
    public ProtoAggregate calculate() {
        return calculate(
            options.aggregateResult,
            options.alias,
            options.value
        );
    }
    
    public ProtoAggregate calculate(ProtoAggregate aggregateResult, String alias, Object value) {
        Decimal currValue = (Decimal) aggregateResult.get(alias);
        Decimal newValue = (Decimal) value;

        if(currValue == null) {
            currValue = newValue;
        } else {
            currValue = Math.max(currValue, newValue);
        }

        aggregateResult.put(alias, currValue);
        return aggregateResult;
    }
}