Account a = new Account(Name = 'Test', NumberOfEmployees = 5);
Account b = new Account(Name = 'Test2', NumberOfEmployees = 10);
Account c = new Account(Name = 'Test3', NumberOfEmployees = 15);
Account d = new Account(Name = 'Not Test', NumberOfEmployees = 20);
MockDatabase mockDb = new MockDatabase();
List<Account> acctList = new List<Account>{a, b, c, d};
mockDb.doInsert(acctList);

List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, NumberOfEmployees FROM Account WHERE NumberOfEmployees > 5 AND NumberOfEmployees < 20');
System.debug(queriedAccts.size());