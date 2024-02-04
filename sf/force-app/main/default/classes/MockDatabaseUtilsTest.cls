@IsTest
public with sharing class MockDatabaseUtilsTest {
    @IsTest
    public static void testClone() {
        Lexer t = new Lexer();
        Lexer.Node head = t.parse('SELECT Id FROM Account');
        Lexer.Node clone = MockDatabaseUtils.cloneNode(head);
        Assert.areEqual(
            head.toString(),
            clone.toString(),
            'Expected clone to be the same as the original'
        );
    }
}