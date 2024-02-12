public with sharing class ParserUtils {
    public static String skipWhitespace(String query) {
        while(query.length() > 0 && query.substring(0, 1).isWhitespace()) {
            query = query.subString(1);
        }
        return query;
    }
    
    public static Boolean validCharForFieldOrObject(String character) {
        return character.isAlpha() || character == '_' || character.isNumeric();
    }
}