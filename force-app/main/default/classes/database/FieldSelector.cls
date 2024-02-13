public with sharing class FieldSelector {
    
    public SObject databaseRecord;
    public SObject queriedRecord;
    public Node fieldNode;
    public Map<String, Object> params;

    public FieldSelector setDatabaseRecord(SObject databaseRecord) {
        this.databaseRecord = databaseRecord;
        return this;
    }

    public FieldSelector setQueriedRecord(SObject queriedRecord) {
        this.queriedRecord = queriedRecord;
        return this;
    }

    public FieldSelector setFieldNode(Node fieldNode) {
        this.fieldNode = fieldNode;
        return this;
    }

    public FieldSelector setParams(Map<String, Object> params) {
        this.params = params;
        return this;
    }
}