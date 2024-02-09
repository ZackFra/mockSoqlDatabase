/**
 * @description : Builder class for the Node class, used to create a Node
 */
public class NodeBuilder {
    public String id {get; private set;}
    public String nodeType {get; private set;}
    public Node left {get; private set;}
    public Node right {get; private set;}
    
    /**
     * @description : Sets the id of the node
     * @param id : String, the id of the node
     * @return : NodeBuilder, the current instance of the NodeBuilder
     */
    public NodeBuilder setId(String id) {
        this.id = id;
        return this;
    }

    /**
     * @description : Sets the type of the node
     * @param nodeType : String, the type of the node
     * @return : NodeBuilder, the current instance of the NodeBuilder
     */
    public NodeBuilder setNodeType(String nodeType) {
        this.nodeType = nodeType;
        return this;
    }

    /**
     * @description : Sets the left child of the node
     * @param left : Node, the left child of the node
     * @return : NodeBuilder, the current instance of the NodeBuilder
     */
    public NodeBuilder setLeft(Node left) {
        this.left = left;
        return this;
    }

    /**
     * @description : Sets the right child of the node
     * @param right : Node, the right child of the node
     * @return : NodeBuilder, the current instance of the NodeBuilder
     */
    public NodeBuilder setRight(Node right) {
        this.right = right;
        return this;
    }

    /**
     * @description : Builds the node
     * @return : Node, the built node
     */
    public Node build() {
        return new Node(nodeType, id, left, right);
    }
}
