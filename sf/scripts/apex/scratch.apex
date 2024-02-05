MockDatabase mockDb = new MockDatabase();
List<Account> acctList1 = new List<Account>();
for(Integer i = 0; i < 2000; i++){
    Account a = new Account(Name = 'Test');
    acctList1.add(a);
}

DateTime startTime1 = Datetime.now();
for(Integer i = 0; i < 2000; i++) {
    mockDb.doInsert(acctList1[i]);
}
DateTime endTime1 = Datetime.now();

System.debug(startTime1.getTime());
System.debug(endTime1.getTime());
Long diff1 = endTime1.getTime() - startTime1.getTime();
System.debug('Time taken test 1 : ' + diff1 + ' ms');


List<Account> acctList = new List<Account>();
for(Integer i = 0; i < 2000; i++){
    Account a = new Account(Name = 'Test');
    acctList.add(a);
}
DateTime startTime2 = Datetime.now();
mockDb.doInsert(acctList);
DateTime endTime2 = Datetime.now();

System.debug(startTime2.getTime());
System.debug(endTime2.getTime());
Long diff2 = endTime2.getTime() - startTime2.getTime();
System.debug('Time taken test 2 : ' + diff2 + ' ms');