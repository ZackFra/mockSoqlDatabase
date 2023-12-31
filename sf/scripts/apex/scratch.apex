        Account acct = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(acct);
        List<Contact> queriedAccts = (List<Contact>) mockDb.query('SELECT Id, Name, Name FROM Account');