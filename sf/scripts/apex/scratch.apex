Tokenizer t = new Tokenizer();

System.debug(t.parse('SELECT Opportunity.Account.Name, Opportunity.Name, Opportunity.Account.BillingStreet, Opportunity.CloseDate FROM OpportunityLineItem WHERE Opportunity.Id = :oppId'));