MockDatabase db = new MockDatabase();
Account acct = new Account(
    Name = 'Test',
    BillingStreet = '123 Main St',
    NumberOfEmployees = 5
);

db.doInsert(acct);

Account acct2 = new Account(
    Name = 'Test 2',
    BillingStreet = '123 Main St',
    NumberOfEmployees = 3
);

db.doInsert(acct2);

Account acct3 = new Account(
    Name = 'Test',
    BillingStreet = '123 Main St',
    NumberOfEmployees = 5
);

db.doInsert(acct3);

Contact con = new Contact(
    FirstName = 'Test',
    LastName = 'Test',
    AccountId = acct.Id
);

db.doInsert(con);

List<Account> acctList = (List<Account>) db.query('SELECT Name, SUM(NumberOfEmployees) numOfEmpl FROM Account GROUP BY Name');
Tokenizer t = new Tokenizer();