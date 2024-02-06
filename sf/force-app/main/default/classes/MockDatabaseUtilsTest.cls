@IsTest
private with sharing class MockDatabaseUtilsTest {
    @IsTest
    static void testClone() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id FROM Account');
        Test.startTest();
        Lexer.Node clone = MockDatabaseUtils.cloneNode(head);
        Test.stopTest();
        Assert.areEqual(
            head.toString(),
            clone.toString(),
            'Expected clone to be the same as the original'
        );
    }

    @IsTest
    static void testEqualityHandler() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('=');
        Test.startTest();
        Boolean isEqual = handler.handle('test', 'test');
        Test.stopTest();

        Assert.isTrue(
            isEqual,
            'Expected values to be equal'
        );
    }

    @IsTest
    static void testNotEqual1() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('!=');
        Test.startTest();
        Boolean isNotEqual = handler.handle('test1', 'test');
        Test.stopTest();

        Assert.isTrue(
            isNotEqual,
            'Expected values to not be equal'
        );        
    }

    @IsTest
    static void testNotEqual2() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<>');
        Test.startTest();
        Boolean isNotEqual = handler.handle('test1', 'test');
        Test.stopTest();

        Assert.isTrue(
            isNotEqual,
            'Expected values to not be equal'
        );        
    }

    @IsTest
    static void testLike() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('like');
        Test.startTest();
        Boolean isLike = handler.handle('test', '%tes_');
        Test.stopTest();

        Assert.isTrue(
            isLike,
            'Expected values to be like'
        );
    }

    @IsTest
    static void testIn() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('in');
        Test.startTest();
        Boolean isIn = handler.handle('test', new List<String>{'test', 'test1'});
        Test.stopTest();

        Assert.isTrue(
            isIn,
            'Expected value to be in list'
        );
    }

    @IsTest
    static void testNotIn() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('not in');
        Test.startTest();
        Boolean isNotIn = handler.handle('test', new List<String>{'test1', 'test2'});
        Test.stopTest();

        Assert.isTrue(
            isNotIn,
            'Expected value to not be in list'
        );
    }

    @IsTest
    static void testGreaterThanHandler() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>');
        Test.startTest();
        Boolean isGreaterThan = handler.handle('test1', 'test');
        Test.stopTest();

        Assert.isTrue(
            isGreaterThan,
            'Expected value a to be greater than value b'
        );        
    }

    @IsTest
    static void testLessThanHandler() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<');
        Test.startTest();
        Boolean isLessThan = handler.handle('test', 'test1');
        Test.stopTest();

        Assert.isTrue(
            isLessThan,
            'Expected value a to be less than value b'
        );        
    }

    @IsTest
    static void testGreaterThanOrEqualHandler() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>=');
        Test.startTest();
        Boolean isGreaterThanOrEqual = handler.handle('test', 'test');
        Test.stopTest();

        Assert.isTrue(
            isGreaterThanOrEqual,
            'Expected value a to be greater than or equal to value b'
        );
    }

    @IsTest
    static void testLessThanOrEqualHandler() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<=');
        Test.startTest();
        Boolean isLessThanOrEqual = handler.handle('test', 'test');
        Test.stopTest();

        Assert.isTrue(
            isLessThanOrEqual,
            'Expected value a to be less than or equal to value b'
        );
    }

    @IsTest
    static void testNull() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('=');
        Test.startTest();
        Boolean isNull = handler.handle(null, null);
        Test.stopTest();

        Assert.isTrue(
            isNull,
            'Expected value to be true'
        );
    }

    @IsTest
    static void testGreaterThanHandlerString() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>');
        Test.startTest();
        Boolean isGreaterThan = handler.handle('test1', 'test');
        Test.stopTest();

        Assert.isTrue(
            isGreaterThan,
            'Expected value a to be greater than value b'
        );
    }

    @IsTest
    static void testGreaterThanHandlerNull() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>');
        Test.startTest();
        Boolean isGreaterThan = handler.handle(null, 'test');
        Test.stopTest();

        Assert.isFalse(
            isGreaterThan,
            'Expected value a to be greater than value b'
        );
    }

    @IsTest
    static void testGreaterThanHandlerDouble() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>');
        Test.startTest();
        Boolean isGreaterThan = handler.handle((Double) 2.0, '1.0');
        Test.stopTest();

        Assert.isTrue(
            isGreaterThan,
            'Expected value a to be greater than value b'
        );
    }

    @IsTest 
    static void testGreaterThanHandlerInteger() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>');
        Test.startTest();
        Boolean isGreaterThan = handler.handle(2, '1');
        Test.stopTest();

        Assert.isTrue(
            isGreaterThan,
            'Expected value a to be greater than value b'
        );
    }

    @IsTest 
    static void testGreaterThanHandlerDecimal() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>');
        Test.startTest();
        Boolean isGreaterThan = handler.handle( (Decimal) 2.0, '1.0');
        Test.stopTest();

        Assert.isTrue(
            isGreaterThan,
            'Expected value a to be greater than value b'
        );
    }

    @IsTest
    static void testGreaterThanHandlerDate() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>');
        Test.startTest();
        Boolean isGreaterThan = handler.handle(Date.newInstance(2020, 1, 1), '2019-01-01');
        Test.stopTest();

        Assert.isTrue(
            isGreaterThan,
            'Expected value a to be greater than value b'
        );
    }

    @IsTest
    static void testGreaterThanHandlerDateTime1() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>');
        Test.startTest();
        Boolean isGreaterThan = handler.handle(DateTime.newInstance(2020, 1, 1, 1, 1, 1), '1999-01-01T23:01:01+01:00');
        Test.stopTest();

        Assert.isTrue(
            isGreaterThan,
            'Expected value a to be greater than value b'
        );
    }

    @IsTest
    static void testGreaterThanHandlerDateTime2() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>');
        Test.startTest();
        Boolean isGreaterThan = handler.handle(DateTime.newInstance(2020, 1, 1, 1, 1, 1), '1999-01-01T23:01:01-08:00');
        Test.stopTest();

        Assert.isTrue(
            isGreaterThan,
            'Expected value a to be greater than value b'
        );
    }

    @IsTest
    static void testGreaterThanHandlerDateTime3() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>');
        Test.startTest();
        Boolean isGreaterThan = handler.handle(DateTime.newInstance(2020, 1, 1, 1, 1, 1), '1999-01-01T23:01:01Z');
        Test.stopTest();

        Assert.isTrue(
            isGreaterThan,
            'Expected value a to be greater than value b'
        );
    }

    @IsTest
    static void testGreaterThanHandlerTime() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>');
        Test.startTest();
        Boolean isGreaterThan = handler.handle(Time.newInstance(1, 1, 1, 1), '00:00:00.000Z');
        Test.stopTest();

        Assert.isTrue(
            isGreaterThan,
            'Expected value a to be greater than value b'
        );
    }
}