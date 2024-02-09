List<Task> taskList = [SELECT TYPEOF What WHEN Opportunity THEN Name END FROM Task];
for(Task t : taskList) {
    System.debug(t.What);
}