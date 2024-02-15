for(AggregateResult ar : [SELECT Opportunity.Name, Opportunity.Account.Name acctName, Opportunity.StageName, SUM(Opportunity.Amount)
    FROM OpportunityLineItem
    GROUP BY ROLLUP(Opportunity.Name, Opportunity.Account.Name, Opportunity.StageName)]) {
        System.debug(ar);
}
