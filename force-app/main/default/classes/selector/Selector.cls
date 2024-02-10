public with sharing class Selector {
    public static Selector db;
	
    public List<Object> query(String queryString) {
        return Database.query(queryString);
    }

    public List<Object> query(String queryString, Map<String, Object> parameters) {
        return Database.queryWithBinds(queryString, parameters, AccessLevel.USER_MODE);
    }
    
    public Integer countQuery(String queryString) {
        return Database.countQuery(queryString);
    }
}