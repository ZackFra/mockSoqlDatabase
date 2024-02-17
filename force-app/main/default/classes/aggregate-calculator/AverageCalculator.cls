public with sharing class AverageCalculator implements IAggregateCalculator {
    AggregateCalculatorOptions options;
    public AverageCalculator(AggregateCalculatorOptions options) {
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
        Decimal currValue = (Decimal) aggregateResult.get(alias);
        Decimal newValue = (Decimal) value;
        Decimal n = (Decimal) aggregateResult.get(alias + '__n');
        if(n == null) {
            n = 1;
        }

        if(currValue == null) {
            currValue = newValue;
        } else {
            currValue = currValue + (newValue - currValue) / n;
        }

        aggregateResult.put(alias, currValue);
        aggregateResult.put(alias + '__n', n + 1);

        return aggregateResult;
    }
}