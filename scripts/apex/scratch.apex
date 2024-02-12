List<Schema.SObjectField> fields = SchemaService.getFields(
    SchemaService.getSObjectType('Name')
);
for(Schema.SObjectField field : fields) {
    System.debug(SchemaService.getSObjectName(
        SchemaService.getNameSObjectType())
    );
}