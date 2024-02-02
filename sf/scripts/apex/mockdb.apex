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


List<Contact> conList = new List<Contact>();
Contact con = new Contact(
    FirstName = 'Test',
    LastName = 'Test',
    AccountId = acct.Id
);
conList.add(con);

Contact con2 = new Contact(
    FirstName = 'Test 2',
    LastName = 'Test 2',
    AccountId = acct2.Id
);
conList.add(con2);

Contact con3 = new Contact(
    FirstName = 'Test 3',
    LastName = 'Test 3',
    AccountId = acct.Id
);
conList.add(con3);

db.doInsert(conList);
List<AggregateResultProxy> arList = (List<AggregateResultProxy>) db.query('SELECT Account.Name, COUNT_DISTINCT(FirstName) distinctStr FROM Contact GROUP BY Account.Name');
for(AggregateResultProxy ar : arList) {
    System.debug(ar);
}