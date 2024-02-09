MockDatabase mockDb = new MockDatabase();
Account acct = new Account(
    Name = 'Test'
);
mockDb.doInsert(acct);
Task t = new Task(
    Subject = 'Test',
    WhatId = acct.Id
);
mockDb.doInsert(t);
Lexer l = new Lexer();
l.parse('SELECT Id, Subject, TYPEOF What WHEN Account THEN Name ELSE Id END FROM Task');
List<Task> queriedTaskList = (List<Task>) mockDb.query('SELECT Id, Subject, TYPEOF What WHEN Account THEN Name ELSE Id END FROM Task');

Task queriedTask = queriedTaskList[0];
System.debug(queriedTask.What);