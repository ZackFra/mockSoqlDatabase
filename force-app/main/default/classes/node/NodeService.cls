/**
 * @description Service class for manipulating and describing the nodes of the AST created by the lexer
 *              each method is a static method that takes in a TopLevelNodes
 */
public with sharing class NodeService {
    
    public static Boolean isAggregateQuery(TopLevelNodes topLevelNodes) {
        Node selectNode = topLevelNodes.selectNode;
        Node groupByNode = topLevelNodes.groupByNode;

        if(isSingularCount(topLevelNodes)) {
            return false;
        }

        Node curr = selectNode;
        while(curr != null) {
            if(curr.nodeType == 'aggregate function') {
                return true;
            }
            curr = curr.left;
        }

        if(groupByNode != null) {
            return true;
        }

        return false;
    }

    // if all we're doing is counting, no other aggregate funcs
    public static Boolean isSingularCount(TopLevelNodes topLevelNodes) {
        Node selectNode = topLevelNodes.selectNode;
        return (selectNode.left.id == 'count' && selectNode.left.right == null && selectNode.left.left == null);
    }

}