public with sharing class HavingLogicHandler extends BooleanLogicHandler {
    private Node selectNode;

    public HavingLogicHandler(MockDatabase db, Node head, Node selectNode, Map<String, Object> aggr, Map<String, Object> params) {
        super(db, head, aggr, params);
        this.selectNode = selectNode;
    }

    public override Boolean isCompareConditionMet(Node operatorNode) {
        Map<String, Object> aggr = (Map<String, Object>) this.obj;

        Node aggrNode = operatorNode.left;
        Map<String, Object> aggrNodeValue = this.db.utils.getAggrNodeValue(aggrNode, this.selectNode);
        String alias = (String) aggrNodeValue.get('alias');

        Object value = aggr.get(alias);
        Node valueNode = operatorNode.right;
        Object expectedValue;

        if(valueNode.nodeType == 'bind variable') {
            expectedValue = String.valueOf(params.get(valueNode.id));
        } else {
            expectedValue = valueNode.id;
        }
        
        MockDatabaseUtils.OperatorHandlerFactory handlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = handlerFactory.getHandler(operatorNode.id);
        return handler.handle(value, expectedValue);
    }
}