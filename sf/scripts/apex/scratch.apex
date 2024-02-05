MockDatabase db = new MockDatabase();
Account acct = new Account(Name = 'Test Account');
Account acct2 = new Account(Name = 'Test Account 2');
List<Account> acctList = new List<Account>{acct, acct2};
db.doInsert(acctList);

Contact con = new Contact(LastName = 'Test Contact', AccountId = acct.Id);
Contact con2 = new Contact(LastName = 'Test Contact 2', AccountId = acct2.Id);
List<Contact> conList = new List<Contact>{con, con2};
db.doInsert(conList);
List<Contact> queriedCons = (List<Contact>) db.query('SELECT Account.Name FROM Contact ORDER BY Account.Name DESC');
for(Contact con : queriedCons) {
    System.debug(con.Account.Name);
}