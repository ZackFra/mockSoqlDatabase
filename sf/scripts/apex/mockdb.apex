MockDatabase db = new MockDatabase();
Account acct = new Account(
    Name = 'Test',
    BillingStreet = '123 Main St',
    NumberOfEmployees = 1
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
    NumberOfEmployees = 2,
    BillingStreet = '1234 Main St'
);

db.doInsert(acct3);

Contact con = new Contact(
    FirstName = 'Test',
    LastName = 'Test',
    AccountId = acct.Id
);

db.doInsert(con);

List<AggregateResultProxy> arList = (List<AggregateResultProxy>) db.query('SELECT COUNT_DISTINCT(BillingStreet) distinctStr FROM Account');
for(AggregateResultProxy ar : arList) {
    System.debug(ar);
}