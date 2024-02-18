/**
 * @description This class is used to create test data for the test classes
 */
public class TestDataFactory {

    /**
     * @description create a standard set of accounts for testing,
     * creates the same test accounts as in a trailhead module
     */
    public static List<Account> createTrailheadAccounts() {
    /**
     *  NumberOfEmployees Account Number Name                                AnnualRevenue
     *  1000              CD451796       Edge Communications                 1000              
        9000              CD656092       Burlington Textiles Corp of America 9000              
        2680              CC213425       Pyramid Construction Inc.           2680              
        120               CC634267       Dickenson plc                       120               
        5600              CD439877       Grand Hotels & Resorts Ltd          5600              
        145000            CD355118       United Oil & Gas Corp.              145000            
        12300             CC947211       Express Logistics and Transport     12300             
        39000             CD736025       University of Arizona               39000             
        24000             CD355119-A     United Oil & Gas, UK                24000             
        3000              CD355120-B     United Oil & Gas, Singapore         3000              
        265               CC978213       GenePoint                           265               
        null              null           sForce                              null              
        null              null           Sample Account for Entitlements     null 
    */
        Account a = new Account(NumberOfEmployees = 1000, AccountNumber = 'CD451796', Name = 'Edge Communications', AnnualRevenue = 139000000, BillingState='TX');
        Account b = new Account(NumberOfEmployees = 9000, AccountNumber = 'CD656092', Name = 'Burlington Textiles Corp of America', AnnualRevenue = 350000000, BillingState = 'NC');
        Account c = new Account(NumberOfEmployees = 2680, AccountNumber = 'CC213425', Name = 'Pyramid Construction Inc.', AnnualRevenue = 950000000);
        Account d = new Account(NumberOfEmployees = 120, AccountNumber = 'CC634267', Name = 'Dickenson plc', AnnualRevenue = 50000000, BillingState = 'KS');
        Account e = new Account(NumberOfEmployees = 5600, AccountNumber = 'CD439877', Name = 'Grand Hotels & Resorts Ltd', AnnualRevenue = 500000000, BillingState = 'IL');
        Account f = new Account(NumberOfEmployees = 145000, AccountNumber = 'CD355118', Name = 'United Oil & Gas Corp.', AnnualRevenue = 5600000000.0, BillingState = 'NY');
        Account g = new Account(NumberOfEmployees = 12300, AccountNumber = 'CC947211', Name = 'Express Logistics and Transport', AnnualRevenue = 950000000.0, BillingState = 'OR');
        Account h = new Account(NumberOfEmployees = 39000, AccountNumber = 'CD736025', Name = 'University of Arizona', BillingState = 'AZ');
        Account i = new Account(NumberOfEmployees = 24000, AccountNumber = 'CD355119-A', Name = 'United Oil & Gas, UK', BillingState = 'UK');
        Account j = new Account(NumberOfEmployees = 3000, AccountNumber = 'CD355120-B', Name = 'United Oil & Gas, Singapore', BillingState = 'Singapore');
        Account k = new Account(NumberOfEmployees = 265, AccountNumber = 'CC978213', Name = 'GenePoint', AnnualRevenue = 30000000.0, BillingState = 'CA');
        Account l = new Account(Name = 'sForce', BillingState = 'CA');
        Account m = new Account(Name = 'Sample Account for Entitlements');

        List<Account> acctList = new List<Account>{a, b, c, d, e, f, g, h, i, j, k, l, m};
        return acctList;
    }
}