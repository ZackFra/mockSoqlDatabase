@IsTest
public with sharing class MockDatabaseTest {

    /** DML Tests */
    @IsTest
    public static void testDelete() {
        Account a = new Account(Name = 'Test 1');
        Account b = new Account(Name = 'Test 2');
        Account c = new Account(Name = 'Test 3');
        Account d = new Account(Name = 'Test 4');
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        mockDb.doDelete(acctList);
        Test.stopTest();

        List<sObject> queriedAccts = (List<sObject>) mockDb.query('SELECT Id FROM Account');
        Assert.areEqual(0, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testUpdateList() {
        Account a = new Account(Name = 'Test 1');
        Account b = new Account(Name = 'Test 2');
        Account c = new Account(Name = 'Test 3');
        Account d = new Account(Name = 'Test 4');
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        for(Account acct : acctList) {
            acct.Name = 'Updated';
        }
        Test.startTest();
        mockDb.doUpdate(acctList);
        Test.stopTest();

        List<sObject> queriedAccts = (List<sObject>) mockDb.query('SELECT Id, Name FROM Account');
        for(sObject acct : queriedAccts) {
            Assert.areEqual('Updated', acct.get('Name'), 'Account was not updated');
        }
    }

    @IsTest
    public static void testInsert() {
        Account a = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        Test.startTest();
        mockDb.doInsert(a);
        Test.stopTest();

        Assert.isNotNull(mockDb.db.get('Account').get(a.Id), 'Account was not inserted');
    }

    @IsTest
    public static void testInsertList() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        MockDatabase mockDb = new MockDatabase();
        Test.startTest();
        mockDb.doInsert(new List<SObject>{a, b});
        Test.stopTest();

        Account insertedAcctA = (Account) mockDb.db.get('Account').get(a.Id);
        Account insertedAcctB = (Account) mockDb.db.get('Account').get(b.Id);

        Assert.isNotNull(insertedAcctA, 'Account A was not inserted');
        Assert.isNotNull(insertedAcctB, 'Account B was not inserted');
    }

    @IsTest
    public static void testUpdate() {
        Account a = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);

        Test.startTest();
        a.Name = 'Test2';
        mockDb.doUpdate(a);
        Test.stopTest();

        Account updatedAcct = (Account) mockDb.db.get('Account').get(a.Id);

        Assert.areEqual('Test2', updatedAcct.Name, 'Account was not updated');
    }

    /** SOQL Tests */
    @IsTest
    public static void testQuerySingle() {
        Account a = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account');
        Test.stopTest();
        Account queriedAcct = queriedAccts[0];
        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.isNotNull(queriedAcct, 'Account was not queried');
    }

    @IsTest
    public static void testQueryMultiple() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);
        mockDb.doInsert(b);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account');
        Test.stopTest();

        Assert.isNotNull(queriedAccts, 'Accounts were not queried');
        Assert.areEqual(2, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testInsertMultiple() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        MockDatabase mockDb = new MockDatabase();

        Test.startTest();
        mockDb.doInsert(new List<SObject>{a, b});
        Test.stopTest();
        
        Account insertedAcctA = (Account) mockDb.db.get('Account').get(a.Id);
        Account insertedAcctB = (Account) mockDb.db.get('Account').get(b.Id);

        Assert.isNotNull(insertedAcctA, 'Account A was not inserted');
        Assert.isNotNull(insertedAcctB, 'Account B was not inserted');
    }

    @IsTest
    public static void testParentSubQuery() {
        Account a = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);

        Contact con = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = a.Id
        );

        mockDb.doInsert(con);

        Test.startTest();
        List<Contact> queriedCons = (List<Contact>) mockDb.query('SELECT Id, FirstName, LastName, Account.Name FROM Contact');
        Test.stopTest();

        Contact queriedCon = queriedCons[0];
        Assert.areEqual(1, queriedCons.size(), 'Incorrect number of contacts queried');
        Assert.areEqual('Test', queriedCon.Account.Name, 'Expected account name to be \'Test\'');
        Assert.areEqual('Steve', queriedCon.FirstName, 'Expected first name to be \'Steve\'');
        Assert.areEqual('Banner', queriedCon.LastName, 'Expected last name to be \'Banner\'');
        Assert.areEqual(con.Id, queriedCon.Id, 'Expected queried contact to be the same as inserted contact');
    }

    @IsTest
    static void testChildSubQuery(){
        Account acct = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(acct);

        Contact con = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = acct.Id
        );

        mockDb.doInsert(con);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, (SELECT Id, FirstName, LastName FROM Contacts) FROM Account');
        Test.stopTest();

        Account queriedAcct = queriedAccts[0];
        Contact queriedCon = queriedAcct.Contacts[0];

        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual(1, queriedAcct.Contacts.size(), 'Incorrect number of contacts queried');
        Assert.areEqual('Test', queriedAcct.Name, 'Expected account name to be \'Test\'');
        Assert.areEqual('Steve', queriedCon.FirstName, 'Expected first name to be \'Steve\'');
        Assert.areEqual('Banner', queriedCon.LastName, 'Expected last name to be \'Banner\'');
        Assert.areEqual(con.Id, queriedCon.Id, 'Expected queried contact to be the same as inserted contact');
   
    }

    @IsTest
    public static void testChildSubQueryMultiple() {
        Account acct = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(acct);

        List<Contact> conList = new List<Contact>();
        for(Integer i = 0; i < 5; i++) {
            Contact con = new Contact(
                FirstName = 'Steve',
                LastName = 'Banner' + i,
                AccountId = acct.Id
            );
            conList.add(con);
        }
        mockDb.doInsert(conList);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, (SELECT Id, FirstName, LastName FROM Contacts) FROM Account');
        Test.stopTest();

        Account queriedAcct = queriedAccts[0];


        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual(5, queriedAcct.Contacts.size(), 'Incorrect number of contacts queried');
        Assert.areEqual('Test', queriedAcct.Name, 'Expected account name to be \'Test\'');

        Map<String, Boolean> queriedConNames = new Map<String, Boolean>();
        for(Integer i = 0; i < 5; i++) {
            queriedConNames.put(queriedAcct.Contacts[i].FirstName + queriedAcct.Contacts[i].LastName, true);
        }
        for(Integer i = 0; i < 5; i++) {
            Assert.areEqual('Steve', queriedAcct.Contacts[i].FirstName, 'Expected first name to be \'Steve\'');
            queriedConNames.put(queriedAcct.Contacts[i].FirstName + queriedAcct.Contacts[i].LastName, true);
        }

        for(Boolean foundName : queriedConNames.values()) {
            Assert.isTrue(foundName, 'Expected queried contact to be the same as inserted contact');
        }
    }

    @IsTest
    public static void testMutipleChildSubQueries() {
        Account acct = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(acct);

        List<sObject> childRecords = new List<sObject>();
        for(Integer i = 0; i < 5; i++) {
            Contact con = new Contact(
                FirstName = 'Steve',
                LastName = 'Banner' + i,
                AccountId = acct.Id
            );
            childRecords.add(con);
        }

        for(Integer i = 0; i < 5; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Test' + i,
                AccountId = acct.Id,
                CloseDate = Date.today(),
                StageName = 'Prospecting'
            );
            childRecords.add(opp);
        }
        mockDb.doInsert(childRecords);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, (SELECT Id, FirstName, LastName FROM Contacts), (SELECT Id, Name FROM Opportunities) FROM Account');
        Test.stopTest();

        Account queriedAcct = queriedAccts[0];

        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual(5, queriedAcct.Contacts.size(), 'Incorrect number of contacts queried');
        Assert.areEqual(5, queriedAcct.Opportunities.size(), 'Incorrect number of opportunities queried');
        Assert.areEqual('Test', queriedAcct.Name, 'Expected account name to be \'Test\'');

        Map<String, Boolean> queriedConNames = new Map<String, Boolean>();
        for(Integer i = 0; i < 5; i++) {
            queriedConNames.put(queriedAcct.Contacts[i].FirstName + queriedAcct.Contacts[i].LastName, true);
        }
        for(Integer i = 0; i < 5; i++) {
            Assert.areEqual('Steve', queriedAcct.Contacts[i].FirstName, 'Expected first name to be \'Steve\'');
            queriedConNames.put(queriedAcct.Contacts[i].FirstName + queriedAcct.Contacts[i].LastName, true);
        }

        for(Boolean foundName : queriedConNames.values()) {
            Assert.isTrue(foundName, 'Expected queried contact to be the same as inserted contact');
        }

        Map<String, Boolean> queriedOppNames = new Map<String, Boolean>();
        for(Integer i = 0; i < 5; i++) {
            queriedOppNames.put(queriedAcct.Opportunities[i].Name, true);
        }
        for(Integer i = 0; i < 5; i++) {
            Assert.areEqual('Test' + i, queriedAcct.Opportunities[i].Name, 'Expected opportunity name to be \'Test' + i + '\'');
            queriedOppNames.put(queriedAcct.Opportunities[i].Name, true);
        }

        for(Boolean foundName : queriedOppNames.values()) {
            Assert.isTrue(foundName, 'Expected queried opportunity to be the same as inserted opportunity');
        }
    }

    @IsTest
    public static void testDisallowDuplicateSubQueries() {
        Account acct = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(acct);

        List<sObject> childRecords = new List<sObject>();
        for(Integer i = 0; i < 5; i++) {
            Contact con = new Contact(
                FirstName = 'Steve',
                LastName = 'Banner' + i,
                AccountId = acct.Id
            );
            childRecords.add(con);
        }

        for(Integer i = 0; i < 5; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Test' + i,
                AccountId = acct.Id,
                CloseDate = Date.today(),
                StageName = 'Prospecting'
            );
            childRecords.add(opp);
        }
        mockDb.doInsert(childRecords);

        String exMessage;
        Test.startTest();
        try {
            mockDb.query('SELECT Id, Name, (SELECT Id, FirstName, LastName FROM Contacts), (SELECT Id, Name FROM Opportunities), (SELECT Id, Name FROM Opportunities WHERE Name = \'Test1\') FROM Account');
        } catch(QueryException e) {
            exMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.areEqual('Cannot follow the same aggregate relationship twice', exMessage, 'Expected exception message to be \'Cannot follow the same aggregate relationship twice\'');
    }

    @IsTest
    public static void testQueryWithWhereClause() {
        Account a = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account WHERE Name = \'Test\'');
        Test.stopTest();

        Account queriedAcct = queriedAccts[0];
        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.isNotNull(queriedAcct, 'Account was not queried');
    }

    @IsTest
    public static void testQueryWithWhereClauseMultiple() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);
        mockDb.doInsert(b);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account WHERE Name = \'Test\'');
        Test.stopTest();

        Account queriedAcct = queriedAccts[0];
        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.isNotNull(queriedAcct, 'Account was not queried');
    }

    @IsTest
    public static void testQueryWithWhereClauseNone() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);
        mockDb.doInsert(b);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account WHERE Name = \'Test3\'');
        Test.stopTest();

        Assert.areEqual(0, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testQueryWithWhereClauseMultipleFields() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);
        mockDb.doInsert(b);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account WHERE Name = \'Test\' OR Name = \'Test2\'');
        Test.stopTest();
        Assert.areEqual(2, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testQueryWithWhereClauseMultipleFieldsNone() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);
        mockDb.doInsert(b);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account WHERE Name = \'Test3\' OR Name = \'Test4\'');
        Test.stopTest();

        Assert.areEqual(0, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testQueryWithWhereClauseMultipleFieldsOne() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);
        mockDb.doInsert(b);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account WHERE Name = \'Test\' OR Name = \'Test4\'');
        Test.stopTest();

        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testQueryWithSubQueryInWhereClause() {
        Account acct = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(acct);

        Contact con = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = acct.Id
        );

        mockDb.doInsert(con);

        Test.startTest();
        List<Contact> queriedCons = (List<Contact>) mockDb.query('SELECT Id, FirstName, LastName, Account.Name FROM Contact WHERE AccountId IN (SELECT Id FROM Account WHERE Name = \'Test\')');
        Test.stopTest();

        Contact queriedCon = queriedCons[0];
        Assert.areEqual(1, queriedCons.size(), 'Incorrect number of contacts queried');
        Assert.areEqual('Test', queriedCon.Account.Name, 'Expected account name to be \'Test\'');
        Assert.areEqual('Steve', queriedCon.FirstName, 'Expected first name to be \'Steve\'');
        Assert.areEqual('Banner', queriedCon.LastName, 'Expected last name to be \'Banner\'');
        Assert.areEqual(con.Id, queriedCon.Id, 'Expected queried contact to be the same as inserted contact');
    }

    @IsTest
    public static void testDuplicateFieldsQueried() {
        Account acct = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(acct);
        String exMessage;
        Test.startTest();
        try {
            mockDb.query('SELECT Id, Name, Name FROM Account');
        } catch(QueryException e) {
            exMessage = e.getMessage();
        }
        Test.stopTest();
        Assert.areEqual('Duplicate field selected', exMessage, 'Expected exception message to be \'Duplicate field selected: Name\'');
    }

    @IsTest
    public static void testQueryWithSubQueryInWhereClauseMultiple() {
        Account acct = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(acct);

        List<Contact> conList = new List<Contact>();
        for(Integer i = 0; i < 5; i++) {
            Contact con = new Contact(
                FirstName = 'Steve',
                LastName = 'Banner' + i,
                AccountId = acct.Id
            );
            conList.add(con);
        }
        mockDb.doInsert(conList);
        
        Test.startTest();
        List<Contact> queriedCons = (List<Contact>) mockDb.query('SELECT Id, FirstName, LastName, Account.Name FROM Contact WHERE AccountId IN (SELECT Id FROM Account WHERE Name = \'Test\')');
        Test.stopTest();

        Contact queriedCon = queriedCons[0];

        Assert.areEqual(5, queriedCons.size(), 'Incorrect number of contacts queried');
        Assert.areEqual('Test', queriedCon.Account.Name, 'Expected account name to be \'Test\'');

        Map<String, Boolean> queriedConNames = new Map<String, Boolean>();
        for(Integer i = 0; i < 5; i++) {
            queriedConNames.put(queriedCons[i].FirstName + queriedCons[i].LastName, true);
        }
        for(Integer i = 0; i < 5; i++) {
            Assert.areEqual('Steve', queriedCons[i].FirstName, 'Expected first name to be \'Steve\'');
            queriedConNames.put(queriedCons[i].FirstName + queriedCons[i].LastName, true);
        }

        for(Boolean foundName : queriedConNames.values()) {
            Assert.isTrue(foundName, 'Expected queried contact to be the same as inserted contact');
        }
    }

    @IsTest
    public static void testQueryWithSubQueryInWhereClauseMultipleNone() {
        Account acct = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(acct);

        List<Contact> conList = new List<Contact>();
        for(Integer i = 0; i < 5; i++) {
            Contact con = new Contact(
                FirstName = 'Steve',
                LastName = 'Banner' + i,
                AccountId = acct.Id
            );
            conList.add(con);
        }
        mockDb.doInsert(conList);

        Test.startTest();
        List<Contact> queriedCons = (List<Contact>) mockDb.query('SELECT Id, FirstName, LastName, Account.Name FROM Contact WHERE AccountId IN (SELECT Id FROM Account WHERE Name = \'Test2\')');
        Test.stopTest();

        Assert.areEqual(0, queriedCons.size(), 'Incorrect number of contacts queried');
    }

    @IsTest
    public static void testCount() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);
        mockDb.doInsert(b);

        Test.startTest();
        Integer count = (Integer) mockDb.query('SELECT COUNT() FROM Account');
        Test.stopTest();

        Assert.areEqual(2, count, 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testCountWithWhereClause() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);
        mockDb.doInsert(b);

        Test.startTest();
        Integer count = (Integer) mockDb.query('SELECT COUNT() FROM Account WHERE Name = \'Test\'');
        Test.stopTest();

        Assert.areEqual(1, count, 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testLikeOperator() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        Account c = new Account(Name = 'Test3');
        Account d = new Account(Name = 'Not Test');
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account WHERE Name LIKE \'Test%\'');
        Test.stopTest();
        Assert.areEqual(3, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testWhereConditionWithAnd() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        Account c = new Account(Name = 'Test3');
        Account d = new Account(Name = 'Not Test');
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDB.doInsert(acctList);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account WHERE Name LIKE \'%Test%\' AND Name != \'Test\'');
        Test.stopTest();

        Assert.areEqual(3, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testWhereConditionWithOr() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        Account c = new Account(Name = 'Test3');
        Account d = new Account(Name = 'Not Test');
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account WHERE Name LIKE \'%Test%\' OR Name != \'Test\'');
        Test.stopTest();
        Assert.areEqual(4, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testQueryWithBinds() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        Account c = new Account(Name = 'Test3');
        Account d = new Account(Name = 'Not Test');
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Map<String, Object> binds = new Map<String, Object> {
            'name' => 'Test'
        };

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.queryWithBinds('SELECT Id, Name FROM Account WHERE Name = :name', binds);
        Test.stopTest();
        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testQueryWithBindsList() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        Account c = new Account(Name = 'Test3');
        Account d = new Account(Name = 'Not Test');
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        List<String> names = new List<String>{'Test', 'Test2'};

        Map<String, Object> binds = new Map<String, Object> {
            'names' => names
        };

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.queryWithBinds('SELECT Id, Name FROM Account WHERE Name IN :names', binds);
        Test.stopTest();

        Assert.areEqual(2, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testQueryWithValueList() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        Account c = new Account(Name = 'Test3');
        Account d = new Account(Name = 'Not Test');
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account WHERE Name IN (\'Test\', \'Test2\')');
        Test.stopTest();

        Assert.areEqual(2, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testWhereClauseParentSubQuery() {
        Account acct = new Account(Name = 'Test');
        Account acct2 = new Account(Name = 'Test2');
        List<Account> accts = new List<Account>{acct, acct2};
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(accts);

        Contact con = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = acct.Id
        );

        mockDb.doInsert(con);

        Test.startTest();
        List<Contact> queriedCons = (List<Contact>) mockDb.query('SELECT Id, FirstName, LastName, Account.Name FROM Contact WHERE Account.Name = \'Test\'');
        Test.stopTest();

        Contact queriedCon = queriedCons[0];
        Assert.areEqual(1, queriedCons.size(), 'Incorrect number of contacts queried');
        Assert.areEqual('Test', queriedCon.Account.Name, 'Expected account name to be \'Test\'');
        Assert.areEqual('Steve', queriedCon.FirstName, 'Expected first name to be \'Steve\'');
        Assert.areEqual('Banner', queriedCon.LastName, 'Expected last name to be \'Banner\'');
        Assert.areEqual(con.Id, queriedCon.Id, 'Expected queried contact to be the same as inserted contact');
    }

    @IsTest
    public static void testAllOperators() {

        Account a = new Account(Name = 'Test', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test2', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test3', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Not Test', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, NumberOfEmployees FROM Account WHERE NumberOfEmployees > 5 AND NumberOfEmployees < 20 AND NumberOfEmployees >= 10 AND NumberOfEmployees <= 15 AND NumberOfEmployees != 20 AND NumberOfEmployees IN (5, 10, 15)');
        Test.stopTest();

        Assert.areEqual(2, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testWhereClauseComparisonNonString() {
            
        Account a = new Account(Name = 'Test', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test2', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test3', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Not Test', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);
    
        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, NumberOfEmployees FROM Account WHERE NumberOfEmployees = 5');
        Test.stopTest();

        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testWhereClauseNotIn() {
                
        Account a = new Account(Name = 'Test', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test2', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test3', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Not Test', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, NumberOfEmployees FROM Account WHERE NumberOfEmployees NOT IN (5, 10, 15)');
        Test.stopTest();

        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testWhereClauseSubQuery() {          
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
        mockDb.doInsert(con);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, NumberOfEmployees FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE Account.Name = \'Test\')');
        Test.stopTest();

        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testSumFunc() {
        Account a = new Account(Name = 'Test', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test2', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test3', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Not Test', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT SUM(NumberOfEmployees) FROM Account');
        Test.stopTest();

        Decimal sum = (Decimal) queriedAccts[0].get('expr0');
        Assert.areEqual(50, sum, 'Incorrect sum');
    }

    @IsTest
    public static void testSingulerCount() {
        Account a = new Account(Name = 'Test', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test2', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test3', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Not Test', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        Integer count = (Integer) mockDb.query('SELECT COUNT() FROM Account');
        Test.stopTest();

        Assert.areEqual(4, count, 'Incorrect count');
    }

    @IsTest
    public static void testCountWithGroupBy() {
        Account a = new Account(Name = 'Test', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test2', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test3', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Not Test', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT COUNT(Id) FROM Account GROUP BY Name');
        Test.stopTest();

        Assert.areEqual(4, queriedAccts.size(), 'Incorrect count');
    }

    @IsTest
    public static void testCountDistinct() {
        Account a = new Account(Name = 'Test', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test2', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test3', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Not Test', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT COUNT_DISTINCT(Name) FROM Account');
        Test.stopTest();

        Integer count = (Integer) queriedAccts[0].get('expr0');
        Assert.areEqual(4, count, 'Incorrect count');
    }

    @IsTest
    public static void testMinFunc() {
        Account a = new Account(Name = 'Test', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test2', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test3', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Not Test', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT MIN(NumberOfEmployees) FROM Account');
        Test.stopTest();

        Decimal min = (Decimal) queriedAccts[0].get('expr0');
        Assert.areEqual(5, min, 'Incorrect min');
    }

    @IsTest
    public static void testMaxFunc() {
        Account a = new Account(Name = 'Test', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test2', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test3', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Not Test', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT MAX(NumberOfEmployees) FROM Account');
        Test.stopTest();

        Decimal max = (Decimal) queriedAccts[0].get('expr0');
        Assert.areEqual(20, max, 'Incorrect max');
    }

    @IsTest
    public static void testSumWithAlias() {
        Account a = new Account(Name = 'Test', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test2', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test3', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Not Test', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT SUM(NumberOfEmployees) sum FROM Account');
        Test.stopTest();
        Decimal sum = (Decimal) queriedAccts[0].get('sum');
        Assert.areEqual(50, sum, 'Incorrect sum');
    }

    @IsTest
    public static void testAvgFunc() {
        Account a = new Account(Name = 'Test', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test2', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test3', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Not Test', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT AVG(NumberOfEmployees) FROM Account');
        Test.stopTest();

        Decimal avg = (Decimal) queriedAccts[0].get('expr0');
        Assert.areEqual(12.5, avg, 'Incorrect avg');
    }

    @IsTest 
    public static void testSumWithGroupBy() {
        Account a = new Account(Name = 'Test', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test3', NumberOfEmployees = 5);
        Account d = new Account(Name = 'Not Test', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT SUM(NumberOfEmployees) FROM Account GROUP BY Name');
        Test.stopTest();

        Assert.areEqual(3, queriedAccts.size(), 'Incorrect count');
    }
    
    @IsTest
    public static void testGroupBySelectBadField() {
        Account a = new Account(Name = 'Test', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test2', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test3', NumberOfEmployees = 5);
        Account d = new Account(Name = 'Not Test', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);
        String exMessage;
        Test.startTest();
        try {
            mockDb.query('SELECT Name, SUM(NumberOfEmployees) FROM Account GROUP BY NumberOfEmployees');
        } catch(QueryException e) {
            exMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(
            exMessage.contains('Field must be grouped or aggregated'),
            'Expected exception message to contain \'Field must be grouped or aggregated\''
        );
    }

    @IsTest
    public static void testMultipleAggregateFuncs() {
        Account a = new Account(Name = 'Test', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test', NumberOfEmployees = 5);
        Account c = new Account(Name = 'Test', NumberOfEmployees = 5);
        Account d = new Account(Name = 'Test', NumberOfEmployees = 5);

        Account e = new Account(Name = 'Test2', NumberOfEmployees = 10);
        Account f = new Account(Name = 'Test3', NumberOfEmployees = 5);
        Account g = new Account(Name = 'Not Test', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d, e, f, g};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT Name, SUM(NumberOfEmployees), AVG(NumberOfEmployees) FROM Account GROUP BY Name');
        Test.stopTest();

        Assert.areEqual(4, queriedAccts.size(), 'Incorrect count');
        for(Aggregate agg : queriedAccts) {
            Decimal sum = (Decimal) agg.get('expr0');
            Decimal avg = (Decimal) agg.get('expr1');
            if(agg.get('Name') == 'Test') {
                Assert.areEqual(20, sum, 'Incorrect sum');
                Assert.areEqual(5, avg, 'Incorrect avg');
            } else if(agg.get('Name') == 'Test2') {
                Assert.areEqual(10, sum, 'Incorrect sum');
                Assert.areEqual(10, avg, 'Incorrect avg');
            } else if(agg.get('Name') == 'Test3') {
                Assert.areEqual(5, sum, 'Incorrect sum');
                Assert.areEqual(5, avg, 'Incorrect avg');
            } else if(agg.get('Name') == 'Not Test') {
                Assert.areEqual(20, sum, 'Incorrect sum');
                Assert.areEqual(20, avg, 'Incorrect avg');
            }
        }
    }

    @IsTest
    public static void testAggrGroupByFail() {
        Account a = new Account(Name = 'Test', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test', NumberOfEmployees = 5);
        Account c = new Account(Name = 'Test', NumberOfEmployees = 5);
        Account d = new Account(Name = 'Test', NumberOfEmployees = 5);

        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        String exMessage;
        Test.startTest();
        try {
            mockDb.query('SELECT Name, COUNT_DISTINCT(Name) FROM Account GROUP BY Name');
        } catch(QueryException e) {
            exMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(
            exMessage.contains('Grouped field should not be aggregated'),
            'Expected exception message to contain \'Field must be grouped or aggregated\''
        );
    }

    @IsTest
    public static void testEmptyQuery() {
        MockDatabase mockDb = new MockDatabase();
        Test.startTest();
        List<sObject> queriedAccts = (List<sObject>) mockDb.query('SELECT Id FROM Account');
        Test.stopTest();
        Assert.areEqual(0, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testGroupByParentAccountName() {
        Account a = new Account(Name = 'Test 1');
        Account b = new Account(Name = 'Test 2');
        Account c = new Account(Name = 'Test 3');
        Account d = new Account(Name = 'Test 4');
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Contact con = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = a.Id
        );
        mockDb.doInsert(con);

        String exMessage;
        Test.startTest();
        try {
            mockDb.query('SELECT Account.Name, Name, COUNT(Id) FROM Contact GROUP BY Name, Account.Name');
        } catch(QueryException e) {
            exMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(
            exMessage.contains('Duplicate alias'),
            'Expected exception message to contain \'Duplicate alias\''
        );
    }

    @IsTest
    public static void testAliases() {
        Account a = new Account(Name = 'Test 1');
        Account b = new Account(Name = 'Test 2');
        Account c = new Account(Name = 'Test 3');
        Account d = new Account(Name = 'Test 4');
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Contact con = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = a.Id
        );
        mockDb.doInsert(con);

        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT Account.Name acctName, Name, COUNT(Id) FROM Contact GROUP BY Name, Account.Name');
        Test.stopTest();

        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testDuplicateAliases() {
        Account a = new Account(Name = 'Test 1');
        Account b = new Account(Name = 'Test 2');
        Account c = new Account(Name = 'Test 3');
        Account d = new Account(Name = 'Test 4');
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Contact con = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = a.Id
        );
        mockDb.doInsert(con);

        String exMessage;
        Test.startTest();
        try {
            mockDb.query('SELECT Account.Name acctName, Name acctName, COUNT(Id) FROM Contact GROUP BY Name, Account.Name');
        } catch(QueryException e) {
            exMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(
            exMessage.contains('Duplicate alias'),
            'Expected exception message to contain \'Duplicate alias\''
        );
    }

    @IsTest
    public static void testChildSubQueryWithWhereClause() {
        Account acct = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(acct);

        List<Contact> conList = new List<Contact>();
        for(Integer i = 0; i < 5; i++) {
            Contact con = new Contact(
                FirstName = 'Steve',
                LastName = 'Banner' + i,
                AccountId = acct.Id
            );
            conList.add(con);
        }
        mockDb.doInsert(conList);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, (SELECT FirstName, LastName FROM Contacts WHERE FirstName LIKE \'%Steve%\') FROM Account');
        Test.stopTest();

        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual(5, queriedAccts[0].Contacts.size(), 'Incorrect number of contacts queried');

        for(Contact con : queriedAccts[0].Contacts) {
            Assert.isTrue(con.FirstName.contains('Steve'), 'Expected first name to contain \'Steve\'');
        }
    }

    @IsTest
    public static void testChildSubQueryWithWhereClause2() {
        Account acct = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(acct);

        List<Contact> conList = new List<Contact>();
        for(Integer i = 0; i < 5; i++) {
            Contact con = new Contact(
                FirstName = 'Steve',
                LastName = 'Banner' + i,
                AccountId = acct.Id
            );
            conList.add(con);
        }
        mockDb.doInsert(conList);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, (SELECT FirstName, LastName FROM Contacts WHERE LastName IN (\'Banner1\', \'Banner2\', \'Banner3\')) FROM Account');
        Test.stopTest();

        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual(3, queriedAccts[0].Contacts.size(), 'Incorrect number of contacts queried');
        List<String> expectedLastNames = new List<String>{'Banner1', 'Banner2', 'Banner3'};
        for(Integer i = 0; i < 3; i++) {
            Contact con = queriedAccts[0].Contacts[i];
            Assert.isTrue(
                expectedLastNames.contains(con.LastName),
                'Expected last name to be in list of expected last names'
            );
        }
    }

    @IsTest
    public static void testNot() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        Account c = new Account(Name = 'Test3');
        Account d = new Account(Name = 'Not Test');
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account WHERE NOT Name = \'Test\'');
        Test.stopTest();

        Assert.areEqual(3, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testConditionalSubExpr() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        Account c = new Account(Name = 'Test3');
        Account d = new Account(Name = 'Not Test');
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account WHERE Name = \'Test\' OR (Name = \'Test2\' AND Name = \'Test3\')');
        Test.stopTest();
        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testHavingClause() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test1', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test2', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Test2', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT Name, SUM(NumberOfEmployees) FROM Account GROUP BY Name HAVING SUM(NumberOfEmployees) > 10');
        Test.stopTest();
        Assert.areEqual(2, queriedAccts.size(), 'Incorrect count');
    }

    @IsTest
    public static void testHavingClauseMixedConditions() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test1', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test2', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Test2', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT Name, SUM(NumberOfEmployees) FROM Account GROUP BY Name HAVING Name = \'Test1\' AND SUM(NumberOfEmployees) > 10 AND Name = \'Test2\'');
        Test.stopTest();

        Assert.areEqual(0, queriedAccts.size(), 'Incorrect count');
    }

    @IsTest 
    public static void testHavingClauseWithMixedConditionsCorrectAnd() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test1', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test2', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Test2', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT Name, SUM(NumberOfEmployees) FROM Account GROUP BY Name HAVING Name = \'Test2\' OR Name = \'Test1\' AND SUM(NumberOfEmployees) > 10');
        Test.stopTest();

        Assert.areEqual(2, queriedAccts.size(), 'Incorrect count');       
    }

    @IsTest
    public static void testHavingWithQueryWithBinds() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test1', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test2', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Test2', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Map<String, Object> binds = new Map<String, Object> {
            'num' => 10
        };

        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.queryWithBinds('SELECT Name, SUM(NumberOfEmployees) FROM Account GROUP BY Name HAVING SUM(NumberOfEmployees) > :num', binds);
        Test.stopTest();
        Assert.areEqual(2, queriedAccts.size(), 'Incorrect count');
    }

    @IsTest
    public static void testHavingCrazyConditions() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test1', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test2', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Test2', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT Name, SUM(NumberOfEmployees) FROM Account GROUP BY Name HAVING Name = \'Test1\' AND SUM(NumberOfEmployees) > 10 OR Name = \'Test2\' AND SUM(NumberOfEmployees) > 10');
        Test.stopTest();

        Assert.areEqual(2, queriedAccts.size(), 'Incorrect count');
    }

    @IsTest
    public static void testOrderBy() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test2', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test3', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Test4', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);
        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, NumberOfEmployees FROM Account ORDER BY Name');
        Test.stopTest();

        Assert.areEqual(4, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual('Test1', queriedAccts[0].Name, 'Incorrect order');
        Assert.areEqual('Test2', queriedAccts[1].Name, 'Incorrect order');
        Assert.areEqual('Test3', queriedAccts[2].Name, 'Incorrect order');
        Assert.areEqual('Test4', queriedAccts[3].Name, 'Incorrect order');
    }

    @IsTest
    public static void testOrderByDESC() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test2', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test3', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Test4', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, NumberOfEmployees FROM Account ORDER BY Name DESC');
        Test.stopTest();

        Assert.areEqual(4, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual('Test4', queriedAccts[0].Name, 'Incorrect order');
        Assert.areEqual('Test3', queriedAccts[1].Name, 'Incorrect order');
        Assert.areEqual('Test2', queriedAccts[2].Name, 'Incorrect order');
        Assert.areEqual('Test1', queriedAccts[3].Name, 'Incorrect order');
    }

    @IsTest
    public static void testOrderByASC() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test2', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test3', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Test4', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);
        
        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, NumberOfEmployees FROM Account ORDER BY Name ASC');
        Test.stopTest();

        Assert.areEqual(4, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual('Test1', queriedAccts[0].Name, 'Incorrect order');
        Assert.areEqual('Test2', queriedAccts[1].Name, 'Incorrect order');
        Assert.areEqual('Test3', queriedAccts[2].Name, 'Incorrect order');
        Assert.areEqual('Test4', queriedAccts[3].Name, 'Incorrect order');
    }

    @IsTest
    public static void testOrderByWithGroupBy() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test1', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test2', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Test2', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);
        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT Name, SUM(NumberOfEmployees) FROM Account GROUP BY Name ORDER BY Name');
        Test.stopTest();

        Assert.areEqual('Test1', queriedAccts[0].get('Name'), 'Incorrect order');
        Assert.areEqual('Test2', queriedAccts[1].get('Name'), 'Incorrect order');
    }

    @IsTest
    public static void testOrderByWithGroupByDESC() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test1', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test2', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Test2', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);
        
        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT Name, SUM(NumberOfEmployees) FROM Account GROUP BY Name ORDER BY Name DESC');
        Test.stopTest();

        Assert.areEqual('Test2', queriedAccts[0].get('Name'), 'Incorrect order');
        Assert.areEqual('Test1', queriedAccts[1].get('Name'), 'Incorrect order');
    }

    @IsTest
    public static void testOrderByWithGroupByASC() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test1', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test2', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Test2', NumberOfEmployees = 20);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d};
        mockDb.doInsert(acctList);
        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT Name, SUM(NumberOfEmployees) FROM Account GROUP BY Name ORDER BY Name ASC');
        Test.stopTest();
        Assert.areEqual('Test1', queriedAccts[0].get('Name'), 'Incorrect order');
        Assert.areEqual('Test2', queriedAccts[1].get('Name'), 'Incorrect order');
    }

    @IsTest
    public static void testOrderByTwoFields() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5);
        Account b = new Account(Name = 'Test1', NumberOfEmployees = 10);
        Account c = new Account(Name = 'Test2', NumberOfEmployees = 15);
        Account d = new Account(Name = 'Test2', NumberOfEmployees = 20);
        Account e = new Account(Name = 'Test2', NumberOfEmployees = 5);
        Account f = new Account(Name = 'Test3', NumberOfEmployees = 10);
        Account g = new Account(Name = 'Test3', NumberOfEmployees = 15);
        Account h = new Account(Name = 'Test3', NumberOfEmployees = 20);
        Account i = new Account(Name = 'Test3', NumberOfEmployees = 5);
        Account j = new Account(Name = 'Test4', NumberOfEmployees = 10);
        Account k = new Account(Name = 'Test4', NumberOfEmployees = 15);
        Account l = new Account(Name = 'Test4', NumberOfEmployees = 20);
        Account m = new Account(Name = 'Test4', NumberOfEmployees = 5);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d, e, f, g, h, i, j, k, l, m};
        mockDb.doInsert(acctList);
        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, NumberOfEmployees FROM Account ORDER BY Name, NumberOfEmployees');
        Test.stopTest();
        Assert.areEqual(13, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual('Test1', queriedAccts[0].Name, 'Incorrect order');
        Assert.areEqual('Test1', queriedAccts[1].Name, 'Incorrect order');
        Assert.areEqual('Test2', queriedAccts[2].Name, 'Incorrect order');
        Assert.areEqual('Test2', queriedAccts[3].Name, 'Incorrect order');
        Assert.areEqual('Test2', queriedAccts[4].Name, 'Incorrect order');
        Assert.areEqual('Test3', queriedAccts[5].Name, 'Incorrect order');
        Assert.areEqual('Test3', queriedAccts[6].Name, 'Incorrect order');
        Assert.areEqual('Test3', queriedAccts[7].Name, 'Incorrect order');
        Assert.areEqual('Test3', queriedAccts[8].Name, 'Incorrect order');
        Assert.areEqual('Test4', queriedAccts[9].Name, 'Incorrect order');
        Assert.areEqual('Test4', queriedAccts[10].Name, 'Incorrect order');
        Assert.areEqual('Test4', queriedAccts[11].Name, 'Incorrect order');
        Assert.areEqual('Test4', queriedAccts[12].Name, 'Incorrect order');

        Assert.areEqual(5, queriedAccts[0].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(10, queriedAccts[1].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(5, queriedAccts[2].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(15, queriedAccts[3].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(20, queriedAccts[4].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(5, queriedAccts[5].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(10, queriedAccts[6].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(15, queriedAccts[7].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(20, queriedAccts[8].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(5, queriedAccts[9].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(10, queriedAccts[10].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(15, queriedAccts[11].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(20, queriedAccts[12].NumberOfEmployees, 'Incorrect order');
    }

    @IsTest
    public static void testOrderByThreeFields() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5, AnnualRevenue = 1000);
        Account b = new Account(Name = 'Test1', NumberOfEmployees = 10, AnnualRevenue = 1000);
        Account c = new Account(Name = 'Test2', NumberOfEmployees = 5, AnnualRevenue = 2000);
        Account d = new Account(Name = 'Test2', NumberOfEmployees = 20, AnnualRevenue = 3000);
        Account e = new Account(Name = 'Test2', NumberOfEmployees = 5, AnnualRevenue = 4000);
        Account f = new Account(Name = 'Test3', NumberOfEmployees = 10, AnnualRevenue = 5000);
        Account g = new Account(Name = 'Test3', NumberOfEmployees = 15, AnnualRevenue = 3000);
        Account h = new Account(Name = 'Test3', NumberOfEmployees = 10, AnnualRevenue = 3000);
        Account i = new Account(Name = 'Test3', NumberOfEmployees = 5, AnnualRevenue = 5000);
        Account j = new Account(Name = 'Test4', NumberOfEmployees = 10, AnnualRevenue = 10000);
        Account k = new Account(Name = 'Test4', NumberOfEmployees = 10, AnnualRevenue = 2000);
        Account l = new Account(Name = 'Test4', NumberOfEmployees = 5, AnnualRevenue = 4000);
        Account m = new Account(Name = 'Test4', NumberOfEmployees = 5, AnnualRevenue = 3000);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d, e, f, g, h, i, j, k, l, m};
        mockDb.doInsert(acctList);
        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, NumberOfEmployees, AnnualRevenue FROM Account ORDER BY Name, NumberOfEmployees, AnnualRevenue');
        Test.stopTest();
        Assert.areEqual(13, queriedAccts.size(), 'Incorrect number of accounts queried');

        Assert.areEqual('Test1', queriedAccts[0].Name, 'Incorrect order');
        Assert.areEqual(5, queriedAccts[0].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(1000, queriedAccts[0].AnnualRevenue, 'Incorrect order');

        Assert.areEqual('Test1', queriedAccts[1].Name, 'Incorrect order');
        Assert.areEqual(10, queriedAccts[1].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(1000, queriedAccts[1].AnnualRevenue, 'Incorrect order');

        Assert.areEqual('Test2', queriedAccts[2].Name, 'Incorrect order');
        Assert.areEqual(5, queriedAccts[2].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(2000, queriedAccts[2].AnnualRevenue, 'Incorrect order');

        Assert.areEqual('Test2', queriedAccts[3].Name, 'Incorrect order');
        Assert.areEqual(5, queriedAccts[3].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(4000, queriedAccts[3].AnnualRevenue, 'Incorrect order');

        Assert.areEqual('Test2', queriedAccts[4].Name, 'Incorrect order');
        Assert.areEqual(20, queriedAccts[4].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(3000, queriedAccts[4].AnnualRevenue, 'Incorrect order');

        Assert.areEqual('Test3', queriedAccts[5].Name, 'Incorrect order');
        Assert.areEqual(5, queriedAccts[5].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(5000, queriedAccts[5].AnnualRevenue, 'Incorrect order');

        Assert.areEqual('Test3', queriedAccts[6].Name, 'Incorrect order');
        Assert.areEqual(10, queriedAccts[6].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(3000, queriedAccts[6].AnnualRevenue, 'Incorrect order');

        Assert.areEqual('Test3', queriedAccts[7].Name, 'Incorrect order');
        Assert.areEqual(10, queriedAccts[7].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(5000, queriedAccts[7].AnnualRevenue, 'Incorrect order');

        Assert.areEqual('Test3', queriedAccts[8].Name, 'Incorrect order');
        Assert.areEqual(15, queriedAccts[8].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(3000, queriedAccts[8].AnnualRevenue, 'Incorrect order');

        Assert.areEqual('Test4', queriedAccts[9].Name, 'Incorrect order');
        Assert.areEqual(5, queriedAccts[9].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(3000, queriedAccts[9].AnnualRevenue, 'Incorrect order');

        Assert.areEqual('Test4', queriedAccts[10].Name, 'Incorrect order');
        Assert.areEqual(5, queriedAccts[10].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(4000, queriedAccts[10].AnnualRevenue, 'Incorrect order');

        Assert.areEqual('Test4', queriedAccts[11].Name, 'Incorrect order');
        Assert.areEqual(10, queriedAccts[11].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(2000, queriedAccts[11].AnnualRevenue, 'Incorrect order');

        Assert.areEqual('Test4', queriedAccts[12].Name, 'Incorrect order');
        Assert.areEqual(10, queriedAccts[12].NumberOfEmployees, 'Incorrect order');
        Assert.areEqual(10000, queriedAccts[12].AnnualRevenue, 'Incorrect order');
    }

    @IsTest
    public static void testOrderByWithParentField() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5, AnnualRevenue = 1000);
        Account b = new Account(Name = 'Test1', NumberOfEmployees = 10, AnnualRevenue = 1000);
        Account c = new Account(Name = 'Test2', NumberOfEmployees = 5, AnnualRevenue = 2000);
        Account d = new Account(Name = 'Test2', NumberOfEmployees = 20, AnnualRevenue = 3000);
        Account e = new Account(Name = 'Test2', NumberOfEmployees = 5, AnnualRevenue = 4000);
        Account f = new Account(Name = 'Test3', NumberOfEmployees = 10, AnnualRevenue = 5000);
        Account g = new Account(Name = 'Test3', NumberOfEmployees = 15, AnnualRevenue = 3000);
        Account h = new Account(Name = 'Test3', NumberOfEmployees = 10, AnnualRevenue = 3000);
        Account i = new Account(Name = 'Test3', NumberOfEmployees = 5, AnnualRevenue = 5000);
        Account j = new Account(Name = 'Test4', NumberOfEmployees = 10, AnnualRevenue = 10000);
        Account k = new Account(Name = 'Test4', NumberOfEmployees = 10, AnnualRevenue = 2000);
        Account l = new Account(Name = 'Test4', NumberOfEmployees = 5, AnnualRevenue = 4000);
        Account m = new Account(Name = 'Test4', NumberOfEmployees = 5, AnnualRevenue = 3000);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d, e, f, g, h, i, j, k, l, m};
        mockDb.doInsert(acctList);

        Contact con0 = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = a.Id
        );

        Contact con1 = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = b.Id
        );

        Contact con2 = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = c.Id
        );

        Contact con3 = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = d.Id
        );
        List<Contact> conList = new List<Contact>{con0, con1, con2, con3};
        mockDb.doInsert(conList);

        Test.startTest();
        List<Contact> queriedContacts = (List<Contact>) mockDb.query('SELECT Id, FirstName, LastName, Account.Name FROM Contact ORDER BY Account.Name');
        Test.stopTest();

        Assert.areEqual(4, queriedContacts.size(), 'Incorrect number of contacts queried');
        Assert.areEqual('Test1', queriedContacts[0].Account.Name, 'Incorrect order');
        Assert.areEqual('Test1', queriedContacts[1].Account.Name, 'Incorrect order');
        Assert.areEqual('Test2', queriedContacts[2].Account.Name, 'Incorrect order');
        Assert.areEqual('Test2', queriedContacts[3].Account.Name, 'Incorrect order');
    }

    @IsTest
    public static void testOrderByWithGroupByParentField() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5, AnnualRevenue = 1000);
        Account b = new Account(Name = 'Test1', NumberOfEmployees = 10, AnnualRevenue = 1000);
        Account c = new Account(Name = 'Test2', NumberOfEmployees = 5, AnnualRevenue = 2000);
        Account d = new Account(Name = 'Test2', NumberOfEmployees = 20, AnnualRevenue = 3000);
        Account e = new Account(Name = 'Test2', NumberOfEmployees = 5, AnnualRevenue = 4000);
        Account f = new Account(Name = 'Test3', NumberOfEmployees = 10, AnnualRevenue = 5000);
        Account g = new Account(Name = 'Test3', NumberOfEmployees = 15, AnnualRevenue = 3000);
        Account h = new Account(Name = 'Test3', NumberOfEmployees = 10, AnnualRevenue = 3000);
        Account i = new Account(Name = 'Test3', NumberOfEmployees = 5, AnnualRevenue = 5000);
        Account j = new Account(Name = 'Test4', NumberOfEmployees = 10, AnnualRevenue = 10000);
        Account k = new Account(Name = 'Test4', NumberOfEmployees = 10, AnnualRevenue = 2000);
        Account l = new Account(Name = 'Test4', NumberOfEmployees = 5, AnnualRevenue = 4000);
        Account m = new Account(Name = 'Test4', NumberOfEmployees = 5, AnnualRevenue = 3000);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d, e, f, g, h, i, j, k, l, m};
        mockDb.doInsert(acctList);

        Contact con0 = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = a.Id
        );

        Contact con1 = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = c.Id
        );

        Contact con2 = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = f.Id
        );

        Contact con3 = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = j.Id
        );
        List<Contact> conList = new List<Contact>{con0, con1, con2, con3};
        mockDb.doInsert(conList);

        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT Account.Name, COUNT(Id) FROM Contact GROUP BY Account.Name ORDER BY Account.Name');
        Test.stopTest();

        Assert.areEqual(4, queriedAccts.size(), 'Incorrect number of accounts queried');

        Assert.areEqual('Test1', queriedAccts[0].get('Name'), 'Incorrect order');
        Assert.areEqual('Test2', queriedAccts[1].get('Name'), 'Incorrect order');
        Assert.areEqual('Test3', queriedAccts[2].get('Name'), 'Incorrect order');
        Assert.areEqual('Test4', queriedAccts[3].get('Name'), 'Incorrect order');
    }

    @IsTest
    public static void testOrderByMutipleOrders() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5, AnnualRevenue = 1000);
        Account b = new Account(Name = 'Test1', NumberOfEmployees = 10, AnnualRevenue = 1000);
        Account c = new Account(Name = 'Test2', NumberOfEmployees = 5, AnnualRevenue = 2000);
        Account d = new Account(Name = 'Test2', NumberOfEmployees = 20, AnnualRevenue = 3000);
        Account e = new Account(Name = 'Test2', NumberOfEmployees = 5, AnnualRevenue = 4000);
        Account f = new Account(Name = 'Test3', NumberOfEmployees = 10, AnnualRevenue = 5000);
        Account g = new Account(Name = 'Test3', NumberOfEmployees = 15, AnnualRevenue = 3000);
        Account h = new Account(Name = 'Test3', NumberOfEmployees = 10, AnnualRevenue = 3000);
        Account i = new Account(Name = 'Test3', NumberOfEmployees = 5, AnnualRevenue = 5000);
        Account j = new Account(Name = 'Test4', NumberOfEmployees = 10, AnnualRevenue = 10000);
        Account k = new Account(Name = 'Test4', NumberOfEmployees = 10, AnnualRevenue = 2000);
        Account l = new Account(Name = 'Test4', NumberOfEmployees = 5, AnnualRevenue = 4000);
        Account m = new Account(Name = 'Test4', NumberOfEmployees = 5, AnnualRevenue = 3000);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d, e, f, g, h, i, j, k, l, m};
        mockDb.doInsert(acctList);

        Contact con0 = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = a.Id
        );

        Contact con1 = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = c.Id
        );

        Contact con2 = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = f.Id
        );

        Contact con3 = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = j.Id
        );
        List<Contact> conList = new List<Contact>{con0, con1, con2, con3};
        mockDb.doInsert(conList);

        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT Account.Name, COUNT(Id) FROM Contact GROUP BY Account.Name ORDER BY Account.Name, COUNT(Id)');
        Test.stopTest();

        Assert.areEqual(4, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual('Test1', queriedAccts[0].get('Name'), 'Incorrect order');
        Assert.areEqual('Test2', queriedAccts[1].get('Name'), 'Incorrect order');
        Assert.areEqual('Test3', queriedAccts[2].get('Name'), 'Incorrect order');
        Assert.areEqual('Test4', queriedAccts[3].get('Name'), 'Incorrect order');
    }

    @IsTest
    public static void testOrderByMutipleOrdersDESC() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5, AnnualRevenue = 1000);
        Account b = new Account(Name = 'Test1', NumberOfEmployees = 10, AnnualRevenue = 1000);
        Account c = new Account(Name = 'Test2', NumberOfEmployees = 5, AnnualRevenue = 2000);
        Account d = new Account(Name = 'Test2', NumberOfEmployees = 20, AnnualRevenue = 3000);
        Account e = new Account(Name = 'Test2', NumberOfEmployees = 5, AnnualRevenue = 4000);
        Account f = new Account(Name = 'Test3', NumberOfEmployees = 10, AnnualRevenue = 5000);
        Account g = new Account(Name = 'Test3', NumberOfEmployees = 15, AnnualRevenue = 3000);
        Account h = new Account(Name = 'Test3', NumberOfEmployees = 10, AnnualRevenue = 3000);
        Account i = new Account(Name = 'Test3', NumberOfEmployees = 5, AnnualRevenue = 5000);
        Account j = new Account(Name = 'Test4', NumberOfEmployees = 10, AnnualRevenue = 10000);
        Account k = new Account(Name = 'Test4', NumberOfEmployees = 10, AnnualRevenue = 2000);
        Account l = new Account(Name = 'Test4', NumberOfEmployees = 5, AnnualRevenue = 4000);
        Account m = new Account(Name = 'Test4', NumberOfEmployees = 5, AnnualRevenue = 3000);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d, e, f, g, h, i, j, k, l, m};
        mockDb.doInsert(acctList);

        Contact con0 = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = a.Id
        );

        Contact con1 = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = c.Id
        );

        Contact con2 = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = f.Id
        );

        Contact con3 = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = j.Id
        );

        Contact con4 = new Contact(
            FirstName = 'Steve',
            LastName = 'Banner',
            AccountId = k.Id
        );
        List<Contact> conList = new List<Contact>{con0, con1, con2, con3, con4};
        mockDb.doInsert(conList);

        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT Account.Name, COUNT(Id) FROM Contact GROUP BY Account.Name ORDER BY Account.Name DESC, COUNT(Id) DESC');
        Test.stopTest();

        Assert.areEqual(4, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual('Test4', queriedAccts[0].get('Name'), 'Incorrect order');
        Assert.areEqual('Test3', queriedAccts[1].get('Name'), 'Incorrect order');
        Assert.areEqual('Test2', queriedAccts[2].get('Name'), 'Incorrect order');
        Assert.areEqual('Test1', queriedAccts[3].get('Name'), 'Incorrect order');

        Assert.areEqual(2, queriedAccts[0].get('expr0'), 'Incorrect order');
        Assert.areEqual(1, queriedAccts[1].get('expr0'), 'Incorrect order');
        Assert.areEqual(1, queriedAccts[2].get('expr0'), 'Incorrect order');
        Assert.areEqual(1, queriedAccts[3].get('expr0'), 'Incorrect order');
    }

    @IsTest
    public static void testNullsFirst() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5, AnnualRevenue = 1000);
        Account b = new Account(Name = 'Test1', NumberOfEmployees = 10, AnnualRevenue = 1000);
        Account c = new Account(Name = 'Test2', NumberOfEmployees = 5, AnnualRevenue = 2000);
        Account d = new Account(Name = 'Test2', NumberOfEmployees = 20, AnnualRevenue = 3000);
        Account e = new Account(Name = 'Test2', NumberOfEmployees = 5, AnnualRevenue = 4000);
        Account f = new Account(Name = 'Test3', NumberOfEmployees = 10, AnnualRevenue = 5000);
        Account g = new Account(Name = 'Test3', NumberOfEmployees = 15, AnnualRevenue = 3000);
        Account h = new Account(Name = 'Test3', NumberOfEmployees = 10, AnnualRevenue = 3000);
        Account i = new Account(Name = 'Test3', NumberOfEmployees = 5, AnnualRevenue = 5000);
        Account j = new Account(Name = 'Test4', NumberOfEmployees = 10, AnnualRevenue = 10000);
        Account k = new Account(Name = 'Test4', NumberOfEmployees = 10, AnnualRevenue = 2000);
        Account l = new Account(Name = 'Test4', NumberOfEmployees = 5, AnnualRevenue = 4000);
        Account m = new Account(Name = 'Test4', NumberOfEmployees = 5, AnnualRevenue = 3000);
        Account n = new Account(Name = 'Test5', NumberOfEmployees = 5, AnnualRevenue = null);
        Account o = new Account(Name = 'Test5', NumberOfEmployees = 5, AnnualRevenue = 1000);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d, e, f, g, h, i, j, k, l, m, n, o};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, NumberOfEmployees, AnnualRevenue FROM Account ORDER BY AnnualRevenue NULLS FIRST');
        Test.stopTest();

        Assert.areEqual(15, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual('Test5', queriedAccts[0].Name, 'Incorrect order');
        Assert.areEqual('Test1', queriedAccts[1].Name, 'Incorrect order');
        Assert.areEqual('Test1', queriedAccts[2].Name, 'Incorrect order');
        Assert.areEqual('Test5', queriedAccts[3].Name, 'Incorrect order');
        Assert.areEqual('Test2', queriedAccts[4].Name, 'Incorrect order');
        Assert.areEqual('Test4', queriedAccts[5].Name, 'Incorrect order');
        Assert.areEqual('Test2', queriedAccts[6].Name, 'Incorrect order');
        Assert.areEqual('Test3', queriedAccts[7].Name, 'Incorrect order');
        Assert.areEqual('Test3', queriedAccts[8].Name, 'Incorrect order');
        Assert.areEqual('Test4', queriedAccts[9].Name, 'Incorrect order');
        Assert.areEqual('Test2', queriedAccts[10].Name, 'Incorrect order');
        Assert.areEqual('Test4', queriedAccts[11].Name, 'Incorrect order');
        Assert.areEqual('Test3', queriedAccts[12].Name, 'Incorrect order');
        Assert.areEqual('Test3', queriedAccts[13].Name, 'Incorrect order');
        Assert.areEqual('Test4', queriedAccts[14].Name, 'Incorrect order');
    }

    @IsTest
    public static void testNullsLast() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5, AnnualRevenue = 1000);
        Account b = new Account(Name = 'Test1', NumberOfEmployees = 10, AnnualRevenue = 1000);
        Account c = new Account(Name = 'Test2', NumberOfEmployees = 5, AnnualRevenue = 2000);
        Account d = new Account(Name = 'Test2', NumberOfEmployees = 20, AnnualRevenue = 3000);
        Account e = new Account(Name = 'Test2', NumberOfEmployees = 5, AnnualRevenue = 4000);
        Account f = new Account(Name = 'Test3', NumberOfEmployees = 10, AnnualRevenue = 5000);
        Account g = new Account(Name = 'Test3', NumberOfEmployees = 15, AnnualRevenue = 3000);
        Account h = new Account(Name = 'Test3', NumberOfEmployees = 10, AnnualRevenue = 3000);
        Account i = new Account(Name = 'Test3', NumberOfEmployees = 5, AnnualRevenue = 5000);
        Account j = new Account(Name = 'Test4', NumberOfEmployees = 10, AnnualRevenue = 10000);
        Account k = new Account(Name = 'Test4', NumberOfEmployees = 10, AnnualRevenue = 2000);
        Account l = new Account(Name = 'Test4', NumberOfEmployees = 5, AnnualRevenue = 4000);
        Account m = new Account(Name = 'Test4', NumberOfEmployees = 5, AnnualRevenue = 3000);
        Account n = new Account(Name = 'Test5', NumberOfEmployees = 5, AnnualRevenue = null);
        Account o = new Account(Name = 'Test5', NumberOfEmployees = 5, AnnualRevenue = 1000);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d, e, f, g, h, i, j, k, l, m, n, o};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, NumberOfEmployees, AnnualRevenue FROM Account ORDER BY AnnualRevenue NULLS LAST');
        Test.stopTest();
        
        Assert.areEqual(15, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual('Test1', queriedAccts[0].Name, 'Incorrect order');
        Assert.areEqual('Test1', queriedAccts[1].Name, 'Incorrect order');
        Assert.areEqual('Test5', queriedAccts[2].Name, 'Incorrect order');
        Assert.areEqual('Test2', queriedAccts[3].Name, 'Incorrect order');
        Assert.areEqual('Test4', queriedAccts[4].Name, 'Incorrect order');
        Assert.areEqual('Test2', queriedAccts[5].Name, 'Incorrect order');
        Assert.areEqual('Test3', queriedAccts[6].Name, 'Incorrect order');
        Assert.areEqual('Test3', queriedAccts[7].Name, 'Incorrect order');
        Assert.areEqual('Test4', queriedAccts[8].Name, 'Incorrect order');
        Assert.areEqual('Test2', queriedAccts[9].Name, 'Incorrect order');
        Assert.areEqual('Test4', queriedAccts[10].Name, 'Incorrect order');
        Assert.areEqual('Test3', queriedAccts[11].Name, 'Incorrect order');
        Assert.areEqual('Test3', queriedAccts[12].Name, 'Incorrect order');
        Assert.areEqual('Test4', queriedAccts[13].Name, 'Incorrect order');
        Assert.areEqual('Test5', queriedAccts[14].Name, 'Incorrect order');

    }

    @IsTest
    public static void testLimitSObject() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5, AnnualRevenue = 1000);
        Account b = new Account(Name = 'Test1', NumberOfEmployees = 10, AnnualRevenue = 1000);
        Account c = new Account(Name = 'Test2', NumberOfEmployees = 5, AnnualRevenue = 2000);
        Account d = new Account(Name = 'Test2', NumberOfEmployees = 20, AnnualRevenue = 3000);
        Account e = new Account(Name = 'Test2', NumberOfEmployees = 5, AnnualRevenue = 4000);
        Account f = new Account(Name = 'Test3', NumberOfEmployees = 10, AnnualRevenue = 5000);
        Account g = new Account(Name = 'Test3', NumberOfEmployees = 15, AnnualRevenue = 3000);
        Account h = new Account(Name = 'Test3', NumberOfEmployees = 10, AnnualRevenue = 3000);
        Account i = new Account(Name = 'Test3', NumberOfEmployees = 5, AnnualRevenue = 5000);
        Account j = new Account(Name = 'Test4', NumberOfEmployees = 10, AnnualRevenue = 10000);
        Account k = new Account(Name = 'Test4', NumberOfEmployees = 10, AnnualRevenue = 2000);
        Account l = new Account(Name = 'Test4', NumberOfEmployees = 5, AnnualRevenue = 4000);
        Account m = new Account(Name = 'Test4', NumberOfEmployees = 5, AnnualRevenue = 3000);
        Account n = new Account(Name = 'Test5', NumberOfEmployees = 5, AnnualRevenue = null);
        Account o = new Account(Name = 'Test5', NumberOfEmployees = 5, AnnualRevenue = 1000);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d, e, f, g, h, i, j, k, l, m, n, o};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, NumberOfEmployees, AnnualRevenue FROM Account ORDER BY AnnualRevenue NULLS LAST, Name NULLS FIRST LIMIT 5');
        Test.stopTest();

        Assert.areEqual(5, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual(1000, queriedAccts[0].AnnualRevenue, 'Incorrect order');
        Assert.areEqual(1000, queriedAccts[1].AnnualRevenue, 'Incorrect order');
        Assert.areEqual(1000, queriedAccts[2].AnnualRevenue, 'Incorrect order');
        Assert.areEqual(2000, queriedAccts[3].AnnualRevenue, 'Incorrect order');
        Assert.areEqual(2000, queriedAccts[4].AnnualRevenue, 'Incorrect order');

        Assert.areEqual('Test1', queriedAccts[0].Name, 'Incorrect order');
        Assert.areEqual('Test1', queriedAccts[1].Name, 'Incorrect order');
        Assert.areEqual('Test5', queriedAccts[2].Name, 'Incorrect order');
        Assert.areEqual('Test2', queriedAccts[3].Name, 'Incorrect order');
        Assert.areEqual('Test4', queriedAccts[4].Name, 'Incorrect order');   
    }

    @IsTest
    public static void testLimitCount() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5, AnnualRevenue = 1000);
        Account b = new Account(Name = 'Test1', NumberOfEmployees = 10, AnnualRevenue = 1000);
        Account c = new Account(Name = 'Test2', NumberOfEmployees = 5, AnnualRevenue = 2000);
        Account d = new Account(Name = 'Test2', NumberOfEmployees = 20, AnnualRevenue = 3000);
        Account e = new Account(Name = 'Test2', NumberOfEmployees = 5, AnnualRevenue = 4000);
        Account f = new Account(Name = 'Test3', NumberOfEmployees = 10, AnnualRevenue = 5000);
        Account g = new Account(Name = 'Test3', NumberOfEmployees = 15, AnnualRevenue = 3000);
        Account h = new Account(Name = 'Test3', NumberOfEmployees = 10, AnnualRevenue = 3000);
        Account i = new Account(Name = 'Test3', NumberOfEmployees = 5, AnnualRevenue = 5000);
        Account j = new Account(Name = 'Test4', NumberOfEmployees = 10, AnnualRevenue = 10000);
        Account k = new Account(Name = 'Test4', NumberOfEmployees = 10, AnnualRevenue = 2000);
        Account l = new Account(Name = 'Test4', NumberOfEmployees = 5, AnnualRevenue = 4000);
        Account m = new Account(Name = 'Test4', NumberOfEmployees = 5, AnnualRevenue = 3000);
        Account n = new Account(Name = 'Test5', NumberOfEmployees = 5, AnnualRevenue = null);
        Account o = new Account(Name = 'Test5', NumberOfEmployees = 5, AnnualRevenue = 1000);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d, e, f, g, h, i, j, k, l, m, n, o};
        mockDb.doInsert(acctList);

        Test.startTest();
        Integer acctCount = (Integer) mockDb.query('SELECT COUNT() FROM Account LIMIT 5');
        Test.stopTest();

        Assert.areEqual(5, acctCount, 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testLimitAggregate() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5, AnnualRevenue = 1000);
        Account b = new Account(Name = 'Test1', NumberOfEmployees = 10, AnnualRevenue = 1000);
        Account c = new Account(Name = 'Test2', NumberOfEmployees = 5, AnnualRevenue = 2000);
        Account d = new Account(Name = 'Test2', NumberOfEmployees = 20, AnnualRevenue = 3000);
        Account e = new Account(Name = 'Test2', NumberOfEmployees = 5, AnnualRevenue = 4000);
        Account f = new Account(Name = 'Test3', NumberOfEmployees = 10, AnnualRevenue = 5000);
        Account g = new Account(Name = 'Test3', NumberOfEmployees = 15, AnnualRevenue = 3000);
        Account h = new Account(Name = 'Test3', NumberOfEmployees = 10, AnnualRevenue = 3000);
        Account i = new Account(Name = 'Test3', NumberOfEmployees = 5, AnnualRevenue = 5000);
        Account j = new Account(Name = 'Test4', NumberOfEmployees = 10, AnnualRevenue = 10000);
        Account k = new Account(Name = 'Test4', NumberOfEmployees = 10, AnnualRevenue = 2000);
        Account l = new Account(Name = 'Test4', NumberOfEmployees = 5, AnnualRevenue = 4000);
        Account m = new Account(Name = 'Test4', NumberOfEmployees = 5, AnnualRevenue = 3000);
        Account n = new Account(Name = 'Test5', NumberOfEmployees = 5, AnnualRevenue = null);
        Account o = new Account(Name = 'Test5', NumberOfEmployees = 5, AnnualRevenue = 1000);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d, e, f, g, h, i, j, k, l, m, n, o};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Aggregate> queriedAccts = (List<Aggregate>) mockDb.query('SELECT Name, COUNT(Id) FROM Account GROUP BY Name ORDER BY Name LIMIT 3');
        Test.stopTest();
        
        Assert.areEqual(3, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual('Test1', queriedAccts[0].get('Name'), 'Incorrect order');
        Assert.areEqual('Test2', queriedAccts[1].get('Name'), 'Incorrect order');
        Assert.areEqual('Test3', queriedAccts[2].get('Name'), 'Incorrect order');

        Assert.areEqual(2, queriedAccts[0].get('expr0'), 'Incorrect order');
        Assert.areEqual(3, queriedAccts[1].get('expr0'), 'Incorrect order');
        Assert.areEqual(4, queriedAccts[2].get('expr0'), 'Incorrect order');
    }

    @IsTest
    public static void testOnlyQueriedFieldsReturned() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5, AnnualRevenue = 1000);
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(new List<Account>{a});

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Name FROM Account');
        Test.stopTest();

        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual('Test1', queriedAccts[0].Name, 'Name should have been queried');
        Assert.isNull(queriedAccts[0].NumberOfEmployees, 'NumberOfEmployees should not have been queried');
        Assert.isNull(queriedAccts[0].AnnualRevenue, 'AnnualRevenue should not have been queried');
    }

    @IsTest
    public static void testOffset() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5, AnnualRevenue = 1000);
        Account b = new Account(Name = 'Test2', NumberOfEmployees = 10, AnnualRevenue = 2000);
        Account c = new Account(Name = 'Test3', NumberOfEmployees = 5, AnnualRevenue = 3000);
        Account d = new Account(Name = 'Test4', NumberOfEmployees = 20, AnnualRevenue = 4000);
        Account e = new Account(Name = 'Test5', NumberOfEmployees = 5, AnnualRevenue = 5000);
        Account f = new Account(Name = 'Test6', NumberOfEmployees = 10, AnnualRevenue = 6000);
        Account g = new Account(Name = 'Test7', NumberOfEmployees = 15, AnnualRevenue = 7000);
        Account h = new Account(Name = 'Test8', NumberOfEmployees = 10, AnnualRevenue = 8000);
        Account i = new Account(Name = 'Test9', NumberOfEmployees = 5, AnnualRevenue = 9000);
        Account j = new Account(Name = 'Test10', NumberOfEmployees = 10, AnnualRevenue = 10000);
        Account k = new Account(Name = 'Test11', NumberOfEmployees = 10, AnnualRevenue = 11000);
        Account l = new Account(Name = 'Test12', NumberOfEmployees = 5, AnnualRevenue = 12000);
        Account m = new Account(Name = 'Test13', NumberOfEmployees = 5, AnnualRevenue = 13000);
        Account n = new Account(Name = 'Test14', NumberOfEmployees = 5, AnnualRevenue = 14000);
        Account o = new Account(Name = 'Test15', NumberOfEmployees = 5, AnnualRevenue = 15000);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d, e, f, g, h, i, j, k, l, m, n, o};
        mockDb.doInsert(acctList);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, NumberOfEmployees, AnnualRevenue FROM Account ORDER BY AnnualRevenue OFFSET 5');
        Test.stopTest();

        Assert.areEqual(10, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual('Test6', queriedAccts[0].Name, 'Incorrect order');
        Assert.areEqual('Test7', queriedAccts[1].Name, 'Incorrect order');
        Assert.areEqual('Test8', queriedAccts[2].Name, 'Incorrect order');
        Assert.areEqual('Test9', queriedAccts[3].Name, 'Incorrect order');
        Assert.areEqual('Test10', queriedAccts[4].Name, 'Incorrect order');
        Assert.areEqual('Test11', queriedAccts[5].Name, 'Incorrect order');
        Assert.areEqual('Test12', queriedAccts[6].Name, 'Incorrect order');
        Assert.areEqual('Test13', queriedAccts[7].Name, 'Incorrect order');
        Assert.areEqual('Test14', queriedAccts[8].Name, 'Incorrect order');
        Assert.areEqual('Test15', queriedAccts[9].Name, 'Incorrect order');

    }

    @IsTest 
    public static void testOffsetWithBindVar() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5, AnnualRevenue = 1000);
        Account b = new Account(Name = 'Test2', NumberOfEmployees = 10, AnnualRevenue = 2000);
        Account c = new Account(Name = 'Test3', NumberOfEmployees = 5, AnnualRevenue = 3000);
        Account d = new Account(Name = 'Test4', NumberOfEmployees = 20, AnnualRevenue = 4000);
        Account e = new Account(Name = 'Test5', NumberOfEmployees = 5, AnnualRevenue = 5000);
        Account f = new Account(Name = 'Test6', NumberOfEmployees = 10, AnnualRevenue = 6000);
        Account g = new Account(Name = 'Test7', NumberOfEmployees = 15, AnnualRevenue = 7000);
        Account h = new Account(Name = 'Test8', NumberOfEmployees = 10, AnnualRevenue = 8000);
        Account i = new Account(Name = 'Test9', NumberOfEmployees = 5, AnnualRevenue = 9000);
        Account j = new Account(Name = 'Test10', NumberOfEmployees = 10, AnnualRevenue = 10000);
        Account k = new Account(Name = 'Test11', NumberOfEmployees = 10, AnnualRevenue = 11000);
        Account l = new Account(Name = 'Test12', NumberOfEmployees = 5, AnnualRevenue = 12000);
        Account m = new Account(Name = 'Test13', NumberOfEmployees = 5, AnnualRevenue = 13000);
        Account n = new Account(Name = 'Test14', NumberOfEmployees = 5, AnnualRevenue = 14000);
        Account o = new Account(Name = 'Test15', NumberOfEmployees = 5, AnnualRevenue = 15000);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d, e, f, g, h, i, j, k, l, m, n, o};
        mockDb.doInsert(acctList);

        Map<String, Object> binds = new Map<String, Object>{
            'offset' => 5
        };
        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.queryWithBinds('SELECT Id, Name, NumberOfEmployees, AnnualRevenue FROM Account ORDER BY AnnualRevenue OFFSET :offset', binds);
        Test.stopTest();

        Assert.areEqual(10, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual('Test6', queriedAccts[0].Name, 'Incorrect order');
        Assert.areEqual('Test7', queriedAccts[1].Name, 'Incorrect order');
        Assert.areEqual('Test8', queriedAccts[2].Name, 'Incorrect order');
        Assert.areEqual('Test9', queriedAccts[3].Name, 'Incorrect order');
        Assert.areEqual('Test10', queriedAccts[4].Name, 'Incorrect order');
        Assert.areEqual('Test11', queriedAccts[5].Name, 'Incorrect order');
        Assert.areEqual('Test12', queriedAccts[6].Name, 'Incorrect order');
        Assert.areEqual('Test13', queriedAccts[7].Name, 'Incorrect order');
        Assert.areEqual('Test14', queriedAccts[8].Name, 'Incorrect order');
        Assert.areEqual('Test15', queriedAccts[9].Name, 'Incorrect order');       
    }

    @IsTest
    public static void testLimitWithBindVar() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5, AnnualRevenue = 1000);
        Account b = new Account(Name = 'Test2', NumberOfEmployees = 10, AnnualRevenue = 2000);
        Account c = new Account(Name = 'Test3', NumberOfEmployees = 5, AnnualRevenue = 3000);
        Account d = new Account(Name = 'Test4', NumberOfEmployees = 20, AnnualRevenue = 4000);
        Account e = new Account(Name = 'Test5', NumberOfEmployees = 5, AnnualRevenue = 5000);
        Account f = new Account(Name = 'Test6', NumberOfEmployees = 10, AnnualRevenue = 6000);
        Account g = new Account(Name = 'Test7', NumberOfEmployees = 15, AnnualRevenue = 7000);
        Account h = new Account(Name = 'Test8', NumberOfEmployees = 10, AnnualRevenue = 8000);
        Account i = new Account(Name = 'Test9', NumberOfEmployees = 5, AnnualRevenue = 9000);
        Account j = new Account(Name = 'Test10', NumberOfEmployees = 10, AnnualRevenue = 10000);
        Account k = new Account(Name = 'Test11', NumberOfEmployees = 10, AnnualRevenue = 11000);
        Account l = new Account(Name = 'Test12', NumberOfEmployees = 5, AnnualRevenue = 12000);
        Account m = new Account(Name = 'Test13', NumberOfEmployees = 5, AnnualRevenue = 13000);
        Account n = new Account(Name = 'Test14', NumberOfEmployees = 5, AnnualRevenue = 14000);
        Account o = new Account(Name = 'Test15', NumberOfEmployees = 5, AnnualRevenue = 15000);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d, e, f, g, h, i, j, k, l, m, n, o};
        mockDb.doInsert(acctList);

        Map<String, Object> binds = new Map<String, Object>{
            'limit' => 5
        };
        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.queryWithBinds('SELECT Id, Name, NumberOfEmployees, AnnualRevenue FROM Account ORDER BY AnnualRevenue LIMIT :limit', binds);
        Test.stopTest();

        Assert.areEqual(5, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testLimitAndOffsetTogether() {
        Account a = new Account(Name = 'Test1', NumberOfEmployees = 5, AnnualRevenue = 1000);
        Account b = new Account(Name = 'Test2', NumberOfEmployees = 10, AnnualRevenue = 2000);
        Account c = new Account(Name = 'Test3', NumberOfEmployees = 5, AnnualRevenue = 3000);
        Account d = new Account(Name = 'Test4', NumberOfEmployees = 20, AnnualRevenue = 4000);
        Account e = new Account(Name = 'Test5', NumberOfEmployees = 5, AnnualRevenue = 5000);
        Account f = new Account(Name = 'Test6', NumberOfEmployees = 10, AnnualRevenue = 6000);
        Account g = new Account(Name = 'Test7', NumberOfEmployees = 15, AnnualRevenue = 7000);
        Account h = new Account(Name = 'Test8', NumberOfEmployees = 10, AnnualRevenue = 8000);
        Account i = new Account(Name = 'Test9', NumberOfEmployees = 5, AnnualRevenue = 9000);
        Account j = new Account(Name = 'Test10', NumberOfEmployees = 10, AnnualRevenue = 10000);
        Account k = new Account(Name = 'Test11', NumberOfEmployees = 10, AnnualRevenue = 11000);
        Account l = new Account(Name = 'Test12', NumberOfEmployees = 5, AnnualRevenue = 12000);
        Account m = new Account(Name = 'Test13', NumberOfEmployees = 5, AnnualRevenue = 13000);
        Account n = new Account(Name = 'Test14', NumberOfEmployees = 5, AnnualRevenue = 14000);
        Account o = new Account(Name = 'Test15', NumberOfEmployees = 5, AnnualRevenue = 15000);
        MockDatabase mockDb = new MockDatabase();
        List<Account> acctList = new List<Account>{a, b, c, d, e, f, g, h, i, j, k, l, m, n, o};
        mockDb.doInsert(acctList);

        Map<String, Object> binds = new Map<String, Object>{
            'limit' => 5,
            'offset' => 5
        };
        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.queryWithBinds('SELECT Id, Name, NumberOfEmployees, AnnualRevenue FROM Account ORDER BY AnnualRevenue LIMIT :limit OFFSET :offset', binds);
        Test.stopTest();

        Assert.areEqual(5, queriedAccts.size(), 'Incorrect number of accounts queried');
        Assert.areEqual('Test6', queriedAccts[0].Name, 'Incorrect order');
        Assert.areEqual('Test7', queriedAccts[1].Name, 'Incorrect order');
        Assert.areEqual('Test8', queriedAccts[2].Name, 'Incorrect order');
        Assert.areEqual('Test9', queriedAccts[3].Name, 'Incorrect order');
        Assert.areEqual('Test10', queriedAccts[4].Name, 'Incorrect order');

    }

    @IsTest
    public static void testForUpdate() {
        Account acct = new Account(Name = 'Test1', NumberOfEmployees = 5, AnnualRevenue = 1000);

        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(acct);

        Test.startTest();
        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name, NumberOfEmployees, AnnualRevenue FROM Account FOR UPDATE');
        Test.stopTest();

        Assert.areEqual(1, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testForUpdateFailOnGroupBy() {
        Account acct = new Account(Name = 'Test1', NumberOfEmployees = 5, AnnualRevenue = 1000);

        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(acct);

        String exMessage;
        Test.startTest();
        try {
            mockDb.query('SELECT Name, COUNT(Id) FROM Account GROUP BY Name FOR UPDATE');
        } catch(Exception e) {
            exMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(
            exMessage != null &&
            exMessage.contains('FOR UPDATE not allowed in this context'),
            'Exception should have been thrown with the message "FOR UPDATE not allowed in this context"'
        );
    }

    @IsTest
    public static void testForUpdateFailOnCount() {
        Account acct = new Account(Name = 'Test1', NumberOfEmployees = 5, AnnualRevenue = 1000);

        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(acct);

        String exMessage;
        Test.startTest();
        try {
            mockDb.query('SELECT COUNT() FROM Account FOR UPDATE');
        } catch(Exception e) {
            exMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(
            exMessage != null &&
            exMessage.contains('FOR UPDATE not allowed in this context'),
            'Exception should have been thrown with the message "FOR UPDATE not allowed in this context"'
        );
    }
}