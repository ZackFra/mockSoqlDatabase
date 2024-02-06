@isTest
private class ParserUtilsTest {

    @isTest
    private static void testSkipWhitespace() {
        String query = '   SELECT Id FROM Account';
        Test.startTest();
        query = ParserUtils.skipWhitespace(query);
        Test.stopTest();

        Assert.areEqual('SELECT Id FROM Account', query, 'skipWhitespace should remove leading whitespace');
    }

    @IsTest
    private static void testValidCharForFieldOrObject() {
        String validChars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_';
        Test.startTest();
        for (Integer i = 0; i < validChars.length(); i++) {
            String c = validChars.substring(i, i + 1);
            Assert.isTrue(ParserUtils.validCharForFieldOrObject(c), c + ' should be a valid character for a field or object');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testInvalidCharForFieldOrObject() {
        String invalidChars = '@#$%^&**()!-+=[]{}|;:,.<>?/\\~`"\'\t\n\r';
        Test.startTest();
        for (Integer i = 0; i < invalidChars.length(); i++) {
            String c = invalidChars.substring(i, i + 1);
            Assert.isFalse(ParserUtils.validCharForFieldOrObject(c), c + ' should be an invalid character for a field or object');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testNullCheck() {
        String query = null;
        String exMessage;
        Test.startTest();
        try {
            ParserUtils.nullCheck(query, 'query');
        } catch(IllegalArgumentException ex) {
            exMessage = ex.getMessage();
        }
        Test.stopTest();
        Assert.isTrue(
            exMessage != null &&
            exMessage.contains('query'),
            'nullCheck should throw an IllegalArgumentException with a message containing "null"'
        );
    }
}