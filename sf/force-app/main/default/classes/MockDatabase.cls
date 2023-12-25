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


    public Object query(String query, Map<String, Object> params) {
        Tokenizer parser = new Tokenizer();
        Tokenizer.Node selectNode = parser.parse(query);
        Tokenizer.Node fromNode = selectNode.right;

        String objName = fromNode.left.id;
        String objApiName = getSObjectApiName(objName);

        return doQuery(selectNode, objApiName, params);        
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

    Boolean isWhereConditionMet(Tokenizer.Node operatorNode, sObject sObj, Map<String, Object> params) {
        Tokenizer.Node fieldNode = operatorNode.left;
        Tokenizer.Node valueNode = operatorNode.right;
        
        Object fieldValue = getFieldNodeValue(valueNode, sObj, params);
        if(operatorNode.nodeType != 'operator') {
            // TODO : implement for other node types
            throw new QueryException('Invalid where condition');
        }
        
        switch on operatorNode.id {
            when '=' {
                return sObj.get(fieldNode.id) == fieldValue;
            }
            when '!=', '<>' {
                return sObj.get(fieldNode.id) != fieldValue;
            }
        }

        throw new QueryException('Invalid where condition');
    }

    private Boolean meetsWhereConditions(sObject sObj, Tokenizer.Node whereNode, Map<String, Object> params) {
        if(whereNode == null) {
            return true;
        }

        Tokenizer.Node whereField = whereNode.left;

        // @TODO : add better... everything handling here lol
        while(whereField != null) {
            if(whereField.nodeType != 'operator') {
                whereField = whereField.left;
                continue;
            }

            Tokenizer.Node operatorNode = whereNode.left;
            Tokenizer.Node valueNode = operatorNode.right;
            
            Object fieldValue = getFieldNodeValue(valueNode, sObj, params);
            if(!isWhereConditionMet(whereField, sObj, params)) {
                return false;
            }
            
            whereField = whereField.left;
        }
        return true;
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
    private Object doQuery(Tokenizer.Node head, String objApiName, Map<String, Object> params) {
        Tokenizer.Node selectNode = head;
        Tokenizer.Node fromNode = selectNode.right;
        Tokenizer.Node whereNode;

        if(fromNode.right != null) {
            whereNode = fromNode.right;
        }

        Map<String, sObject> mockObjects = this.db.get(objApiName);
        if (mockObjects == null) {
            return new List<sObject>();
        }

        List<sObject> results = new List<sObject>();
        for(sObject obj : mockObjects.values()) {
            System.debug('where node = ' + whereNode);
            if(!meetsWhereConditions(obj, whereNode, params)) {
                continue;
            }

            sObject sObj = copyWithFields(obj, selectNode);
            results.add(sObj);
        }
        if(results.size() == 1) {
            return results[0];
        }
        return results;
    }

    public Object query(String query) {
        Tokenizer parser = new Tokenizer();
        Tokenizer.Node selectNode = parser.parse(query);
        Tokenizer.Node fromNode = selectNode.right;

        Tokenizer.Node whereNode;
        if(fromNode.right != null) {
            whereNode =  fromNode.right;
        }
        
        String objName = fromNode.left.id;

        String objApiName = getSObjectApiName(objName);

        return doQuery(selectNode, objApiName, null);
    }

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
}