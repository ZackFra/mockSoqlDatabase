
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

Contact con = new Contact(
    FirstName = 'Test',
    LastName = 'Contact',
    AccountId = acct2.Id
);
db.doInsert(con);

List<Id> acctIds = new List<Id> {
    acct.Id,
    acct2.Id
};

Opportunity mockOpp = new Opportunity(
    Name = 'Test Opportunity',
    StageName = 'Prospecting',
    CloseDate = Date.today(),
    AccountId = acct.Id
);

db.doInsert(mockOpp);

OpportunityLineItem oppLine = new OpportunityLineItem(
    OpportunityId = mockOpp.Id,
    Quantity = 1,
    UnitPrice = 100
);

db.doInsert(oppLine);

Map<String, Object> args = new Map<String, Object> {
    'acctId1' => acct.Id,
    'acctId2' => acct2.Id,
    'acctIds' => acctIds
};

List<Opportunity> createdOpps = 
    (List<Opportunity>) db.queryWithBinds(
        'SELECT (SELECT Id FROM OpportunityLineItems) ' + 
        'FROM Opportunity ' + 
        'WHERE Id IN (' + 
            'SELECT OpportunityId ' +
            'FROM OpportunityLineItem' + 
        ')', args);
for(Opportunity opp : createdOpps) {
    System.debug(opp.Id);
    for(OpportunityLineItem line : opp.OpportunityLineItems) {
        System.debug(line.Id);
    }
}