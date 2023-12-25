
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
    'acctId1' => acct.Id,
    'acctId2' => acct2.Id
};

List<Account> createdAccts = (List<Account>) db.query('SELECT Id, Name, BillingStreet ' + 
                                                    'FROM Account ' + 
                                                    'WHERE Name LIKE \'%Test%\' ' + 
                                                    'AND (Id != :acctid1 OR BillingCity = \'Testville\') ',
                                                    args);
for(Account a : createdAccts) {
    System.debug(a.Name);
}