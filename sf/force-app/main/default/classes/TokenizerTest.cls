@IsTest
public with sharing class TokenizerTest {
    @IsTest
    public static void testSelectAccount() {
        Tokenizer t = new Tokenizer();
        Tokenizer.Node head = t.parse('SELECT Id FROM Account');
        
        // we expect this to come back in a particular order
        Assert.areEqual('select', head.id, 'Expected id to be "select"');
        Assert.areEqual('select', head.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(head.left, 'Expected left to be not null');
        Assert.isNotNull(head.right, 'Expected right to be not null');

        Tokenizer.Node idNode = head.left;
        Assert.areEqual('id', idNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(idNode.left, 'Expected left to be null');
        Assert.isNull(idNode.right, 'Expected right to be null');

        Tokenizer.Node fromNode = head.right;
        Assert.areEqual('from', fromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', fromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(fromNode.left, 'Expected left to be not null');
        Assert.isNull(fromNode.right, 'Expected right to be null');

        Tokenizer.Node accountNode = fromNode.left;
        Assert.areEqual('account', accountNode.id, 'Expected id to be "account"');
        Assert.areEqual('object', accountNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(accountNode.left, 'Expected left to be null');
        Assert.isNull(accountNode.right, 'Expected right to be null');
    }

    @IsTest
    public static void testSelectWithWhereClause() {
        Tokenizer t = new Tokenizer();
        Tokenizer.Node head = t.parse('SELECT Id FROM Account WHERE Name = \'Test\'');
        
        // we expect this to come back in a particular order
        Assert.areEqual('select', head.id, 'Expected id to be "select"');
        Assert.areEqual('select', head.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(head.left, 'Expected left to be not null');
        Assert.isNotNull(head.right, 'Expected right to be not null');

        Tokenizer.Node idNode = head.left;
        Assert.areEqual('id', idNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(idNode.left, 'Expected left to be null');
        Assert.isNull(idNode.right, 'Expected right to be null');

        Tokenizer.Node fromNode = head.right;
        Assert.areEqual('from', fromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', fromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(fromNode.left, 'Expected left to be not null');
        Assert.isNotNull(fromNode.right, 'Expected right to be not null');

        Tokenizer.Node accountNode = fromNode.left;
        Assert.areEqual('account', accountNode.id, 'Expected id to be "account"');
        Assert.areEqual('object', accountNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(accountNode.left, 'Expected left to be null');
        Assert.isNull(accountNode.right, 'Expected right to be null');

        Tokenizer.Node whereNode = fromNode.right;
        Assert.areEqual('where', whereNode.id, 'Expected id to be "where"');
        Assert.areEqual('where', whereNode.nodeType, 'Expected nodeType to be "where"');
        Assert.isNotNull(whereNode.left, 'Expected left to be not null');
        Assert.isNull(whereNode.right, 'Expected right to be null');

        Tokenizer.Node conditionalExprNode = whereNode.left;
        Assert.areEqual('conditional expression', conditionalExprNode.id, 'Expected id to be "conditional expression"');
        Assert.areEqual('conditional expression', conditionalExprNode.nodeType, 'Expected nodeType to be "conditional expression"');
        Assert.isNotNull(conditionalExprNode.left, 'Expected left to not be null');
        Assert.isNull(conditionalExprNode.right, 'Expected right to be null');

        Tokenizer.Node operatorNode = conditionalExprNode.left;
        Assert.areEqual('=', operatorNode.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode.right, 'Expected right to not be null');

        Tokenizer.Node nameNode = operatorNode.left;
        Assert.areEqual('name', nameNode.id, 'Expected id to be "name"');
        Assert.areEqual('field', nameNode.nodeType, 'Expected nodeType to be "name"');
        Assert.isNull(nameNode.left, 'Expected left to be null');
        Assert.isNull(nameNode.right, 'Expected right to be null');

        Tokenizer.Node valueNode = operatorNode.right;
        Assert.areEqual('test', valueNode.id, 'Expected id to be "value"');
        Assert.areEqual('string', valueNode.nodeType, 'Expected nodeType to be "value"');
        Assert.isNull(valueNode.left, 'Expected left to be null');
        Assert.isNull(valueNode.right, 'Expected right to be null');
    }

    @IsTest
    public static void testSubQueryWithSubQueryFirst() {
        Tokenizer t = new Tokenizer();
        Tokenizer.Node head = t.parse('SELECT (SELECT Id FROM Contacts), Id FROM Account');

        Assert.areEqual('select', head.id, 'Expected id to be "select"');
        Assert.areEqual('select', head.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(head.left, 'Expected left to be not null');
        Assert.isNotNull(head.right, 'Expected right to be not null');

        Tokenizer.Node subQueryNode = head.left;
        Assert.areEqual('subquery', subQueryNode.id, 'Expected id to be "subquery"');
        Assert.areEqual('subquery', subQueryNode.nodeType, 'Expected nodeType to be "subquery"');
        Assert.isNotNull(subQueryNode.left, 'Expected left to not be null');
        Assert.isNotNull(subQueryNode.right, 'Expected right to not be null');

        Tokenizer.Node subQuerySelectNode = subQueryNode.right;
        Assert.areEqual('select', subQuerySelectNode.id, 'Expected id to be "select"');
        Assert.areEqual('select', subQuerySelectNode.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(subQuerySelectNode.left, 'Expected left to not be null');
        Assert.isNotNull(subQuerySelectNode.right, 'Expected right to not be null');

        Tokenizer.Node subQueryIdNode = subQuerySelectNode.left;
        Assert.areEqual('id', subQueryIdNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', subQueryIdNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(subQueryIdNode.left, 'Expected left to be null');
        Assert.isNull(subQueryIdNode.right, 'Expected right to be null');

        Tokenizer.Node subQueryFromNode = subQuerySelectNode.right;
        Assert.areEqual('from', subQueryFromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', subQueryFromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(subQueryFromNode.left, 'Expected left to not be null');
        Assert.isNull(subQueryFromNode.right, 'Expected right to be null');

        Tokenizer.Node subQueryContactNode = subQueryFromNode.left;
        Assert.areEqual('contacts', subQueryContactNode.id, 'Expected id to be "contact"');
        Assert.areEqual('object', subQueryContactNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(subQueryContactNode.left, 'Expected left to be null');
        Assert.isNull(subQueryContactNode.right, 'Expected right to be null');

    }

    @IsTest
    public static void testSubQueryWithSubQuerySecond() {
        Tokenizer t = new Tokenizer();
        Tokenizer.Node head = t.parse('SELECT Id, (SELECT Id FROM Contacts) FROM Account');

        Assert.areEqual('select', head.id, 'Expected id to be "select"');
        Assert.areEqual('select', head.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(head.left, 'Expected left to be not null');
        Assert.isNotNull(head.right, 'Expected right to be not null');

        Tokenizer.Node idNode = head.left;
        Assert.areEqual('id', idNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNotNull(idNode.left, 'Expected left to not be null');
        Assert.isNull(idNode.right, 'Expected right to be null');

        Tokenizer.Node subQueryNode = idNode.left;
        Assert.areEqual('subquery', subQueryNode.id, 'Expected id to be "subquery"');
        Assert.areEqual('subquery', subQueryNode.nodeType, 'Expected nodeType to be "subquery"');
        Assert.isNull(subQueryNode.left, 'Expected left to be null');
        Assert.isNotNull(subQueryNode.right, 'Expected right to not be null');

        Tokenizer.Node subQuerySelectNode = subQueryNode.right;
        Assert.areEqual('select', subQuerySelectNode.id, 'Expected id to be "select"');
        Assert.areEqual('select', subQuerySelectNode.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(subQuerySelectNode.left, 'Expected left to not be null');
        Assert.isNotNull(subQuerySelectNode.right, 'Expected right to not be null');

        Tokenizer.Node subQueryIdNode = subQuerySelectNode.left;
        Assert.areEqual('id', subQueryIdNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', subQueryIdNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(subQueryIdNode.left, 'Expected left to be null');
        Assert.isNull(subQueryIdNode.right, 'Expected right to be null');

        Tokenizer.Node subQueryFromNode = subQuerySelectNode.right;
        Assert.areEqual('from', subQueryFromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', subQueryFromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(subQueryFromNode.left, 'Expected left to not be null');
        Assert.isNull(subQueryFromNode.right, 'Expected right to be null');

        Tokenizer.Node subQueryContactNode = subQueryFromNode.left;
        Assert.areEqual('contacts', subQueryContactNode.id, 'Expected id to be "contact"');
        Assert.areEqual('object', subQueryContactNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(subQueryContactNode.left, 'Expected left to be null');
        Assert.isNull(subQueryContactNode.right, 'Expected right to be null');
    }

    @IsTest
    public static void testSubQueryWithQueryInWhereClause() {
        Tokenizer t = new Tokenizer();
        Tokenizer.Node head = t.parse('SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact)');

        Assert.areEqual('select', head.id, 'Expected id to be "select"');
        Assert.areEqual('select', head.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(head.left, 'Expected left to be not null');
        Assert.isNotNull(head.right, 'Expected right to be not null');

        Tokenizer.Node idNode = head.left;
        Assert.areEqual('id', idNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(idNode.left, 'Expected left to be null');
        Assert.isNull(idNode.right, 'Expected right to be null');

        Tokenizer.Node fromNode = head.right;
        Assert.areEqual('from', fromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', fromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(fromNode.left, 'Expected left to be not null');
        Assert.isNotNull(fromNode.right, 'Expected right to be not null');

        Tokenizer.Node accountNode = fromNode.left;
        Assert.areEqual('account', accountNode.id, 'Expected id to be "account"');
        Assert.areEqual('object', accountNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(accountNode.left, 'Expected left to be null');
        Assert.isNull(accountNode.right, 'Expected right to be null');

        Tokenizer.Node whereNode = fromNode.right;
        Assert.areEqual('where', whereNode.id, 'Expected id to be "where"');
        Assert.areEqual('where', whereNode.nodeType, 'Expected nodeType to be "where"');
        Assert.isNotNull(whereNode.left, 'Expected left to be not null');
        Assert.isNull(whereNode.right, 'Expected right to be null');

        Tokenizer.Node conditionalExprNode = whereNode.left;
        Assert.areEqual('conditional expression', conditionalExprNode.id, 'Expected id to be "conditional expression"');
        Assert.areEqual('conditional expression', conditionalExprNode.nodeType, 'Expected nodeType to be "conditional expression"');
        Assert.isNotNull(conditionalExprNode.left, 'Expected left to not be null');
        Assert.isNull(conditionalExprNode.right, 'Expected right to be null');

        Tokenizer.Node operatorNode = conditionalExprNode.left;
        Assert.areEqual('in', operatorNode.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode.right, 'Expected right to not be null');

        Tokenizer.Node idNode2 = operatorNode.left;
        Assert.areEqual('id', idNode2.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode2.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(idNode2.left, 'Expected left to be null');
        Assert.isNull(idNode2.right, 'Expected right to be null');

        Tokenizer.Node subQueryNode = operatorNode.right;
        Assert.areEqual('subquery', subQueryNode.id, 'Expected id to be "subquery"');
        Assert.areEqual('subquery', subQueryNode.nodeType, 'Expected nodeType to be "subquery"');
        Assert.isNull(subQueryNode.left, 'Expected left to be null');
        Assert.isNotNull(subQueryNode.right, 'Expected right to not be null');

        Tokenizer.Node subQuerySelectNode = subQueryNode.right;
        Assert.areEqual('select', subQuerySelectNode.id, 'Expected id to be "select"');
        Assert.areEqual('select', subQuerySelectNode.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(subQuerySelectNode.left, 'Expected left to not be null');
        Assert.isNotNull(subQuerySelectNode.right, 'Expected right to not be null');

        Tokenizer.Node subQueryAccountIdNode = subQuerySelectNode.left;
        Assert.areEqual('accountid', subQueryAccountIdNode.id, 'Expected id to be "accountid"');
        Assert.areEqual('field', subQueryAccountIdNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(subQueryAccountIdNode.left, 'Expected left to be null');
        Assert.isNull(subQueryAccountIdNode.right, 'Expected right to be null');

        Tokenizer.Node subQueryFromNode = subQuerySelectNode.right;
        Assert.areEqual('from', subQueryFromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', subQueryFromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(subQueryFromNode.left, 'Expected left to not be null');
        Assert.isNull(subQueryFromNode.right, 'Expected right to be null');

        Tokenizer.Node subQueryContactNode = subQueryFromNode.left;
        Assert.areEqual('contact', subQueryContactNode.id, 'Expected id to be "contact"');
        Assert.areEqual('object', subQueryContactNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(subQueryContactNode.left, 'Expected left to be null');
        Assert.isNull(subQueryContactNode.right, 'Expected right to be null');



    }
}