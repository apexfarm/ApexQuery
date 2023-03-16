@isTest
public with sharing class QueryTest extends Query {
    @TestSetup
    static void makeData() {
        // prettier-ignore
        List<Account> accountList = new List<Account> {
            new Account(Name = 'Account 1', AnnualRevenue = 1500, BillingCountry = 'China', BillingState = 'Shanghai'),
            new Account(Name = 'Account 2', AnnualRevenue = 500, BillingCountry = 'China', BillingState = 'Shanghai'),
            new Account(Name = 'Account 3', AnnualRevenue = 1500, BillingCountry = 'China', BillingState = 'Beijing'),
            new Account(Name = 'Account 4', AnnualRevenue = 500, BillingCountry = 'China', BillingState = 'Beijing'),
            new Account(Name = 'Account 5', AnnualRevenue = 1500),
            new Account(Name = 'Account 6', AnnualRevenue = 500)
        };
        insert accountList;

        // prettier-ignore
        List<Contact> contactList = new List<Contact> {
            new Contact(LastName = 'Contact 1', AccountId = accountList[0].Id),
            new Contact(LastName = 'Contact 2', AccountId = accountList[1].Id),
            new Contact(LastName = 'Contact 3', AccountId = accountList[2].Id),
            new Contact(LastName = 'Contact 4', AccountId = accountList[3].Id)
        };
        insert contactList;
    }

    @isTest
    static void testQuery_Of_Soql() {
        // prettier-ignore
        List<Account> accountList = (List<Account>) Query.of(Account.SObjectType)
            .selectWith('Name', 'AnnualRevenue', 'BillingState')
            .selectWith('Contacts', Query.of(Contact.SObjectType).selectWith('Name'))
            .filterBy(orx()
                .add(andx()
                    .add(gt('AnnualRevenue', 1000))
                    .add(eq('BillingCountry', 'China'))
                    .add(eq('BillingState', 'Beijing'))
                )
                .add(andx()
                    .add(lt('AnnualRevenue', 1000))
                    .add(eq('BillingCountry', 'China'))
                    .add(eq('BillingState', 'Shanghai'))
                )
            )
            .orderBy('AnnualRevenue').descending().nullsLast()
            .limitx(10)
            .forView()
            .run();
        System.debug(accountList);
        System.assertEquals(2, accountList.size());
        System.assertEquals(1500, accountList[0].AnnualRevenue);
        System.assertEquals('Beijing', accountList[0].BillingState);
        System.assertEquals(500, accountList[1].AnnualRevenue);
        System.assertEquals('Shanghai', accountList[1].BillingState);
    }

    @isTest
    // prettier-ignore
    static void testQuery_Of_Soql_Composite() {
        Query contactQuery = Query.of(Contact.SObjectType).selectWith('Name');

        Query query = Query.of(Account.SObjectType);
        query.selectWith('Name', 'AnnualRevenue');
        query.selectWith('BillingCountry', 'BillingState');
        query.selectWith('Contacts', contactQuery);

        Query.CompositeFilterExpression filters = orx();

        filters.add(andx()
            .add(gt('AnnualRevenue', 1000))
            .add(eq('BillingCountry', 'China'))
            .add(eq('BillingState', 'Beijing'))
        );

        filters.add(andx()
            .add(lt('AnnualRevenue', 1000))
            .add(eq('BillingCountry', 'China'))
            .add(eq('BillingState', 'Shanghai'))
        );

        query.filterBy(filters);

        query.orderBy('AnnualRevenue').descending().nullsLast();

        List<Account> accountList = (List<Account>) query.run();
        System.assertEquals(2, accountList.size());
        System.assertEquals(1500, accountList[0].AnnualRevenue);
        System.assertEquals('Beijing', accountList[0].BillingState);
        System.assertEquals(500, accountList[1].AnnualRevenue);
        System.assertEquals('Shanghai', accountList[1].BillingState);
    }

    @isTest
    static void testQuery_Of_Soql_Params() {
        // prettier-ignore
        List<Contact> contactList = (List<Contact>) Query.of(Contact.SObjectType).selectWith('Id', 'Name').run();
        // prettier-ignore
        List<Account> accountList = (List<Account>) Query.of(Account.SObjectType)
            .selectWith('Name', 'AnnualRevenue', 'BillingCountry', 'BillingState')
            .selectWith('Contacts', Query.of(Contact.SObjectType).selectWith('Name').filterBy(inx('Id', contactList)))
            .filterBy(andx()
                .add(inx('Id', Query.of(Contact.SObjectType).selectWith('AccountId')))
                .add(orx()
                    .add(andx()
                        .add(gt('AnnualRevenue', 1000))
                        .add(eq('BillingCountry', 'China'))
                        .add(eq('BillingState', 'Beijing'))
                    )
                    .add(andx()
                        .add(lt('AnnualRevenue', 1000))
                        .add(eq('BillingCountry', 'China'))
                        .add(eq('BillingState', 'Shanghai'))
                    )
                )
            )
            .orderBy('AnnualRevenue').descending().nullsLast()
            .run();
        System.debug(accountList);
        System.assertEquals(2, accountList.size());
        System.assertEquals(1500, accountList[0].AnnualRevenue);
        System.assertEquals('Beijing', accountList[0].BillingState);
        System.assertEquals(500, accountList[1].AnnualRevenue);
        System.assertEquals('Shanghai', accountList[1].BillingState);
    }
}
