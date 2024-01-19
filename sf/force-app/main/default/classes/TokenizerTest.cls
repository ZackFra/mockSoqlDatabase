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

        Tokenizer.Node operatorNode = whereNode.left;
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
    public static void testMixedFieldsSubQueries() {
        Tokenizer t = new Tokenizer();
        Tokenizer.Node head = t.parse('SELECT Id, (SELECT Id FROM Contacts), Name FROM Account');

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

        Tokenizer.Node nameNode = subQueryNode.left;
        Assert.areEqual('name', nameNode.id, 'Expected id to be "name"');
        Assert.areEqual('field', nameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(nameNode.left, 'Expected left to be null');
        Assert.isNull(nameNode.right, 'Expected right to be null');

        Tokenizer.Node fromNode = head.right;
        Assert.areEqual('from', fromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', fromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(fromNode.left, 'Expected left to not be null');
        Assert.isNull(fromNode.right, 'Expected right to be null');

        Tokenizer.Node accountNode = fromNode.left;
        Assert.areEqual('account', accountNode.id, 'Expected id to be "account"');
        Assert.areEqual('object', accountNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(accountNode.left, 'Expected left to be null');
        Assert.isNull(accountNode.right, 'Expected right to be null');

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
    public static void testMultipleSubQueries() {

        Tokenizer t = new Tokenizer();
        Tokenizer.Node head = t.parse('SELECT Id, (SELECT Id FROM Contacts), (SELECT Id FROM Opportunities) FROM Account');

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

        Tokenizer.Node subQueryNode2 = subQueryNode.left;
        Assert.areEqual('subquery', subQueryNode2.id, 'Expected id to be "subquery"');
        Assert.areEqual('subquery', subQueryNode2.nodeType, 'Expected nodeType to be "subquery"');
        Assert.isNull(subQueryNode2.left, 'Expected left to be null');
        Assert.isNotNull(subQueryNode2.right, 'Expected right to not be null');

        Tokenizer.Node subQuerySelectNode2 = subQueryNode2.right;
        Assert.areEqual('select', subQuerySelectNode2.id, 'Expected id to be "select"');
        Assert.areEqual('select', subQuerySelectNode2.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(subQuerySelectNode2.left, 'Expected left to not be null');
        Assert.isNotNull(subQuerySelectNode2.right, 'Expected right to not be null');

        Tokenizer.Node subQueryIdNode2 = subQuerySelectNode2.left;
        Assert.areEqual('id', subQueryIdNode2.id, 'Expected id to be "id"');
        Assert.areEqual('field', subQueryIdNode2.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(subQueryIdNode2.left, 'Expected left to be null');
        Assert.isNull(subQueryIdNode2.right, 'Expected right to be null');

        Tokenizer.Node subQueryFromNode2 = subQuerySelectNode2.right;
        Assert.areEqual('from', subQueryFromNode2.id, 'Expected id to be "from"');
        Assert.areEqual('from', subQueryFromNode2.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(subQueryFromNode2.left, 'Expected left to not be null');
        Assert.isNull(subQueryFromNode2.right, 'Expected right to be null');

        Tokenizer.Node subQueryOpportunityNode = subQueryFromNode2.left;
        Assert.areEqual('opportunities', subQueryOpportunityNode.id, 'Expected id to be "opportunities"');
        Assert.areEqual('object', subQueryOpportunityNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(subQueryOpportunityNode.left, 'Expected left to be null');
        Assert.isNull(subQueryOpportunityNode.right, 'Expected right to be null');

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

        Tokenizer.Node operatorNode = whereNode.left;
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

    @IsTest
    public static void testSubQueryWithQueryInWhereClause2() {
        Tokenizer t = new Tokenizer();
        Tokenizer.Node head = t.parse('SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE Name = \'Test\')');

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

        Tokenizer.Node operatorNode = whereNode.left;
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
        Assert.isNotNull(subQueryFromNode.right, 'Expected right to not be null');

        Tokenizer.Node subQueryContactNode = subQueryFromNode.left;
        Assert.areEqual('contact', subQueryContactNode.id, 'Expected id to be "contact"');
        Assert.areEqual('object', subQueryContactNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(subQueryContactNode.left, 'Expected left to be null');

        Tokenizer.Node subQueryWhereNode = subQueryFromNode.right;
        Assert.areEqual('where', subQueryWhereNode.id, 'Expected id to be "where"');
        Assert.areEqual('where', subQueryWhereNode.nodeType, 'Expected nodeType to be "where"');
        Assert.isNotNull(subQueryWhereNode.left, 'Expected left to not be null');
        Assert.isNull(subQueryWhereNode.right, 'Expected right to be null');

        Tokenizer.Node subQueryOperatorNode = subQueryWhereNode.left;
        Assert.areEqual('=', subQueryOperatorNode.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', subQueryOperatorNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(subQueryOperatorNode.left, 'Expected left to not be null');
        Assert.isNotNull(subQueryOperatorNode.right, 'Expected right to not be null');

        Tokenizer.Node subQueryNameNode = subQueryOperatorNode.left;
        Assert.areEqual('name', subQueryNameNode.id, 'Expected id to be "name"');
        Assert.areEqual('field', subQueryNameNode.nodeType, 'Expected nodeType to be "name"');
        Assert.isNull(subQueryNameNode.left, 'Expected left to be null');
        Assert.isNull(subQueryNameNode.right, 'Expected right to be null');

        Tokenizer.Node subQueryValueNode = subQueryOperatorNode.right;
        Assert.areEqual('test', subQueryValueNode.id, 'Expected id to be "value"');
        Assert.areEqual('string', subQueryValueNode.nodeType, 'Expected nodeType to be "value"');
        Assert.isNull(subQueryValueNode.left, 'Expected left to be null');
        Assert.isNull(subQueryValueNode.right, 'Expected right to be null');
    }

    @IsTest
    public static void testBindVar() {
        Tokenizer t = new Tokenizer();
        Tokenizer.Node head = t.parse('SELECT Id FROM Account WHERE Id = :id');

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

        Tokenizer.Node operatorNode = whereNode.left;
        Assert.areEqual('=', operatorNode.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode.right, 'Expected right to not be null');

        Tokenizer.Node idNode2 = operatorNode.left;
        Assert.areEqual('id', idNode2.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode2.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(idNode2.left, 'Expected left to be null');
        Assert.isNull(idNode2.right, 'Expected right to be null');

        Tokenizer.Node bindVarNode = operatorNode.right;
        Assert.areEqual('id', bindVarNode.id, 'Expected id to be "id"');
        Assert.areEqual('bind variable', bindVarNode.nodeType, 'Expected nodeType to be "bind variable"');
        Assert.isNull(bindVarNode.left, 'Expected left to be null');
        Assert.isNull(bindVarNode.right, 'Expected right to be null');

    }

    @IsTest
    public static void testAndStatements() {
        Tokenizer t = new Tokenizer();
        Tokenizer.Node head = t.parse('SELECT Id FROM Contact WHERE FirstName = \'test\' AND LastName = \'test2\' AND Account.Name = \'testAcct\'');
        
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

        Tokenizer.Node contactNode = fromNode.left;
        Assert.areEqual('contact', contactNode.id, 'Expected id to be "contact"');
        Assert.areEqual('object', contactNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(contactNode.left, 'Expected left to be null');
        Assert.isNull(contactNode.right, 'Expected right to be null');

        Tokenizer.Node whereNode = fromNode.right;
        Assert.areEqual('where', whereNode.id, 'Expected id to be "where"');
        Assert.areEqual('where', whereNode.nodeType, 'Expected nodeType to be "where"');
        Assert.isNotNull(whereNode.left, 'Expected left to be not null');
        Assert.isNull(whereNode.right, 'Expected right to be null');

        Tokenizer.Node andNode = whereNode.left;
        Assert.areEqual('and', andNode.id, 'Expected id to be "and"');
        Assert.areEqual('and', andNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(andNode.left, 'Expected left to not be null');
        Assert.isNotNull(andNode.right, 'Expected right to not be null');

        Tokenizer.Node operatorNode = andNode.left;
        Assert.areEqual('=', operatorNode.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode.right, 'Expected right to not be null');

        Tokenizer.Node firstNameNode = operatorNode.left;
        Assert.areEqual('firstname', firstNameNode.id, 'Expected id to be "firstname"');
        Assert.areEqual('field', firstNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(firstNameNode.left, 'Expected left to be null');
        Assert.isNull(firstNameNode.right, 'Expected right to be null');

        Tokenizer.Node valueNode = operatorNode.right;
        Assert.areEqual('test', valueNode.id, 'Expected id to be "test"');
        Assert.areEqual('string', valueNode.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode.left, 'Expected left to be null');
        Assert.isNull(valueNode.right, 'Expected right to be null');

        Tokenizer.Node andNode2 = andNode.right;
        Assert.areEqual('and', andNode2.id, 'Expected id to be "and"');
        Assert.areEqual('and', andNode2.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(andNode2.left, 'Expected left to not be null');
        Assert.isNotNull(andNode2.right, 'Expected right to not be null');

        Tokenizer.Node operatorNode2 = andNode2.left;
        Assert.areEqual('=', operatorNode2.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode2.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode2.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode2.right, 'Expected right to not be null');

        Tokenizer.Node lastNameNode = operatorNode2.left;
        Assert.areEqual('lastname', lastNameNode.id, 'Expected id to be "lastname"');
        Assert.areEqual('field', lastNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(lastNameNode.left, 'Expected left to be null');
        Assert.isNull(lastNameNode.right, 'Expected right to be null');

        Tokenizer.Node valueNode2 = operatorNode2.right;
        Assert.areEqual('test2', valueNode2.id, 'Expected id to be "test2"');
        Assert.areEqual('string', valueNode2.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode2.left, 'Expected left to be null');
        Assert.isNull(valueNode2.right, 'Expected right to be null');

        Tokenizer.Node operatorNode3 = andNode2.right;
        Assert.areEqual('=', operatorNode3.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode3.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode3.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode3.right, 'Expected right to not be null');

        Tokenizer.Node accountNameNode = operatorNode3.left;
        Assert.areEqual('account.name', accountNameNode.id, 'Expected id to be "account.name"');
        Assert.areEqual('field', accountNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(accountNameNode.left, 'Expected left to be null');
        Assert.isNull(accountNameNode.right, 'Expected right to be null');

        Tokenizer.Node valueNode3 = operatorNode3.right;
        Assert.areEqual('testacct', valueNode3.id, 'Expected id to be "testacct"');
        Assert.areEqual('string', valueNode3.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode3.left, 'Expected left to be null');
        Assert.isNull(valueNode3.right, 'Expected right to be null');
    }

    @IsTest
    public static void testQueryWithOrAnd() {
        Tokenizer t = new Tokenizer();
        Tokenizer.Node head = t.parse('SELECT Id FROM Contact WHERE FirstName = \'test\' OR LastName = \'test2\' AND Account.Name = \'testAcct\'');

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

        Tokenizer.Node contactNode = fromNode.left;
        Assert.areEqual('contact', contactNode.id, 'Expected id to be "contact"');
        Assert.areEqual('object', contactNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(contactNode.left, 'Expected left to be null');
        Assert.isNull(contactNode.right, 'Expected right to be null');

        Tokenizer.Node whereNode = fromNode.right;
        Assert.areEqual('where', whereNode.id, 'Expected id to be "where"');
        Assert.areEqual('where', whereNode.nodeType, 'Expected nodeType to be "where"');
        Assert.isNotNull(whereNode.left, 'Expected left to be not null');
        Assert.isNull(whereNode.right, 'Expected right to be null');

        Tokenizer.Node orNode = whereNode.left;
        Assert.areEqual('or', orNode.id, 'Expected id to be "or"');
        Assert.areEqual('or', orNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(orNode.left, 'Expected left to not be null');
        Assert.isNotNull(orNode.right, 'Expected right to not be null');

        Tokenizer.Node operatorNode = orNode.left;
        Assert.areEqual('=', operatorNode.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode.right, 'Expected right to not be null');

        Tokenizer.Node firstNameNode = operatorNode.left;
        Assert.areEqual('firstname', firstNameNode.id, 'Expected id to be "firstname"');
        Assert.areEqual('field', firstNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(firstNameNode.left, 'Expected left to be null');
        Assert.isNull(firstNameNode.right, 'Expected right to be null');

        Tokenizer.Node valueNode = operatorNode.right;
        Assert.areEqual('test', valueNode.id, 'Expected id to be "test"');
        Assert.areEqual('string', valueNode.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode.left, 'Expected left to be null');
        Assert.isNull(valueNode.right, 'Expected right to be null');

        Tokenizer.Node andNode = orNode.right;
        Assert.areEqual('and', andNode.id, 'Expected id to be "and"');
        Assert.areEqual('and', andNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(andNode.left, 'Expected left to not be null');
        Assert.isNotNull(andNode.right, 'Expected right to not be null');

        Tokenizer.Node operatorNode2 = andNode.left;
        Assert.areEqual('=', operatorNode2.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode2.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode2.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode2.right, 'Expected right to not be null');

        Tokenizer.Node lastNameNode = operatorNode2.left;
        Assert.areEqual('lastname', lastNameNode.id, 'Expected id to be "lastname"');
        Assert.areEqual('field', lastNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(lastNameNode.left, 'Expected left to be null');
        Assert.isNull(lastNameNode.right, 'Expected right to be null');

        Tokenizer.Node valueNode2 = operatorNode2.right;
        Assert.areEqual('test2', valueNode2.id, 'Expected id to be "test2"');
        Assert.areEqual('string', valueNode2.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode2.left, 'Expected left to be null');
        Assert.isNull(valueNode2.right, 'Expected right to be null');

        Tokenizer.Node operatorNode3 = andNode.right;
        Assert.areEqual('=', operatorNode3.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode3.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode3.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode3.right, 'Expected right to not be null');

        Tokenizer.Node accountNameNode = operatorNode3.left;
        Assert.areEqual('account.name', accountNameNode.id, 'Expected id to be "account.name"');
        Assert.areEqual('field', accountNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(accountNameNode.left, 'Expected left to be null');
        Assert.isNull(accountNameNode.right, 'Expected right to be null');

        Tokenizer.Node valueNode3 = operatorNode3.right;
        Assert.areEqual('testacct', valueNode3.id, 'Expected id to be "testacct"');
        Assert.areEqual('string', valueNode3.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode3.left, 'Expected left to be null');
        Assert.isNull(valueNode3.right, 'Expected right to be null');

        
    }

    @IsTest
    public static void testNot() {
        Tokenizer t = new Tokenizer();
        Tokenizer.Node head = t.parse('SELECT Id FROM Contact WHERE NOT FirstName = \'test\'');

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

        Tokenizer.Node contactNode = fromNode.left;
        Assert.areEqual('contact', contactNode.id, 'Expected id to be "contact"');
        Assert.areEqual('object', contactNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(contactNode.left, 'Expected left to be null');
        Assert.isNull(contactNode.right, 'Expected right to be null');

        Tokenizer.Node whereNode = fromNode.right;
        Assert.areEqual('where', whereNode.id, 'Expected id to be "where"');
        Assert.areEqual('where', whereNode.nodeType, 'Expected nodeType to be "where"');
        Assert.isNotNull(whereNode.left, 'Expected left to be not null');
        Assert.isNull(whereNode.right, 'Expected right to be null');

        Tokenizer.Node notNode = whereNode.left;
        Assert.areEqual('not', notNode.id, 'Expected id to be "not"');
        Assert.areEqual('not', notNode.nodeType, 'Expected nodeType to be "not"');
        Assert.isNotNull(notNode.left, 'Expected left to be not null');
        Assert.isNull(notNode.right, 'Expected right to be null');

        Tokenizer.Node operatorNode = notNode.left;
        Assert.areEqual('=', operatorNode.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode.right, 'Expected right to not be null');

        Tokenizer.Node firstNameNode = operatorNode.left;
        Assert.areEqual('firstname', firstNameNode.id, 'Expected id to be "firstname"');
        Assert.areEqual('field', firstNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(firstNameNode.left, 'Expected left to be null');
        Assert.isNull(firstNameNode.right, 'Expected right to be null');

        Tokenizer.Node valueNode = operatorNode.right;
        Assert.areEqual('test', valueNode.id, 'Expected id to be "test"');
        Assert.areEqual('string', valueNode.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode.left, 'Expected left to be null');
        Assert.isNull(valueNode.right, 'Expected right to be null');
    }

    @IsTest
    public static void testCorrectsForAndWithOr() {
        Tokenizer t = new Tokenizer();
        Tokenizer.Node head = t.parse('SELECT Id FROM Contact WHERE FirstName = \'test\' OR LastName = \'test2\' AND Account.Name = \'testAcct\' OR Account.Name = \'testAcct2\'');

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

        Tokenizer.Node contactNode = fromNode.left;
        Assert.areEqual('contact', contactNode.id, 'Expected id to be "contact"');
        Assert.areEqual('object', contactNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(contactNode.left, 'Expected left to be null');
        Assert.isNull(contactNode.right, 'Expected right to be null');

        Tokenizer.Node whereNode = fromNode.right;
        Assert.areEqual('where', whereNode.id, 'Expected id to be "where"');
        Assert.areEqual('where', whereNode.nodeType, 'Expected nodeType to be "where"');
        Assert.isNotNull(whereNode.left, 'Expected left to be not null');
        Assert.isNull(whereNode.right, 'Expected right to be null');

        Tokenizer.Node orNode = whereNode.left;
        Assert.areEqual('or', orNode.id, 'Expected id to be "or"');
        Assert.areEqual('or', orNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(orNode.left, 'Expected left to not be null');
        Assert.isNotNull(orNode.right, 'Expected right to not be null');

        Tokenizer.Node orNode2 = orNode.left;
        Assert.areEqual('or', orNode2.id, 'Expected id to be "or"');
        Assert.areEqual('or', orNode2.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(orNode2.left, 'Expected left to not be null');
        Assert.isNotNull(orNode2.right, 'Expected right to not be null');

        Tokenizer.Node operatorNode = orNode2.left;
        Assert.areEqual('=', operatorNode.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode.right, 'Expected right to not be null');

        Tokenizer.Node firstNameNode = operatorNode.left;
        Assert.areEqual('firstname', firstNameNode.id, 'Expected id to be "firstname"');
        Assert.areEqual('field', firstNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(firstNameNode.left, 'Expected left to be null');
        Assert.isNull(firstNameNode.right, 'Expected right to be null');

        Tokenizer.Node valueNode = operatorNode.right;
        Assert.areEqual('test', valueNode.id, 'Expected id to be "test"');
        Assert.areEqual('string', valueNode.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode.left, 'Expected left to be null');
        Assert.isNull(valueNode.right, 'Expected right to be null');

        Tokenizer.Node andNode = orNode2.right;
        Assert.areEqual('and', andNode.id, 'Expected id to be "and"');
        Assert.areEqual('and', andNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(andNode.left, 'Expected left to not be null');
        Assert.isNotNull(andNode.right, 'Expected right to not be null');

        Tokenizer.Node operatorNode2 = andNode.left;
        Assert.areEqual('=', operatorNode2.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode2.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode2.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode2.right, 'Expected right to not be null');

        Tokenizer.Node lastNameNode = operatorNode2.left;
        Assert.areEqual('lastname', lastNameNode.id, 'Expected id to be "lastname"');
        Assert.areEqual('field', lastNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(lastNameNode.left, 'Expected left to be null');
        Assert.isNull(lastNameNode.right, 'Expected right to be null');

        Tokenizer.Node valueNode2 = operatorNode2.right;
        Assert.areEqual('test2', valueNode2.id, 'Expected id to be "test2"');
        Assert.areEqual('string', valueNode2.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode2.left, 'Expected left to be null');
        Assert.isNull(valueNode2.right, 'Expected right to be null');

        Tokenizer.Node operatorNode3 = andNode.right;
        Assert.areEqual('=', operatorNode3.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode3.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode3.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode3.right, 'Expected right to not be null');

        Tokenizer.Node accountNameNode = operatorNode3.left;
        Assert.areEqual('account.name', accountNameNode.id, 'Expected id to be "account.name"');
        Assert.areEqual('field', accountNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(accountNameNode.left, 'Expected left to be null');
        Assert.isNull(accountNameNode.right, 'Expected right to be null');

        Tokenizer.Node valueNode3 = operatorNode3.right;
        Assert.areEqual('testacct', valueNode3.id, 'Expected id to be "testacct"');
        Assert.areEqual('string', valueNode3.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode3.left, 'Expected left to be null');
        Assert.isNull(valueNode3.right, 'Expected right to be null');

        Tokenizer.Node operatorNode4 = orNode.right;
        Assert.areEqual('=', operatorNode4.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode4.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode4.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode4.right, 'Expected right to not be null');

        Tokenizer.Node accountNameNode2 = operatorNode4.left;
        Assert.areEqual('account.name', accountNameNode2.id, 'Expected id to be "account.name"');
        Assert.areEqual('field', accountNameNode2.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(accountNameNode2.left, 'Expected left to be null');
        Assert.isNull(accountNameNode2.right, 'Expected right to be null');

        Tokenizer.Node valueNode4 = operatorNode4.right;
        Assert.areEqual('testacct2', valueNode4.id, 'Expected id to be "testacct2"');
        Assert.areEqual('string', valueNode4.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode4.left, 'Expected left to be null');
        Assert.isNull(valueNode4.right, 'Expected right to be null');
    }

    @IsTest
    public static void testCorrectsForAndWithOrWithSubExpr() {
        Tokenizer t = new Tokenizer();
        Tokenizer.Node head = t.parse('SELECT Id FROM Contact WHERE FirstName = \'test\' AND LastName = \'test2\' OR (Account.Name = \'testAcct\' AND Account.Name = \'testAcct2\' OR Account.Name = \'testAcct3\')');

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

        Tokenizer.Node contactNode = fromNode.left;
        Assert.areEqual('contact', contactNode.id, 'Expected id to be "contact"');
        Assert.areEqual('object', contactNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(contactNode.left, 'Expected left to be null');
        Assert.isNull(contactNode.right, 'Expected right to be null');

        Tokenizer.Node whereNode = fromNode.right;
        Assert.areEqual('where', whereNode.id, 'Expected id to be "where"');
        Assert.areEqual('where', whereNode.nodeType, 'Expected nodeType to be "where"');
        Assert.isNotNull(whereNode.left, 'Expected left to be not null');
        Assert.isNull(whereNode.right, 'Expected right to be null');

        Tokenizer.Node orNode = whereNode.left;
        Assert.areEqual('or', orNode.id, 'Expected id to be "or"');
        Assert.areEqual('or', orNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(orNode.left, 'Expected left to not be null');
        Assert.isNotNull(orNode.right, 'Expected right to not be null');

        Tokenizer.Node andNode = orNode.left;
        Assert.areEqual('and', andNode.id, 'Expected id to be "and"');
        Assert.areEqual('and', andNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(andNode.left, 'Expected left to not be null');
        Assert.isNotNull(andNode.right, 'Expected right to not be null');

        Tokenizer.Node operatorNode = andNode.left;
        Assert.areEqual('=', operatorNode.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode.right, 'Expected right to not be null');

        Tokenizer.Node firstNameNode = operatorNode.left;
        Assert.areEqual('firstname', firstNameNode.id, 'Expected id to be "firstname"');
        Assert.areEqual('field', firstNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(firstNameNode.left, 'Expected left to be null');
        Assert.isNull(firstNameNode.right, 'Expected right to be null');

        Tokenizer.Node valueNode = operatorNode.right;
        Assert.areEqual('test', valueNode.id, 'Expected id to be "test"');
        Assert.areEqual('string', valueNode.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode.left, 'Expected left to be null');
        Assert.isNull(valueNode.right, 'Expected right to be null');

        Tokenizer.Node operatorNode2 = andNode.right;
        Assert.areEqual('=', operatorNode2.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode2.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode2.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode2.right, 'Expected right to not be null');

        Tokenizer.Node lastNameNode = operatorNode2.left;
        Assert.areEqual('lastname', lastNameNode.id, 'Expected id to be "lastname"');
        Assert.areEqual('field', lastNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(lastNameNode.left, 'Expected left to be null');
        Assert.isNull(lastNameNode.right, 'Expected right to be null');

        Tokenizer.Node valueNode2 = operatorNode2.right;
        Assert.areEqual('test2', valueNode2.id, 'Expected id to be "test2"');
        Assert.areEqual('string', valueNode2.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode2.left, 'Expected left to be null');
        Assert.isNull(valueNode2.right, 'Expected right to be null');

        Tokenizer.Node subExprNode2 = orNode.right;
        Assert.areEqual('conditional subexpression', subExprNode2.id, 'Expected id to be "conditional subexpression"');
        Assert.areEqual('conditional subexpression', subExprNode2.nodeType, 'Expected nodeType to be "conditional subexpression"');
        Assert.isNotNull(subExprNode2.left, 'Expected left to not be null');
        Assert.isNull(subExprNode2.right, 'Expected right to be null');

        Tokenizer.Node orNode2 = subExprNode2.left;
        Assert.areEqual('or', orNode2.id, 'Expected id to be "or"');
        Assert.areEqual('or', orNode2.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(orNode2.left, 'Expected left to not be null');
        Assert.isNotNull(orNode2.right, 'Expected right to not be null');

        Tokenizer.Node andNode2 = orNode2.left;
        Assert.areEqual('and', andNode2.id, 'Expected id to be "and"');
        Assert.areEqual('and', andNode2.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(andNode2.left, 'Expected left to not be null');
        Assert.isNotNull(andNode2.right, 'Expected right to not be null');

        Tokenizer.Node operatorNode3 = andNode2.left;
        Assert.areEqual('=', operatorNode3.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode3.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode3.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode3.right, 'Expected right to not be null');

        Tokenizer.Node accountNameNode = operatorNode3.left;
        Assert.areEqual('account.name', accountNameNode.id, 'Expected id to be "account.name"');
        Assert.areEqual('field', accountNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(accountNameNode.left, 'Expected left to be null');
        Assert.isNull(accountNameNode.right, 'Expected right to be null');

        Tokenizer.Node valueNode3 = operatorNode3.right;
        Assert.areEqual('testacct', valueNode3.id, 'Expected id to be "testacct"');
        Assert.areEqual('string', valueNode3.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode3.left, 'Expected left to be null');
        Assert.isNull(valueNode3.right, 'Expected right to be null');

        Tokenizer.Node operatorNode4 = andNode2.right;
        Assert.areEqual('=', operatorNode4.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode4.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode4.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode4.right, 'Expected right to not be null');

        Tokenizer.Node accountNameNode2 = operatorNode4.left;
        Assert.areEqual('account.name', accountNameNode2.id, 'Expected id to be "account.name"');
        Assert.areEqual('field', accountNameNode2.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(accountNameNode2.left, 'Expected left to be null');
        Assert.isNull(accountNameNode2.right, 'Expected right to be null');

        Tokenizer.Node valueNode4 = operatorNode4.right;
        Assert.areEqual('testacct2', valueNode4.id, 'Expected id to be "testacct2"');
        Assert.areEqual('string', valueNode4.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode4.left, 'Expected left to be null');
        Assert.isNull(valueNode4.right, 'Expected right to be null');

        Tokenizer.Node operatorNode5 = orNode2.right;
        Assert.areEqual('=', operatorNode5.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode5.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode5.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode5.right, 'Expected right to not be null');

        Tokenizer.Node accountNameNode3 = operatorNode5.left;
        Assert.areEqual('account.name', accountNameNode3.id, 'Expected id to be "account.name"');
        Assert.areEqual('field', accountNameNode3.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(accountNameNode3.left, 'Expected left to be null');
        Assert.isNull(accountNameNode3.right, 'Expected right to be null');

        Tokenizer.Node valueNode5 = operatorNode5.right;
        Assert.areEqual('testacct3', valueNode5.id, 'Expected id to be "testacct3"');
        Assert.areEqual('string', valueNode5.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode5.left, 'Expected left to be null');
        Assert.isNull(valueNode5.right, 'Expected right to be null');

    }

    @IsTest
    public static void testAlias() {
        Tokenizer t = new Tokenizer();
        Tokenizer.Node head = t.parse('SELECT COUNT(Id) cnt1 FROM Account GROUP BY Id');

        Assert.areEqual('select', head.id, 'Expected id to be "select"');
        Assert.areEqual('select', head.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(head.left, 'Expected left to be not null');
        Assert.isNotNull(head.right, 'Expected right to not be null');

        Tokenizer.Node countNode = head.left;
        Assert.areEqual('count', countNode.id, 'Expected id to be "count"');
        Assert.areEqual('aggregate function', countNode.nodeType, 'Expected nodeType to be "function"');
        Assert.isNull(countNode.left, 'Expected left to be null');
        Assert.isNotNull(countNode.right, 'Expected right to not be null');

        Tokenizer.Node idNode = countNode.right;
        Assert.areEqual('id', idNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNotNull(idNode.left, 'Expected left to not be null');
        Assert.isNull(idNode.right, 'Expected right to be null');

        Tokenizer.Node aliasNode = idNode.left;
        Assert.areEqual('cnt1', aliasNode.id, 'Expected id to be "cnt1"');
        Assert.areEqual('alias', aliasNode.nodeType, 'Expected nodeType to be "alias"');
        Assert.isNull(aliasNode.left, 'Expected left to be null');
        Assert.isNull(aliasNode.right, 'Expected right to be null');

        Tokenizer.Node fromNode = head.right;
        Assert.areEqual('from', fromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', fromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(fromNode.left, 'Expected left to be not null');
        Assert.isNotNull(fromNode.right, 'Expected right to not be null');

        Tokenizer.Node accountNode = fromNode.left;
        Assert.areEqual('account', accountNode.id, 'Expected id to be "account"');
        Assert.areEqual('object', accountNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(accountNode.left, 'Expected left to be null');
        Assert.isNull(accountNode.right, 'Expected right to be null');

        Tokenizer.Node groupByNode = fromNode.right;
        Assert.areEqual('group by', groupByNode.id, 'Expected id to be "group by"');
        Assert.areEqual('group by', groupByNode.nodeType, 'Expected nodeType to be "group by"');
        Assert.isNotNull(groupByNode.left, 'Expected left to be not null');
        Assert.isNull(groupByNode.right, 'Expected right to be null');

        Tokenizer.Node idNode2 = groupByNode.left;
        Assert.areEqual('id', idNode2.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode2.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(idNode2.left, 'Expected left to be null');
        Assert.isNull(idNode2.right, 'Expected right to be null');
    }
}