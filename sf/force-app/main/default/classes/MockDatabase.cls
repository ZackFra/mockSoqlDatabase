public with sharing class MockDatabase {

    @TestVisible
    Map<String, Map<String, sObject>> db;
    
    Integer sObjnum = 1;
    public String getFakeId(Schema.SObjectType sot) {
        String result = String.valueOf(sObjNum++);
        String fakeId = result + sot.getDescribe().getKeyPrefix().rightPad(15 - result.length(), '0');
        return fakeId;
    }

    private String getSObjectApiName(String objName) {
        Type t = type.forName(objName);
        if(t == null) {
            throw new QueryException('Invalid object name: ' + objName);
        }
        DescribeSObjectResult dsor = (((SObject)t.newInstance()).getSObjectType()).getDescribe();
        String objApiName = dsor.getName();
        return objApiName;
    }


    public MockDatabase() {
        this.db = new Map<String, Map<String, sObject>>();
    }

    private Object getFieldNodeValue(Tokenizer.Node valueNode, sObject sObj, Map<String, Object> params) {

        Boolean isBindVar = (valueNode.nodeType == 'bind variable');
        Boolean isParamsNull = (params == null);
        Boolean isValueInParams = (!isParamsNull && params.containsKey(valueNode.id));

        if(isBindVar && isParamsNull || isBindVar && !isValueInParams) {
            throw new QueryException('Missing bind variable: ' + valueNode.id);
        }

        if(isBindVar) {
            return params.get(valueNode.id);
        }
        return valueNode.Id;
    }

    private Boolean isWhereAndConditionMet(Tokenizer.Node andNode, sObject sObj, Map<String, Object> params) {
        Tokenizer.Node leftNode = andNode.left;
        Tokenizer.Node rightNode = andNode.right;

        return (
            isWhereConditionMet(leftNode, sObj, params) &&
            isWhereConditionMet(rightNode, sObj, params)
        );
    }

    private Boolean isWhereOrConditonMet(Tokenizer.Node orNode, sObject sObj, Map<String, Object> params) {
        Tokenizer.Node leftNode = orNode.left;
        Tokenizer.Node rightNode = orNode.right;

        return (
            isWhereConditionMet(leftNode, sObj, params) ||
            isWhereConditionMet(rightNode, sObj, params)
        );
    }

    private Boolean isWhereCompareConditionMet(Tokenizer.Node operatorNode, sObject sObj, Map<String, Object> params) {
        Tokenizer.Node fieldNode = operatorNode.left;
        Tokenizer.Node valueNode = operatorNode.right;
        
        Object fieldValue = getFieldNodeValue(valueNode, sObj, params);
        
        switch on operatorNode.id {
            when '=' {
                return sObj.get(fieldNode.id) == fieldValue;
            }
            when '!=', '<>' {
                return sObj.get(fieldNode.id) != fieldValue;
            }
            when 'like' {
                String regexPattern = String.valueOf(fieldValue)
                    .replaceAll('%', '.*')
                    .replaceAll('_', '.');
                Pattern regex = Pattern.compile(regexPattern);
                Matcher regexMatcher = regex.matcher(String.valueOf(sObj.get(fieldNode.id)).toLowerCase());
                return regexMatcher.matches();
            }
        }

        throw new QueryException('Invalid where condition');
    }

    private Boolean isConditionalSubExprMet(Tokenizer.Node subExprNode, sObject sObj, Map<String, Object> params) {
        return isWhereConditionMet(subExprNode.left, sObj, params);
    }

    private Boolean isWhereConditionMet(Tokenizer.Node whereField, sObject sObj, Map<String, Object> params) {
        if(whereField.nodeType == 'operator') {
            return isWhereCompareConditionMet(whereField, sObj, params);
        } else if(whereField.nodeType == 'and') {
            return isWhereAndConditionMet(whereField, sObj, params);
        } else if(whereField.nodeType == 'or') {
            return isWhereOrConditonMet(whereField, sObj, params);
        } else if(whereField.nodeType == 'conditional subexpression') {
            return isConditionalSubExprMet(whereField, sObj, params);
        }

        throw new QueryException('Invalid where condition');
    }

    private Boolean checkWhereCondition(sObject sObj, Tokenizer.Node whereNode, Map<String, Object> params) {
        if(whereNode == null) {
            return true;
        }

        Tokenizer.Node whereField = whereNode.left;

        return isWhereConditionMet(whereField, sObj, params);
    }

    private sObject copyWithFields(sObject obj, Tokenizer.Node selectNode) {
        Tokenizer.Node field = selectNode.left;
        sObject sObj = (sObject) Type.forName(obj.getSObjectType().getDescribe().getName()).newInstance();

        while(field != null) {

            String fieldName = field.id;
            Object fieldValue = obj.get(fieldName);
            if (fieldValue != null) {
                sObj.put(fieldName, fieldValue);
            }
            field = field.left;
        }
        return sObj;
    }

    // @description: This method is used to query the mock database by traversing the AST
    private List<sObject> doQuery(String query, Map<String, Object> params) {
        Tokenizer parser = new Tokenizer();
        Tokenizer.Node selectNode = parser.parse(query);

        Tokenizer.Node fromNode = selectNode.right;
        Tokenizer.Node whereNode;

        if(fromNode.right != null) {
            whereNode = fromNode.right;
        }

        Tokenizer.Node objNode = fromNode.left;
        String objName = objNode.id;
        String objApiName = getSObjectApiName(objName);

        Map<String, sObject> mockObjects = this.db.get(objApiName);
        if (mockObjects == null) {
            return new List<sObject>();
        }

        List<sObject> results = new List<sObject>();
        for(sObject obj : mockObjects.values()) {
            if(!checkWhereCondition(obj, whereNode, params)) {
                continue;
            }

            sObject sObj = copyWithFields(obj, selectNode);
            results.add(sObj);
        }

        return results;
    }

    /** DML methods **/

    public void doInsert(sObject obj) {
        String objName = obj.getSObjectType().getDescribe().getName();
        Map<String, sObject> mockObjects = this.db.get(objName);

        String fakeId = getFakeId(obj.getSObjectType());
        obj.put('Id', fakeId);
        if (mockObjects == null) {
            mockObjects = new Map<String, sObject>();
            this.db.put(objName, mockObjects);
        } else if (mockObjects.get(obj.Id) != null) {
            throw new DmlException('Duplicate id');
        }

        mockObjects.put(obj.Id, obj);
    }

    public void doInsert(List<sObject> objList) {
        for(sObject obj : objList) {
            doInsert(obj);
        }
    }

    public void doUpdate(sObject obj) {
        String objName = obj.getSObjectType().getDescribe().getName();
        Map<String, sObject> mockObjects = this.db.get(objName);

        if (mockObjects == null) {
            throw new DmlException('Object does not exist');
        } else if (mockObjects.get(obj.Id) == null) {
            throw new DmlException('Object does not exist');
        }

        mockObjects.put(obj.Id, obj);
    }

    public void doUpdate(List<sObject> objList) {
        for(sObject obj : objList) {
            doUpdate(obj);
        }
    }

    public void doDelete(sObject obj) {
        String objName = obj.getSObjectType().getDescribe().getName();
        Map<String, sObject> mockObjects = this.db.get(objName);

        if (mockObjects == null) {
            throw new DmlException('Object does not exist');
        } else if (mockObjects.get(obj.Id) == null) {
            throw new DmlException('Object does not exist');
        }

        mockObjects.remove(obj.Id);
    }

    public void doDelete(List<sObject> objList) {
        for(sObject obj : objList) {
            doDelete(obj);
        }
    }


    /** SOQL methods **/

    // @description: This method is used to query the mock database by traversing the AST
    public List<sObject> query(String query) {
        return doQuery(query, null);
    }

    // @description: This method is used to query the mock database by traversing the AST with bind variables
    public Object query(String query, Map<String, Object> params) {
        Map<String, Object> lowerCaseParams = new Map<String, Object>();
        for(String key : params.keySet()) {
            lowerCaseParams.put(key.toLowerCase(), params.get(key));
        }

        return doQuery(query, lowerCaseParams);        
    }
}