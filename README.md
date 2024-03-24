# Mock SOQL Database

This project mocks the logic of the Salesforce database for testing. The purpose is to create a unified mocking framework for DML statements and SOQL queries that simplifies the mocking process.
## Example
```
Account a = new Account(Name = 'Test1', NumberOfEmployees = 5);
Account b = new Account(Name = 'Test1', NumberOfEmployees = 10);
Account c = new Account(Name = 'Test2', NumberOfEmployees = 15);
Account d = new Account(Name = 'Test2', NumberOfEmployees = 20);
MockDatabase mockDb = new MockDatabase();
List<Account> acctList = new List<Account>{a, b, c, d};
mockDb.doInsert(acctList);

Test.startTest();
    List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT Name, SUM(NumberOfEmployees) FROM Account GROUP BY Name ORDER BY Name ASC');
Test.stopTest();

Assert.areEqual('Test1', queriedAccts[0].get('Name'), 'Incorrect order');
Assert.areEqual('Test2', queriedAccts[1].get('Name'), 'Incorrect order');
```


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
There are four categories of support for a SOQL query done via the mock SOQL database.
* Fully Supported
* Partially Supported
* Ignored
  * It won't throw an exception when parsed, but won't be applied by the mock database
* Not Supported
  * Throws a QueryException when read by the parser

# Supported Clauses
| Clause      | Level of Support    | Notes |
|-------------|---------------------|-------|
| SELECT      | Partially Supported | FORMAT(), convertCurrency(), convertTimezone(), date functions, GROUPING(), and toLabel() are not supported |
| TYPEOF      | Fully Supported     ||
| FROM        | Fully Supported     ||
| USING SCOPE | Ignored             ||
| WHERE       | Fully Supported     ||
| WITH        | Not Supported       ||
| GROUP BY    | Partially Supported | GROUP BY ROLLUP and GROUP BY CUBE are not supported |
| HAVING | Fully Supported ||
| ORDER BY | Fully Supported ||
| LIMIT | Fully Supported ||
| OFFSET | Fully Supported ||
| FOR VIEW\|REFERENCE | Ignored ||
| UPDATE TRACKING\|VIEWSTAT | Not Supported ||
| FOR UPDATE | Ignored ||
