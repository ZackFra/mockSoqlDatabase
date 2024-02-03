@IsTest
public with sharing class LexerTest {

    /**
     * Helper class to assert the properties of a node
     */
    private class AssertNode {
        public String id;
        public String nodeType;
        public Boolean isLeftNull;
        public Boolean isRightNull;
        public Lexer.Node node;

        public AssertNode(Lexer.Node node, String id, String nodeType, Boolean isLeftNull, Boolean isRightNull) {
            this.node = node;
            this.id = id;
            this.nodeType = nodeType;
            this.isLeftNull = isLeftNull;
            this.isRightNull = isRightNull;
        }

        public void doAssert() {
            Assert.areEqual(id, node.id, 'Expected id to be "' + id + '"');
            Assert.areEqual(nodeType, node.nodeType, 'Expected nodeType to be "' + nodeType + '"');
            Assert.areEqual(isLeftNull, node.left == null, 'Expected left to be ' + (isLeftNull ? 'null' : 'not null'));
            Assert.areEqual(isRightNull, node.right == null, 'Expected right to be ' + (isRightNull ? 'null' : 'not null'));
        }
    }

    public class AssertNodeBuilder {
        Lexer.Node node;
        String id;
        String nodeType;
        Boolean isLeftNull;
        Boolean isRightNull;

        AssertNodeBuilder setNode(Lexer.Node node) {
            this.node = node;
            return this;
        }

        AssertNodeBuilder setId(String id) {
            this.id = id;
            return this;
        }

        AssertNodeBuilder setNodeType(String nodeType) {
            this.nodeType = nodeType;
            return this;
        }

        AssertNodeBuilder setIsLeftNull(Boolean isLeftNull) {
            this.isLeftNull = isLeftNull;
            return this;
        }

        AssertNodeBuilder setIsRightNull(Boolean isRightNull) {
            this.isRightNull = isRightNull;
            return this;
        }

        AssertNode build() {
            return new AssertNode(this.node, this.id, this.nodeType, this.isLeftNull, this.isRightNull);
        }
    }

    @IsTest
    public static void testToString() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id FROM Account');
        String result = head.toString();
        String expectedResult = '{ id: id, nodeType: field }, { id: select, nodeType: select }, { id: account, nodeType: object }, { id: from, nodeType: from}';
        Assert.areEqual(
            expectedResult,
            result, 
            'Expected result to be "' + expectedResult + '"'
        );
    }

    // fails for the wrong reason
    @IsTest
    public static void testAggrFuncFail1() {
        Lexer t = new Lexer();
        try {
            Lexer.Node head = t.parse('SELECT SUM_DISTINCT(Amount) FROM Opportunity');
            Assert.fail('Expected exception to be thrown');
        } catch(Exception e) {
            Assert.isTrue(
                e.getMessage().startsWith('Parsing exception, expected "("'),
                'Expected exception message to start with "Parsing exception, expected "(""'
            );
        }
    }

    @IsTest
    public static void testAggrFuncFail2() {
        Lexer t = new Lexer();
        try {
            Lexer.Node head = t.parse('SELECT C(Amount) FROM Opportunity');
            Assert.fail('Expected exception to be thrown');
        } catch(Exception e) {
            Assert.isTrue(
                e.getMessage().startsWith('Parsing exception, expected "from"'),
                'Expected exception message to start with "Parsing exception, expected "from""'
            );
        }
    }

    @IsTest
    public static void testAggrFuncFail3() {
        Lexer t = new Lexer();
        try {
            Lexer.Node head = t.parse('SELECT SUM(DISTINCT Amount) FROM Opportunity');
            Assert.fail('Expected exception to be thrown');
        } catch(Exception e) {
            Assert.isTrue(
                e.getMessage().startsWith('Parsing exception, expected ")"'),
                'Expected exception message to start with "Parsing exception, expected ")"'
            );
        }
    }

    @IsTest
    public static void testParseBoolean() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id FROM Account WHERE IsDeleted = true');
        AssertNode assertSelect = new AssertNodeBuilder()
            .setNode(head)
            .setId('select')
            .setNodeType('select')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertSelect.doAssert();

        Lexer.Node idNode = head.left;
        AssertNode assertId = new AssertNodeBuilder()
            .setNode(idNode)
            .setId('id')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertId.doAssert();

        Lexer.Node fromNode = head.right;
        AssertNode assertFrom = new AssertNodeBuilder()
            .setNode(fromNode)
            .setId('from')
            .setNodeType('from')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertFrom.doAssert();

        Lexer.Node accountNode = fromNode.left;
        AssertNode assertAccount = new AssertNodeBuilder()
            .setNode(accountNode)
            .setId('account')
            .setNodeType('object')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertAccount.doAssert();

        Lexer.Node whereNode = fromNode.right;
        AssertNode assertWhere = new AssertNodeBuilder()
            .setNode(whereNode)
            .setId('where')
            .setNodeType('where')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertWhere.doAssert();

        Lexer.Node operatorNode = whereNode.left;
        AssertNode assertOperator = new AssertNodeBuilder()
            .setNode(operatorNode)
            .setId('=')
            .setNodeType('operator')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertOperator.doAssert();

        Lexer.Node isDeletedNode = operatorNode.left;
        AssertNode assertIsDeleted = new AssertNodeBuilder()
            .setNode(isDeletedNode)
            .setId('isdeleted')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertIsDeleted.doAssert();

        Lexer.Node valueNode = operatorNode.right;
        AssertNode assertValue = new AssertNodeBuilder()
            .setNode(valueNode)
            .setId('true')
            .setNodeType('boolean')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertValue.doAssert();
    }

    @IsTest
    public static void testOrderBy() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id FROM Account ORDER BY Name, Id');
        AssertNode assertSelect = new AssertNodeBuilder()
            .setNode(head)
            .setId('select')
            .setNodeType('select')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertSelect.doAssert();

        Lexer.Node idNode = head.left;
        AssertNode assertId = new AssertNodeBuilder()
            .setNode(idNode)
            .setId('id')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertId.doAssert();

        Lexer.Node fromNode = head.right;
        AssertNode assertFrom = new AssertNodeBuilder()
            .setNode(fromNode)
            .setId('from')
            .setNodeType('from')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertFrom.doAssert();

        Lexer.Node accountNode = fromNode.left;
        AssertNode assertAccount = new AssertNodeBuilder()
            .setNode(accountNode)
            .setId('account')
            .setNodeType('object')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertAccount.doAssert();

        Lexer.Node orderByNode = fromNode.right;
        AssertNode assertOrderBy = new AssertNodeBuilder()
            .setNode(orderByNode)
            .setId('order by')
            .setNodeType('order by')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertOrderBy.doAssert();

        Lexer.Node nameNode = orderByNode.left;
        AssertNode assertName = new AssertNodeBuilder()
            .setNode(nameNode)
            .setId('name')
            .setNodeType('field')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertName.doAssert();

        Lexer.Node idNode2 = nameNode.left;
        AssertNode assertId2 = new AssertNodeBuilder()
            .setNode(idNode2)
            .setId('id')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertId2.doAssert();
    }

    @IsTest
    public static void testLimit() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id FROM Account LIMIT 10');

        AssertNode assertSelect = new AssertNodeBuilder()
            .setNode(head)
            .setId('select')
            .setNodeType('select')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertSelect.doAssert();

        Lexer.Node idNode = head.left;
        AssertNode assertId = new AssertNodeBuilder()
            .setNode(idNode)
            .setId('id')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertId.doAssert();

        Lexer.Node fromNode = head.right;
        AssertNode assertFrom = new AssertNodeBuilder()
            .setNode(fromNode)
            .setId('from')
            .setNodeType('from')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertFrom.doAssert();

        Lexer.Node accountNode = fromNode.left;
        AssertNode assertAccount = new AssertNodeBuilder()
            .setNode(accountNode)
            .setId('account')
            .setNodeType('object')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertAccount.doAssert();

        Lexer.Node limitNode = fromNode.right;
        AssertNode assertLimit = new AssertNodeBuilder()
            .setNode(limitNode)
            .setId('limit')
            .setNodeType('limit')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertLimit.doAssert();

        Lexer.Node valueNode = limitNode.left;
        AssertNode assertValue = new AssertNodeBuilder()
            .setNode(valueNode)
            .setId('10')
            .setNodeType('number')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertValue.doAssert();
    }

    @IsTest
    public static void testForUpdate() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id FROM Account FOR UPDATE');
        AssertNode assertSelect = new AssertNodeBuilder()
            .setNode(head)
            .setId('select')
            .setNodeType('select')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertSelect.doAssert();

        Lexer.Node idNode = head.left;
        AssertNode assertId = new AssertNodeBuilder()
            .setNode(idNode)
            .setId('id')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertId.doAssert();

        Lexer.Node fromNode = head.right;
        AssertNode assertFrom = new AssertNodeBuilder()
            .setNode(fromNode)
            .setId('from')
            .setNodeType('from')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertFrom.doAssert();

        Lexer.Node accountNode = fromNode.left;
        AssertNode assertAccount = new AssertNodeBuilder()
            .setNode(accountNode)
            .setId('account')
            .setNodeType('object')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertAccount.doAssert();

        Lexer.Node forUpdateNode = fromNode.right;
        AssertNode assertForUpdate = new AssertNodeBuilder()
            .setNode(forUpdateNode)
            .setId('for update')
            .setNodeType('for update')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertForUpdate.doAssert();
    }

    @IsTest 
    public static void testHavingClause() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id FROM Account GROUP BY Id HAVING COUNT(Id) > 0');
        AssertNode assertSelect = new AssertNodeBuilder()
            .setNode(head)
            .setId('select')
            .setNodeType('select')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertSelect.doAssert();
    
        Lexer.Node idNode = head.left;
        AssertNode assertId = new AssertNodeBuilder()
            .setNode(idNode)
            .setId('id')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertId.doAssert();

        Lexer.Node fromNode = head.right;
        AssertNode assertFrom = new AssertNodeBuilder()
            .setNode(fromNode)
            .setId('from')
            .setNodeType('from')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertFrom.doAssert();

        Lexer.Node accountNode = fromNode.left;
        AssertNode assertAccount = new AssertNodeBuilder()
            .setNode(accountNode)
            .setId('account')
            .setNodeType('object')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertAccount.doAssert();

        Lexer.Node groupByNode = fromNode.right;
        AssertNode assertGroupBy = new AssertNodeBuilder()
            .setNode(groupByNode)
            .setId('group by')
            .setNodeType('group by')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertGroupBy.doAssert();

        Lexer.Node idNode2 = groupByNode.left;
        AssertNode assertId2 = new AssertNodeBuilder()
            .setNode(idNode2)
            .setId('id')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertId2.doAssert();

        Lexer.Node havingNode = groupByNode.right;
        AssertNode assertHaving = new AssertNodeBuilder()
            .setNode(havingNode)
            .setId('having')
            .setNodeType('having')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertHaving.doAssert();

        Lexer.Node operatorNode = havingNode.left;
        AssertNode assertOperator = new AssertNodeBuilder()
            .setNode(operatorNode)
            .setId('>')
            .setNodeType('operator')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertOperator.doAssert();

        Lexer.Node aggregateFunctionNode = operatorNode.left;
        AssertNode assertAggregateFunction = new AssertNodeBuilder()
            .setNode(aggregateFunctionNode)
            .setId('count')
            .setNodeType('aggregate function')
            .setIsLeftNull(true)
            .setIsRightNull(false)
            .build();
        assertAggregateFunction.doAssert();

        Lexer.Node idNode3 = aggregateFunctionNode.right;
        AssertNode assertId3 = new AssertNodeBuilder()
            .setNode(idNode3)
            .setId('id')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertId3.doAssert();

        Lexer.Node valueNode = operatorNode.right;
        AssertNode assertValue = new AssertNodeBuilder()
            .setNode(valueNode)
            .setId('0')
            .setNodeType('number')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertValue.doAssert();
    }

    @IsTest
    public static void testAggrFuncs() {
        List<String> aggrFuncs = new List<String> {
            'avg',
            'count',
            'count_distinct',
            'min',
            'max',
            'sum'
        };
        for(String func : aggrFuncs) {
            Lexer t = new Lexer();
            Lexer.Node head = t.parse('SELECT ' + func + '(Amount) FROM Opportunity');
            
            // we expect this to come back in a particular order
            Assert.areEqual('select', head.id, 'Expected id to be "select"');
            Assert.areEqual('select', head.nodeType, 'Expected nodeType to be "select"');
            Assert.isNotNull(head.left, 'Expected left to be not null');
            Assert.isNotNull(head.right, 'Expected right to be not null');
    
            Lexer.Node sumNode = head.left;
            Assert.areEqual(func, sumNode.id, 'Expected id to be "' + func + '"');
            Assert.areEqual('aggregate function', sumNode.nodeType, 'Expected nodeType to be "aggregate function"');
            Assert.isNull(sumNode.left, 'Expected left to be null');
            Assert.isNotNull(sumNode.right, 'Expected right to be not null');
    
            Lexer.Node amountNode = sumNode.right;
            Assert.areEqual('amount', amountNode.id, 'Expected id to be "amount"');
            Assert.areEqual('field', amountNode.nodeType, 'Expected nodeType to be "field"');
            Assert.isNull(amountNode.left, 'Expected left to be null');
            Assert.isNull(amountNode.right, 'Expected right to be null');
    
            Lexer.Node fromNode = head.right;
            Assert.areEqual('from', fromNode.id, 'Expected id to be "from"');
            Assert.areEqual('from', fromNode.nodeType, 'Expected nodeType to be "from"');
            Assert.isNotNull(fromNode.left, 'Expected left to be not null');
            Assert.isNull(fromNode.right, 'Expected right to be null');
    
            Lexer.Node opportunityNode = fromNode.left;
            Assert.areEqual('opportunity', opportunityNode.id, 'Expected id to be "opportunity"');
            Assert.areEqual('object', opportunityNode.nodeType, 'Expected nodeType to be "object"');
            Assert.isNull(opportunityNode.left, 'Expected left to be null');
            Assert.isNull(opportunityNode.right, 'Expected right to be null');       
        }
    }

    @IsTest
    public static void testSelectAccount() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id FROM Account');
        
        // we expect this to come back in a particular order
        Assert.areEqual('select', head.id, 'Expected id to be "select"');
        Assert.areEqual('select', head.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(head.left, 'Expected left to be not null');
        Assert.isNotNull(head.right, 'Expected right to be not null');

        Lexer.Node idNode = head.left;
        Assert.areEqual('id', idNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(idNode.left, 'Expected left to be null');
        Assert.isNull(idNode.right, 'Expected right to be null');

        Lexer.Node fromNode = head.right;
        Assert.areEqual('from', fromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', fromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(fromNode.left, 'Expected left to be not null');
        Assert.isNull(fromNode.right, 'Expected right to be null');

        Lexer.Node accountNode = fromNode.left;
        Assert.areEqual('account', accountNode.id, 'Expected id to be "account"');
        Assert.areEqual('object', accountNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(accountNode.left, 'Expected left to be null');
        Assert.isNull(accountNode.right, 'Expected right to be null');
    }

    @IsTest
    public static void testSelectWithWhereClause() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id FROM Account WHERE Name = \'Test\'');
        
        // we expect this to come back in a particular order
        Assert.areEqual('select', head.id, 'Expected id to be "select"');
        Assert.areEqual('select', head.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(head.left, 'Expected left to be not null');
        Assert.isNotNull(head.right, 'Expected right to be not null');

        Lexer.Node idNode = head.left;
        Assert.areEqual('id', idNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(idNode.left, 'Expected left to be null');
        Assert.isNull(idNode.right, 'Expected right to be null');

        Lexer.Node fromNode = head.right;
        Assert.areEqual('from', fromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', fromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(fromNode.left, 'Expected left to be not null');
        Assert.isNotNull(fromNode.right, 'Expected right to be not null');

        Lexer.Node accountNode = fromNode.left;
        Assert.areEqual('account', accountNode.id, 'Expected id to be "account"');
        Assert.areEqual('object', accountNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(accountNode.left, 'Expected left to be null');
        Assert.isNull(accountNode.right, 'Expected right to be null');

        Lexer.Node whereNode = fromNode.right;
        Assert.areEqual('where', whereNode.id, 'Expected id to be "where"');
        Assert.areEqual('where', whereNode.nodeType, 'Expected nodeType to be "where"');
        Assert.isNotNull(whereNode.left, 'Expected left to be not null');
        Assert.isNull(whereNode.right, 'Expected right to be null');

        Lexer.Node operatorNode = whereNode.left;
        Assert.areEqual('=', operatorNode.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode.right, 'Expected right to not be null');

        Lexer.Node nameNode = operatorNode.left;
        Assert.areEqual('name', nameNode.id, 'Expected id to be "name"');
        Assert.areEqual('field', nameNode.nodeType, 'Expected nodeType to be "name"');
        Assert.isNull(nameNode.left, 'Expected left to be null');
        Assert.isNull(nameNode.right, 'Expected right to be null');

        Lexer.Node valueNode = operatorNode.right;
        Assert.areEqual('test', valueNode.id, 'Expected id to be "value"');
        Assert.areEqual('string', valueNode.nodeType, 'Expected nodeType to be "value"');
        Assert.isNull(valueNode.left, 'Expected left to be null');
        Assert.isNull(valueNode.right, 'Expected right to be null');
    }

    @IsTest
    public static void testMixedFieldsSubQueries() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id, (SELECT Id FROM Contacts), Name FROM Account');

        Assert.areEqual('select', head.id, 'Expected id to be "select"');
        Assert.areEqual('select', head.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(head.left, 'Expected left to be not null');
        Assert.isNotNull(head.right, 'Expected right to be not null');

        Lexer.Node idNode = head.left;
        Assert.areEqual('id', idNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNotNull(idNode.left, 'Expected left to not be null');
        Assert.isNull(idNode.right, 'Expected right to be null');

        Lexer.Node subQueryNode = idNode.left;
        Assert.areEqual('subquery', subQueryNode.id, 'Expected id to be "subquery"');
        Assert.areEqual('subquery', subQueryNode.nodeType, 'Expected nodeType to be "subquery"');
        Assert.isNotNull(subQueryNode.left, 'Expected left to not be null');
        Assert.isNotNull(subQueryNode.right, 'Expected right to not be null');

        Lexer.Node subQuerySelectNode = subQueryNode.right;
        Assert.areEqual('select', subQuerySelectNode.id, 'Expected id to be "select"');
        Assert.areEqual('select', subQuerySelectNode.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(subQuerySelectNode.left, 'Expected left to not be null');
        Assert.isNotNull(subQuerySelectNode.right, 'Expected right to not be null');

        Lexer.Node subQueryIdNode = subQuerySelectNode.left;
        Assert.areEqual('id', subQueryIdNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', subQueryIdNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(subQueryIdNode.left, 'Expected left to be null');
        Assert.isNull(subQueryIdNode.right, 'Expected right to be null');

        Lexer.Node subQueryFromNode = subQuerySelectNode.right;
        Assert.areEqual('from', subQueryFromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', subQueryFromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(subQueryFromNode.left, 'Expected left to not be null');
        Assert.isNull(subQueryFromNode.right, 'Expected right to be null');

        Lexer.Node subQueryContactNode = subQueryFromNode.left;
        Assert.areEqual('contacts', subQueryContactNode.id, 'Expected id to be "contact"');
        Assert.areEqual('object', subQueryContactNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(subQueryContactNode.left, 'Expected left to be null');
        Assert.isNull(subQueryContactNode.right, 'Expected right to be null');

        Lexer.Node nameNode = subQueryNode.left;
        Assert.areEqual('name', nameNode.id, 'Expected id to be "name"');
        Assert.areEqual('field', nameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(nameNode.left, 'Expected left to be null');
        Assert.isNull(nameNode.right, 'Expected right to be null');

        Lexer.Node fromNode = head.right;
        Assert.areEqual('from', fromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', fromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(fromNode.left, 'Expected left to not be null');
        Assert.isNull(fromNode.right, 'Expected right to be null');

        Lexer.Node accountNode = fromNode.left;
        Assert.areEqual('account', accountNode.id, 'Expected id to be "account"');
        Assert.areEqual('object', accountNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(accountNode.left, 'Expected left to be null');
        Assert.isNull(accountNode.right, 'Expected right to be null');

    }

    @IsTest
    public static void testSubQueryWithSubQueryFirst() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT (SELECT Id FROM Contacts), Id FROM Account');

        Assert.areEqual('select', head.id, 'Expected id to be "select"');
        Assert.areEqual('select', head.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(head.left, 'Expected left to be not null');
        Assert.isNotNull(head.right, 'Expected right to be not null');

        Lexer.Node subQueryNode = head.left;
        Assert.areEqual('subquery', subQueryNode.id, 'Expected id to be "subquery"');
        Assert.areEqual('subquery', subQueryNode.nodeType, 'Expected nodeType to be "subquery"');
        Assert.isNotNull(subQueryNode.left, 'Expected left to not be null');
        Assert.isNotNull(subQueryNode.right, 'Expected right to not be null');

        Lexer.Node subQuerySelectNode = subQueryNode.right;
        Assert.areEqual('select', subQuerySelectNode.id, 'Expected id to be "select"');
        Assert.areEqual('select', subQuerySelectNode.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(subQuerySelectNode.left, 'Expected left to not be null');
        Assert.isNotNull(subQuerySelectNode.right, 'Expected right to not be null');

        Lexer.Node subQueryIdNode = subQuerySelectNode.left;
        Assert.areEqual('id', subQueryIdNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', subQueryIdNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(subQueryIdNode.left, 'Expected left to be null');
        Assert.isNull(subQueryIdNode.right, 'Expected right to be null');

        Lexer.Node subQueryFromNode = subQuerySelectNode.right;
        Assert.areEqual('from', subQueryFromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', subQueryFromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(subQueryFromNode.left, 'Expected left to not be null');
        Assert.isNull(subQueryFromNode.right, 'Expected right to be null');

        Lexer.Node subQueryContactNode = subQueryFromNode.left;
        Assert.areEqual('contacts', subQueryContactNode.id, 'Expected id to be "contact"');
        Assert.areEqual('object', subQueryContactNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(subQueryContactNode.left, 'Expected left to be null');
        Assert.isNull(subQueryContactNode.right, 'Expected right to be null');

    }

    @IsTest
    public static void testSubQueryWithSubQuerySecond() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id, (SELECT Id FROM Contacts) FROM Account');

        Assert.areEqual('select', head.id, 'Expected id to be "select"');
        Assert.areEqual('select', head.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(head.left, 'Expected left to be not null');
        Assert.isNotNull(head.right, 'Expected right to be not null');

        Lexer.Node idNode = head.left;
        Assert.areEqual('id', idNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNotNull(idNode.left, 'Expected left to not be null');
        Assert.isNull(idNode.right, 'Expected right to be null');

        Lexer.Node subQueryNode = idNode.left;
        Assert.areEqual('subquery', subQueryNode.id, 'Expected id to be "subquery"');
        Assert.areEqual('subquery', subQueryNode.nodeType, 'Expected nodeType to be "subquery"');
        Assert.isNull(subQueryNode.left, 'Expected left to be null');
        Assert.isNotNull(subQueryNode.right, 'Expected right to not be null');

        Lexer.Node subQuerySelectNode = subQueryNode.right;
        Assert.areEqual('select', subQuerySelectNode.id, 'Expected id to be "select"');
        Assert.areEqual('select', subQuerySelectNode.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(subQuerySelectNode.left, 'Expected left to not be null');
        Assert.isNotNull(subQuerySelectNode.right, 'Expected right to not be null');

        Lexer.Node subQueryIdNode = subQuerySelectNode.left;
        Assert.areEqual('id', subQueryIdNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', subQueryIdNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(subQueryIdNode.left, 'Expected left to be null');
        Assert.isNull(subQueryIdNode.right, 'Expected right to be null');

        Lexer.Node subQueryFromNode = subQuerySelectNode.right;
        Assert.areEqual('from', subQueryFromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', subQueryFromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(subQueryFromNode.left, 'Expected left to not be null');
        Assert.isNull(subQueryFromNode.right, 'Expected right to be null');

        Lexer.Node subQueryContactNode = subQueryFromNode.left;
        Assert.areEqual('contacts', subQueryContactNode.id, 'Expected id to be "contact"');
        Assert.areEqual('object', subQueryContactNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(subQueryContactNode.left, 'Expected left to be null');
        Assert.isNull(subQueryContactNode.right, 'Expected right to be null');
    }

    @IsTest
    public static void testMultipleSubQueries() {

        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id, (SELECT Id FROM Contacts), (SELECT Id FROM Opportunities) FROM Account');

        Assert.areEqual('select', head.id, 'Expected id to be "select"');
        Assert.areEqual('select', head.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(head.left, 'Expected left to be not null');
        Assert.isNotNull(head.right, 'Expected right to be not null');

        Lexer.Node idNode = head.left;
        Assert.areEqual('id', idNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNotNull(idNode.left, 'Expected left to not be null');
        Assert.isNull(idNode.right, 'Expected right to be null');

        Lexer.Node subQueryNode = idNode.left;
        Assert.areEqual('subquery', subQueryNode.id, 'Expected id to be "subquery"');
        Assert.areEqual('subquery', subQueryNode.nodeType, 'Expected nodeType to be "subquery"');
        Assert.isNotNull(subQueryNode.left, 'Expected left to not be null');
        Assert.isNotNull(subQueryNode.right, 'Expected right to not be null');

        Lexer.Node subQuerySelectNode = subQueryNode.right;
        Assert.areEqual('select', subQuerySelectNode.id, 'Expected id to be "select"');
        Assert.areEqual('select', subQuerySelectNode.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(subQuerySelectNode.left, 'Expected left to not be null');
        Assert.isNotNull(subQuerySelectNode.right, 'Expected right to not be null');

        Lexer.Node subQueryIdNode = subQuerySelectNode.left;
        Assert.areEqual('id', subQueryIdNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', subQueryIdNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(subQueryIdNode.left, 'Expected left to be null');
        Assert.isNull(subQueryIdNode.right, 'Expected right to be null');

        Lexer.Node subQueryFromNode = subQuerySelectNode.right;
        Assert.areEqual('from', subQueryFromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', subQueryFromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(subQueryFromNode.left, 'Expected left to not be null');
        Assert.isNull(subQueryFromNode.right, 'Expected right to be null');

        Lexer.Node subQueryContactNode = subQueryFromNode.left;
        Assert.areEqual('contacts', subQueryContactNode.id, 'Expected id to be "contact"');
        Assert.areEqual('object', subQueryContactNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(subQueryContactNode.left, 'Expected left to be null');
        Assert.isNull(subQueryContactNode.right, 'Expected right to be null');

        Lexer.Node subQueryNode2 = subQueryNode.left;
        Assert.areEqual('subquery', subQueryNode2.id, 'Expected id to be "subquery"');
        Assert.areEqual('subquery', subQueryNode2.nodeType, 'Expected nodeType to be "subquery"');
        Assert.isNull(subQueryNode2.left, 'Expected left to be null');
        Assert.isNotNull(subQueryNode2.right, 'Expected right to not be null');

        Lexer.Node subQuerySelectNode2 = subQueryNode2.right;
        Assert.areEqual('select', subQuerySelectNode2.id, 'Expected id to be "select"');
        Assert.areEqual('select', subQuerySelectNode2.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(subQuerySelectNode2.left, 'Expected left to not be null');
        Assert.isNotNull(subQuerySelectNode2.right, 'Expected right to not be null');

        Lexer.Node subQueryIdNode2 = subQuerySelectNode2.left;
        Assert.areEqual('id', subQueryIdNode2.id, 'Expected id to be "id"');
        Assert.areEqual('field', subQueryIdNode2.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(subQueryIdNode2.left, 'Expected left to be null');
        Assert.isNull(subQueryIdNode2.right, 'Expected right to be null');

        Lexer.Node subQueryFromNode2 = subQuerySelectNode2.right;
        Assert.areEqual('from', subQueryFromNode2.id, 'Expected id to be "from"');
        Assert.areEqual('from', subQueryFromNode2.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(subQueryFromNode2.left, 'Expected left to not be null');
        Assert.isNull(subQueryFromNode2.right, 'Expected right to be null');

        Lexer.Node subQueryOpportunityNode = subQueryFromNode2.left;
        Assert.areEqual('opportunities', subQueryOpportunityNode.id, 'Expected id to be "opportunities"');
        Assert.areEqual('object', subQueryOpportunityNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(subQueryOpportunityNode.left, 'Expected left to be null');
        Assert.isNull(subQueryOpportunityNode.right, 'Expected right to be null');

    }

    @IsTest
    public static void testSubQueryWithQueryInWhereClause() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact)');

        Assert.areEqual('select', head.id, 'Expected id to be "select"');
        Assert.areEqual('select', head.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(head.left, 'Expected left to be not null');
        Assert.isNotNull(head.right, 'Expected right to be not null');

        Lexer.Node idNode = head.left;
        Assert.areEqual('id', idNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(idNode.left, 'Expected left to be null');
        Assert.isNull(idNode.right, 'Expected right to be null');

        Lexer.Node fromNode = head.right;
        Assert.areEqual('from', fromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', fromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(fromNode.left, 'Expected left to be not null');
        Assert.isNotNull(fromNode.right, 'Expected right to be not null');

        Lexer.Node accountNode = fromNode.left;
        Assert.areEqual('account', accountNode.id, 'Expected id to be "account"');
        Assert.areEqual('object', accountNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(accountNode.left, 'Expected left to be null');
        Assert.isNull(accountNode.right, 'Expected right to be null');

        Lexer.Node whereNode = fromNode.right;
        Assert.areEqual('where', whereNode.id, 'Expected id to be "where"');
        Assert.areEqual('where', whereNode.nodeType, 'Expected nodeType to be "where"');
        Assert.isNotNull(whereNode.left, 'Expected left to be not null');
        Assert.isNull(whereNode.right, 'Expected right to be null');

        Lexer.Node operatorNode = whereNode.left;
        Assert.areEqual('in', operatorNode.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode.right, 'Expected right to not be null');

        Lexer.Node idNode2 = operatorNode.left;
        Assert.areEqual('id', idNode2.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode2.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(idNode2.left, 'Expected left to be null');
        Assert.isNull(idNode2.right, 'Expected right to be null');

        Lexer.Node subQueryNode = operatorNode.right;
        Assert.areEqual('subquery', subQueryNode.id, 'Expected id to be "subquery"');
        Assert.areEqual('subquery', subQueryNode.nodeType, 'Expected nodeType to be "subquery"');
        Assert.isNull(subQueryNode.left, 'Expected left to be null');
        Assert.isNotNull(subQueryNode.right, 'Expected right to not be null');

        Lexer.Node subQuerySelectNode = subQueryNode.right;
        Assert.areEqual('select', subQuerySelectNode.id, 'Expected id to be "select"');
        Assert.areEqual('select', subQuerySelectNode.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(subQuerySelectNode.left, 'Expected left to not be null');
        Assert.isNotNull(subQuerySelectNode.right, 'Expected right to not be null');

        Lexer.Node subQueryAccountIdNode = subQuerySelectNode.left;
        Assert.areEqual('accountid', subQueryAccountIdNode.id, 'Expected id to be "accountid"');
        Assert.areEqual('field', subQueryAccountIdNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(subQueryAccountIdNode.left, 'Expected left to be null');
        Assert.isNull(subQueryAccountIdNode.right, 'Expected right to be null');

        Lexer.Node subQueryFromNode = subQuerySelectNode.right;
        Assert.areEqual('from', subQueryFromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', subQueryFromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(subQueryFromNode.left, 'Expected left to not be null');
        Assert.isNull(subQueryFromNode.right, 'Expected right to be null');

        Lexer.Node subQueryContactNode = subQueryFromNode.left;
        Assert.areEqual('contact', subQueryContactNode.id, 'Expected id to be "contact"');
        Assert.areEqual('object', subQueryContactNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(subQueryContactNode.left, 'Expected left to be null');
        Assert.isNull(subQueryContactNode.right, 'Expected right to be null');
    }

    @IsTest
    public static void testSubQueryWithQueryInWhereClause2() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE Name = \'Test\')');

        Assert.areEqual('select', head.id, 'Expected id to be "select"');
        Assert.areEqual('select', head.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(head.left, 'Expected left to be not null');
        Assert.isNotNull(head.right, 'Expected right to be not null');

        Lexer.Node idNode = head.left;
        Assert.areEqual('id', idNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(idNode.left, 'Expected left to be null');
        Assert.isNull(idNode.right, 'Expected right to be null');

        Lexer.Node fromNode = head.right;
        Assert.areEqual('from', fromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', fromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(fromNode.left, 'Expected left to be not null');
        Assert.isNotNull(fromNode.right, 'Expected right to be not null');

        Lexer.Node accountNode = fromNode.left;
        Assert.areEqual('account', accountNode.id, 'Expected id to be "account"');
        Assert.areEqual('object', accountNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(accountNode.left, 'Expected left to be null');
        Assert.isNull(accountNode.right, 'Expected right to be null');

        Lexer.Node whereNode = fromNode.right;
        Assert.areEqual('where', whereNode.id, 'Expected id to be "where"');
        Assert.areEqual('where', whereNode.nodeType, 'Expected nodeType to be "where"');
        Assert.isNotNull(whereNode.left, 'Expected left to be not null');
        Assert.isNull(whereNode.right, 'Expected right to be null');

        Lexer.Node operatorNode = whereNode.left;
        Assert.areEqual('in', operatorNode.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode.right, 'Expected right to not be null');

        Lexer.Node idNode2 = operatorNode.left;
        Assert.areEqual('id', idNode2.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode2.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(idNode2.left, 'Expected left to be null');
        Assert.isNull(idNode2.right, 'Expected right to be null');

        Lexer.Node subQueryNode = operatorNode.right;
        Assert.areEqual('subquery', subQueryNode.id, 'Expected id to be "subquery"');
        Assert.areEqual('subquery', subQueryNode.nodeType, 'Expected nodeType to be "subquery"');
        Assert.isNull(subQueryNode.left, 'Expected left to be null');

        Lexer.Node subQuerySelectNode = subQueryNode.right;
        Assert.areEqual('select', subQuerySelectNode.id, 'Expected id to be "select"');
        Assert.areEqual('select', subQuerySelectNode.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(subQuerySelectNode.left, 'Expected left to not be null');
        Assert.isNotNull(subQuerySelectNode.right, 'Expected right to not be null');

        Lexer.Node subQueryAccountIdNode = subQuerySelectNode.left;
        Assert.areEqual('accountid', subQueryAccountIdNode.id, 'Expected id to be "accountid"');
        Assert.areEqual('field', subQueryAccountIdNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(subQueryAccountIdNode.left, 'Expected left to be null');
        Assert.isNull(subQueryAccountIdNode.right, 'Expected right to be null');

        Lexer.Node subQueryFromNode = subQuerySelectNode.right;
        Assert.areEqual('from', subQueryFromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', subQueryFromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(subQueryFromNode.left, 'Expected left to not be null');
        Assert.isNotNull(subQueryFromNode.right, 'Expected right to not be null');

        Lexer.Node subQueryContactNode = subQueryFromNode.left;
        Assert.areEqual('contact', subQueryContactNode.id, 'Expected id to be "contact"');
        Assert.areEqual('object', subQueryContactNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(subQueryContactNode.left, 'Expected left to be null');

        Lexer.Node subQueryWhereNode = subQueryFromNode.right;
        Assert.areEqual('where', subQueryWhereNode.id, 'Expected id to be "where"');
        Assert.areEqual('where', subQueryWhereNode.nodeType, 'Expected nodeType to be "where"');
        Assert.isNotNull(subQueryWhereNode.left, 'Expected left to not be null');
        Assert.isNull(subQueryWhereNode.right, 'Expected right to be null');

        Lexer.Node subQueryOperatorNode = subQueryWhereNode.left;
        Assert.areEqual('=', subQueryOperatorNode.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', subQueryOperatorNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(subQueryOperatorNode.left, 'Expected left to not be null');
        Assert.isNotNull(subQueryOperatorNode.right, 'Expected right to not be null');

        Lexer.Node subQueryNameNode = subQueryOperatorNode.left;
        Assert.areEqual('name', subQueryNameNode.id, 'Expected id to be "name"');
        Assert.areEqual('field', subQueryNameNode.nodeType, 'Expected nodeType to be "name"');
        Assert.isNull(subQueryNameNode.left, 'Expected left to be null');
        Assert.isNull(subQueryNameNode.right, 'Expected right to be null');

        Lexer.Node subQueryValueNode = subQueryOperatorNode.right;
        Assert.areEqual('test', subQueryValueNode.id, 'Expected id to be "value"');
        Assert.areEqual('string', subQueryValueNode.nodeType, 'Expected nodeType to be "value"');
        Assert.isNull(subQueryValueNode.left, 'Expected left to be null');
        Assert.isNull(subQueryValueNode.right, 'Expected right to be null');
    }

    @IsTest
    public static void testBindVar() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id FROM Account WHERE Id = :id');

        Assert.areEqual('select', head.id, 'Expected id to be "select"');
        Assert.areEqual('select', head.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(head.left, 'Expected left to be not null');
        Assert.isNotNull(head.right, 'Expected right to be not null');

        Lexer.Node idNode = head.left;
        Assert.areEqual('id', idNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(idNode.left, 'Expected left to be null');
        Assert.isNull(idNode.right, 'Expected right to be null');

        Lexer.Node fromNode = head.right;
        Assert.areEqual('from', fromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', fromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(fromNode.left, 'Expected left to be not null');

        Lexer.Node accountNode = fromNode.left;
        Assert.areEqual('account', accountNode.id, 'Expected id to be "account"');
        Assert.areEqual('object', accountNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(accountNode.left, 'Expected left to be null');
        Assert.isNull(accountNode.right, 'Expected right to be null');

        Lexer.Node whereNode = fromNode.right;
        Assert.areEqual('where', whereNode.id, 'Expected id to be "where"');
        Assert.areEqual('where', whereNode.nodeType, 'Expected nodeType to be "where"');
        Assert.isNotNull(whereNode.left, 'Expected left to be not null');
        Assert.isNull(whereNode.right, 'Expected right to be null');

        Lexer.Node operatorNode = whereNode.left;
        Assert.areEqual('=', operatorNode.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode.right, 'Expected right to not be null');

        Lexer.Node idNode2 = operatorNode.left;
        Assert.areEqual('id', idNode2.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode2.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(idNode2.left, 'Expected left to be null');
        Assert.isNull(idNode2.right, 'Expected right to be null');

        Lexer.Node bindVarNode = operatorNode.right;
        Assert.areEqual('id', bindVarNode.id, 'Expected id to be "id"');
        Assert.areEqual('bind variable', bindVarNode.nodeType, 'Expected nodeType to be "bind variable"');
        Assert.isNull(bindVarNode.left, 'Expected left to be null');
        Assert.isNull(bindVarNode.right, 'Expected right to be null');

    }

    @IsTest
    public static void testAndStatements() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id FROM Contact WHERE FirstName = \'test\' AND LastName = \'test2\' AND Account.Name = \'testAcct\'');
        
        Assert.areEqual('select', head.id, 'Expected id to be "select"');
        Assert.areEqual('select', head.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(head.left, 'Expected left to be not null');
        Assert.isNotNull(head.right, 'Expected right to be not null');

        Lexer.Node idNode = head.left;
        Assert.areEqual('id', idNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(idNode.left, 'Expected left to be null');
        Assert.isNull(idNode.right, 'Expected right to be null');

        Lexer.Node fromNode = head.right;
        Assert.areEqual('from', fromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', fromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(fromNode.left, 'Expected left to be not null');
        Assert.isNotNull(fromNode.right, 'Expected right to be not null');

        Lexer.Node contactNode = fromNode.left;
        Assert.areEqual('contact', contactNode.id, 'Expected id to be "contact"');
        Assert.areEqual('object', contactNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(contactNode.left, 'Expected left to be null');
        Assert.isNull(contactNode.right, 'Expected right to be null');

        Lexer.Node whereNode = fromNode.right;
        Assert.areEqual('where', whereNode.id, 'Expected id to be "where"');
        Assert.areEqual('where', whereNode.nodeType, 'Expected nodeType to be "where"');
        Assert.isNotNull(whereNode.left, 'Expected left to be not null');
        Assert.isNull(whereNode.right, 'Expected right to be null');

        Lexer.Node andNode = whereNode.left;
        Assert.areEqual('and', andNode.id, 'Expected id to be "and"');
        Assert.areEqual('and', andNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(andNode.left, 'Expected left to not be null');
        Assert.isNotNull(andNode.right, 'Expected right to not be null');

        Lexer.Node operatorNode = andNode.left;
        Assert.areEqual('=', operatorNode.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode.right, 'Expected right to not be null');

        Lexer.Node firstNameNode = operatorNode.left;
        Assert.areEqual('firstname', firstNameNode.id, 'Expected id to be "firstname"');
        Assert.areEqual('field', firstNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(firstNameNode.left, 'Expected left to be null');
        Assert.isNull(firstNameNode.right, 'Expected right to be null');

        Lexer.Node valueNode = operatorNode.right;
        Assert.areEqual('test', valueNode.id, 'Expected id to be "test"');
        Assert.areEqual('string', valueNode.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode.left, 'Expected left to be null');
        Assert.isNull(valueNode.right, 'Expected right to be null');

        Lexer.Node andNode2 = andNode.right;
        Assert.areEqual('and', andNode2.id, 'Expected id to be "and"');
        Assert.areEqual('and', andNode2.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(andNode2.left, 'Expected left to not be null');
        Assert.isNotNull(andNode2.right, 'Expected right to not be null');

        Lexer.Node operatorNode2 = andNode2.left;
        Assert.areEqual('=', operatorNode2.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode2.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode2.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode2.right, 'Expected right to not be null');

        Lexer.Node lastNameNode = operatorNode2.left;
        Assert.areEqual('lastname', lastNameNode.id, 'Expected id to be "lastname"');
        Assert.areEqual('field', lastNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(lastNameNode.left, 'Expected left to be null');
        Assert.isNull(lastNameNode.right, 'Expected right to be null');

        Lexer.Node valueNode2 = operatorNode2.right;
        Assert.areEqual('test2', valueNode2.id, 'Expected id to be "test2"');
        Assert.areEqual('string', valueNode2.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode2.left, 'Expected left to be null');
        Assert.isNull(valueNode2.right, 'Expected right to be null');

        Lexer.Node operatorNode3 = andNode2.right;
        Assert.areEqual('=', operatorNode3.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode3.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode3.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode3.right, 'Expected right to not be null');

        Lexer.Node accountNameNode = operatorNode3.left;
        Assert.areEqual('account.name', accountNameNode.id, 'Expected id to be "account.name"');
        Assert.areEqual('field', accountNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(accountNameNode.left, 'Expected left to be null');
        Assert.isNull(accountNameNode.right, 'Expected right to be null');

        Lexer.Node valueNode3 = operatorNode3.right;
        Assert.areEqual('testacct', valueNode3.id, 'Expected id to be "testacct"');
        Assert.areEqual('string', valueNode3.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode3.left, 'Expected left to be null');
        Assert.isNull(valueNode3.right, 'Expected right to be null');
    }

    @IsTest
    public static void testQueryWithOrAnd() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id FROM Contact WHERE FirstName = \'test\' OR LastName = \'test2\' AND Account.Name = \'testAcct\'');

        Assert.areEqual('select', head.id, 'Expected id to be "select"');
        Assert.areEqual('select', head.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(head.left, 'Expected left to be not null');
        Assert.isNotNull(head.right, 'Expected right to be not null');

        Lexer.Node idNode = head.left;
        Assert.areEqual('id', idNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(idNode.left, 'Expected left to be null');
        Assert.isNull(idNode.right, 'Expected right to be null');

        Lexer.Node fromNode = head.right;
        Assert.areEqual('from', fromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', fromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(fromNode.left, 'Expected left to be not null');
        Assert.isNotNull(fromNode.right, 'Expected right to be not null');

        Lexer.Node contactNode = fromNode.left;
        Assert.areEqual('contact', contactNode.id, 'Expected id to be "contact"');
        Assert.areEqual('object', contactNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(contactNode.left, 'Expected left to be null');
        Assert.isNull(contactNode.right, 'Expected right to be null');

        Lexer.Node whereNode = fromNode.right;
        Assert.areEqual('where', whereNode.id, 'Expected id to be "where"');
        Assert.areEqual('where', whereNode.nodeType, 'Expected nodeType to be "where"');
        Assert.isNotNull(whereNode.left, 'Expected left to be not null');
        Assert.isNull(whereNode.right, 'Expected right to be null');

        Lexer.Node orNode = whereNode.left;
        Assert.areEqual('or', orNode.id, 'Expected id to be "or"');
        Assert.areEqual('or', orNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(orNode.left, 'Expected left to not be null');
        Assert.isNotNull(orNode.right, 'Expected right to not be null');

        Lexer.Node operatorNode = orNode.left;
        Assert.areEqual('=', operatorNode.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode.right, 'Expected right to not be null');

        Lexer.Node firstNameNode = operatorNode.left;
        Assert.areEqual('firstname', firstNameNode.id, 'Expected id to be "firstname"');
        Assert.areEqual('field', firstNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(firstNameNode.left, 'Expected left to be null');
        Assert.isNull(firstNameNode.right, 'Expected right to be null');

        Lexer.Node valueNode = operatorNode.right;
        Assert.areEqual('test', valueNode.id, 'Expected id to be "test"');
        Assert.areEqual('string', valueNode.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode.left, 'Expected left to be null');
        Assert.isNull(valueNode.right, 'Expected right to be null');

        Lexer.Node andNode = orNode.right;
        Assert.areEqual('and', andNode.id, 'Expected id to be "and"');
        Assert.areEqual('and', andNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(andNode.left, 'Expected left to not be null');
        Assert.isNotNull(andNode.right, 'Expected right to not be null');

        Lexer.Node operatorNode2 = andNode.left;
        Assert.areEqual('=', operatorNode2.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode2.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode2.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode2.right, 'Expected right to not be null');

        Lexer.Node lastNameNode = operatorNode2.left;
        Assert.areEqual('lastname', lastNameNode.id, 'Expected id to be "lastname"');
        Assert.areEqual('field', lastNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(lastNameNode.left, 'Expected left to be null');
        Assert.isNull(lastNameNode.right, 'Expected right to be null');

        Lexer.Node valueNode2 = operatorNode2.right;
        Assert.areEqual('test2', valueNode2.id, 'Expected id to be "test2"');
        Assert.areEqual('string', valueNode2.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode2.left, 'Expected left to be null');
        Assert.isNull(valueNode2.right, 'Expected right to be null');

        Lexer.Node operatorNode3 = andNode.right;
        Assert.areEqual('=', operatorNode3.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode3.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode3.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode3.right, 'Expected right to not be null');

        Lexer.Node accountNameNode = operatorNode3.left;
        Assert.areEqual('account.name', accountNameNode.id, 'Expected id to be "account.name"');
        Assert.areEqual('field', accountNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(accountNameNode.left, 'Expected left to be null');
        Assert.isNull(accountNameNode.right, 'Expected right to be null');

        Lexer.Node valueNode3 = operatorNode3.right;
        Assert.areEqual('testacct', valueNode3.id, 'Expected id to be "testacct"');
        Assert.areEqual('string', valueNode3.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode3.left, 'Expected left to be null');
        Assert.isNull(valueNode3.right, 'Expected right to be null');

        
    }

    @IsTest
    public static void testNot() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id FROM Contact WHERE NOT FirstName = \'test\'');

        Assert.areEqual('select', head.id, 'Expected id to be "select"');
        Assert.areEqual('select', head.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(head.left, 'Expected left to be not null');
        Assert.isNotNull(head.right, 'Expected right to be not null');

        Lexer.Node idNode = head.left;
        Assert.areEqual('id', idNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(idNode.left, 'Expected left to be null');
        Assert.isNull(idNode.right, 'Expected right to be null');

        Lexer.Node fromNode = head.right;
        Assert.areEqual('from', fromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', fromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(fromNode.left, 'Expected left to be not null');
        Assert.isNotNull(fromNode.right, 'Expected right to be not null');

        Lexer.Node contactNode = fromNode.left;
        Assert.areEqual('contact', contactNode.id, 'Expected id to be "contact"');
        Assert.areEqual('object', contactNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(contactNode.left, 'Expected left to be null');
        Assert.isNull(contactNode.right, 'Expected right to be null');

        Lexer.Node whereNode = fromNode.right;
        Assert.areEqual('where', whereNode.id, 'Expected id to be "where"');
        Assert.areEqual('where', whereNode.nodeType, 'Expected nodeType to be "where"');
        Assert.isNotNull(whereNode.left, 'Expected left to be not null');
        Assert.isNull(whereNode.right, 'Expected right to be null');

        Lexer.Node notNode = whereNode.left;
        Assert.areEqual('not', notNode.id, 'Expected id to be "not"');
        Assert.areEqual('not', notNode.nodeType, 'Expected nodeType to be "not"');
        Assert.isNotNull(notNode.left, 'Expected left to be not null');
        Assert.isNull(notNode.right, 'Expected right to be null');

        Lexer.Node operatorNode = notNode.left;
        Assert.areEqual('=', operatorNode.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode.right, 'Expected right to not be null');

        Lexer.Node firstNameNode = operatorNode.left;
        Assert.areEqual('firstname', firstNameNode.id, 'Expected id to be "firstname"');
        Assert.areEqual('field', firstNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(firstNameNode.left, 'Expected left to be null');
        Assert.isNull(firstNameNode.right, 'Expected right to be null');

        Lexer.Node valueNode = operatorNode.right;
        Assert.areEqual('test', valueNode.id, 'Expected id to be "test"');
        Assert.areEqual('string', valueNode.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode.left, 'Expected left to be null');
        Assert.isNull(valueNode.right, 'Expected right to be null');
    }

    @IsTest
    public static void testCorrectsForAndWithOr() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id FROM Contact WHERE FirstName = \'test\' OR LastName = \'test2\' AND Account.Name = \'testAcct\' OR Account.Name = \'testAcct2\'');

        Assert.areEqual('select', head.id, 'Expected id to be "select"');
        Assert.areEqual('select', head.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(head.left, 'Expected left to be not null');
        Assert.isNotNull(head.right, 'Expected right to be not null');

        Lexer.Node idNode = head.left;
        Assert.areEqual('id', idNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(idNode.left, 'Expected left to be null');
        Assert.isNull(idNode.right, 'Expected right to be null');

        Lexer.Node fromNode = head.right;
        Assert.areEqual('from', fromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', fromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(fromNode.left, 'Expected left to be not null');
        Assert.isNotNull(fromNode.right, 'Expected right to be not null');

        Lexer.Node contactNode = fromNode.left;
        Assert.areEqual('contact', contactNode.id, 'Expected id to be "contact"');
        Assert.areEqual('object', contactNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(contactNode.left, 'Expected left to be null');
        Assert.isNull(contactNode.right, 'Expected right to be null');

        Lexer.Node whereNode = fromNode.right;
        Assert.areEqual('where', whereNode.id, 'Expected id to be "where"');
        Assert.areEqual('where', whereNode.nodeType, 'Expected nodeType to be "where"');
        Assert.isNotNull(whereNode.left, 'Expected left to be not null');
        Assert.isNull(whereNode.right, 'Expected right to be null');

        Lexer.Node orNode = whereNode.left;
        Assert.areEqual('or', orNode.id, 'Expected id to be "or"');
        Assert.areEqual('or', orNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(orNode.left, 'Expected left to not be null');
        Assert.isNotNull(orNode.right, 'Expected right to not be null');

        Lexer.Node orNode2 = orNode.left;
        Assert.areEqual('or', orNode2.id, 'Expected id to be "or"');
        Assert.areEqual('or', orNode2.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(orNode2.left, 'Expected left to not be null');
        Assert.isNotNull(orNode2.right, 'Expected right to not be null');

        Lexer.Node operatorNode = orNode2.left;
        Assert.areEqual('=', operatorNode.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode.right, 'Expected right to not be null');

        Lexer.Node firstNameNode = operatorNode.left;
        Assert.areEqual('firstname', firstNameNode.id, 'Expected id to be "firstname"');
        Assert.areEqual('field', firstNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(firstNameNode.left, 'Expected left to be null');
        Assert.isNull(firstNameNode.right, 'Expected right to be null');

        Lexer.Node valueNode = operatorNode.right;
        Assert.areEqual('test', valueNode.id, 'Expected id to be "test"');
        Assert.areEqual('string', valueNode.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode.left, 'Expected left to be null');
        Assert.isNull(valueNode.right, 'Expected right to be null');

        Lexer.Node andNode = orNode2.right;
        Assert.areEqual('and', andNode.id, 'Expected id to be "and"');
        Assert.areEqual('and', andNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(andNode.left, 'Expected left to not be null');
        Assert.isNotNull(andNode.right, 'Expected right to not be null');

        Lexer.Node operatorNode2 = andNode.left;
        Assert.areEqual('=', operatorNode2.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode2.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode2.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode2.right, 'Expected right to not be null');

        Lexer.Node lastNameNode = operatorNode2.left;
        Assert.areEqual('lastname', lastNameNode.id, 'Expected id to be "lastname"');
        Assert.areEqual('field', lastNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(lastNameNode.left, 'Expected left to be null');
        Assert.isNull(lastNameNode.right, 'Expected right to be null');

        Lexer.Node valueNode2 = operatorNode2.right;
        Assert.areEqual('test2', valueNode2.id, 'Expected id to be "test2"');
        Assert.areEqual('string', valueNode2.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode2.left, 'Expected left to be null');
        Assert.isNull(valueNode2.right, 'Expected right to be null');

        Lexer.Node operatorNode3 = andNode.right;
        Assert.areEqual('=', operatorNode3.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode3.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode3.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode3.right, 'Expected right to not be null');

        Lexer.Node accountNameNode = operatorNode3.left;
        Assert.areEqual('account.name', accountNameNode.id, 'Expected id to be "account.name"');
        Assert.areEqual('field', accountNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(accountNameNode.left, 'Expected left to be null');
        Assert.isNull(accountNameNode.right, 'Expected right to be null');

        Lexer.Node valueNode3 = operatorNode3.right;
        Assert.areEqual('testacct', valueNode3.id, 'Expected id to be "testacct"');
        Assert.areEqual('string', valueNode3.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode3.left, 'Expected left to be null');
        Assert.isNull(valueNode3.right, 'Expected right to be null');

        Lexer.Node operatorNode4 = orNode.right;
        Assert.areEqual('=', operatorNode4.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode4.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode4.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode4.right, 'Expected right to not be null');

        Lexer.Node accountNameNode2 = operatorNode4.left;
        Assert.areEqual('account.name', accountNameNode2.id, 'Expected id to be "account.name"');
        Assert.areEqual('field', accountNameNode2.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(accountNameNode2.left, 'Expected left to be null');
        Assert.isNull(accountNameNode2.right, 'Expected right to be null');

        Lexer.Node valueNode4 = operatorNode4.right;
        Assert.areEqual('testacct2', valueNode4.id, 'Expected id to be "testacct2"');
        Assert.areEqual('string', valueNode4.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode4.left, 'Expected left to be null');
        Assert.isNull(valueNode4.right, 'Expected right to be null');
    }

    @IsTest
    public static void testCorrectsForAndWithOrWithSubExpr() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id FROM Contact WHERE FirstName = \'test\' AND LastName = \'test2\' OR (Account.Name = \'testAcct\' AND Account.Name = \'testAcct2\' OR Account.Name = \'testAcct3\')');

        Assert.areEqual('select', head.id, 'Expected id to be "select"');
        Assert.areEqual('select', head.nodeType, 'Expected nodeType to be "select"');
        Assert.isNotNull(head.left, 'Expected left to be not null');
        Assert.isNotNull(head.right, 'Expected right to be not null');

        Lexer.Node idNode = head.left;
        Assert.areEqual('id', idNode.id, 'Expected id to be "id"');
        Assert.areEqual('field', idNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(idNode.left, 'Expected left to be null');
        Assert.isNull(idNode.right, 'Expected right to be null');

        Lexer.Node fromNode = head.right;
        Assert.areEqual('from', fromNode.id, 'Expected id to be "from"');
        Assert.areEqual('from', fromNode.nodeType, 'Expected nodeType to be "from"');
        Assert.isNotNull(fromNode.left, 'Expected left to be not null');
        Assert.isNotNull(fromNode.right, 'Expected right to be not null');

        Lexer.Node contactNode = fromNode.left;
        Assert.areEqual('contact', contactNode.id, 'Expected id to be "contact"');
        Assert.areEqual('object', contactNode.nodeType, 'Expected nodeType to be "object"');
        Assert.isNull(contactNode.left, 'Expected left to be null');
        Assert.isNull(contactNode.right, 'Expected right to be null');

        Lexer.Node whereNode = fromNode.right;
        Assert.areEqual('where', whereNode.id, 'Expected id to be "where"');
        Assert.areEqual('where', whereNode.nodeType, 'Expected nodeType to be "where"');
        Assert.isNotNull(whereNode.left, 'Expected left to be not null');
        Assert.isNull(whereNode.right, 'Expected right to be null');

        Lexer.Node orNode = whereNode.left;
        Assert.areEqual('or', orNode.id, 'Expected id to be "or"');
        Assert.areEqual('or', orNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(orNode.left, 'Expected left to not be null');
        Assert.isNotNull(orNode.right, 'Expected right to not be null');

        Lexer.Node andNode = orNode.left;
        Assert.areEqual('and', andNode.id, 'Expected id to be "and"');
        Assert.areEqual('and', andNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(andNode.left, 'Expected left to not be null');
        Assert.isNotNull(andNode.right, 'Expected right to not be null');

        Lexer.Node operatorNode = andNode.left;
        Assert.areEqual('=', operatorNode.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode.right, 'Expected right to not be null');

        Lexer.Node firstNameNode = operatorNode.left;
        Assert.areEqual('firstname', firstNameNode.id, 'Expected id to be "firstname"');
        Assert.areEqual('field', firstNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(firstNameNode.left, 'Expected left to be null');
        Assert.isNull(firstNameNode.right, 'Expected right to be null');

        Lexer.Node valueNode = operatorNode.right;
        Assert.areEqual('test', valueNode.id, 'Expected id to be "test"');
        Assert.areEqual('string', valueNode.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode.left, 'Expected left to be null');
        Assert.isNull(valueNode.right, 'Expected right to be null');

        Lexer.Node operatorNode2 = andNode.right;
        Assert.areEqual('=', operatorNode2.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode2.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode2.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode2.right, 'Expected right to not be null');

        Lexer.Node lastNameNode = operatorNode2.left;
        Assert.areEqual('lastname', lastNameNode.id, 'Expected id to be "lastname"');
        Assert.areEqual('field', lastNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(lastNameNode.left, 'Expected left to be null');
        Assert.isNull(lastNameNode.right, 'Expected right to be null');

        Lexer.Node valueNode2 = operatorNode2.right;
        Assert.areEqual('test2', valueNode2.id, 'Expected id to be "test2"');
        Assert.areEqual('string', valueNode2.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode2.left, 'Expected left to be null');
        Assert.isNull(valueNode2.right, 'Expected right to be null');

        Lexer.Node subExprNode2 = orNode.right;
        Assert.areEqual('conditional subexpression', subExprNode2.id, 'Expected id to be "conditional subexpression"');
        Assert.areEqual('conditional subexpression', subExprNode2.nodeType, 'Expected nodeType to be "conditional subexpression"');
        Assert.isNotNull(subExprNode2.left, 'Expected left to not be null');
        Assert.isNull(subExprNode2.right, 'Expected right to be null');

        Lexer.Node orNode2 = subExprNode2.left;
        Assert.areEqual('or', orNode2.id, 'Expected id to be "or"');
        Assert.areEqual('or', orNode2.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(orNode2.left, 'Expected left to not be null');
        Assert.isNotNull(orNode2.right, 'Expected right to not be null');

        Lexer.Node andNode2 = orNode2.left;
        Assert.areEqual('and', andNode2.id, 'Expected id to be "and"');
        Assert.areEqual('and', andNode2.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(andNode2.left, 'Expected left to not be null');
        Assert.isNotNull(andNode2.right, 'Expected right to not be null');

        Lexer.Node operatorNode3 = andNode2.left;
        Assert.areEqual('=', operatorNode3.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode3.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode3.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode3.right, 'Expected right to not be null');

        Lexer.Node accountNameNode = operatorNode3.left;
        Assert.areEqual('account.name', accountNameNode.id, 'Expected id to be "account.name"');
        Assert.areEqual('field', accountNameNode.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(accountNameNode.left, 'Expected left to be null');
        Assert.isNull(accountNameNode.right, 'Expected right to be null');

        Lexer.Node valueNode3 = operatorNode3.right;
        Assert.areEqual('testacct', valueNode3.id, 'Expected id to be "testacct"');
        Assert.areEqual('string', valueNode3.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode3.left, 'Expected left to be null');
        Assert.isNull(valueNode3.right, 'Expected right to be null');

        Lexer.Node operatorNode4 = andNode2.right;
        Assert.areEqual('=', operatorNode4.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode4.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode4.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode4.right, 'Expected right to not be null');

        Lexer.Node accountNameNode2 = operatorNode4.left;
        Assert.areEqual('account.name', accountNameNode2.id, 'Expected id to be "account.name"');
        Assert.areEqual('field', accountNameNode2.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(accountNameNode2.left, 'Expected left to be null');
        Assert.isNull(accountNameNode2.right, 'Expected right to be null');

        Lexer.Node valueNode4 = operatorNode4.right;
        Assert.areEqual('testacct2', valueNode4.id, 'Expected id to be "testacct2"');
        Assert.areEqual('string', valueNode4.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode4.left, 'Expected left to be null');
        Assert.isNull(valueNode4.right, 'Expected right to be null');

        Lexer.Node operatorNode5 = orNode2.right;
        Assert.areEqual('=', operatorNode5.id, 'Expected id to be "operator"');
        Assert.areEqual('operator', operatorNode5.nodeType, 'Expected nodeType to be "operator"');
        Assert.isNotNull(operatorNode5.left, 'Expected left to not be null');
        Assert.isNotNull(operatorNode5.right, 'Expected right to not be null');

        Lexer.Node accountNameNode3 = operatorNode5.left;
        Assert.areEqual('account.name', accountNameNode3.id, 'Expected id to be "account.name"');
        Assert.areEqual('field', accountNameNode3.nodeType, 'Expected nodeType to be "field"');
        Assert.isNull(accountNameNode3.left, 'Expected left to be null');
        Assert.isNull(accountNameNode3.right, 'Expected right to be null');

        Lexer.Node valueNode5 = operatorNode5.right;
        Assert.areEqual('testacct3', valueNode5.id, 'Expected id to be "testacct3"');
        Assert.areEqual('string', valueNode5.nodeType, 'Expected nodeType to be "string"');
        Assert.isNull(valueNode5.left, 'Expected left to be null');
        Assert.isNull(valueNode5.right, 'Expected right to be null');

    }

    @IsTest
    public static void testAlias() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT COUNT(Id) cnt1 FROM Account GROUP BY Id');

        AssertNode assertSelect = new AssertNodeBuilder()
            .setNode(head)
            .setId('select')
            .setNodeType('select')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertSelect.doAssert();

        Lexer.Node countNode = head.left;
        AssertNode assertCount = new AssertNodeBuilder()
            .setNode(countNode)
            .setId('count')
            .setNodeType('aggregate function')
            .setIsLeftNull(true)
            .setIsRightNull(false)
            .build();
        assertCount.doAssert();

        Lexer.Node idNode = countNode.right;
        AssertNode assertId = new AssertNodeBuilder()
            .setNode(idNode)
            .setId('id')
            .setNodeType('field')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertId.doAssert();

        Lexer.Node aliasNode = idNode.left;
        AssertNode assertAlias = new AssertNodeBuilder()
            .setNode(aliasNode)
            .setId('cnt1')
            .setNodeType('alias')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertAlias.doAssert();

        Lexer.Node fromNode = head.right;
        AssertNode assertFrom = new AssertNodeBuilder()
            .setNode(fromNode)
            .setId('from')
            .setNodeType('from')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertFrom.doAssert();

        Lexer.Node accountNode = fromNode.left;
        AssertNode assertAccount = new AssertNodeBuilder()
            .setNode(accountNode)
            .setId('account')
            .setNodeType('object')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertAccount.doAssert();

        Lexer.Node groupByNode = fromNode.right;
        AssertNode assertGroupBy = new AssertNodeBuilder()
            .setNode(groupByNode)
            .setId('group by')
            .setNodeType('group by')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertGroupBy.doAssert();

        Lexer.Node idNode2 = groupByNode.left;
        AssertNode assertId2 = new AssertNodeBuilder()
            .setNode(idNode2)
            .setId('id')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertId2.doAssert();
    }

    @IsTest
    public static void testParseValueList() {
        Lexer t = new Lexer();

        Lexer.Node head = t.parse('SELECT Id FROM Contact WHERE FirstName IN (\'test\', \'test2\')');
        AssertNode assertSelect = new AssertNodeBuilder()
            .setNode(head)
            .setId('select')
            .setNodeType('select')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertSelect.doAssert();

        Lexer.Node idNode = head.left;
        AssertNode assertId = new AssertNodeBuilder()
            .setNode(idNode)
            .setId('id')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertId.doAssert();

        Lexer.Node fromNode = head.right;
        AssertNode assertFrom = new AssertNodeBuilder()
            .setNode(fromNode)
            .setId('from')
            .setNodeType('from')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertFrom.doAssert();

        Lexer.Node contactNode = fromNode.left;
        AssertNode assertContact = new AssertNodeBuilder()
            .setNode(contactNode)
            .setId('contact')
            .setNodeType('object')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertContact.doAssert();

        Lexer.Node whereNode = fromNode.right;
        AssertNode assertWhere = new AssertNodeBuilder()
            .setNode(whereNode)
            .setId('where')
            .setNodeType('where')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertWhere.doAssert();

        Lexer.Node inNode = whereNode.left;
        AssertNode assertIn = new AssertNodeBuilder()
            .setNode(inNode)
            .setId('in')
            .setNodeType('operator')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertIn.doAssert();

        Lexer.Node firstNameNode = inNode.left;
        AssertNode assertFirstName = new AssertNodeBuilder()
            .setNode(firstNameNode)
            .setId('firstname')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertFirstName.doAssert();

        Lexer.Node valueListNode = inNode.right;
        AssertNode assertValueList = new AssertNodeBuilder()
            .setNode(valueListNode)
            .setId('value list')
            .setNodeType('value list')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertValueList.doAssert();

        Lexer.Node valueNode = valueListNode.left;
        AssertNode assertValue = new AssertNodeBuilder()
            .setNode(valueNode)
            .setId('test')
            .setNodeType('string')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertValue.doAssert();

        Lexer.Node valueListNode2 = valueNode.left;
        AssertNode assertValueList2 = new AssertNodeBuilder()
            .setNode(valueListNode2)
            .setId('value list')
            .setNodeType('value list')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertValueList2.doAssert();

        Lexer.Node valueNode2 = valueListNode2.left;
        AssertNode assertValue2 = new AssertNodeBuilder()
            .setNode(valueNode2)
            .setId('test2')
            .setNodeType('string')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertValue2.doAssert();
    }

    @IsTest
    public static void testSingularCount() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT COUNT() FROM Account');
        AssertNode assertSelect = new AssertNodeBuilder()
            .setNode(head)
            .setId('select')
            .setNodeType('select')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertSelect.doAssert();

        Lexer.Node countNode = head.left;

        AssertNode assertCount = new AssertNodeBuilder()
            .setNode(countNode)
            .setId('count')
            .setNodeType('aggregate function')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertCount.doAssert();

        Lexer.Node fromNode = head.right;

        AssertNode assertFrom = new AssertNodeBuilder()
            .setNode(fromNode)
            .setId('from')
            .setNodeType('from')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertFrom.doAssert();

        Lexer.Node accountNode = fromNode.left;
        AssertNode assertAccount = new AssertNodeBuilder()
            .setNode(accountNode)
            .setId('account')
            .setNodeType('object')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertAccount.doAssert();

    }

    @IsTest
    public static void testSimpleAlias() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id id FROM Account');
        AssertNode assertSelect = new AssertNodeBuilder()
            .setNode(head)
            .setId('select')
            .setNodeType('select')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertSelect.doAssert();

        Lexer.Node idNode = head.left;
        AssertNode assertId = new AssertNodeBuilder()
            .setNode(idNode)
            .setId('id')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(false)
            .build();
        assertId.doAssert();

        Lexer.Node idAliasNode = idNode.right;
        AssertNode assertIdAlias = new AssertNodeBuilder()
            .setNode(idAliasNode)
            .setId('id')
            .setNodeType('alias')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertIdAlias.doAssert();

        Lexer.Node fromNode = head.right;
        AssertNode assertFrom = new AssertNodeBuilder()
            .setNode(fromNode)
            .setId('from')
            .setNodeType('from')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertFrom.doAssert();

        Lexer.Node accountNode = fromNode.left;
        AssertNode assertAccount = new AssertNodeBuilder()
            .setNode(accountNode)
            .setId('account')
            .setNodeType('object')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertAccount.doAssert();
    }

    @IsTest
    public static void testAliases() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Account.Name acctName, Name, COUNT(Id) FROM Contact GROUP BY Name, Account.Name');
        AssertNode assertSelect = new AssertNodeBuilder()
            .setNode(head)
            .setId('select')
            .setNodeType('select')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertSelect.doAssert();

        Lexer.Node accountNameNode = head.left;
        AssertNode assertAccountName = new AssertNodeBuilder()
            .setNode(accountNameNode)
            .setId('account.name')
            .setNodeType('field')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertAccountName.doAssert();

        Lexer.Node acctNameNode = accountNameNode.right;
        AssertNode assertAcctName = new AssertNodeBuilder()
            .setNode(acctNameNode)
            .setId('acctname')
            .setNodeType('alias')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertAcctName.doAssert();

        Lexer.Node nameNode = accountNameNode.left;
        AssertNode assertName = new AssertNodeBuilder()
            .setNode(nameNode)
            .setId('name')
            .setNodeType('field')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertName.doAssert();

        Lexer.Node countNode = nameNode.left;
        AssertNode assertCount = new AssertNodeBuilder()
            .setNode(countNode)
            .setId('count')
            .setNodeType('aggregate function')
            .setIsLeftNull(true)
            .setIsRightNull(false)
            .build();
        assertCount.doAssert();

        Lexer.Node idNode = countNode.right;
        AssertNode assertId = new AssertNodeBuilder()
            .setNode(idNode)
            .setId('id')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertId.doAssert();

        Lexer.Node fromNode = head.right;
        AssertNode assertFrom = new AssertNodeBuilder()
            .setNode(fromNode)
            .setId('from')
            .setNodeType('from')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertFrom.doAssert();

        Lexer.Node contactNode = fromNode.left;
        AssertNode assertContact = new AssertNodeBuilder()
            .setNode(contactNode)
            .setId('contact')
            .setNodeType('object')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertContact.doAssert();

        Lexer.Node groupByNode = fromNode.right;
        AssertNode assertGroupBy = new AssertNodeBuilder()
            .setNode(groupByNode)
            .setId('group by')
            .setNodeType('group by')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertGroupBy.doAssert();

        Lexer.Node nameNode2 = groupByNode.left;
        AssertNode assertName2 = new AssertNodeBuilder()
            .setNode(nameNode2)
            .setId('name')
            .setNodeType('field')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertName2.doAssert();

        Lexer.Node accountNameNode2 = nameNode2.left;
        AssertNode assertAccountName2 = new AssertNodeBuilder()
            .setNode(accountNameNode2)
            .setId('account.name')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertAccountName2.doAssert();
    }

    @IsTest
    public static void testSubQueryNoAlias() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id, Name, (SELECT Id, FirstName, LastName FROM Contacts) FROM Account');
        AssertNode assertSelect = new AssertNodeBuilder()
            .setNode(head)
            .setId('select')
            .setNodeType('select')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertSelect.doAssert();

        Lexer.Node idNode = head.left;
        AssertNode assertId = new AssertNodeBuilder()
            .setNode(idNode)
            .setId('id')
            .setNodeType('field')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertId.doAssert();

        Lexer.Node nameNode = idNode.left;
        AssertNode assertName = new AssertNodeBuilder()
            .setNode(nameNode)
            .setId('name')
            .setNodeType('field')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertName.doAssert();

        Lexer.Node subQueryNode = nameNode.left;
        AssertNode assertSubQuery = new AssertNodeBuilder()
            .setNode(subQueryNode)
            .setId('subquery')
            .setNodeType('subquery')
            .setIsLeftNull(true)
            .setIsRightNull(false)
            .build();
        assertSubQuery.doAssert();

        Lexer.Node selectNode2 = subQueryNode.right;
        AssertNode assertSelect2 = new AssertNodeBuilder()
            .setNode(selectNode2)
            .setId('select')
            .setNodeType('select')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertSelect2.doAssert();

        Lexer.Node idNode2 = selectNode2.left;
        AssertNode assertId2 = new AssertNodeBuilder()
            .setNode(idNode2)
            .setId('id')
            .setNodeType('field')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertId2.doAssert();

        Lexer.Node firstNameNode = idNode2.left;
        AssertNode assertFirstName = new AssertNodeBuilder()
            .setNode(firstNameNode)
            .setId('firstname')
            .setNodeType('field')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertFirstName.doAssert();

        Lexer.Node lastNameNode = firstNameNode.left;
        AssertNode assertLastName = new AssertNodeBuilder()
            .setNode(lastNameNode)
            .setId('lastname')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertLastName.doAssert();

        Lexer.Node fromNode = selectNode2.right;
        AssertNode assertFrom = new AssertNodeBuilder()
            .setNode(fromNode)
            .setId('from')
            .setNodeType('from')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertFrom.doAssert();

        Lexer.Node contactsNode = fromNode.left;
        AssertNode assertContacts = new AssertNodeBuilder()
            .setNode(contactsNode)
            .setId('contacts')
            .setNodeType('object')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertContacts.doAssert();

        Lexer.Node fromNode2 = head.right;
        AssertNode assertFrom2 = new AssertNodeBuilder()
            .setNode(fromNode2)
            .setId('from')
            .setNodeType('from')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertFrom2.doAssert();

        Lexer.Node accountNode = fromNode2.left;
        AssertNode assertAccount = new AssertNodeBuilder()
            .setNode(accountNode)
            .setId('account')
            .setNodeType('object')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertAccount.doAssert();
    }

    @IsTest
    public static void testHavingClauseWithMultipleConditions() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Name, COUNT(Id) FROM Account GROUP BY Name HAVING COUNT(Id) > 1 AND COUNT(Id) < 10');
        AssertNode assertSelect = new AssertNodeBuilder()
            .setNode(head)
            .setId('select')
            .setNodeType('select')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertSelect.doAssert();

        Lexer.Node nameNode = head.left;
        AssertNode assertName = new AssertNodeBuilder()
            .setNode(nameNode)
            .setId('name')
            .setNodeType('field')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertName.doAssert();

        Lexer.Node countNode = nameNode.left;
        AssertNode assertCount = new AssertNodeBuilder()
            .setNode(countNode)
            .setId('count')
            .setNodeType('aggregate function')
            .setIsLeftNull(true)
            .setIsRightNull(false)
            .build();
        assertCount.doAssert();

        Lexer.Node idNode = countNode.right;
        AssertNode assertId = new AssertNodeBuilder()
            .setNode(idNode)
            .setId('id')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertId.doAssert();

        Lexer.Node fromNode = head.right;
        AssertNode assertFrom = new AssertNodeBuilder()
            .setNode(fromNode)
            .setId('from')
            .setNodeType('from')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertFrom.doAssert();

        Lexer.Node accountNode = fromNode.left;
        AssertNode assertAccount = new AssertNodeBuilder()
            .setNode(accountNode)
            .setId('account')
            .setNodeType('object')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertAccount.doAssert();

        Lexer.Node groupByNode = fromNode.right;
        AssertNode assertGroupBy = new AssertNodeBuilder()
            .setNode(groupByNode)
            .setId('group by')
            .setNodeType('group by')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertGroupBy.doAssert();

        Lexer.Node nameNode2 = groupByNode.left;
        AssertNode assertName2 = new AssertNodeBuilder()
            .setNode(nameNode2)
            .setId('name')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertName2.doAssert();

        Lexer.Node havingNode = groupByNode.right;
        AssertNode assertHaving = new AssertNodeBuilder()
            .setNode(havingNode)
            .setId('having')
            .setNodeType('having')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertHaving.doAssert();

        Lexer.Node andNode = havingNode.left;
        AssertNode assertAnd = new AssertNodeBuilder()
            .setNode(andNode)
            .setId('and')
            .setNodeType('and')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertAnd.doAssert();

        Lexer.Node operatorNode = andNode.left;
        AssertNode assertOperator = new AssertNodeBuilder()
            .setNode(operatorNode)
            .setId('>')
            .setNodeType('operator')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertOperator.doAssert();

        Lexer.Node countNode2 = operatorNode.left;
        AssertNode assertCount2 = new AssertNodeBuilder()
            .setNode(countNode2)
            .setId('count')
            .setNodeType('aggregate function')
            .setIsLeftNull(true)
            .setIsRightNull(false)
            .build();
        assertCount2.doAssert();

        Lexer.Node idNode2 = countNode2.right;
        AssertNode assertId2 = new AssertNodeBuilder()
            .setNode(idNode2)
            .setId('id')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertId2.doAssert();

        Lexer.Node valueNode = operatorNode.right;
        AssertNode assertValue = new AssertNodeBuilder()
            .setNode(valueNode)
            .setId('1')
            .setNodeType('number')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertValue.doAssert();

        Lexer.Node operatorNode2 = andNode.right;
        AssertNode assertOperator2 = new AssertNodeBuilder()
            .setNode(operatorNode2)
            .setId('<')
            .setNodeType('operator')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertOperator2.doAssert();

        Lexer.Node countNode3 = operatorNode2.left;
        AssertNode assertCount3 = new AssertNodeBuilder()
            .setNode(countNode3)
            .setId('count')
            .setNodeType('aggregate function')
            .setIsLeftNull(true)
            .setIsRightNull(false)
            .build();
        assertCount3.doAssert();

        Lexer.Node idNode3 = countNode3.right;
        AssertNode assertId3 = new AssertNodeBuilder()
            .setNode(idNode3)
            .setId('id')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertId3.doAssert();

        Lexer.Node valueNode2 = operatorNode2.right;
        AssertNode assertValue2 = new AssertNodeBuilder()
            .setNode(valueNode2)
            .setId('10')
            .setNodeType('number')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertValue2.doAssert();
    }

    @IsTest
    public static void testHavingClauseWhereAdjust() {
        Lexer l = new Lexer();
        
        Test.startTest();
        Lexer.Node head = l.parse('SELECT Name, SUM(NumberOfEmployees) FROM Account GROUP BY Name HAVING Name = \'Test2\' OR Name = \'Test1\' AND SUM(NumberOfEmployees) > 10');
        Test.stopTest();

        AssertNode assertSelect = new AssertNodeBuilder()
            .setNode(head)
            .setId('select')
            .setNodeType('select')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertSelect.doAssert();

        Lexer.Node nameNode = head.left;
        AssertNode assertName = new AssertNodeBuilder()
            .setNode(nameNode)
            .setId('name')
            .setNodeType('field')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertName.doAssert();

        Lexer.Node sumNode = nameNode.left;
        AssertNode assertSum = new AssertNodeBuilder()
            .setNode(sumNode)
            .setId('sum')
            .setNodeType('aggregate function')
            .setIsLeftNull(true)
            .setIsRightNull(false)
            .build();
        assertSum.doAssert();

        Lexer.Node numberOfEmployeesNode = sumNode.right;
        AssertNode assertNumberOfEmployees = new AssertNodeBuilder()
            .setNode(numberOfEmployeesNode)
            .setId('numberofemployees')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertNumberOfEmployees.doAssert();

        Lexer.Node fromNode = head.right;
        AssertNode assertFrom = new AssertNodeBuilder()
            .setNode(fromNode)
            .setId('from')
            .setNodeType('from')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertFrom.doAssert();

        Lexer.Node accountNode = fromNode.left;
        AssertNode assertAccount = new AssertNodeBuilder()
            .setNode(accountNode)
            .setId('account')
            .setNodeType('object')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertAccount.doAssert();

        Lexer.Node groupByNode = fromNode.right;
        AssertNode assertGroupBy = new AssertNodeBuilder()
            .setNode(groupByNode)
            .setId('group by')
            .setNodeType('group by')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertGroupBy.doAssert();

        Lexer.Node nameNode2 = groupByNode.left;
        AssertNode assertName2 = new AssertNodeBuilder()
            .setNode(nameNode2)
            .setId('name')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertName2.doAssert();

        Lexer.Node havingNode = groupByNode.right;
        AssertNode assertHaving = new AssertNodeBuilder()
            .setNode(havingNode)
            .setId('having')
            .setNodeType('having')
            .setIsLeftNull(false)
            .setIsRightNull(true)
            .build();
        assertHaving.doAssert();

        Lexer.Node orNode = havingNode.left;
        AssertNode assertOr = new AssertNodeBuilder()
            .setNode(orNode)
            .setId('or')
            .setNodeType('or')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertOr.doAssert();

        Lexer.Node operatorNode = orNode.left;
        AssertNode assertOperator = new AssertNodeBuilder()
            .setNode(operatorNode)
            .setId('=')
            .setNodeType('operator')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertOperator.doAssert();

        Lexer.Node nameNode3 = operatorNode.left;
        AssertNode assertName3 = new AssertNodeBuilder()
            .setNode(nameNode3)
            .setId('name')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertName3.doAssert();

        Lexer.Node valueNode = operatorNode.right;
        AssertNode assertValue = new AssertNodeBuilder()
            .setNode(valueNode)
            .setId('test2')
            .setNodeType('string')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertValue.doAssert();

        Lexer.Node andNode = orNode.right;
        AssertNode assertAnd = new AssertNodeBuilder()
            .setNode(andNode)
            .setId('and')
            .setNodeType('and')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertAnd.doAssert();

        Lexer.Node operatorNode2 = andNode.left;
        AssertNode assertOperator2 = new AssertNodeBuilder()
            .setNode(operatorNode2)
            .setId('=')
            .setNodeType('operator')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertOperator2.doAssert();

        Lexer.Node nameNode4 = operatorNode2.left;
        AssertNode assertName4 = new AssertNodeBuilder()
            .setNode(nameNode4)
            .setId('name')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertName4.doAssert();

        Lexer.Node valueNode2 = operatorNode2.right;
        AssertNode assertValue2 = new AssertNodeBuilder()
            .setNode(valueNode2)
            .setId('test1')
            .setNodeType('string')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertValue2.doAssert();

        Lexer.Node operatorNode3 = andNode.right;
        AssertNode assertOperator3 = new AssertNodeBuilder()
            .setNode(operatorNode3)
            .setId('>')
            .setNodeType('operator')
            .setIsLeftNull(false)
            .setIsRightNull(false)
            .build();
        assertOperator3.doAssert();

        Lexer.Node sumNode2 = operatorNode3.left;
        AssertNode assertSum2 = new AssertNodeBuilder()
            .setNode(sumNode2)
            .setId('sum')
            .setNodeType('aggregate function')
            .setIsLeftNull(true)
            .setIsRightNull(false)
            .build();
        assertSum2.doAssert();

        Lexer.Node numberOfEmployeesNode2 = sumNode2.right;
        AssertNode assertNumberOfEmployees2 = new AssertNodeBuilder()
            .setNode(numberOfEmployeesNode2)
            .setId('numberofemployees')
            .setNodeType('field')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertNumberOfEmployees2.doAssert();

        Lexer.Node valueNode3 = operatorNode3.right;
        AssertNode assertValue3 = new AssertNodeBuilder()
            .setNode(valueNode3)
            .setId('10')
            .setNodeType('number')
            .setIsLeftNull(true)
            .setIsRightNull(true)
            .build();
        assertValue3.doAssert();
    }
}