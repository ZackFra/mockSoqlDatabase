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
* Partially Supported
* Ignored
  * It won't throw an exception when parsed, but won't be applied by the mock database
* Not Supported
  * Throws a QueryException when read by the parser

# Supported Clauses
| Clause      | Level of Support    | Notes |
|-------------|---------------------|-------|
| SELECT      | Fully Supported     ||
| TYPEOF      | Fully Supported     ||
| FROM        | Fully Supported     ||
| USING SCOPE | Ignored             ||
| WHERE       | Fully Supported     ||
| WITH        | Not Supported       ||
| GROUP BY    | Partially Supported | GROUP BY ROLLUP and GROUP BY CUBE are not supported, the CPU time used to compute these defeats the point of using a mock SOQL database. |
| HAVING | Fully Supported ||
| ORDER BY | Fully Supported ||
| LIMIT | Fully Supported ||
| OFFSET | Fully Supported ||
| FOR VIEW\|REFERENCE | Ignored ||
| UPDATE TRACKING\|VIEWSTAT | Not Supported ||
| FOR UPDATE | Ignored ||