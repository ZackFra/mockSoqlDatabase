@IsTest
public with sharing class StubProvider implements System.StubProvider {
    static Integer s_num = 1;
    public static String getFakeId(Schema.SObjectType sot)
    {
        String result = String.valueOf(s_num++);
        String fakeId = sot.getDescribe().getKeyPrefix().rightPad(15, '0');
        return fakeId;
    }
    
    Map<String, MockQueryHandler> queryHandlers;
    public StubProvider(Map<String, MockQueryHandler> queryHandlers) {
        this.queryHandlers = queryHandlers;
    }
    
    public Object handleMethodCall(
        Object stubbedObject, 
        String stubbedMethodName, 
        System.Type returnType, 
        List<System.Type> listOfParamTypes, 
        List<String> listOfParamNames, 
        List<Object> listOfArgs) {

        Boolean isQuery = (stubbedMethodName == 'query');
        Boolean isSelector = (stubbedObject instanceof Selector);
        if(!isQuery && !isSelector) return null;
        
        String query = (String) listOfArgs[0];
        MockQueryHandler queryHandler = queryHandlers.get(query);
        if(queryHandler == null) return null;
        return queryHandler.handleQuery();
    }
}