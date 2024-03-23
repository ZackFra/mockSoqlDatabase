# Mock SOQL Database


A SOQL query will have the following format.

```
SELECT fieldList [subquery][...]
[TYPEOF typeOfField whenExpression[...] elseExpression END][...]
FROM objectType[,...] 
    [USING SCOPE filterScope]
[WHERE conditionExpression]
[WITH [DATA CATEGORY] filteringExpression]
[GROUP BY {fieldGroupByList|ROLLUP (fieldSubtotalGroupByList)|CUBE (fieldSubtotalGroupByList)} 
    [HAVING havingConditionExpression] ] 
[ORDER BY fieldOrderByList {ASC|DESC} [NULLS {FIRST|LAST}] ]
[LIMIT numberOfRowsToReturn]
[OFFSET numberOfRowsToSkip]
[{FOR VIEW  | FOR REFERENCE} ]
[UPDATE {TRACKING|VIEWSTAT} ]
[FOR UPDATE]
```

# Levels of Support
There are three categories of support for a SOQL query done via the mock SOQL database.
* Fully Supported
* Ignored
  * It won't throw an exception when parsed, but won't be applied by the mock database
* Not Supported
  * Throws a QueryException when read by the parser

* SELECT fieldList \[subquery\]\[...\] (Fully Supported)
* \[TYPEOF typeOfField whenExpression\[...\] elseExpression END\]\[...\] (Fully Supported)
* FROM objectType\[,...\] (Fully Supported)
  * \[USING SCOPE filterScope\] (Ignored)
* \[WHERE conditionExpression\] (Fully Supported)
* \[WITH \[DATA CATEGORY\] filteringExpression\] (Not Supported)
* \[GROUP BY fieldGroupByList\]
* \[GROUP BY ROLLUP (fieldSubtotalGroupByList)\] (Not Supported)
* \[GROUP BY CUBE (fieldSubtotalGroupByList)\] (Not Supported)
* \[HAVING havingConditionExpression\] (Fully Supported)
* \[ORDER BY fieldOrderByList {ASC|DESC} \[NULLS {FIRST|LAST}\] \] (Fully Supported)
* \[LIMIT numberOfRowsToReturn\] (Fully Supported)
* \[OFFSET numberOfRowsToSkip\] (Fully Supported)
* \[{FOR VIEW  | FOR REFERENCE} \] (Ignored)
* \[UPDATE {TRACKING|VIEWSTAT} \] (Not Supported)
* \[FOR UPDATE\] (Ignored)