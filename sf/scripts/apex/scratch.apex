        Account a = new Account(Name = 'Test', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test2', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test3', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Not Test', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Contact con = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = a.Id
        );

        Contact con2 = new Contact(
            FirstName = 'Tony',
            LastName = 'Stark',
            AccountId = b.Id
        );

        Contact con3 = new Contact(
            FirstName = 'Bruce',
            LastName = 'Banner',
            AccountId = c.Id
        );

        List<Contact> conList = new List<Contact>{con, con2, con3};
        mockDb.doInsert(conList);

        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, NumberOfEmployees FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE Account.Name IN (\'Test\', \'Test2\'))');
        System.debug(queriedAccts.size());