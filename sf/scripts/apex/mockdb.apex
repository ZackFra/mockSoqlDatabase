MockDatabase db = new MockDatabase();
Account acct = new Account(
    Name = 'Test',
    BillingStreet = '123 Main St'
);

db.doInsert(acct);

Contact con = new Contact(
    FirstName = 'Test',
    LastName = 'Test',
    AccountId = acct.Id
);

db.doInsert(con);

List<Account> acctList = (List<Account>) db.query('SELECT Id, Name, BillingStreet, (SELECT FirstName, LastName FROM Contacts) FROM Account');
Tokenizer t = new Tokenizer();
System.debug('PARSING === ');
System.debug('parse tree = ' + t.parse('SELECT Id, Name, BillingStreet, (SELECT Id, LastName FROM Contacts) FROM Account'));
System.debug('PARSING === ');
for(Account a : acctList) {
    System.debug('Account = ' + a);
    System.debug('Account Name = ' + a.Name);
    System.debug('Account BillingStreet = ' + a.BillingStreet);
    for(Contact c : a.Contacts) {
        System.debug('Contact = ' + c);
        System.debug('Contact LastName = ' + c.LastName);
        System.debug('Contact FirstName = ' + c.FirstName);
        System.debug('Contact Id = ' + c.Id);
    }
}