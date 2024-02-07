Map<String,String> objectMap = new Map<String,String>();
Map<String, String> objToFieldMap = new Map<String, String>();

for(Schema.SObjectType objTyp : Schema.getGlobalDescribe().Values()){
    Schema.DescribeSObjectResult dsor = objTyp.getDescribe();
    Map<String,Schema.SObjectField> fieldMap = dsor.fields.getMap();
    for(String fld : fieldMap.keySet()){
        Schema.SObjectField fldObj = fieldMap.get(fld);
        Schema.DescribeFieldResult dfr = fldObj.getDescribe();
        if(dfr.getType() == Schema.DisplayType.MULTIPICKLIST) {
            String objName = objTyp.getDescribe().getName();
            objToFieldMap.put(objName, fld);
        }
    }
}
System.debug(objToFieldMap);