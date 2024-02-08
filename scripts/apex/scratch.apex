Node numNode = new NodeBuilder()
    .setId('1')
    .setNodeType('number')
    .build();

Node whereNode = new NodeBuilder()
    .setId('where')
    .setNodeType('where')
    .setRight(numNode)
    .build();
Node whereNodeClone = whereNode.clone();
System.debug(whereNodeClone.right == numNode); // true??