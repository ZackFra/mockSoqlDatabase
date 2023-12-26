
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
    'acctIds' => acctIds,
    'oppId' => mockOpp.Id
};

List<OpportunityLineItem> createdOppLines = 
    (List<OpportunityLineItem>) db.queryWithBinds(
        'SELECT Opportunity.Account.Name, Opportunity.Name, Opportunity.Account.BillingStreet, Opportunity.CloseDate FROM OpportunityLineItem', args);
System.debug(createdOppLines);
for(OpportunityLineItem oppLine : createdOppLines) {
    System.debug('Opportunity Line = ' + oppLine);
    System.debug('Opportunity Line Id = ' + oppLine.Id);
    System.debug('Opportunity = ' + oppLine.Opportunity);
    System.debug('Opportunity Id = ' + oppLine.Opportunity.Id);
    System.debug('Opportunity Name = ' + oppLine.Opportunity.Name);
    System.debug('Opportunity Account = ' + oppLine.Opportunity.Account);
    System.debug('Opportunity Account Name = ' + oppLine.Opportunity.Account.Name);
    System.debug('Opportunity Account Billing Street = ' + oppLine.Opportunity.Account.BillingStreet);
    System.debug('Opportunity Close Date = ' + oppLine.Opportunity.CloseDate);

}