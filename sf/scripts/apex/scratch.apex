String parentRecordApiName = 'Opportunity';
String strField = 'name';
DescribeSObjectResult dsor = Schema.getGlobalDescribe().get(parentRecordApiName).getDescribe();
 fields = dsor.fields.getMap();
DescribeFieldResult dfr = dsor.get(strField).getDescribe();
System.debug(dfr);