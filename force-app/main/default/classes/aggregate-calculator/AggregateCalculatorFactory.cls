public with sharing class AggregateCalculatorFactory {
    private class AggregateCalculatorException extends Exception {}
    
    public static IAggregateCalculator getCalculator(String type, AggregateCalculatorOptions options) {
        switch on type {
            when 'sum' {
                return new SumCalculator(options);
            }
            when 'avg' {
                return new AverageCalculator(options);
            }
            when 'max' {
                return new MaxCalculator(options);
            }
            when 'min' {
                return new MinCalculator(options);
            }
            when 'count_distinct' {
                return new CountDistinctCalculator(options);
            }
            when 'count' {
                return new CountCalculator(options);
            }
            when else {
                throw new AggregateCalculatorException('Invalid type');
            }
        }
    }
}