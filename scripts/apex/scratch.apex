/**System.debug([
    SELECT Id, Description, DeveloperName, EnforcementType, 
    FullName, IsActive, Language, MasterLabel, Metadata, RecordFilter,
    TargetEntity, UserCriteria, Version
    FROM RestrictionRule
]);**/

FormulaEval.FormulaInstance isItSuper = FormulaEval.FormulaBuilder.builder()
                            .withReturnType(FormulaEval.FormulaReturnType.Boolean)
                            .withType(Account.class)
                            .withFormula('OwnerId=$User.Id"')
                            .build();
isItSuper.evaluate(aBoat); //=> "Not Super"