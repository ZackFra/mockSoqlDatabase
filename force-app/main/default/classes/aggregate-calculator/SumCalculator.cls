public with sharing class SumCalculator implements IAggregateCalculator {
    AggregateCalculatorOptions options;
    public SumCalculator(AggregateCalculatorOptions options) {
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
        Decimal sum;
        if(currValue == null) {
            sum = newValue;
        } else {
            sum = currValue + newValue;
        }

        aggregateResult.put(alias, sum);
        return aggregateResult;
    }
}