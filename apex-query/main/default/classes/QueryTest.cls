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
    static void testQuery_Of_Soql_GroupBy() {
        // prettier-ignore
        List<AggregateResult> results = (List<AggregateResult>) Query.of(Account.SObjectType)
            .grouping('BillingCountry')
            .grouping('BillingState', 'StateGroup')
            .min('AnnualRevenue')
            .max('AnnualRevenue')
            .avg('AnnualRevenue', 'average')
            .sum('AnnualRevenue', 'summary')
            .groupBy('BillingCountry' ,'BillingState').rollup()
            .orderBy('expr0', 'StateGroup').nullsLast().descending()
            .run();
        System.debug(results);
    }

    @isTest
    static void testQuery_Of_Object_List_GroupBy() {
        // prettier-ignore
        List<Account> accountList = (List<Account>) Query.of(Account.SObjectType)
            .selectWith('Name', 'AnnualRevenue', 'BillingCountry', 'BillingState')
            .run();
        // prettier-ignore
        List<GroupByResult> results = (List<GroupByResult>) Query.of(accountList)
            // .grouping('BillingCountry')
            // .grouping('BillingState', 'StateGroup')
            .min('AnnualRevenue')
            .max('AnnualRevenue')
            .avg('AnnualRevenue', 'average')
            .sum('AnnualRevenue', 'summary')
            .groupBy('BillingCountry', 'BillingState').rollup()
            .orderBy('expr0', 'average').nullsLast().descending()
            .run();
        System.debug(results);
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

        Query.FilterableList filters = orx();

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

    @isTest
    static void testQuery_Of_Object_List() {
        // prettier-ignore
        List<Account> accountList = (List<Account>) Query.of(Account.SObjectType)
            .selectWith('Name', 'AnnualRevenue', 'BillingCountry', 'BillingState')
            .run();
        // prettier-ignore
        accountList = (List<Account>) Query.of(accountList)
            .selectWith('Name', 'AnnualRevenue', 'BillingCountry', 'BillingState')
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
            .run();
        System.debug(accountList);
        System.assertEquals(2, accountList.size());
        System.assertEquals(1500, accountList[0].AnnualRevenue);
        System.assertEquals('Beijing', accountList[0].BillingState);
        System.assertEquals(500, accountList[1].AnnualRevenue);
        System.assertEquals('Shanghai', accountList[1].BillingState);
    }

    @isTest
    static void testQuery_Of_Map() {
        String jsonStr =
            '{' +
            '  "Accounts": [' +
            '    {' +
            '      "Account": {' +
            '        "Name": "Account 1",' +
            '        "AnnualRevenue": 1500,' +
            '        "BillingCountry": "China",' +
            '        "BillingState": "Shanghai"' +
            '      },' +
            '      "FieldName5": "value3"' +
            '    },' +
            '    {' +
            '      "Account": {' +
            '        "Name": "Account 2",' +
            '        "AnnualRevenue": 500,' +
            '        "BillingCountry": "China",' +
            '        "BillingState": "Shanghai"' +
            '      },' +
            '      "FieldName5": "value3"' +
            '    },' +
            '    {' +
            '      "Account": {' +
            '        "Name": "Account 3",' +
            '        "AnnualRevenue": 1500,' +
            '        "BillingCountry": "China",' +
            '        "BillingState": "Beijing"' +
            '      },' +
            '      "FieldName5": "value3"' +
            '    },' +
            '    {' +
            '      "Account": {' +
            '        "Name": "Account 4",' +
            '        "AnnualRevenue": 500,' +
            '        "BillingCountry": "China",' +
            '        "BillingState": "Beijing"' +
            '      },' +
            '      "FieldName5": "value3"' +
            '    }' +
            '  ]' +
            '}';

        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonStr);

        // prettier-ignore
        List<Map<String, Object>> resultList = (List<Map<String, Object>>) Query.of(jsonMap)
            .selectWith('Accounts.Account.Name', 'Accounts.Account.AnnualRevenue')
            .selectWith('Accounts.Account.BillingCountry', 'Accounts.Account.BillingState')
            .filterBy(orx()
                .add(andx()
                    .add(gt('Accounts.Account.AnnualRevenue', 1000))
                    .add(eq('Accounts.Account.BillingCountry', 'China'))
                    .add(eq('Accounts.Account.BillingState', 'Beijing'))
                )
                .add(andx()
                    .add(lt('Accounts.Account.AnnualRevenue', 1000))
                    .add(eq('Accounts.Account.BillingCountry', 'China'))
                    .add(eq('Accounts.Account.BillingState', 'Shanghai'))
                )
            )
            .orderBy('Accounts.Account.AnnualRevenue').descending().nullsLast()
            .run();
        System.debug(resultList);
        System.assertEquals(2, resultList.size());
        System.assertEquals(1500, resultList[0].get('AnnualRevenue'));
        System.assertEquals('Beijing', resultList[0].get('BillingState'));
        System.assertEquals(500, resultList[1].get('AnnualRevenue'));
        System.assertEquals('Shanghai', resultList[1].get('BillingState'));
    }

    @isTest
    static void testQuery_Of_List() {
        String jsonStr =
            '[' +
            '  {' +
            '    "Accounts": [' +
            '      {' +
            '        "Account": {' +
            '          "Fields": [' +
            '            { "Name": "Name", "Value": "Account 1" },' +
            '            { "Name": "AnnualRevenue", "Value": 1500 },' +
            '            { "Name": "BillingCountry", "Value": "China" },' +
            '            { "Name": "BillingState", "Value": "Shanghai" }' +
            '          ]' +
            '        },' +
            '        "FieldName5": "value3"' +
            '      },' +
            '      {' +
            '        "Account": {' +
            '          "Fields": [' +
            '            { "Name": "Name", "Value": "Account 1" },' +
            '            { "Name": "AnnualRevenue", "Value": 500 },' +
            '            { "Name": "BillingCountry", "Value": "China" },' +
            '            { "Name": "BillingState", "Value": "Shanghai" }' +
            '          ]' +
            '        },' +
            '        "FieldName5": "value3"' +
            '      },' +
            '      {' +
            '        "Account": {' +
            '          "Fields": [' +
            '            { "Name": "Name", "Value": "Account 1" },' +
            '            { "Name": "AnnualRevenue", "Value": 1500 },' +
            '            { "Name": "BillingCountry", "Value": "China" },' +
            '            { "Name": "BillingState", "Value": "Beijing" }' +
            '          ]' +
            '        },' +
            '        "FieldName5": "value3"' +
            '      },' +
            '      {' +
            '        "Account": {' +
            '          "Fields": [' +
            '            { "Name": "Name", "Value": "Account 1" },' +
            '            { "Name": "AnnualRevenue", "Value": 500 },' +
            '            { "Name": "BillingCountry", "Value": "China" },' +
            '            { "Name": "BillingState", "Value": "Beijing" }' +
            '          ]' +
            '        },' +
            '        "FieldName5": "value3"' +
            '      }' +
            '    ]' +
            '  }' +
            ']';

        List<Object> jsonList = (List<Object>) JSON.deserializeUntyped(jsonStr);

        // prettier-ignore
        List<Map<String, Object>> resultList = (List<Map<String, Object>>) Query.of(jsonList)
            .selectWith('Accounts.Account')
            .filterBy(orx()
                .add(andx()
                    .add(anyOf('Accounts.Account.Fields', andx()
                        .add(eq('Name', 'AnnualRevenue'))
                        .add(gt('Value', 1000))
                    ))
                    .add(anyOf('Accounts.Account.Fields', andx()
                        .add(eq('Name', 'BillingCountry'))
                        .add(eq('Value', 'China'))
                    ))
                    .add(anyOf('Accounts.Account.Fields', andx()
                        .add(eq('Name', 'BillingState'))
                        .add(eq('Value', 'Beijing'))
                    ))
                )
                .add(andx()
                    .add(anyOf('Accounts.Account.Fields', andx()
                        .add(eq('Name', 'AnnualRevenue'))
                        .add(lt('Value', 1000))
                    ))
                    .add(anyOf('Accounts.Account.Fields', andx()
                        .add(eq('Name', 'BillingCountry'))
                        .add(eq('Value', 'China'))
                    ))
                    .add(anyOf('Accounts.Account.Fields', andx()
                        .add(eq('Name', 'BillingState'))
                        .add(eq('Value', 'Shanghai'))
                    ))
                )
            )
            .orderBy(firstOf('Accounts.Account.Fields', eq('Name', 'AnnualRevenue'), 'Value')).descending().nullsLast()
            .run();
        System.debug(resultList);
        System.assertEquals(2, resultList.size());
        System.assertEquals(1500, resultList[0].get('AnnualRevenue'));
        System.assertEquals('Beijing', resultList[0].get('BillingState'));
        System.assertEquals(500, resultList[1].get('AnnualRevenue'));
        System.assertEquals('Shanghai', resultList[1].get('BillingState'));
    }

    // @isTest
    // static void testQuery() {
    //     List<Database.AggregateResult> accountList = Query.of(Account.SObjectType)
    //         .sum('Price', 'alias1')
    //         .max('Price')
    //         .min('Price')
    //         .avg('Price')
    //         .filterBy()
    //         .groupBy('FieldName1', 'FieldName2')
    //         .orderBy('alias1', 'expr0')
    //         .run();

    //     List<Account> accountList = Query.of(Account.SObjectType)
    //         .selectAll()
    //         .filterBy()
    //         .orderBy('FieldName')
    //         .run();
    // }

    // @isTest
    // static void testQuery() {
    //     List<Contact> contacts = new List<Contact>();
    //     List<Query.Database.AggregateResult> resultList = Query.of(contacts)
    //         .sum('Price', 'alias1')
    //         .max('Price')
    //         .min('Price')
    //         .avg('Price')
    //         .filterBy()
    //         .groupBy('FieldName1', 'FieldName2')
    //         .orderBy('alias1', 'expr0')
    //         .run();

    //     List<Contact> resultList = Query.of(contacts)
    //         .selectAll()
    //         .filterBy()
    //         .orderBy('FieldName')
    //         .run();
    // }

    // @isTest
    // static void testQuery() {
    //     String jsonStr =
    //         '{' +
    //         '  "FieldName1": [' +
    //         '    {' +
    //         '      "FieldName2": {' +
    //         '        "FieldName3": "value1",' +
    //         '        "FieldName4": "value2"' +
    //         '      },' +
    //         '      "FieldName5": "value3"' +
    //         '    },' +
    //         '    {' +
    //         '      "FieldName2": {' +
    //         '        "FieldName3": "value4",' +
    //         '        "FieldName4": "value5"' +
    //         '      },' +
    //         '      "FieldName5": "value6"' +
    //         '    }' +
    //         '  ]' +
    //         '}';

    //     Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(
    //         jsonStr
    //     );
    //     List<Map<String, Object>> resultList = Query.of(jsonMap)
    //         .selectAll('FieldName1.FieldName2.FieldName4')
    //         .selectAll('FieldName1.FieldName5')
    //         .filterBy(
    //             _OR()
    //                 .add(EQ('FieldName1.FieldName2.FieldName3', 'value2'))
    //                 .add(EQ('FieldName1.FieldName2.FieldName3', 'value3'))
    //         )
    //         .orderBy('FieldName')
    //         .run();
    // }

    // @isTest
    // static void testDatabase.AggregateResult() {
    //     List<Contact> contacts = new List<Contact>();
    //     List<Query.Database.AggregateResult> resultList = Query.of(contacts)
    //         .groupBy('AccountId', 'Gender')
    //         .run();

    //     for (Query.Database.AggregateResult result : resultList) {
    //         Id accoutnId = result.get('AccountId');
    //         Id gender = result.get('Gender');
    //         for (Contact contact : (List<Contact>) result.elements) {
    //         }
    //     }

    //     Map<String, Query.Database.AggregateResult> resultMap = Query.toMap(resultList);

    //     Id accountId;
    //     Query.Database.AggregateResult result = resultMap.get(accountId + 'Male');
    //     for (Contact contact : (List<Contact>) result.elements) {
    //     }
    // }

    // @isTest
    // static void testDatabase.AggregateResult() {
    //     List<Contact> contacts = new List<Contact>();
    //     List<Query.Database.AggregateResult> resultList = Query.of(contacts)
    //         .groupBy(new ContactNameFistLetterGrouper('FirstLetterOfName'))
    //         .run();

    //     for (Query.Database.AggregateResult result : resultList) {
    //         String firstLetterOfName = result.get('FirstLetterOfName');
    //         for (Contact contact : (List<Contact>) result.elements) {
    //         }
    //     }
    // }

    // public class ContactNameFistLetterGrouper extends Query.Grouper {
    //     ContactNameFistLetterGrouper(String grouperName) {
    //         grouperNames = new List<String>();
    //         grouperNames.add(grouperName);
    //     }

    //     public List<Object> getGrouperValues(Object item) {
    //         Contact contact = (Contact) item;
    //         return new List<Object>{ contact.Name.substring(0, 1) }; // FistLetter
    //     }
    // }
}
