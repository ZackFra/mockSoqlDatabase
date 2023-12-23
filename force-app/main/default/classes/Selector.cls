public with sharing class Selector {
    public static Selector db;
	
    public List<Object> query(String queryString) {
        return Database.query(queryString);
    }
    
    public Integer countQuery(String queryString) {
        return Database.countQuery(queryString);
    }
}