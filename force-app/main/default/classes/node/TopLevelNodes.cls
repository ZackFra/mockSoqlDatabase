/**
 * @description This class is used to parse the top level nodes of a SOQL query.
 * Designed to refresh the instance if the head node changes, i.e. if a new SOQL query is made.
 */
public with sharing class TopLevelNodes {
    
    public Node selectNode { get; private set; }
    public Node fromNode { get; private set; }
    public Node whereNode { get; private set; }
    public Node groupByNode { get; private set; }
    public Node havingNode { get; private set; }
    public Node orderByNode { get; private set; }
    public Node limitNode { get; private set; }
    public Node offsetNode { get; private set; }
    public Node forUpdateNode { get; private set; }
    public Node usingScopeNode { get; private set; }
    

    public TopLevelNodes(Node selectNode) {
        this.selectNode = selectNode;
        this.fromNode = selectNode.right;

        Node curr = fromNode.right;

        if(isNode(curr, 'using scope')) {
            this.usingScopeNode = curr;
            curr = curr.right;
        }

        if(isNode(curr, 'where')) {
            this.whereNode = curr;
            curr = curr.right;
        }

        if(isNode(curr, 'group by')) {
            this.groupByNode = curr;
            curr = curr.right;
            // can only have a HAVING node if there's a group by node
            if(isNode(curr, 'having')) {
                this.havingNode = curr;
                curr = curr.right;
            }
        }

        if(isNode(curr, 'order by')) {
            this.orderByNode = curr;
            curr = curr.right;
        }

        if(isNode(curr, 'limit')) {
            this.limitNode = curr;
            curr = curr.right;
        }

        if(isNode(curr, 'offset')) {
            this.offsetNode = curr;
            curr = curr.right;
        }

        if(isNode(curr, 'for update')) {
            this.forUpdateNode = curr;
            curr = curr.right;
        }
    }

    private Boolean isNode(Node node, String nodeType) {
        return node != null && node.nodeType == nodeType;
    }
}