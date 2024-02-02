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
    
    public class NodeBuilder {
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

    public static Node clone(Node head) {
        if(head == null) {
            return null;
        }
        NodeBuilder nb = new NodeBuilder()
            .setId(head.id)
            .setNodeType(head.nodeType);
        if(head.left != null) {
            nb.setLeft(clone(head.left));
        }
        if(head.right != null) {
            nb.setRight(clone(head.right));
        }
        return nb.build();
    }
    
    // @description : Consumes a token from the query, throwing an error if the token is not present
    private String consume(String query, String token) {
        if(query.length() < token.length() || query.subString(0, token.length()) != token) {
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
        query = query.trim();
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
		if(nextLink.subquery != '' && lookahead(nextLink.subquery, 1) != ')') {
            throw new ParsingException(nextLink.subquery, null);
        }
        return selectIntermediary;
    }
    
    private Intermediary parseSelect(String query) {
        query = ParserUtils.skipWhitespace(query);
        
        query = consume(query, 'select');
        Intermediary leftIntermediary = parseSelectExpr(query);
        query = leftIntermediary.subquery;
        return new Intermediary(
        	new NodeBuilder()
            	.setId('select')
            	.setNodeType('select')
            	.setLeft(leftIntermediary.head)
            	.build(),
            query
        );
        
    }
    
    private Intermediary parseSelectExpr(String query) {
        query = ParserUtils.skipWhitespace(query);
        Intermediary selectExpr;

        if(isAggregateFunction(query)) {
            selectExpr = parseAggregateFunc(query);
            query = selectExpr.subquery;
        } else if(lookahead(query, 1) == '(') {
            query = consume(query, '(');
            Intermediary soqlSubQuery = parseQuery(query);
            query = soqlSubQuery.subquery;
            query = ParserUtils.skipWhitespace(query);
            query = consume(query, ')');
            selectExpr = new Intermediary(
            	new NodeBuilder()
                	.setId('subquery')
                	.setNodeType('subquery')
                	.setRight(soqlSubQuery.head)
                	.build(),
                query
            );
        } else {
            selectExpr = parseFieldListWithAliases(query);
            query = selectExpr.subquery;
        }
        
        query = ParserUtils.skipWhitespace(query);
        String nextChar = lookahead(query, 1);
        if(nextChar == ',') {
            query = consume(query, ',');
            Intermediary restOfExpr = parseSelectExpr(query);
            Node curr = selectExpr.head;
            while(curr.left != null) {
                curr = curr.left;
            }
            curr.left = restOfExpr.head;
            selectExpr.subquery = restOfExpr.subquery;
        }
        return selectExpr;
    }

    // @description : Parses a list of fields, with optional aliases
    // @return : Intermediary, the head of the list of fields
    private Intermediary parseFieldListWithAliases(String query) {
        query = ParserUtils.skipWhitespace(query);
        Intermediary nextItem;
        if(isAggregateFunction(query)) {
            nextItem = parseAggregateFunc(query);
            query = nextItem.subquery;
        } else {
            nextItem = parseField(query);
            query = ParserUtils.skipWhitespace(nextItem.subquery);
        }
        
        String nextChar = lookahead(query, 1);
        String nextCharAfterThat = lookahead(ParserUtils.skipWhitespace(query.subString(1)), 1);
        Boolean isAggrFuncNext = isAggregateFunction(ParserUtils.skipWhitespace(query.subString(1)));
        
        if(nextChar == ',' && nextCharAfterThat != '(' && !isAggrFuncNext) {
            query = query.subString(1);
            Intermediary restOfList = parseFieldListWithAliases(query);
            nextItem.head.left = restOfList.head;
            nextItem.subquery = restOfList.subquery;
        }

        Intermediary alias = null;
        query = ParserUtils.skipWhitespace(nextItem.subquery);
        if(lookahead(query, 5) != 'from ' && lookahead(query, 1) != ',') {
            // NOTE: alias might still be null after parsing, that's ok
            alias = parseAlias(query);
        }
        
        if(alias != null) {
            nextItem.head.right = alias.head;
            query = alias.subquery;
            nextItem.subquery = query;
        }

        query = ParserUtils.skipWhitespace(nextItem.subquery);
        nextChar = lookahead(query, 1);
        nextCharAfterThat = lookahead(ParserUtils.skipWhitespace(query.subString(1)), 1);
        isAggrFuncNext = isAggregateFunction(ParserUtils.skipWhitespace(query.subString(1)));
        
        if(nextChar == ',' && nextCharAfterThat != '(' && !isAggrFuncNext) {
            query = query.subString(1);
            Intermediary restOfList = parseFieldListWithAliases(query);
            nextItem.head.left = restOfList.head;
            nextItem.subquery = restOfList.subquery;
        }


        return nextItem;        
    }
    
    private Intermediary parseFieldList(String query) {
        query = ParserUtils.skipWhitespace(query);
        Intermediary nextItem;
        if(isAggregateFunction(query)) {
            nextItem = parseAggregateFunc(query);
            query = nextItem.subquery;
        } else {
            nextItem = parseField(query);
            query = ParserUtils.skipWhitespace(nextItem.subquery);
            if(query.length() == 0) {
                return nextItem;
            }
        }
        
        String nextChar = lookahead(query, 1);
        String nextCharAfterThat = lookahead(ParserUtils.skipWhitespace(query.subString(1)), 1);
        
        if(nextChar == ',' && nextCharAfterThat != '(') {
            query = query.subString(1);
            Intermediary restOfList = parseFieldList(query);
            nextItem.head.left = restOfList.head;
            nextItem.subquery = restOfList.subquery;
        }
        return nextItem;
    }

    private Boolean isAggregateFunction(String query) {
        query = ParserUtils.skipWhitespace(query);
        Boolean isLongEnough = (query.length() >= 3);
        Boolean isSum = isLongEnough && lookahead(query, 3) == 'sum';
        Boolean isAvg = isLongEnough && lookahead(query, 3) == 'avg';
        Boolean isMin = isLongEnough && lookahead(query, 3) == 'min';
        Boolean isMax = isLongEnough && lookahead(query, 3) == 'max';
        Boolean isCount = isLongEnough && lookahead(query, 5) == 'count';
        Boolean isCountDistinct = isLongEnough && lookahead(query, 14) == 'count_distinct';
        return isSum || isAvg || isMin || isMax || isCount || isCountDistinct;
    }

    // @description : Returns true if the next three tokens in the query denote a subfield
    private Boolean isSubField(String query) {
        Boolean isLongEnough = (query.length() >= 3);
        Boolean isValidChar = isLongEnough && ParserUtils.validCharForFieldOrObject(query.subString(0, 1));
        Boolean isDot = isValidChar && query.subString(1, 2) == '.';
        Boolean isSubField = isDot && ParserUtils.validCharForFieldOrObject(query.subString(2, 3));
        return isSubField;
    }

    // @description returns true if the next token in the query is a field or object
    private Boolean isNextTokenFieldOrObject(String query) {
        return ParserUtils.validCharForFieldOrObject(lookahead(query, 1));
    }
    
    private Intermediary parseField(String query) {
        query = ParserUtils.skipWhitespace(query);
        String fieldName = '';
        while(query.length() != 0 && 
              isNextTokenFieldOrObject(query) ||
              isSubField(query)) {

            if(isSubField(query)) {
                fieldName += lookahead(query, 3);
                query = query.subString(3);
            } else {
                fieldName += lookahead(query, 1);
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
        if(query.length() == 0) {
            return null;
        }
        if(lookahead(query, 5) != 'where') {
            return null;
        }
        query = consume(query, 'where');
        
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

    private Intermediary parseConditionalSubExpr(String query) {
        query = consume(query, '(');
        Intermediary subExpr = parseConditionalExpr(query);
        query = subExpr.subquery;
        query = consume(query, ')');
        return new Intermediary(
            new NodeBuilder()
                .setId('conditional subexpression')
                .setNodeType('conditional subexpression')
                .setLeft(subExpr.head)
                .build(),
            query
        );
    }

    private Intermediary parseNot(String query) {
        query = consume(query, 'not');
        query = consume(query, ' ');
        query = ParserUtils.skipWhitespace(query);

        Intermediary subExpr = parseConditionalExpr(query);
        query = subExpr.subquery;
        return new Intermediary(
            new NodeBuilder()
                .setId('not')
                .setNodeType('not')
                .setLeft(subExpr.head)
                .build(),
            query
        );
    } 

    private Intermediary parseConditionalOperationExpr(String query) {
        if(lookahead(query, 3) == 'not') {
            return parseNot(query);
        }
        Intermediary fieldIntermediary = parseField(query);
        query = fieldIntermediary.subquery;
        query = ParserUtils.skipWhitespace(query);

        Intermediary operatorIntermediary = parseOperator(query);
        query = operatorIntermediary.subquery;
        query = ParserUtils.skipWhitespace(query);
        Boolean isIn = operatorIntermediary.head.id == 'in';
        Boolean isNotIn = operatorIntermediary.head.id == 'not in';
        if((isIn || isNotIn) && lookahead(query, 1) == '(') {
            query = consume(query, '(');
            Intermediary listOrQuery;
            if(lookahead(query, 6) == 'select') {
                Intermediary soqlSubQuery = parseQuery(query);
                listOrQuery = new Intermediary(
                    new NodeBuilder()
                        .setId('subquery')
                        .setNodeType('subquery')
                        .setRight(soqlSubQuery.head)
                        .build(),
                    soqlSubQuery.subquery
                );
            } else {
                listOrQuery = parseValueList(query);
            }
            query = listOrQuery.subquery;
            query = ParserUtils.skipWhitespace(query);

            query = consume(query, ')');

            operatorIntermediary.head.right = listOrQuery.head;
        } else {
            Intermediary valueIntermediary = parseValue(query);
            query = valueIntermediary.subquery;
            operatorIntermediary.head.right = valueIntermediary.head;
        }
        operatorIntermediary.subquery = query;
        operatorIntermediary.head.left = fieldIntermediary.head;

        return operatorIntermediary;
    }

    private Intermediary parseConditionalExpr(String query) {
        query = ParserUtils.skipWhitespace(query);

        Intermediary leftIntermediary;

        // work out the left intermediary first, it's either a sub-expression or a field being compared to a value
        if(lookahead(query, 1) == '(') {
            leftIntermediary = parseConditionalSubExpr(query);
        } else {
            leftIntermediary = parseConditionalOperationExpr(query);
        }
        query = leftIntermediary.subquery;
        query = ParserUtils.skipWhitespace(query);

        // if the next token is an AND or OR, parse it
        String token = null;
        if(lookahead(query, 3) == 'and') {
            token = 'and';
        }

        if(lookahead(query, 2) == 'or') {
            token = 'or';
        }

        if(token == null) {
            return leftIntermediary;
        }

        query = consume(query, token);
        Intermediary restOfExpr = parseConditionalExpr(query);
        query = restOfExpr.subquery;

        Tokenizer.Node head = new NodeBuilder()
                .setId(token)
                .setNodeType(token)
                .setLeft(leftIntermediary.head)
                .setRight(restOfExpr.head)
                .build();

        Tokenizer.Node prev = head;
        Tokenizer.Node curr = head.right;
        while(curr != null) {
            if(curr.nodeType == 'or') {
                prev.right = curr.left;
                curr.left = head;
                head = curr;
            }
            curr = curr.right;
        }

        return new Intermediary(
            head,
            query
        );
    }

    private Intermediary parseValueList(String query) {
        query = ParserUtils.skipWhitespace(query);
        
        Intermediary value = parseValue(query);
        query = value.subquery;
        query = ParserUtils.skipWhitespace(query);
        
        if(lookahead(query, 1) == ',') {
            query = consume(query, ',');
            Intermediary restOfList = parseValueList(query);
            value.head.left = restOfList.head;
            value.subquery = restOfList.subquery;
        }
        query = value.subquery;
        return new Intermediary(
            new NodeBuilder()
            .setId('value list')
            .setNodeType('value list')
            .setLeft(value.head)
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
            '<',
            'includes',
            'excludes'
        };
        for(String token : opTokens) {
            if(query.length() >= token.length() && lookahead(query, token.length()) == token) {
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
        if(lookahead(query, 1) == '\'') {
            query = query.subString(1);
            baseValue = parseString(query);
            query = baseValue.subquery;
            if(lookahead(query, 1) != '\'') {
                throw new ParsingException(baseValue.subquery, '\'');
            }
            query = consume(query, '\'');
            baseValue.subquery = query;
            return baseValue;
        } else if(query.length() >= 4 && (query.subString(0, 4) == 'true' || query.subString(0, 5) == 'false')) {
        	return parseBoolean(query);
        } else if(lookahead(query, 1) == ':') {
            query = consume(query, ':');
            return parseBindVariable(query);
        } else {
        	return parseNum(query);
        }
    }

    private Intermediary parseBindVariable(String query) {
        query = ParserUtils.skipWhitespace(query);
        String bindVarName = '';
        while(query.length() > 0 && isNextTokenFieldOrObject(query)) {
            bindVarName += query.subString(0, 1);
            query = query.subString(1);
        }

        if(bindVarName.isNumeric()) {
            throw new ParsingException(bindVarName, 'bind variable name');
        }

        return new Intermediary(
            new NodeBuilder()
                .setId(bindVarName)
                .setNodeType('bind variable')
                .build(),
            query
        );
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

        Boolean isTrue = (lookahead(query, 4) == 'true');
        Boolean isFalse = (lookahead(query, 5) == 'false');
        
        if(!isTrue && !isFalse) {
        	throw new ParsingException(query, 'boolean');
        }
        
        String boolVal;
        if(isTrue) {
            boolVal = 'true';
        } else { 
            boolVal = 'false';
        }
        
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
        while(query.length() != 0 && lookahead(query, 1) != '\'') {
            strValue += lookahead(query, 1);
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
        if(query.length() < 5) {
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
        if(query.length() < 5 || lookahead(query, 5) != 'limit') { 
            return null;
        }
        
        query = consume(query, 'limit');
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
        if(query.length() == 0 || query.length() < 3) { 
            return null;
        }
        if(lookahead(query, 3) != 'for') {
            return null;
        }
        
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
        if(query.length() < 6 || lookahead(query, 6) != 'having') {
            return null;
        }

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

    // @description : Parses an alias, which is a string of characters that is not a number
    private Intermediary parseAlias(String query) {

        query = ParserUtils.skipWhitespace(query);
        // if the next character is not a letter, it's not an alias
        if(!lookahead(query, 1).isAlpha()) {
            return null;
        }

        String aliasName = '';
        while(query.length() > 0 && ParserUtils.validCharForFieldOrObject(lookahead(query, 1))) {
            aliasName += lookahead(query, 1);
            query = query.subString(1);
        }

        if(aliasName.isNumeric()) {
            throw new ParsingException(aliasName, 'alias name');
        }

        return new Intermediary(
            new NodeBuilder()
                .setId(aliasName)
                .setNodeType('alias')
                .build(),
            query
        );
    }
    
    private Intermediary parseAggregateFunc(String query) {
        NodeBuilder nb = new NodeBuilder()
            .setNodeType('aggregate function');
        if(lookahead(query, 14) == 'count_distinct') {
            query = consume(query, 'count_distinct');
            nb.setId('count_distinct');
        } else if(lookahead(query, 5) == 'count') {
            query = consume(query, 'count');
            nb.setId('count');
        } else if(lookahead(query, 3) == 'sum') {
            query = consume(query, 'sum');
            nb.setId('sum');
        } else if(lookahead(query, 3) == 'avg') {
            query = consume(query, 'avg');
            nb.setId('avg');
        } else if(lookahead(query, 3) == 'min') {
            query = consume(query, 'min');
            nb.setId('min');
        } else if(lookahead(query, 3) == 'max') {
            query = consume(query, 'max');
            nb.setId('max');
        } else {
            throw new ParsingException( query, 'aggregate function');
        }
        query = ParserUtils.skipWhitespace(query);
        
        query = consume(query, '(');
        if(nb.id == 'count' && lookahead(query, 1) == ')') {
            query = consume(query, ')');
            return new Intermediary(
            	nb.build(),
                query
            );
        }

        query = ParserUtils.skipWhitespace(query);
        Intermediary field = parseField(query);
        
        query = field.subquery;
        query = consume(query, ')');

        Intermediary alias = null;
        query = ParserUtils.skipWhitespace(query);
        if(lookahead(query, 5) != 'from ') {
            // NOTE: alias might still be null after parsing, that's ok
            alias = parseAlias(query);
        }

        if(alias != null) {
            field.head.left = alias.head;
            query = alias.subquery;
        }
        nb.setRight(field.head);
        
        
        return new Intermediary(
			nb.build(),
            query
        );
    }
}