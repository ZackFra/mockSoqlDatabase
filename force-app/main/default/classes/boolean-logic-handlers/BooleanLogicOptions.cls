public with sharing class BooleanLogicOptions {

    /** 
     * @description Parameters for bind variables in the query
     */
    public Map<String, Object> params;

    /**
     * @description The object being compared (either SObject or Aggregate)
     */
    public Object obj;

    /**
     * @description The head conditional node
     */
    public Node head;

    /**
     * @description The database to use for queries
     */
    public MockDatabase db;

    /**
     * @description The select node to compare against
     */
    public Node selectNode;

    public BooleanLogicOptions setParams(Map<String, Object> params) {
        this.params = params;
        return this;
    }

    public BooleanLogicOptions setDatabase(MockDatabase db) {
        this.db = db;
        return this;
    }

    public BooleanLogicOptions setObj(Object obj) {
        this.obj = obj;
        return this;
    }

    public BooleanLogicOptions setHead(Node head) {
        this.head = head;
        return this;
    }

    public BooleanLogicOptions setSelectNode(Node selectNode) {
        this.selectNode = selectNode;
        return this;
    }

}