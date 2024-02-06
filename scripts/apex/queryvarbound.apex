Id accId = [SELECT Id FROM Account LIMIT 1].Id;
Id acc2Id = [SELECT Id FROM Account WHERE Id != :accId LIMIT 1].Id;
List<Account> accList = [SELECT Name FROM Account WHERE Id IN (:accId, :acc2Id)];

for(Account acc : accList) {
    System.debug(acc.Name);
}