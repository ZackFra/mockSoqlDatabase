public with sharing class SelectHandlerFactory {
    private FieldSelector fSelector;

    public SelectHandlerFactory(FieldSelector fSelector) {
        this.fSelector = fSelector;
    }

    public ISelectHandler createHandler() {
        Node fieldNode = fSelector.fieldNode;

        Boolean isTypeOf = (fieldNode.nodeType == 'typeof');
        Boolean isChildSubQuery = (fieldNode.nodeType == 'subquery');
        Boolean isParentSubQuery = (fieldNode.id.contains('.'));
        
        if(isTypeOf) {
            return new PolymorphicSelectHandler(fSelector);
        } else if(isChildSubQuery) {
            return new ChildSubQuerySelectHandler(fSelector);
        } else if(isParentSubQuery) {
            return new ParentSubQuerySelectHandler(fSelector);
        } else {
            return new FieldSelectHandler(fSelector);
        }
    }
}