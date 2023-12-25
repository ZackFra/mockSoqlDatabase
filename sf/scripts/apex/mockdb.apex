
MockDatabase db = new MockDatabase();
Account acct = new Account(
    Name = 'Test Account',
    BillingStreet = '123 Test St',
    BillingCity = 'Testville',
    BillingState = 'CA',
    BillingPostalCode = '12345',
    BillingCountry = 'USA',
    Phone = '555-555-5555',
    Website = 'www.testaccount.com'
);

Account acct2 = new Account(
    Name = 'Test Account 2',
    BillingStreet = '123 Test St',
    BillingCity = 'Testville',
    BillingState = 'CA',
    BillingPostalCode = '12345',
    BillingCountry = 'USA',
    Phone = '555-555-5555',
    Website = 'www.testaccount.com'
);

List<sObject> acctList = new List<sObject>();
acctList.add(acct);
acctList.add(acct2);
db.doInsert(acctList);

Map<String, String> args = new Map<String, String> {
    'acctid1' => acct.Id,
    'acctid2' => acct2.Id
};
Account createdAcct = (Account) db.query('SELECT Id, Name, BillingStreet FROM Account WHERE Id = :acctid1', args);
System.debug(createdAcct.Id);
System.debug(createdAcct.Name);
System.debug(createdAcct.BillingStreet);

Account createdAcct2 = (Account) db.query('SELECT Id, Name, BillingStreet FROM Account WHERE Id = :acctid2', args);
System.debug(createdAcct2.Id);
System.debug(createdAcct2.Name);
System.debug(createdAcct2.BillingStreet);