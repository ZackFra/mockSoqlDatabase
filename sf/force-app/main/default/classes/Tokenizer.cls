public with sharing class Tokenizer {
    
    public class Node {
        private Node(String nodeType, string id, Node left, Node right) {
            ParserUtils.nullCheck(nodeType, 'nodeType may not be null');
            ParserUtils.nullCheck(id, 'id may not be null');
            
            this.id = id;
            this.nodeType = nodeType;
            this.left = left;
            this.right = right;
        }
        
        public override String toString() {
            String strVal = '{ id: ' + this.id + ', nodeType: ' + this.nodeType + '},';
            if(this.left != null) {
                strVal = this.left.toString() + strVal;
            }
            if(this.right != null) {
                strVal += this.right.toString();
            }
            return strVal;
        }
        
        public String id;
        public String nodeType;
        public Node left;
        public Node right;
    }
    
    private class NodeBuilder {
        String id;
        String nodeType;
        Node left;
        Node right;
        
        public NodeBuilder setId(String id) {
            this.id = id;
            return this;
        }
        public NodeBuilder setNodeType(String nodeType) {
            this.nodeType = nodeType;
            return this;
        }
        public NodeBuilder setLeft(Node left) {
            this.left = left;
            return this;
        }
        public NodeBuilder setRight(Node right) {
            this.right = right;
            return this;
        }
        public Node build() {
            return new Node(nodeType, id, left, right);
        }
    }
    
    // @description : Consumes a token from the query, throwing an error if the token is not present
    private String consume(String query, String token) {
        if(query.subString(0, token.length()) != token) {
            throw new ParsingException(query, token);
        }
        return query.subString(token.length());
    }

    // @description : Look ahead at the next numChars characters in the query
    private String lookahead(String query, Integer numChars) {
        if(query.length() < numChars) { 
            return query;
        }
        return query.subString(0, numChars);
    }
    
    private class Intermediary {
        public Node head;
        String subquery;
        public Intermediary(Node head, String subquery) {
            this.head = head;
            this.subquery = subquery;
        }
    }
    
    // @description: Custom error thrown when a query cannot be parsed
    private class ParsingException extends Exception {
        public ParsingException(String message, String expected) {
            if(expected == null) {
                this.setMessage('Unkown parsing exception, "' + message + '" could not be parsed.');
            } else {
                this.setMessage('Parsing exception, expected "' + expected + '", instead saw "' + message + '".');
            }
        }
    }
    
    public Node parse(String query) {
        Intermediary fullQuery = parseQuery(query);
        return fullQuery.head;
    }
    
    private Intermediary parseQuery(String query) {
        
        query = query.toLowerCase();
        
        Intermediary selectIntermediary = parseSelect(query);
        query = selectIntermediary.subquery;
        
        Intermediary fromIntermediary = parseFrom(query);
        query = fromIntermediary.subquery;
        
        Intermediary nextLink = selectIntermediary;
        nextLink.head.right = fromIntermediary.head;
        nextLink = fromIntermediary;
        
        Intermediary whereIntermediary = parseWhere(fromIntermediary.subquery);
        if(whereIntermediary != null) {
            query = whereIntermediary.subquery;
            nextLink.head.right = whereIntermediary.head;
            nextLink = whereIntermediary;
        }
        
        Intermediary groupByIntermediary = parseGroupBy(query);
        if(groupByIntermediary != null) {
            query = groupByIntermediary.subquery;
            nextLink.head.right = groupByIntermediary.head;
            nextLink = groupByIntermediary;
            
            Intermediary havingIntermediary = parseHaving(query);
            if(havingIntermediary != null) {
                query = havingIntermediary.subquery;
                nextLink.head.right = havingIntermediary.head;
                nextLink = havingIntermediary;
            }
        }
        
        Intermediary orderByIntermediary = parseOrderBy(query);
        if(orderByIntermediary != null) {
            query = orderByIntermediary.subquery;
            nextLink.head.right = orderByIntermediary.head;
            nextLink = orderByIntermediary;
        }
        
        Intermediary limitIntermediary = parseLimit(query);
        if(limitIntermediary != null) {
            query = limitIntermediary.subquery;
            nextLink.head.right = limitIntermediary.head;
            nextLink = limitIntermediary;
        }
        
        Intermediary forUpdateIntermediary = parseForUpdate(query);
        if(forUpdateIntermediary != null) {
            query = forUpdateIntermediary.subquery;
            nextLink.head.right = forUpdateIntermediary.head;
            nextLink = forUpdateIntermediary;
        }
        
        // head node, so to speak
        selectIntermediary.subquery = nextLink.subquery;
		if(nextLink.subquery != '') {
            throw new ParsingException(nextLink.subquery, null);
        }
        return selectIntermediary;
    }
    
    private Intermediary parseSelect(String query) {
        query = ParserUtils.skipWhitespace(query);
        
        String selectStatement = consume(query, 'select');
        
        String subquery = query.substring(6);
        Intermediary leftIntermediary = parseSelectExpr(subquery);
        return new Intermediary(
        	new NodeBuilder()
            	.setId('select')
            	.setNodeType('select')
            	.setLeft(leftIntermediary.head)
            	.build(),
            leftIntermediary.subquery
        );
        
    }
    
    private Intermediary parseSelectExpr(String query) {
        query = ParserUtils.skipWhitespace(query);
        Intermediary selectExpr;
        
        if(query.subString(0, 1) == '(') {
            query = consume(query, '(');
            Intermediary soqlSubQuery = parseQuery(query);
            query = soqlSubQuery.subquery;
            query = ParserUtils.skipWhitespace(query);
            query = consume(query, ')');
            query = query.subString(1);
            selectExpr = new Intermediary(
            	new NodeBuilder()
                	.setId('subquery')
                	.setNodeType('subquery')
                	.setRight(soqlSubQuery.head)
                	.build(),
                query
            );
        } else {
            selectExpr = parseFieldList(query);
            query = selectExpr.subquery;
        }
        
        query = ParserUtils.skipWhitespace(query);
        String nextChar = lookahead(query, 1);
        if(nextChar == ',') {
            query = consume(query, ',');
            Intermediary restOfExpr = parseSelectExpr(query);
            selectExpr.head.left = restOfExpr.head;
            selectExpr.subquery = restOfExpr.subquery;
        }
        return selectExpr;
    }
    
    private Intermediary parseFieldList(String query) {
        query = ParserUtils.skipWhitespace(query);
        
        Intermediary field = parseField(query);
        query = ParserUtils.skipWhitespace(field.subquery);
        if(query.length() == 0) {
            return field;
        }
        
        String nextChar = lookahead(query, 1);
        String nextCharAfterThat = lookahead(ParserUtils.skipWhitespace(query.subString(1)), 1);
        
        if(nextChar == ',' && nextCharAfterThat != '(') {
            query = query.subString(1);
            Intermediary restOfList = parseFieldList(query);
            field.head.left = restOfList.head;
            field.subquery = restOfList.subquery;
        }
        return field;
    }

    private Boolean isAggregateFunction(String query) {
        query = ParserUtils.skipWhitespace(query);
        if(query.length() < 3) return false;
        if(query.subString(0, 3) == 'sum') return true;
        if(query.subString(0, 3) == 'avg') return true;
        if(query.subString(0, 3) == 'min') return true;
        if(query.subString(0, 3) == 'max') return true;
        if(query.subString(0, 5) == 'count') return true;
        return false;
    }

    // @description : Returns true if the next tokens in the query denote a subfield
    private Boolean isSubField(String query) {
        if(query.length() < 3) return false;
        if(ParserUtils.validCharForFieldOrObject(query.subString(0, 1))) return false;
        if(query.subString(1, 2) != '.') return false;
        if(!ParserUtils.validCharForFieldOrObject(query.subString(2, 3))) return false;
        return true;
    }

    // @description returns true if the next token in the query is a field or object
    private Boolean isNextTokenFieldOrObject(String query) {
        return ParserUtils.validCharForFieldOrObject(query.subString(0, 1));
    }
    
    private Intermediary parseField(String query) {
        query = ParserUtils.skipWhitespace(query);
        String fieldName = '';
        while(query.length() != 0 && 
              isNextTokenFieldOrObject(query) ||
              isSubField(query)) {
            
              if(query.length() >= 3 && ParserUtils.validCharForFieldOrObject(query.subString(0, 1)) && query.subString(1, 2) == '.' && ParserUtils.validCharForFieldOrObject(query.subString(2, 3))) {
              	fieldName += query.subString(0, 3);
                query = query.subString(3);
              } else {
                  
                fieldName += query.subString(0, 1);
                query = query.subString(1);
              }
        }
        
        if(fieldName.isNumeric()) {
            throw new ParsingException(fieldName, 'field name');
        }
        
        Node head = new NodeBuilder()
            .setId(fieldName)
            .setNodeType('field')
            .build();
        return new Intermediary(head, query);
    }
    
    private Intermediary parseFrom(String query) {
        query = ParserUtils.skipWhitespace(query);
        query = consume(query, 'from');
        
        
        Intermediary leftIntermediary = parseObj(query);
		
        return new Intermediary(
        	new NodeBuilder()
            	.setId('from')
            	.setNodeType('from')
            	.setLeft(leftIntermediary.head)
            	.build(),
            leftIntermediary.subquery
        );
    }
    
    private Intermediary parseObj(String query) {
        query = ParserUtils.skipWhitespace(query);
        String objectName = '';
        while(query.length() != 0 && (ParserUtils.validCharForFieldOrObject(query.subString(0, 1)))) {
            objectName += query.subString(0, 1);
            query = query.subString(1);
        }
        return new Intermediary(
        	new NodeBuilder()
            	.setId(objectName)
            	.setNodeType('object')
            	.build(),
            query
        );
    }
    
    private Intermediary parseWhere(String query) {
        query = ParserUtils.skipWhitespace(query);
        if(query.length() == 0) return null;
        String whereClause = query.subString(0, 5);
        if(whereClause != 'where') return null;
        query = query.subString(5);
        
        Intermediary leftIntermediary = parseConditionalExpr(query);
        
        return new Intermediary(
        	new NodeBuilder()
            	.setId('where')
            	.setNodeType('where')
            	.setLeft(leftIntermediary.head)
            	.build(),
            leftIntermediary.subquery
        );
    }
    
    private Boolean isAnd(String query) {
        return lookahead(query, 3) == 'and';
    }

    private Boolean isOr(String query) {
        return lookahead(query, 2) == 'or';
    }

    // TODO: figure out how to handle the AND and OR operators
    private Intermediary parseConditionalExpr(String query) {
        query = ParserUtils.skipWhitespace(query);

        Intermediary leftIntermediary;
        Intermediary rightIntermediary;

        // if this query contains a sub-expression, parse it
        if(lookahead(query, 1) == '(') {
            query = consume(query, '(');
            leftIntermediary = parseConditionalExpr(query);
            query = leftIntermediary.subquery;
            query = consume(query, ')');
        }

        query = ParserUtils.skipWhitespace(query);

        // if the next token is an AND or OR, parse it
        NodeBuilder nb = new NodeBuilder();
        if(isAnd(query) || isOr(query)) {
            String token;
            if(isAnd(query)) {
                token = 'and';
            } else { 
                token = 'or';
            }

            query = consume(query, token);
            Intermediary restOfExpr = parseConditionalExpr(query);
            query = restOfExpr.subquery;

            return new Intermediary(
                nb.setId(token)
                    .setNodeType(token)
                    .setLeft(leftIntermediary.head)
                    .setRight(restOfExpr.head),
                query
            );
        }

        // if the next token is not and AND or OR, it must be a conditional expression
        Intermediary fieldIntermediary = parseField(query);
        query = fieldIntermediary.subquery;
        Intermediary operatorIntermediary = parseOperator(query);
        query = operatorIntermediary.subquery;
        Intermediary valueIntermediary = parseValue(query);
        query = valueIntermediary.subquery;

        operatorIntermediary.head.left = fieldIntermediary.head;
        operatorIntermediary.head.right = valueIntermediary.head;

        if(leftIntermediary == null) {
            leftIntermediary = operatorIntermediary;
        } else {
            leftIntermediary.head.right = operatorIntermediary.head;
        }
        
        return new Intermediary(
            new NodeBuilder()
            .setId('conditional expression')
            .setNodeType('conditional expression')
            .setLeft(operatorIntermediary.head)
            .build(),
            query
        );
    }
    
    private Intermediary parseOperator(String query) {
        query = ParserUtils.skipWhitespace(query);
        NodeBuilder nb = new NodeBuilder()
            .setNodeType('operator');
        List<String> opTokens = new List<String> {
            'like',
            '!=',
            '<>',
            '<=',
            '>=',
            'in',
            'not in',
            '=',
            '>',
            '<'
        };
        for(String token : opTokens) {
            if(query.length() >= token.length() && query.subString(0, token.length()) == token) {
                nb.setId(token);
                query = consume(query, token);
                return new Intermediary(
                	nb.build(),
                    query
                );
            }
        }
        throw new ParsingException(query, null);
    }
    
    private Intermediary parseValue(String query) {
        query = ParserUtils.skipWhitespace(query);
        Intermediary baseValue;
        if(query.subString(0, 1) == '\'') {
            query = query.subString(1);
            baseValue = parseString(query);
            if(baseValue.subquery.subString(0, 1) != '\'') {
                throw new ParsingException(baseValue.subquery, '\'');
            }
            query = baseValue.subquery.subString(1);
            baseValue.subquery = query;
            return baseValue;
        } else if(query.length() >= 4 && (query.subString(0, 4) == 'true' || query.subString(0, 5) == 'false')) {
        	return parseBoolean(query);
        } else {
        	return parseNum(query);
        }
    }
    
    private Intermediary parseNum(String query) {
        query = ParserUtils.skipWhitespace(query);
        String numericValue = '';
        
        while(query.length() != 0 && (query.subString(0, 1).isNumeric() || (query.subString(0, 1) == '.') )) {
            if(query.subString(0, 1) == '.' && !query.subString(1, 2).isNumeric()) {
                throw new ParsingException(query, 'floating point value');
            }
            numericValue += query.subString(0, 1);
            query = query.subString(1);
        }
        if(!numericValue.isNumeric()) {
            throw new ParsingException(query, 'number');
        }
        
        return new Intermediary(
        	new NodeBuilder()
            	.setId(numericValue)
            	.setNodeType('number')
            	.build(),
            query
        );
    }
    
    private Intermediary parseBoolean(String query) {
        query = ParserUtils.skipWhitespace(query);
        
        if(query.subString(0, 4) != 'true' && query.subString(0, 5) != 'false') {
        	throw new ParsingException(query, 'boolean');
        }
        
        String boolVal;
        if(query.subString(0, 4) == 'true') boolVal = 'true';
        else boolVal = 'false';
        
        return new Intermediary(
            new NodeBuilder()
            .setId(boolVal)
            .setNodeType('boolean')
            .build(),
            query.subString(boolVal.length())
        );
    }
    
    private Intermediary parseString(String query) {
        query = ParserUtils.skipWhitespace(query);
        String strValue = '';
        while(query.length() != 0 && query.subString(0, 1) != '\'') {
            strValue += query.subString(0, 1);
            query = query.subString(1);
        }
        return new Intermediary(
        	new NodeBuilder()
            	.setId(strValue)
            	.setNodeType('string')
            	.build(),
            query
        );
    }
    
    private Intermediary parseGroupBy(String query) {
        query = ParserUtils.skipWhitespace(query);
        
        if(query.length() == 0) {
            return null;
        }
        if(lookahead(query, 5) != 'group') { 
            return null;
        }
        
        query = query.subString(5);
        query = ParserUtils.skipWhitespace(query);
        if(query.subString(0, 2) != 'by') {
            throw new ParsingException(query, 'BY');
        }
        query = query.subString(2);
        Intermediary fieldList = parseFieldList(query);
        
        return new Intermediary(
        	new NodeBuilder()
            	.setId('group by')
            	.setNodeType('group by')
            	.setLeft(fieldList.head)
            	.build(),
            fieldList.subquery
        );
    }
    
    private Intermediary parseOrderBy(String query) {
        query = ParserUtils.skipWhitespace(query);
        if(query.length() == 0 || query.length() < 5) {
            return null;
        }
        if(lookahead(query, 5) != 'order') {
            return null;
        }
        
        query = query.subString(5);
        query = ParserUtils.skipWhitespace(query);
        
        if(query.subString(0, 2) != 'by') {
            throw new ParsingException(query, 'BY');
        }
        query = query.subString(2);
        Intermediary fieldList = parseFieldList(query);
        return new Intermediary(
        	new NodeBuilder()
            	.setId('order by')
            	.setNodeType('order by')
            	.setLeft(fieldList.head)
            	.build(),
            fieldList.subquery
        );
    }
    
    private Intermediary parseLimit(String query) {
        query = ParserUtils.skipWhitespace(query);
        if(query.length() == 0 || query.length() < 5) return null;
        if(query.subString(0, 5) != 'limit') return null;
        
        query = query.subString(5);
        Intermediary limitSize = parseNum(query);
        return new Intermediary(
        	new NodeBuilder()
            	.setId('limit')
            	.setNodeType('limit')
            	.setLeft(limitSize.head)
            	.build(),
            limitSize.subquery
        );
    }
    
    private Intermediary parseForUpdate(String query) {
        query = ParserUtils.skipWhitespace(query);
        if(query.length() == 0 || query.length() < 3) return null;
        if(lookahead(query, 3) != 'for') return null;
        
        query = query.subString(3);
        query = ParserUtils.skipWhitespace(query);
        query = consume(query, 'update');
        
        return new Intermediary(
        	new NodeBuilder()
            	.setId('for update')
            	.setNodeType('for update')
            	.build(),
            query
        );
    }
    
    private Intermediary parseHaving(String query) {
        query = ParserUtils.skipWhitespace(query);
        if(query.length() == 0) return null;
        if(query.length() < 6) return null;
        if(query.subString(0, 6) != 'having') return null;
        
        query = consume(query, 'having');
        query = ParserUtils.skipWhitespace(query);
        Intermediary aggregateFunc = parseAggregateFunc(query);
        query = aggregateFunc.subquery;
        query = ParserUtils.skipWhitespace(query);
        
        Intermediary operator = parseOperator(query);
        query = operator.subquery;
        query = ParserUtils.skipWhitespace(query);
        
        Intermediary value = parseValue(query);
        query = value.subquery;
        query = ParserUtils.skipWhitespace(query);
        
        operator.head.left = aggregateFunc.head;
    	operator.head.right = value.head;
        
        
        return new Intermediary(
        	new NodeBuilder()
            	.setId('having')
            	.setNodeType('having')
            	.setLeft(operator.head)
            	.build(),
            query
        );
    }
    
    private Intermediary parseAggregateFunc(String query) {
        NodeBuilder nb = new NodeBuilder()
            .setNodeType('aggregate function');
        if(lookahead(query, 5) == 'count') {
            query = query.subString(5);
            nb.setId('count');
        } else if(lookahead(query, 3) == 'sum') {
            query = query.subString(3);
            nb.setId('sum');
        } else if(lookahead(query, 3) == 'avg') {
            query = query.subString(3);
            nb.setId('avg');
        } else if(lookahead(query, 3) == 'min') {
            query = query.subString(3);
            nb.setId('min');
        } else if(lookahead(query, 3) == 'max') {
            query = query.subString(3);
            nb.setId('max');
        } else {
            throw new ParsingException( query, 'aggregate function');
        }
        query = ParserUtils.skipWhitespace(query);
        query = consume(query, '(');
        
        Intermediary field = parseField(query);
        nb.setLeft(field.head);
        query = field.subquery;
        query = consume(query, ')');
        
        
        return new Intermediary(
			nb.build(),
            query
        );
    }
}