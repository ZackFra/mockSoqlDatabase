/**
 * @description calculates the MAX value of a field for an aggregate result
 */
public with sharing class MaxCalculator implements IAggregateCalculator {
    AggregateCalculatorOptions options;
    public MaxCalculator(AggregateCalculatorOptions options) {
        this.options = options;
    }
    
    /**
     * @description calculates the MAX value of a field for an aggregate result
     */
    public ProtoAggregate calculate() {
        return calculate(
            options.aggregateResult,
            options.alias,
            options.value
        );
    }

    private ProtoAggregate calculate(ProtoAggregate aggregateResult, String alias, Object value) {
        if(value == null) {
            // make sure it's explicitly set to null
            if(!aggregateResult.containsKey(alias)) {
                aggregateResult.put(alias, null);
            }
            return aggregateResult;
        }
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