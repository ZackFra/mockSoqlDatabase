MockDatabase mockDb = new MockDatabase();
List<Account> acctList = TestDataFactory.createTrailheadAccounts();        
mockDb.doInsert(acctList);

List<AggregateResult> queriedAccts = [SELECT NumberOfEmployees, Name, SUM(AnnualRevenue) annualRevSum FROM Account GROUP BY ROLLUP(NumberOfEmployees, Name, BillingState)];


System.debug(queriedAccts.size());
System.debug('NumberOfEmployees, Name, SUM(AnnualRevenue)');
for(AggregateResult ar : queriedAccts) {
    System.debug(ar.get('BillingState'));
    /*System.debug(
        ar.get('NumberOfEmployees') + ' ' + ar.get('Name') + ' ' + ar.get('expr0')
    );*/
}