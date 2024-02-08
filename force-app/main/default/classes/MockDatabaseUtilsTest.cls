@IsTest
private with sharing class MockDatabaseUtilsTest {
    @IsTest
    static void testClone() {
        Lexer t = new Lexer();
        Node head = t.parse('SELECT Id FROM Account');
        Test.startTest();
        Node clone = MockDatabaseUtils.cloneNode(head);
        Test.stopTest();
        Assert.areEqual(
            head.toString(),
            clone.toString(),
            'Expected clone to be the same as the original'
        );
    }

    @IsTest
    static void testEqualityHandlerInteger() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('=');
        Test.startTest();
        Boolean isEqual = handler.handle(1, '1');
        Test.stopTest();

        Assert.isTrue(
            isEqual,
            'Expected values to be equal'
        );
    }

    @IsTest
    static void testEqualityHandlerString() {
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
    static void testEqualityHandlerBoolean() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('=');
        Test.startTest();
        Boolean isEqual = handler.handle(true, 'true');
        Test.stopTest();

        Assert.isTrue(
            isEqual,
            'Expected values to be equal'
        );
    }

    @IsTest
    static void testEqualityHandlerNull() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('=');
        Test.startTest();
        Boolean isEqual = handler.handle(null, null);
        Test.stopTest();

        Assert.isTrue(
            isEqual,
            'Expected values to be equal'
        );
    }

    @IsTest
    static void testEqualityHandlerDate() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('=');
        Test.startTest();
        Boolean isEqual = handler.handle(Date.newInstance(2020, 1, 1), '2020-01-01');
        Test.stopTest();

        Assert.isTrue(
            isEqual,
            'Expected values to be equal'
        );
    }

    @IsTest
    static void testEqualityHandlerDateTime1() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('=');
        Test.startTest();
        Boolean isEqual = handler.handle(DateTime.newInstanceGmt(2020, 1, 1, 1, 1, 1), '2020-01-01T01:01:01+00:00');
        Test.stopTest();

        Assert.isTrue(
            isEqual,
            'Expected values to be equal'
        );
    }

    @IsTest
    static void testEqualityHandlerDateTime2() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('=');
        Test.startTest();
        Boolean isEqual = handler.handle(DateTime.newInstanceGmt(2020, 1, 1, 1, 1, 1), '2020-01-01T01:01:01-00:00');
        Test.stopTest();

        Assert.isTrue(
            isEqual,
            'Expected values to be equal'
        );
    }

    @IsTest
    static void testEqualityHandlerDateTime3() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('=');
        Test.startTest();
        Boolean isEqual = handler.handle(DateTime.newInstanceGmt(2020, 1, 1, 1, 1, 1), '2020-01-01T01:01:01Z');
        Test.stopTest();

        Assert.isTrue(
            isEqual,
            'Expected values to be equal'
        );
    }

    @IsTest
    static void testEqualityHandlerTime() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('=');
        Test.startTest();
        Boolean isEqual = handler.handle(Time.newInstance(1, 1, 1, 1), '01:01:01.001Z');
        Test.stopTest();

        Assert.isTrue(
            isEqual,
            'Expected values to be equal'
        );
    }

    @IsTest
    static void testInequalityHandlerDate() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('!=');
        Test.startTest();
        Boolean isNotEqual = handler.handle(Date.newInstance(2019, 1, 1), '2020-01-01');
        Test.stopTest();

        Assert.isTrue(
            isNotEqual,
            'Expected values to not be equal'
        );
    }

    @IsTest
    static void testInequalityHandlerDateTime1() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('!=');
        Test.startTest();
        Boolean isNotEqual = handler.handle(DateTime.newInstance(1999, 1, 1, 23, 1, 1), '2020-01-01T01:01:01+01:00');
        Test.stopTest();

        Assert.isTrue(
            isNotEqual,
            'Expected values to not be equal'
        );
    }

    @IsTest
    static void testInequalityHandlerDateTime2() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('!=');
        Test.startTest();
        Boolean isNotEqual = handler.handle(DateTime.newInstance(1999, 1, 1, 23, 1, 1), '2020-01-01T01:01:01-08:00');
        Test.stopTest();

        Assert.isTrue(
            isNotEqual,
            'Expected values to not be equal'
        );
    }

    @IsTest
    static void testInequalityHandlerDateTime3() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('!=');
        Test.startTest();
        Boolean isNotEqual = handler.handle(DateTime.newInstance(1999, 1, 1, 23, 1, 1), '2020-01-01T01:01:01Z');
        Test.stopTest();

        Assert.isTrue(
            isNotEqual,
            'Expected values to not be equal'
        );
    }

    @IsTest
    static void testInequalityHandlerTime() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('!=');
        Test.startTest();
        Boolean isNotEqual = handler.handle(Time.newInstance(0, 0, 0, 0), '01:01:01.000Z');
        Test.stopTest();

        Assert.isTrue(
            isNotEqual,
            'Expected values to not be equal'
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

    @IsTest
    static void testGreaterThanHandlerLong() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>');
        Test.startTest();
        Boolean isGreaterThan = handler.handle( (Long) 2L, '1');
        Test.stopTest();

        Assert.isTrue(
            isGreaterThan,
            'Expected value a to be greater than value b'
        );
    }

    @IsTest
    static void testLessThanHandlerString() {
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
    static void testLessThanHandlerNull() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<');
        Test.startTest();
        Boolean isLessThan = handler.handle(null, 'test');
        Test.stopTest();

        Assert.isFalse(
            isLessThan,
            'Expected value a to be less than value b'
        );
    }

    @IsTest
    static void testLessThanHandlerDouble() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<');
        Test.startTest();
        Boolean isLessThan = handler.handle((Double) 1.0, '2.0');
        Test.stopTest();

        Assert.isTrue(
            isLessThan,
            'Expected value a to be less than value b'
        );
    }

    @IsTest
    static void testLessThanHandlerInteger() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<');
        Test.startTest();
        Boolean isLessThan = handler.handle(1, '2');
        Test.stopTest();

        Assert.isTrue(
            isLessThan,
            'Expected value a to be less than value b'
        );
    }

    @IsTest
    static void testLessThanHandlerDecimal() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<');
        Test.startTest();
        Boolean isLessThan = handler.handle( (Decimal) 1.0, '2.0');
        Test.stopTest();

        Assert.isTrue(
            isLessThan,
            'Expected value a to be less than value b'
        );
    }

    @IsTest
    static void testLessThanHandlerDate() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<');
        Test.startTest();
        Boolean isLessThan = handler.handle(Date.newInstance(2019, 1, 1), '2020-01-01');
        Test.stopTest();

        Assert.isTrue(
            isLessThan,
            'Expected value a to be less than value b'
        );
    }

    @IsTest
    static void testLessThanHandlerDateTime1() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<');
        Test.startTest();
        Boolean isLessThan = handler.handle(DateTime.newInstance(1999, 1, 1, 23, 1, 1), '2020-01-01T01:01:01+01:00');
        Test.stopTest();

        Assert.isTrue(
            isLessThan,
            'Expected value a to be less than value b'
        );
    }
    
    @IsTest
    static void testLessThanHandlerDateTime2() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<');
        Test.startTest();
        Boolean isLessThan = handler.handle(DateTime.newInstance(1999, 1, 1, 23, 1, 1), '2020-01-01T01:01:01-08:00');
        Test.stopTest();

        Assert.isTrue(
            isLessThan,
            'Expected value a to be less than value b'
        );
    }

    @IsTest
    static void testLessThanHandlerDateTime3() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<');
        Test.startTest();
        Boolean isLessThan = handler.handle(DateTime.newInstance(1999, 1, 1, 23, 1, 1), '2020-01-01T01:01:01Z');
        Test.stopTest();

        Assert.isTrue(
            isLessThan,
            'Expected value a to be less than value b'
        );
    }

    @IsTest
    static void testLessThanHandlerTime() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<');
        Test.startTest();
        Boolean isLessThan = handler.handle(Time.newInstance(0, 0, 0, 0), '01:01:01.000Z');
        Test.stopTest();

        Assert.isTrue(
            isLessThan,
            'Expected value a to be less than value b'
        );
    }

    @IsTest
    static void testLessThanHandlerLong() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<');
        Test.startTest();
        Boolean isLessThan = handler.handle( (Long) 1L, '2');
        Test.stopTest();

        Assert.isTrue(
            isLessThan,
            'Expected value a to be less than value b'
        );
    }

    @IsTest
    static void testGreaterThanOrEqualHandlerString() {
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
    static void testGreaterThanOrEqualHandlerNull() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>=');
        Test.startTest();
        Boolean isGreaterThanOrEqual = handler.handle(null, 'test');
        Test.stopTest();

        Assert.isFalse(
            isGreaterThanOrEqual,
            'Expected value a to be greater than or equal to value b'
        );
    }

    @IsTest
    static void testGreaterThanOrEqualHandlerDouble() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>=');
        Test.startTest();
        Boolean isGreaterThanOrEqual = handler.handle((Double) 2.0, '1.0');
        Test.stopTest();

        Assert.isTrue(
            isGreaterThanOrEqual,
            'Expected value a to be greater than or equal to value b'
        );
    }

    @IsTest
    static void testGreaterThanOrEqualHandlerInteger() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>=');
        Test.startTest();
        Boolean isGreaterThanOrEqual = handler.handle(2, '1');
        Test.stopTest();

        Assert.isTrue(
            isGreaterThanOrEqual,
            'Expected value a to be greater than or equal to value b'
        );
    }

    @IsTest
    static void testGreaterThanOrEqualHandlerDecimal() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>=');
        Test.startTest();
        Boolean isGreaterThanOrEqual = handler.handle( (Decimal) 2.0, '1.0');
        Test.stopTest();

        Assert.isTrue(
            isGreaterThanOrEqual,
            'Expected value a to be greater than or equal to value b'
        );
    }

    @IsTest
    static void testGreaterThanOrEqualHandlerDate() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>=');
        Test.startTest();
        Boolean isGreaterThanOrEqual = handler.handle(Date.newInstance(2020, 1, 1), '2020-01-01');
        Test.stopTest();

        Assert.isTrue(
            isGreaterThanOrEqual,
            'Expected value a to be greater than or equal to value b'
        );
    }

    @IsTest
    static void testGreaterThanOrEqualHandlerDateTime1() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>=');
        Test.startTest();
        Boolean isGreaterThanOrEqual = handler.handle(DateTime.newInstance(2020, 1, 1, 1, 1, 1), '2020-01-01T01:01:01+01:00');
        Test.stopTest();

        Assert.isTrue(
            isGreaterThanOrEqual,
            'Expected value a to be greater than or equal to value b'
        );
    }

    @IsTest
    static void testGreaterThanOrEqualHandlerDateTime2() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>=');
        Test.startTest();
        Boolean isGreaterThanOrEqual = handler.handle(DateTime.newInstance(2020, 1, 1, 1, 1, 1), '2020-01-01T01:01:01-08:00');
        Test.stopTest();

        Assert.isTrue(
            isGreaterThanOrEqual,
            'Expected value a to be greater than or equal to value b'
        );
    }

    @IsTest
    static void testGreaterThanOrEqualHandlerDateTime3() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>=');
        Test.startTest();
        Boolean isGreaterThanOrEqual = handler.handle(DateTime.newInstance(2020, 1, 1, 1, 1, 1), '2020-01-01T01:01:01Z');
        Test.stopTest();

        Assert.isTrue(
            isGreaterThanOrEqual,
            'Expected value a to be greater than or equal to value b'
        );
    }

    @IsTest
    static void testGreaterThanOrEqualHandlerTime() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>=');
        Test.startTest();
        Boolean isGreaterThanOrEqual = handler.handle(Time.newInstance(1, 1, 1, 1), '01:01:01.000Z');
        Test.stopTest();

        Assert.isTrue(
            isGreaterThanOrEqual,
            'Expected value a to be greater than or equal to value b'
        );
    }

    @IsTest
    static void testGreaterThanOrEqualHandlerLong() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>=');
        Test.startTest();
        Boolean isGreaterThanOrEqual = handler.handle( (Long) 2L, '1');
        Test.stopTest();

        Assert.isTrue(
            isGreaterThanOrEqual,
            'Expected value a to be greater than or equal to value b'
        );
    }

    @IsTest
    static void testLessThanOrEqualHandlerString() {
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
    static void testLessThanOrEqualHandlerNull() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<=');
        Test.startTest();
        Boolean isLessThanOrEqual = handler.handle(null, 'test');
        Test.stopTest();

        Assert.isFalse(
            isLessThanOrEqual,
            'Expected value a to be less than or equal to value b'
        );
    }

    @IsTest
    static void testLessThanOrEqualHandlerDouble() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<=');
        Test.startTest();
        Boolean isLessThanOrEqual = handler.handle((Double) 1.0, '2.0');
        Test.stopTest();

        Assert.isTrue(
            isLessThanOrEqual,
            'Expected value a to be less than or equal to value b'
        );
    }

    @IsTest
    static void testLessThanOrEqualHandlerInteger() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<=');
        Test.startTest();
        Boolean isLessThanOrEqual = handler.handle(1, '2');
        Test.stopTest();

        Assert.isTrue(
            isLessThanOrEqual,
            'Expected value a to be less than or equal to value b'
        );
    }

    @IsTest
    static void testLessThanOrEqualHandlerDecimal() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<=');
        Test.startTest();
        Boolean isLessThanOrEqual = handler.handle( (Decimal) 1.0, '2.0');
        Test.stopTest();

        Assert.isTrue(
            isLessThanOrEqual,
            'Expected value a to be less than or equal to value b'
        );
    }

    @IsTest
    static void testLessThanOrEqualHandlerDate() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<=');
        Test.startTest();
        Boolean isLessThanOrEqual = handler.handle(Date.newInstance(2019, 1, 1), '2020-01-01');
        Test.stopTest();

        Assert.isTrue(
            isLessThanOrEqual,
            'Expected value a to be less than or equal to value b'
        );
    }

    @IsTest
    static void testLessThanOrEqualHandlerDateTime1() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<=');
        Test.startTest();
        Boolean isLessThanOrEqual = handler.handle(DateTime.newInstance(1999, 1, 1, 23, 1, 1), '2020-01-01T01:01:01+01:00');
        Test.stopTest();

        Assert.isTrue(
            isLessThanOrEqual,
            'Expected value a to be less than or equal to value b'
        );
    }

    @IsTest
    static void testLessThanOrEqualHandlerDateTime2() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<=');
        Test.startTest();
        Boolean isLessThanOrEqual = handler.handle(DateTime.newInstance(1999, 1, 1, 23, 1, 1), '2020-01-01T01:01:01-08:00');
        Test.stopTest();

        Assert.isTrue(
            isLessThanOrEqual,
            'Expected value a to be less than or equal to value b'
        );
    }

    @IsTest
    static void testLessThanOrEqualHandlerDateTime3() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<=');
        Test.startTest();
        Boolean isLessThanOrEqual = handler.handle(DateTime.newInstance(1999, 1, 1, 23, 1, 1), '2020-01-01T01:01:01Z');
        Test.stopTest();

        Assert.isTrue(
            isLessThanOrEqual,
            'Expected value a to be less than or equal to value b'
        );
    }

    @IsTest
    static void testLessThanOrEqualHandlerTime() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<=');
        Test.startTest();
        Boolean isLessThanOrEqual = handler.handle(Time.newInstance(0, 0, 0, 0), '01:01:01.000Z');
        Test.stopTest();

        Assert.isTrue(
            isLessThanOrEqual,
            'Expected value a to be less than or equal to value b'
        );
    }

    @IsTest
    static void testLessThanOrEqualHandlerLong() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('<=');
        Test.startTest();
        Boolean isLessThanOrEqual = handler.handle( (Long) 1L, '2');
        Test.stopTest();

        Assert.isTrue(
            isLessThanOrEqual,
            'Expected value a to be less than or equal to value b'
        );
    }

    @IsTest
    static void testNotEqualHandlerString() {
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
    static void testNotEqualHandlerNull() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('!=');
        Test.startTest();
        Boolean isNotEqual = handler.handle(null, 'test');
        Test.stopTest();

        Assert.isTrue(
            isNotEqual,
            'Expected values to not be equal'
        );
    }

    @IsTest
    static void testNotEqualHandlerDouble() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('!=');
        Test.startTest();
        Boolean isNotEqual = handler.handle((Double) 1.0, '2.0');
        Test.stopTest();

        Assert.isTrue(
            isNotEqual,
            'Expected values to not be equal'
        );
    }

    @IsTest
    static void testNotEqualHandlerInteger() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('!=');
        Test.startTest();
        Boolean isNotEqual = handler.handle(1, '2');
        Test.stopTest();

        Assert.isTrue(
            isNotEqual,
            'Expected values to not be equal'
        );
    }

    @IsTest
    static void testNotEqualHandlerDecimal() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('!=');
        Test.startTest();
        Boolean isNotEqual = handler.handle( (Decimal) 1.0, '2.0');
        Test.stopTest();

        Assert.isTrue(
            isNotEqual,
            'Expected values to not be equal'
        );
    }

    @IsTest
    static void testNotEqualHandlerDate() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('!=');
        Test.startTest();
        Boolean isNotEqual = handler.handle(Date.newInstance(2019, 1, 1), '2020-01-01');
        Test.stopTest();

        Assert.isTrue(
            isNotEqual,
            'Expected values to not be equal'
        );
    }

    @IsTest
    static void testNotEqualHandlerDateTime1() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('!=');
        Test.startTest();
        Boolean isNotEqual = handler.handle(DateTime.newInstance(1999, 1, 1, 23, 1, 1), '2020-01-01T01:01:01+01:00');
        Test.stopTest();

        Assert.isTrue(
            isNotEqual,
            'Expected values to not be equal'
        );
    }

    @IsTest
    static void testNotEqualHandlerDateTime2() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('!=');
        Test.startTest();
        Boolean isNotEqual = handler.handle(DateTime.newInstance(1999, 1, 1, 23, 1, 1), '2020-01-01T01:01:01-08:00');
        Test.stopTest();

        Assert.isTrue(
            isNotEqual,
            'Expected values to not be equal'
        );
    }

    @IsTest
    static void testNotEqualHandlerDateTime3() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('!=');
        Test.startTest();
        Boolean isNotEqual = handler.handle(DateTime.newInstance(1999, 1, 1, 23, 1, 1), '2020-01-01T01:01:01Z');
        Test.stopTest();

        Assert.isTrue(
            isNotEqual,
            'Expected values to not be equal'
        );
    }

    @IsTest
    static void testNotEqualHandlerTime() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('!=');
        Test.startTest();
        Boolean isNotEqual = handler.handle(Time.newInstance(0, 0, 0, 0), '01:01:01.000Z');
        Test.stopTest();

        Assert.isTrue(
            isNotEqual,
            'Expected values to not be equal'
        );
    }

    @IsTest
    static void testNotEqualHandlerLong() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('!=');
        Test.startTest();
        Boolean isNotEqual = handler.handle( (Long) 1L, '2');
        Test.stopTest();

        Assert.isTrue(
            isNotEqual,
            'Expected values to not be equal'
        );
    }

    @IsTest
    static void testLikeHandler() {
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
    static void testInHandler() {
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
    static void testNotInHandler() {
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
    static void testGreaterThanHandlerString1() {
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
    static void testGreaterThanHandlerString2() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>');
        Test.startTest();
        Boolean isGreaterThan = handler.handle('test', 'test1');
        Test.stopTest();

        Assert.isFalse(
            isGreaterThan,
            'Expected value a to be greater than value b'
        );
    }

    @IsTest
    static void testGreaterThanHandlerString3() {
        MockDatabaseUtils.OperatorHandlerFactory opHandlerFactory = new MockDatabaseUtils.OperatorHandlerFactory();
        MockDatabaseUtils.OperatorHandler handler = opHandlerFactory.getHandler('>');
        Test.startTest();
        Boolean isGreaterThan = handler.handle('test', 'test');
        Test.stopTest();

        Assert.isFalse(
            isGreaterThan,
            'Expected value a to be greater than value b'
        );
    }
}