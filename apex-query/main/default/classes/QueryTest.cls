/**
 * Copyright 2023 Jeff Jin
 * https://github.com/apexfarm/ApexQuery
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

@isTest
public with sharing class QueryTest extends Query {
    static String getFakeId(Schema.SObjectType objectType, Integer index) {
        return objectType.getDescribe().getKeyPrefix() +
            '000zzzz' + // start from a large Id to avoid confliction during unit test.
            String.valueOf(index).leftPad(5, '0');
    }

    static void makeData() {
        // prettier-ignore
        List<Account> accountList = new List<Account> {
            new Account(Name = 'Account 1', AnnualRevenue = 1500, BillingCountry = 'China', BillingState = 'Shanghai'),
            new Account(Name = 'Account 2', AnnualRevenue = 500, BillingCountry = 'China', BillingState = 'Shanghai',
                ShippingLatitude = 37.775002, ShippingLongitude = -122.41802),
            new Account(Name = 'Account 3', AnnualRevenue = 1500, BillingCountry = 'China', BillingState = 'Beijing',
                ShippingLatitude = 37.775001, ShippingLongitude = -122.41801),
            new Account(Name = 'Account 4', AnnualRevenue = 500, BillingCountry = 'China', BillingState = 'Beijing'),
            new Account(Name = 'Account\' 5', AnnualRevenue = 1500, NumberOfEmployees = 2000),
            new Account(Name = 'Account\' 6', AnnualRevenue = 500, NumberOfEmployees = 2000)
        };
        insert accountList;

        // prettier-ignore
        List<Contact> contactList = new List<Contact> {
            new Contact(LastName = 'Contact 1', AccountId = accountList[0].Id, Birthdate = Date.newInstance(2023, 1, 1)),
            new Contact(LastName = 'Contact 2', AccountId = accountList[1].Id, Birthdate = Date.newInstance(2023, 1, 2)),
            new Contact(LastName = 'Contact 3', AccountId = accountList[2].Id, Birthdate = Date.newInstance(2023, 1, 3)),
            new Contact(LastName = 'Contact 4', AccountId = accountList[3].Id, Birthdate = Date.newInstance(2023, 1, 4))
        };
        insert contactList;
    }

    @isTest
    static void testKeyword_From() {
        Query accountQuery = Query.of(Account.SObjectType);
        Assert.areEqual('SELECT Id FROM Account', accountQuery.build());
        Query contactQuery = Query.of(Contact.SObjectType);
        Assert.areEqual('SELECT Id FROM Contact', contactQuery.build());
    }

    // ======================
    // #region Keyword Select

    @isTest
    static void testKeyword_Select_Fields() {
        // Inline Styles
        Query accountQuery = Query.of(Account.SObjectType).selectBy(Account.Id);
        Assert.areEqual('SELECT Id FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(Account.Id, Account.Name);
        Assert.areEqual('SELECT Id, Name FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(Account.Id, Account.Name, Account.Description);
        Assert.areEqual('SELECT Id, Name, Description FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType)
            .selectBy(Account.Id, Account.Name, Account.Description, Account.BillingCountry);
        Assert.areEqual('SELECT Id, Name, Description, BillingCountry FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType)
            .selectBy(Account.Id, Account.Name, Account.Description, Account.BillingCountry, Account.BillingState);
        Assert.areEqual(
            'SELECT Id, Name, Description, BillingCountry, BillingState FROM Account',
            accountQuery.build()
        );

        accountQuery = Query.of(Account.SObjectType)
            .selectBy(Account.Id, Account.Name)
            .selectBy(Account.Description, Account.BillingCountry, Account.BillingState);
        Assert.areEqual(
            'SELECT Id, Name, Description, BillingCountry, BillingState FROM Account',
            accountQuery.build()
        );

        // Outline Styles
        Query.Selector selector = Query.selector().add(Account.Id);
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual('SELECT Id FROM Account', accountQuery.build());

        selector = Query.selector().add(Account.Id, Account.Name);
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual('SELECT Id, Name FROM Account', accountQuery.build());

        selector = Query.selector().add(Account.Id, Account.Name, Account.Description);
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual('SELECT Id, Name, Description FROM Account', accountQuery.build());

        selector = Query.selector().add(Account.Id, Account.Name, Account.Description, Account.BillingCountry);
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual('SELECT Id, Name, Description, BillingCountry FROM Account', accountQuery.build());

        selector = Query.selector()
            .add(Account.Id, Account.Name, Account.Description, Account.BillingCountry, Account.BillingState);
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual(
            'SELECT Id, Name, Description, BillingCountry, BillingState FROM Account',
            accountQuery.build()
        );

        selector = Query.selector()
            .add(Account.Id, Account.Name)
            .add(Account.Description, Account.BillingCountry, Account.BillingState);
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual(
            'SELECT Id, Name, Description, BillingCountry, BillingState FROM Account',
            accountQuery.build()
        );

        selector = Query.selector().add(Account.Description, Account.BillingCountry, Account.BillingState);
        Query.Selector anotherSelector = Query.selector().add(Account.Id, Account.Name).add(selector);
        accountQuery = Query.of(Account.SObjectType).selectBy(anotherSelector);
        Assert.areEqual(
            'SELECT Id, Name, Description, BillingCountry, BillingState FROM Account',
            accountQuery.build()
        );
    }

    @isTest
    static void testKeyword_Select_Strings_Parents() {
        makeData();
        Query contactQuery = Query.of(Contact.SObjectType)
            .selectBy(Contact.Id, Contact.Name)
            .selectBy('Account.Owner.Name')
            .selectBy('FORMAT(Account.AnnualRevenue)', 'TOLABEL(Account.AccountSource)');
        Assert.areEqual(
            'SELECT Id, Name, Account.Owner.Name, FORMAT(Account.AnnualRevenue), TOLABEL(Account.AccountSource) FROM Contact',
            contactQuery.build()
        );
        List<Contact> contacts = (List<Contact>) contactQuery.run();
        Assert.areEqual(4, contacts.size());
    }

    @isTest
    static void testKeyword_Select_Strings() {
        // Inline Styles
        Query accountQuery = Query.of(Account.SObjectType).selectBy('Id');
        Assert.areEqual('SELECT Id FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy('Id', 'Name');
        Assert.areEqual('SELECT Id, Name FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy('Id', 'Name', 'Description');
        Assert.areEqual('SELECT Id, Name, Description FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy('Id', 'Name', 'Description', 'BillingCountry');
        Assert.areEqual('SELECT Id, Name, Description, BillingCountry FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType)
            .selectBy('Id', 'Name', 'Description', 'BillingCountry', 'BillingState');
        Assert.areEqual(
            'SELECT Id, Name, Description, BillingCountry, BillingState FROM Account',
            accountQuery.build()
        );

        accountQuery = Query.of(Account.SObjectType)
            .selectBy('Id', 'Name')
            .selectBy('Description', 'BillingCountry', 'BillingState');
        Assert.areEqual(
            'SELECT Id, Name, Description, BillingCountry, BillingState FROM Account',
            accountQuery.build()
        );

        // Outline Styles
        Query.Selector selector = Query.selector().add('Id');
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual('SELECT Id FROM Account', accountQuery.build());

        selector = Query.selector().add('Id', 'Name');
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual('SELECT Id, Name FROM Account', accountQuery.build());

        selector = Query.selector().add('Id', 'Name', 'Description');
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual('SELECT Id, Name, Description FROM Account', accountQuery.build());

        selector = Query.selector().add('Id', 'Name', 'Description', 'BillingCountry');
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual('SELECT Id, Name, Description, BillingCountry FROM Account', accountQuery.build());

        selector = Query.selector().add('Id', 'Name', 'Description', 'BillingCountry', 'BillingState');
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual(
            'SELECT Id, Name, Description, BillingCountry, BillingState FROM Account',
            accountQuery.build()
        );

        selector = Query.selector().add('Id', 'Name').add('Description', 'BillingCountry', 'BillingState');
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual(
            'SELECT Id, Name, Description, BillingCountry, BillingState FROM Account',
            accountQuery.build()
        );

        selector = Query.selector().add('Description', 'BillingCountry', 'BillingState');
        Query.Selector anotherSelector = Query.selector().add('Id', 'Name').add(selector);
        accountQuery = Query.of(Account.SObjectType).selectBy(anotherSelector);
        Assert.areEqual(
            'SELECT Id, Name, Description, BillingCountry, BillingState FROM Account',
            accountQuery.build()
        );
    }

    @isTest
    static void testKeyword_Select_Functions() {
        // Inline Styles
        Query accountQuery = Query.of(Account.SObjectType).selectBy(TO_LABEL(Account.Id));
        Assert.areEqual('SELECT TOLABEL(Id) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(TO_LABEL(Account.Id), TO_LABEL(Account.Name));
        Assert.areEqual('SELECT TOLABEL(Id), TOLABEL(Name) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType)
            .selectBy(TO_LABEL(Account.Id), TO_LABEL(Account.Name), TO_LABEL(Account.Description));
        Assert.areEqual('SELECT TOLABEL(Id), TOLABEL(Name), TOLABEL(Description) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType)
            .selectBy(
                TO_LABEL(Account.Id),
                TO_LABEL(Account.Name),
                TO_LABEL(Account.Description),
                TO_LABEL(Account.BillingCountry)
            );
        Assert.areEqual(
            'SELECT TOLABEL(Id), TOLABEL(Name), TOLABEL(Description), TOLABEL(BillingCountry) FROM Account',
            accountQuery.build()
        );

        accountQuery = Query.of(Account.SObjectType)
            .selectBy(
                TO_LABEL(Account.Id),
                TO_LABEL(Account.Name),
                TO_LABEL(Account.Description),
                TO_LABEL(Account.BillingCountry),
                TO_LABEL(Account.BillingState)
            );
        Assert.areEqual(
            'SELECT TOLABEL(Id), TOLABEL(Name), TOLABEL(Description), TOLABEL(BillingCountry), TOLABEL(BillingState) FROM Account',
            accountQuery.build()
        );

        accountQuery = Query.of(Account.SObjectType)
            .selectBy(TO_LABEL(Account.Id), TO_LABEL(Account.Name))
            .selectBy(TO_LABEL(Account.Description), TO_LABEL(Account.BillingCountry), TO_LABEL(Account.BillingState));
        Assert.areEqual(
            'SELECT TOLABEL(Id), TOLABEL(Name), TOLABEL(Description), TOLABEL(BillingCountry), TOLABEL(BillingState) FROM Account',
            accountQuery.build()
        );

        // Outline Styles
        Query.Selector selector = Query.selector().add(TO_LABEL(Account.Id));
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual('SELECT TOLABEL(Id) FROM Account', accountQuery.build());

        selector = Query.selector().add(TO_LABEL(Account.Id), TO_LABEL(Account.Name));
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual('SELECT TOLABEL(Id), TOLABEL(Name) FROM Account', accountQuery.build());

        selector = Query.selector().add(TO_LABEL(Account.Id), TO_LABEL(Account.Name), TO_LABEL(Account.Description));
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual('SELECT TOLABEL(Id), TOLABEL(Name), TOLABEL(Description) FROM Account', accountQuery.build());

        selector = Query.selector()
            .add(
                TO_LABEL(Account.Id),
                TO_LABEL(Account.Name),
                TO_LABEL(Account.Description),
                TO_LABEL(Account.BillingCountry)
            );
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual(
            'SELECT TOLABEL(Id), TOLABEL(Name), TOLABEL(Description), TOLABEL(BillingCountry) FROM Account',
            accountQuery.build()
        );

        selector = Query.selector()
            .add(
                TO_LABEL(Account.Id),
                TO_LABEL(Account.Name),
                TO_LABEL(Account.Description),
                TO_LABEL(Account.BillingCountry),
                TO_LABEL(Account.BillingState)
            );
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual(
            'SELECT TOLABEL(Id), TOLABEL(Name), TOLABEL(Description), TOLABEL(BillingCountry), TOLABEL(BillingState) FROM Account',
            accountQuery.build()
        );

        selector = Query.selector()
            .add(TO_LABEL(Account.Id), TO_LABEL(Account.Name))
            .add(TO_LABEL(Account.Description), TO_LABEL(Account.BillingCountry), TO_LABEL(Account.BillingState));
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual(
            'SELECT TOLABEL(Id), TOLABEL(Name), TOLABEL(Description), TOLABEL(BillingCountry), TOLABEL(BillingState) FROM Account',
            accountQuery.build()
        );

        selector = Query.selector()
            .add(TO_LABEL(Account.Description), TO_LABEL(Account.BillingCountry), TO_LABEL(Account.BillingState));
        Query.Selector anotherSelector = Query.selector()
            .add(TO_LABEL(Account.Id), TO_LABEL(Account.Name))
            .add(selector);
        accountQuery = Query.of(Account.SObjectType).selectBy(anotherSelector);
        Assert.areEqual(
            'SELECT TOLABEL(Id), TOLABEL(Name), TOLABEL(Description), TOLABEL(BillingCountry), TOLABEL(BillingState) FROM Account',
            accountQuery.build()
        );
    }

    @isTest
    static void testKeyword_Select_Queries() {
        // Inline Styles
        Query contactQuery = Query.of(Contact.SObjectType);
        Query accountQuery = Query.of(Account.SObjectType).selectBy('Contacts', contactQuery);
        Assert.areEqual('SELECT (SELECT Id FROM Contacts) FROM Account', accountQuery.build());

        contactQuery = Query.of(Contact.SObjectType).selectBy(Contact.Name);
        accountQuery = Query.of(Account.SObjectType).selectBy('Contacts', contactQuery).selectBy(Account.Name);
        Assert.areEqual('SELECT (SELECT Name FROM Contacts), Name FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(Account.Name).selectBy('Contacts', contactQuery);
        Assert.areEqual('SELECT Name, (SELECT Name FROM Contacts) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType)
            .selectBy('Contacts', contactQuery)
            .selectBy('Contacts', contactQuery);
        Assert.areEqual(
            'SELECT (SELECT Name FROM Contacts), (SELECT Name FROM Contacts) FROM Account',
            accountQuery.build()
        );

        // Outline Styles
        contactQuery = Query.of(Contact.SObjectType);
        Query.Selector selector = Query.selector().add('Contacts', contactQuery);
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual('SELECT (SELECT Id FROM Contacts) FROM Account', accountQuery.build());

        contactQuery = Query.of(Contact.SObjectType).selectBy(Contact.Name);
        selector = Query.selector().add('Contacts', contactQuery).add(Account.Name);
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual('SELECT (SELECT Name FROM Contacts), Name FROM Account', accountQuery.build());

        selector = Query.selector().add(Account.Name).add('Contacts', contactQuery);
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual('SELECT Name, (SELECT Name FROM Contacts) FROM Account', accountQuery.build());

        selector = Query.selector().add('Contacts', contactQuery).add('Contacts', contactQuery);
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        Assert.areEqual(
            'SELECT (SELECT Name FROM Contacts), (SELECT Name FROM Contacts) FROM Account',
            accountQuery.build()
        );
    }

    // #endregion
    // ======================

    // =====================
    // #region Keyword Where

    @isTest
    static void testKeyword_Where() {
        // Inline Styles
        Query accountQuery = Query.of(Account.SObjectType).filterBy(gt(Account.AnnualRevenue, 2000));
        Assert.areEqual('SELECT Id FROM Account WHERE AnnualRevenue > 2000', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType)
            .filterBy(andx().add(gt(Account.AnnualRevenue, 2000)).add(lt(Account.AnnualRevenue, 6000)));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (AnnualRevenue > 2000 AND AnnualRevenue < 6000)',
            accountQuery.build()
        );

        Query.Filter filter = orx()
            .add(
                andx()
                    .add(gt(Account.AnnualRevenue, 1000))
                    .add(eq(Account.BillingCountry, 'China'))
                    .add(eq(Account.BillingState, 'Beijing'))
            )
            .add(
                andx()
                    .add(lt(Account.AnnualRevenue, 1000))
                    .add(eq(Account.BillingCountry, 'China'))
                    .add(eq(Account.BillingState, 'Shanghai'))
            );
        accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE ((AnnualRevenue > 1000 AND BillingCountry = \'China\' AND BillingState = \'Beijing\') ' +
            'OR (AnnualRevenue < 1000 AND BillingCountry = \'China\' AND BillingState = \'Shanghai\'))',
            accountQuery.build()
        );
    }

    @isTest
    static void testKeyword_Where_traditional_Style() {
        Query.Filter filter = orx(
            andx(eq(Account.BillingCountry, 'China'), eq(Account.BillingState, 'Beijing')),
            andx(eq(Account.BillingCountry, 'China'), eq(Account.BillingState, 'Shanghai'))
        );
        Query accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE ((AnnualRevenue > 1000 AND BillingCountry = \'China\' AND BillingState = \'Beijing\') ' +
            'OR (AnnualRevenue < 1000 AND BillingCountry = \'China\' AND BillingState = \'Shanghai\'))',
            accountQuery.build()
        );

        filter = orx(
            andx(eq(Account.BillingCountry, 'China'), eq(Account.BillingState, 'Beijing')),
            andx(eq(Account.BillingCountry, 'China'), eq(Account.BillingState, 'Shanghai'))
        );
    }

    // #endregion
    // =====================

    // ========================
    // #region Operator Logical

    @isTest
    static void testOperator_Logical_Not_Commafree() {
        makeData();
        Query.Filter filter = notx(eq(Account.BillingCountry, 'China'));
        Query accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual('SELECT Id FROM Account WHERE NOT(BillingCountry = \'China\')', accountQuery.build());
        List<Account> accounts = (List<Account>) accountQuery.run();
        Assert.areEqual(2, accounts.size());

        filter = notx(
            andx()
                .add(eq(Account.BillingCountry, 'China'))
                .add(eq(Account.BillingState, 'Shanghai'))
                .add(eq(Account.AnnualRevenue, 1500))
        );
        accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE NOT(BillingCountry = \'China\' ' +
            'AND BillingState = \'Shanghai\' ' +
            'AND AnnualRevenue = 1500)',
            accountQuery.build()
        );
        accounts = (List<Account>) accountQuery.run();
        Assert.areEqual(5, accounts.size());
    }

    @isTest
    static void testOperator_Logical_And_Commafree() {
        Query.Filter filter = andx()
            .add(eq(Account.BillingCountry, 'China'))
            .add(eq(Account.BillingCountry, 'China'))
            .add(eq(Account.BillingCountry, 'China'));
        Query accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\')',
            accountQuery.build()
        );
    }

    @isTest
    static void testOperator_Logical_And_Traditional() {
        Query.Filter filter = andx(eq(Account.BillingCountry, 'China'), eq(Account.BillingCountry, 'China'));
        Query accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = \'China\' AND BillingCountry = \'China\')',
            accountQuery.build()
        );

        filter = andx(
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China')
        );
        accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\')',
            accountQuery.build()
        );

        filter = andx(
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China')
        );
        accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\')',
            accountQuery.build()
        );

        filter = andx(
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China')
        );
        accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\')',
            accountQuery.build()
        );

        filter = andx(
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China')
        );
        accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\')',
            accountQuery.build()
        );

        filter = andx(
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China')
        );
        accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\')',
            accountQuery.build()
        );

        filter = andx(
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China')
        );
        accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\')',
            accountQuery.build()
        );

        filter = andx(
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China')
        );
        accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\')',
            accountQuery.build()
        );

        filter = andx(
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China')
        );
        accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\' ' +
            'AND BillingCountry = \'China\')',
            accountQuery.build()
        );
    }

    @isTest
    static void testOperator_Logical_Or_Commafree() {
        Query.Filter filter = orx()
            .add(eq(Account.BillingCountry, 'China'))
            .add(eq(Account.BillingCountry, 'China'))
            .add(eq(Account.BillingCountry, 'China'));
        Query accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\')',
            accountQuery.build()
        );
    }

    @isTest
    static void testOperator_Logical_Or_Traditional() {
        Query.Filter filter = orx(eq(Account.BillingCountry, 'China'), eq(Account.BillingCountry, 'China'));
        Query accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = \'China\' OR BillingCountry = \'China\')',
            accountQuery.build()
        );

        filter = orx(
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China')
        );
        accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\')',
            accountQuery.build()
        );

        filter = orx(
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China')
        );
        accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\')',
            accountQuery.build()
        );

        filter = orx(
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China')
        );
        accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\')',
            accountQuery.build()
        );

        filter = orx(
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China')
        );
        accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\')',
            accountQuery.build()
        );

        filter = orx(
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China')
        );
        accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\')',
            accountQuery.build()
        );

        filter = orx(
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China')
        );
        accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\')',
            accountQuery.build()
        );

        filter = orx(
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China')
        );
        accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\')',
            accountQuery.build()
        );

        filter = orx(
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingCountry, 'China')
        );
        accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\' ' +
            'OR BillingCountry = \'China\')',
            accountQuery.build()
        );
    }

    // #endregion
    // =====================

    // ============================
    // #region Comparison Operators

    @isTest
    static void testOperator_Comparison_EQ() {
        // param1 are SObjectField
        Query.Filter filter;
        filter = eq(Account.BillingCountry, 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = \'China\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eq(Account.BillingCountry, getFakeId(Account.SObjectType, 0));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = \'001000zzzz00000\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eq(Account.BillingCountry, true);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = true',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eq(Account.BillingCountry, 123);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = 123',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eq(Account.BillingCountry, 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = 123.456',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eq(Account.BillingCountry, Datetime.newInstance(2023, 1, 1, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eq(Account.BillingCountry, Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eq(Account.BillingCountry, Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eq(Account.BillingCountry, LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = LAST_N_DAYS:2',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eq(Account.BillingCountry, CNY(2000));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = CNY2000',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eqNull(Account.BillingCountry);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = NULL',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        // param1 are Strings
        filter = eq('BillingCountry', 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = \'China\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eq('BillingCountry', getFakeId(Account.SObjectType, 0));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = \'001000zzzz00000\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eq('BillingCountry', true);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = true',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eq('BillingCountry', 123);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = 123',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eq('BillingCountry', 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = 123.456',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eq('BillingCountry', Datetime.newInstance(2023, 1, 1, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eq('BillingCountry', Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eq('BillingCountry', Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eq('BillingCountry', LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = LAST_N_DAYS:2',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eq('BillingCountry', CNY(2000));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = CNY2000',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eqNull('BillingCountry');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry = NULL',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        // param1 are AggregateFunction
        filter = eq(MAX(Account.BillingCountry), 'China');
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) = \'China\'',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = eq(MAX(Account.BillingCountry), getFakeId(Account.SObjectType, 0));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) = \'001000zzzz00000\'',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = eq(MAX(Account.BillingCountry), true);
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) = true',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = eq(MAX(Account.BillingCountry), 123);
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) = 123',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = eq(MAX(Account.BillingCountry), 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) = 123.456',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = eq(MAX(Account.BillingCountry), Datetime.newInstance(2023, 1, 1, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) = :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = eq(MAX(Account.BillingCountry), Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) = :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = eq(MAX(Account.BillingCountry), Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) = :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = eq(MAX(Account.BillingCountry), LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) = LAST_N_DAYS:2',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = eq(MAX(Account.BillingCountry), CNY(2000));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) = CNY2000',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = eqNull(MAX(Account.BillingCountry));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) = NULL',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        // param1 are others
        filter = eq(DISTANCE_IN_KILOMETER(Account.ShippingAddress, Location.newInstance(37.775001, -122.41801)), 12.3);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE DISTANCE(ShippingAddress, GEOLOCATION(37.775001, -122.41801), \'km\') = 12.3',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eq(CALENDAR_MONTH(Account.CreatedDate), 2);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE CALENDAR_MONTH(CreatedDate) = 2',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = eq(TO_LABEL(Account.AccountSource), 'Advertisement');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE TOLABEL(AccountSource) = \'Advertisement\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );
    }

    @isTest
    static void testOperator_Comparison_NE() {
        // param1 are SObjectField
        Query.Filter filter;
        filter = ne(Account.BillingCountry, 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != \'China\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = ne(Account.BillingCountry, getFakeId(Account.SObjectType, 0));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != \'001000zzzz00000\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = ne(Account.BillingCountry, true);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != true',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = ne(Account.BillingCountry, 123);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != 123',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = ne(Account.BillingCountry, 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != 123.456',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = ne(Account.BillingCountry, Datetime.newInstance(2023, 1, 1, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = ne(Account.BillingCountry, Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = ne(Account.BillingCountry, Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = ne(Account.BillingCountry, LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != LAST_N_DAYS:2',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = ne(Account.BillingCountry, CNY(2000));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != CNY2000',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = neNull(Account.BillingCountry);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != NULL',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        // param1 are Strings
        filter = ne('BillingCountry', 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != \'China\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = ne('BillingCountry', getFakeId(Account.SObjectType, 0));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != \'001000zzzz00000\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = ne('BillingCountry', true);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != true',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = ne('BillingCountry', 123);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != 123',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = ne('BillingCountry', 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != 123.456',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = ne('BillingCountry', Datetime.newInstance(2023, 1, 1, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = ne('BillingCountry', Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = ne('BillingCountry', Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = ne('BillingCountry', LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != LAST_N_DAYS:2',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = ne('BillingCountry', CNY(2000));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != CNY2000',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = neNull('BillingCountry');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry != NULL',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        // param1 are AggregateFunction
        filter = ne(MAX(Account.BillingCountry), 'China');
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) != \'China\'',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = ne(MAX(Account.BillingCountry), getFakeId(Account.SObjectType, 0));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) != \'001000zzzz00000\'',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = ne(MAX(Account.BillingCountry), true);
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) != true',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = ne(MAX(Account.BillingCountry), 123);
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) != 123',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = ne(MAX(Account.BillingCountry), 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) != 123.456',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = ne(MAX(Account.BillingCountry), Datetime.newInstance(2023, 1, 1, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) != :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = ne(MAX(Account.BillingCountry), Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) != :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = ne(MAX(Account.BillingCountry), Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) != :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = ne(MAX(Account.BillingCountry), LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) != LAST_N_DAYS:2',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = ne(MAX(Account.BillingCountry), CNY(2000));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) != CNY2000',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = neNull(MAX(Account.BillingCountry));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) != NULL',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        // param1 are others
        filter = ne(DISTANCE_IN_KILOMETER(Account.ShippingAddress, Location.newInstance(37.775001, -122.41801)), 12.3);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE DISTANCE(ShippingAddress, GEOLOCATION(37.775001, -122.41801), \'km\') != 12.3',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = ne(CALENDAR_MONTH(Account.CreatedDate), 2);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE CALENDAR_MONTH(CreatedDate) != 2',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = ne(TO_LABEL(Account.AccountSource), 'Advertisement');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE TOLABEL(AccountSource) != \'Advertisement\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );
    }

    @isTest
    static void testOperator_Comparison_GT() {
        // param1 are SObjectField
        Query.Filter filter;
        filter = gt(Account.BillingCountry, 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry > \'China\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gt(Account.BillingCountry, getFakeId(Account.SObjectType, 0));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry > \'001000zzzz00000\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gt(Account.BillingCountry, 123);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry > 123',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gt(Account.BillingCountry, 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry > 123.456',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gt(Account.BillingCountry, Datetime.newInstance(2023, 1, 1, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry > :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gt(Account.BillingCountry, Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry > :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gt(Account.BillingCountry, Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry > :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gt(Account.BillingCountry, LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry > LAST_N_DAYS:2',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gt(Account.BillingCountry, CNY(2000));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry > CNY2000',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        // param1 are Strings
        filter = gt('BillingCountry', 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry > \'China\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gt('BillingCountry', getFakeId(Account.SObjectType, 0));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry > \'001000zzzz00000\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gt('BillingCountry', 123);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry > 123',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gt('BillingCountry', 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry > 123.456',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gt('BillingCountry', Datetime.newInstance(2023, 1, 1, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry > :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gt('BillingCountry', Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry > :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gt('BillingCountry', Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry > :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gt('BillingCountry', LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry > LAST_N_DAYS:2',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gt('BillingCountry', CNY(2000));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry > CNY2000',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        // param1 are AggregateFunction
        filter = gt(MAX(Account.BillingCountry), 'China');
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) > \'China\'',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = gt(MAX(Account.BillingCountry), getFakeId(Account.SObjectType, 0));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) > \'001000zzzz00000\'',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = gt(MAX(Account.BillingCountry), 123);
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) > 123',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = gt(MAX(Account.BillingCountry), 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) > 123.456',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = gt(MAX(Account.BillingCountry), Datetime.newInstance(2023, 1, 1, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) > :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = gt(MAX(Account.BillingCountry), Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) > :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = gt(MAX(Account.BillingCountry), Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) > :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = gt(MAX(Account.BillingCountry), LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) > LAST_N_DAYS:2',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = gt(MAX(Account.BillingCountry), CNY(2000));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) > CNY2000',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        // param1 are others
        filter = gt(DISTANCE_IN_KILOMETER(Account.ShippingAddress, Location.newInstance(37.775001, -122.41801)), 12.3);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE DISTANCE(ShippingAddress, GEOLOCATION(37.775001, -122.41801), \'km\') > 12.3',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gt(CALENDAR_MONTH(Account.CreatedDate), 2);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE CALENDAR_MONTH(CreatedDate) > 2',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gt(TO_LABEL(Account.AccountSource), 'Advertisement');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE TOLABEL(AccountSource) > \'Advertisement\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );
    }

    @isTest
    static void testOperator_Comparison_GTE() {
        // param1 are SObjectField
        Query.Filter filter;
        filter = gte(Account.BillingCountry, 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry >= \'China\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gte(Account.BillingCountry, getFakeId(Account.SObjectType, 0));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry >= \'001000zzzz00000\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gte(Account.BillingCountry, 123);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry >= 123',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gte(Account.BillingCountry, 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry >= 123.456',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gte(Account.BillingCountry, Datetime.newInstance(2023, 1, 1, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry >= :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gte(Account.BillingCountry, Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry >= :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gte(Account.BillingCountry, Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry >= :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gte(Account.BillingCountry, LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry >= LAST_N_DAYS:2',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gte(Account.BillingCountry, CNY(2000));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry >= CNY2000',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        // param1 are Strings
        filter = gte('BillingCountry', 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry >= \'China\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gte('BillingCountry', getFakeId(Account.SObjectType, 0));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry >= \'001000zzzz00000\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gte('BillingCountry', 123);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry >= 123',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gte('BillingCountry', 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry >= 123.456',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gte('BillingCountry', Datetime.newInstance(2023, 1, 1, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry >= :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gte('BillingCountry', Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry >= :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gte('BillingCountry', Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry >= :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gte('BillingCountry', LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry >= LAST_N_DAYS:2',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gte('BillingCountry', CNY(2000));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry >= CNY2000',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        // param1 are AggregateFunction
        filter = gte(MAX(Account.BillingCountry), 'China');
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) >= \'China\'',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = gte(MAX(Account.BillingCountry), getFakeId(Account.SObjectType, 0));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) >= \'001000zzzz00000\'',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = gte(MAX(Account.BillingCountry), 123);
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) >= 123',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = gte(MAX(Account.BillingCountry), 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) >= 123.456',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = gte(MAX(Account.BillingCountry), Datetime.newInstance(2023, 1, 1, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) >= :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = gte(MAX(Account.BillingCountry), Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) >= :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = gte(MAX(Account.BillingCountry), Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) >= :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = gte(MAX(Account.BillingCountry), LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) >= LAST_N_DAYS:2',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = gte(MAX(Account.BillingCountry), CNY(2000));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) >= CNY2000',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        // param1 are others
        filter = gte(DISTANCE_IN_KILOMETER(Account.ShippingAddress, Location.newInstance(37.775001, -122.41801)), 12.3);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE DISTANCE(ShippingAddress, GEOLOCATION(37.775001, -122.41801), \'km\') >= 12.3',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gte(CALENDAR_MONTH(Account.CreatedDate), 2);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE CALENDAR_MONTH(CreatedDate) >= 2',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = gte(TO_LABEL(Account.AccountSource), 'Advertisement');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE TOLABEL(AccountSource) >= \'Advertisement\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );
    }

    @isTest
    static void testOperator_Comparison_LT() {
        // param1 are SObjectField
        Query.Filter filter;
        filter = lt(Account.BillingCountry, 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry < \'China\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lt(Account.BillingCountry, getFakeId(Account.SObjectType, 0));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry < \'001000zzzz00000\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lt(Account.BillingCountry, 123);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry < 123',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lt(Account.BillingCountry, 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry < 123.456',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lt(Account.BillingCountry, Datetime.newInstance(2023, 1, 1, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry < :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lt(Account.BillingCountry, Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry < :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lt(Account.BillingCountry, Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry < :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lt(Account.BillingCountry, LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry < LAST_N_DAYS:2',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lt(Account.BillingCountry, CNY(2000));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry < CNY2000',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        // param1 are Strings
        filter = lt('BillingCountry', 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry < \'China\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lt('BillingCountry', getFakeId(Account.SObjectType, 0));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry < \'001000zzzz00000\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lt('BillingCountry', 123);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry < 123',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lt('BillingCountry', 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry < 123.456',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lt('BillingCountry', Datetime.newInstance(2023, 1, 1, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry < :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lt('BillingCountry', Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry < :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lt('BillingCountry', Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry < :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lt('BillingCountry', LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry < LAST_N_DAYS:2',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lt('BillingCountry', CNY(2000));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry < CNY2000',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        // param1 are AggregateFunction
        filter = lt(MAX(Account.BillingCountry), 'China');
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) < \'China\'',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = lt(MAX(Account.BillingCountry), getFakeId(Account.SObjectType, 0));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) < \'001000zzzz00000\'',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = lt(MAX(Account.BillingCountry), 123);
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) < 123',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = lt(MAX(Account.BillingCountry), 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) < 123.456',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = lt(MAX(Account.BillingCountry), Datetime.newInstance(2023, 1, 1, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) < :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = lt(MAX(Account.BillingCountry), Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) < :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = lt(MAX(Account.BillingCountry), Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) < :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = lt(MAX(Account.BillingCountry), LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) < LAST_N_DAYS:2',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = lt(MAX(Account.BillingCountry), CNY(2000));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) < CNY2000',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        // param1 are others
        filter = lt(DISTANCE_IN_KILOMETER(Account.ShippingAddress, Location.newInstance(37.775001, -122.41801)), 12.3);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE DISTANCE(ShippingAddress, GEOLOCATION(37.775001, -122.41801), \'km\') < 12.3',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lt(CALENDAR_MONTH(Account.CreatedDate), 2);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE CALENDAR_MONTH(CreatedDate) < 2',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lt(TO_LABEL(Account.AccountSource), 'Advertisement');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE TOLABEL(AccountSource) < \'Advertisement\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );
    }

    @isTest
    static void testOperator_Comparison_LTE() {
        // param1 are SObjectField
        Query.Filter filter;
        filter = lte(Account.BillingCountry, 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry <= \'China\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lte(Account.BillingCountry, getFakeId(Account.SObjectType, 0));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry <= \'001000zzzz00000\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lte(Account.BillingCountry, 123);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry <= 123',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lte(Account.BillingCountry, 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry <= 123.456',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lte(Account.BillingCountry, Datetime.newInstance(2023, 1, 1, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry <= :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lte(Account.BillingCountry, Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry <= :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lte(Account.BillingCountry, Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry <= :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lte(Account.BillingCountry, LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry <= LAST_N_DAYS:2',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lte(Account.BillingCountry, CNY(2000));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry <= CNY2000',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        // param1 are Strings
        filter = lte('BillingCountry', 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry <= \'China\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lte('BillingCountry', getFakeId(Account.SObjectType, 0));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry <= \'001000zzzz00000\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lte('BillingCountry', 123);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry <= 123',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lte('BillingCountry', 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry <= 123.456',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lte('BillingCountry', Datetime.newInstance(2023, 1, 1, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry <= :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lte('BillingCountry', Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry <= :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lte('BillingCountry', Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry <= :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lte('BillingCountry', LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry <= LAST_N_DAYS:2',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lte('BillingCountry', CNY(2000));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry <= CNY2000',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        // param1 are AggregateFunction
        filter = lte(MAX(Account.BillingCountry), 'China');
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) <= \'China\'',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = lte(MAX(Account.BillingCountry), getFakeId(Account.SObjectType, 0));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) <= \'001000zzzz00000\'',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = lte(MAX(Account.BillingCountry), 123);
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) <= 123',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = lte(MAX(Account.BillingCountry), 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) <= 123.456',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = lte(MAX(Account.BillingCountry), Datetime.newInstance(2023, 1, 1, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) <= :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = lte(MAX(Account.BillingCountry), Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) <= :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = lte(MAX(Account.BillingCountry), Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) <= :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = lte(MAX(Account.BillingCountry), LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) <= LAST_N_DAYS:2',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = lte(MAX(Account.BillingCountry), CNY(2000));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) <= CNY2000',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        // param1 are others
        filter = lte(DISTANCE_IN_KILOMETER(Account.ShippingAddress, Location.newInstance(37.775001, -122.41801)), 12.3);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE DISTANCE(ShippingAddress, GEOLOCATION(37.775001, -122.41801), \'km\') <= 12.3',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lte(CALENDAR_MONTH(Account.CreatedDate), 2);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE CALENDAR_MONTH(CreatedDate) <= 2',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = lte(TO_LABEL(Account.AccountSource), 'Advertisement');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE TOLABEL(AccountSource) <= \'Advertisement\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );
    }

    @isTest
    static void testOperator_Comparison_BETWEEN() {
        // param1 are SObjectField
        Query.Filter filter;
        filter = between(Account.BillingCountry, 'China', 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= \'China\' AND BillingCountry <= \'China\')',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = between(Account.BillingCountry, getFakeId(Account.SObjectType, 0), getFakeId(Account.SObjectType, 0));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= \'001000zzzz00000\' AND BillingCountry <= \'001000zzzz00000\')',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = between(Account.BillingCountry, 123, 123);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= 123 AND BillingCountry <= 123)',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = between(Account.BillingCountry, 123.456, 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= 123.456 AND BillingCountry <= 123.456)',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = between(
            Account.BillingCountry,
            Datetime.newInstance(2023, 1, 1, 12, 12, 12),
            Datetime.newInstance(2023, 1, 1, 12, 12, 12)
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= :tmpVar1 AND BillingCountry <= :tmpVar2)',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = between(Account.BillingCountry, Date.newInstance(2023, 1, 1), Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= :tmpVar1 AND BillingCountry <= :tmpVar2)',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = between(Account.BillingCountry, Time.newInstance(12, 12, 12, 12), Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= :tmpVar1 AND BillingCountry <= :tmpVar2)',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = between(Account.BillingCountry, LAST_N_DAYS(2), LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= LAST_N_DAYS:2 AND BillingCountry <= LAST_N_DAYS:2)',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = between(Account.BillingCountry, CNY(2000), CNY(2000));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= CNY2000 AND BillingCountry <= CNY2000)',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        // param1 are Strings
        filter = between('BillingCountry', 'China', 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= \'China\' AND BillingCountry <= \'China\')',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = between('BillingCountry', getFakeId(Account.SObjectType, 0), getFakeId(Account.SObjectType, 0));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= \'001000zzzz00000\' AND BillingCountry <= \'001000zzzz00000\')',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = between('BillingCountry', 123, 123);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= 123 AND BillingCountry <= 123)',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = between('BillingCountry', 123.456, 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= 123.456 AND BillingCountry <= 123.456)',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = between(
            'BillingCountry',
            Datetime.newInstance(2023, 1, 1, 12, 12, 12),
            Datetime.newInstance(2023, 1, 1, 12, 12, 12)
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= :tmpVar1 AND BillingCountry <= :tmpVar2)',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = between('BillingCountry', Date.newInstance(2023, 1, 1), Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= :tmpVar1 AND BillingCountry <= :tmpVar2)',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = between('BillingCountry', Time.newInstance(12, 12, 12, 12), Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= :tmpVar1 AND BillingCountry <= :tmpVar2)',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = between('BillingCountry', LAST_N_DAYS(2), LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= LAST_N_DAYS:2 AND BillingCountry <= LAST_N_DAYS:2)',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = between('BillingCountry', CNY(2000), CNY(2000));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= CNY2000 AND BillingCountry <= CNY2000)',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        // param1 are AggregateFunction
        filter = between(MAX(Account.BillingCountry), 'China', 'China');
        Assert.areEqual(
            'SELECT Id FROM Account HAVING (MAX(BillingCountry) >= \'China\' AND MAX(BillingCountry) <= \'China\')',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = between(
            MAX(Account.BillingCountry),
            getFakeId(Account.SObjectType, 0),
            getFakeId(Account.SObjectType, 0)
        );
        Assert.areEqual(
            'SELECT Id FROM Account HAVING (MAX(BillingCountry) >= \'001000zzzz00000\' AND MAX(BillingCountry) <= \'001000zzzz00000\')',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = between(MAX(Account.BillingCountry), 123, 123);
        Assert.areEqual(
            'SELECT Id FROM Account HAVING (MAX(BillingCountry) >= 123 AND MAX(BillingCountry) <= 123)',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = between(MAX(Account.BillingCountry), 123.456, 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account HAVING (MAX(BillingCountry) >= 123.456 AND MAX(BillingCountry) <= 123.456)',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = between(
            MAX(Account.BillingCountry),
            Datetime.newInstance(2023, 1, 1, 12, 12, 12),
            Datetime.newInstance(2023, 1, 1, 12, 12, 12)
        );
        Assert.areEqual(
            'SELECT Id FROM Account HAVING (MAX(BillingCountry) >= :tmpVar1 AND MAX(BillingCountry) <= :tmpVar2)',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = between(MAX(Account.BillingCountry), Date.newInstance(2023, 1, 1), Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING (MAX(BillingCountry) >= :tmpVar1 AND MAX(BillingCountry) <= :tmpVar2)',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = between(
            MAX(Account.BillingCountry),
            Time.newInstance(12, 12, 12, 12),
            Time.newInstance(12, 12, 12, 12)
        );
        Assert.areEqual(
            'SELECT Id FROM Account HAVING (MAX(BillingCountry) >= :tmpVar1 AND MAX(BillingCountry) <= :tmpVar2)',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = between(MAX(Account.BillingCountry), LAST_N_DAYS(2), LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING (MAX(BillingCountry) >= LAST_N_DAYS:2 AND MAX(BillingCountry) <= LAST_N_DAYS:2)',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = between(MAX(Account.BillingCountry), CNY(2000), CNY(2000));
        Assert.areEqual(
            'SELECT Id FROM Account HAVING (MAX(BillingCountry) >= CNY2000 AND MAX(BillingCountry) <= CNY2000)',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        // param1 are others
        filter = between(
            DISTANCE_IN_KILOMETER(Account.ShippingAddress, Location.newInstance(37.775001, -122.41801)),
            12.3,
            12.3
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (DISTANCE(ShippingAddress, GEOLOCATION(37.775001, -122.41801), \'km\') >= 12.3 AND DISTANCE(ShippingAddress, GEOLOCATION(37.775001, -122.41801), \'km\') <= 12.3)',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = between(CALENDAR_MONTH(Account.CreatedDate), 2, 2);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (CALENDAR_MONTH(CreatedDate) >= 2 AND CALENDAR_MONTH(CreatedDate) <= 2)',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = between(TO_LABEL(Account.AccountSource), 'Advertisement', 'Advertisement');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (TOLABEL(AccountSource) >= \'Advertisement\' AND TOLABEL(AccountSource) <= \'Advertisement\')',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );
    }
    // #endregion
    // ============================

    @isTest
    static void testQuery_Style1() {
        // prettier-ignore
        List<Account> accountList = (List<Account>) Query.of(Account.SObjectType)
            .selectBy(selector()
                .add(Account.Name, Account.AnnualRevenue, Account.BillingState)
                .add('Contacts', Query.of(Contact.SObjectType).selectBy(Contact.Name))
            )
            .filterBy(orx()
                .add(andx()
                    .add(gt(Account.AnnualRevenue, 1000))
                    .add(eq(Account.BillingCountry, 'China'))
                    .add(eq(Account.BillingState, 'Beijing'))
                )
                .add(andx()
                    .add(lt(Account.AnnualRevenue, 1000))
                    .add(eq(Account.BillingCountry, 'China'))
                    .add(eq(Account.BillingState, 'Shanghai'))
                )
            )
            .orderBy(Account.AnnualRevenue).descending().nullsLast()
            .limitx(10)
            .forView()
            .run();
        Assert.areEqual(2, accountList.size());
        Assert.areEqual(1500, accountList[0].AnnualRevenue);
        Assert.areEqual('Beijing', accountList[0].BillingState);
        Assert.areEqual(500, accountList[1].AnnualRevenue);
        Assert.areEqual('Shanghai', accountList[1].BillingState);
    }

    @isTest
    static void testQuery_Style2() {
        // prettier-ignore
        List<Account> accountList = (List<Account>) Query.of(Account.SObjectType)
            .selectBy(Account.Name, Account.AnnualRevenue, Account.BillingState)
            .selectBy('Contacts', Query.of(Contact.SObjectType).selectBy(Contact.Name))
            .filterBy(orx()
                .add(andx()
                    .add(gt(Account.AnnualRevenue, 1000))
                    .add(eq(Account.BillingCountry, 'China'))
                    .add(eq(Account.BillingState, 'Beijing'))
                )
                .add(andx()
                    .add(lt(Account.AnnualRevenue, 1000))
                    .add(eq(Account.BillingCountry, 'China'))
                    .add(eq(Account.BillingState, 'Shanghai'))
                )
            )
            .orderBy(Account.AnnualRevenue).descending().nullsLast()
            .limitx(10)
            .forView()
            .run();
        Assert.areEqual(2, accountList.size());
        Assert.areEqual(1500, accountList[0].AnnualRevenue);
        Assert.areEqual('Beijing', accountList[0].BillingState);
        Assert.areEqual(500, accountList[1].AnnualRevenue);
        Assert.areEqual('Shanghai', accountList[1].BillingState);
    }

    @isTest
    static void testQuery_for_View_Reference_Update() {
        List<Account> accountList = (List<Account>) Query.of(Account.SObjectType)
            .selectBy(Account.Name, Account.AnnualRevenue, Account.BillingState)
            .offset(2)
            .limitx(4)
            .forView()
            .run();

        System.debug(accountList);
        Assert.areEqual(4, accountList.size());

        accountList = (List<Account>) Query.of(Account.SObjectType)
            .selectBy(Account.Name, Account.AnnualRevenue, Account.BillingState)
            .offset(2)
            .limitx(4)
            .forReference()
            .run();

        System.debug(accountList);
        Assert.areEqual(4, accountList.size());

        accountList = (List<Account>) Query.of(Account.SObjectType)
            .selectBy(Account.Name, Account.AnnualRevenue, Account.BillingState)
            .limitx(4)
            .forUpdate()
            .run();

        System.debug(accountList);
        Assert.areEqual(4, accountList.size());
    }

    @isTest
    static void testQuery_GetLocator() {
        Database.QueryLocator locator = Query.of(Account.SObjectType)
            .selectBy(Account.Name, Account.AnnualRevenue, Account.BillingState)
            .offset(2)
            .limitx(4)
            .getLocator();

        System.debug(locator.getQuery());
    }

    @isTest
    static void testQuery_Functions_Date() {
        List<AggregateResult> results = (List<AggregateResult>) Query.of(Contact.SObjectType)
            .selectBy(
                selector()
                    .add(CALENDAR_MONTH(Contact.Birthdate))
                    .add(CALENDAR_QUARTER(Contact.Birthdate))
                    .add(CALENDAR_YEAR(Contact.Birthdate))
                    .add(DAY_IN_MONTH(Contact.Birthdate))
                    .add(DAY_IN_WEEK(Contact.Birthdate))
                    .add(DAY_IN_YEAR(Contact.Birthdate))
                    .add(FISCAL_MONTH(Contact.Birthdate))
                    .add(FISCAL_QUARTER(Contact.Birthdate))
                    .add(FISCAL_YEAR(Contact.Birthdate))
            )
            .groupBy(Contact.Birthdate)
            .run();
        System.debug(results);

        results = (List<AggregateResult>) Query.of(Contact.SObjectType)
            .selectBy(
                selector()
                    .add(CALENDAR_MONTH(CONVERT_TIMEZONE(Contact.Birthdate)))
                    .add(CALENDAR_QUARTER(CONVERT_TIMEZONE(Contact.Birthdate)))
                    .add(CALENDAR_YEAR(CONVERT_TIMEZONE(Contact.Birthdate)))
                    .add(DAY_IN_MONTH(CONVERT_TIMEZONE(Contact.Birthdate)))
                    .add(DAY_IN_WEEK(CONVERT_TIMEZONE(Contact.Birthdate)))
                    .add(DAY_IN_YEAR(CONVERT_TIMEZONE(Contact.Birthdate)))
                    .add(FISCAL_MONTH(CONVERT_TIMEZONE(Contact.Birthdate)))
                    .add(FISCAL_QUARTER(CONVERT_TIMEZONE(Contact.Birthdate)))
                    .add(FISCAL_YEAR(CONVERT_TIMEZONE(Contact.Birthdate)))
            )
            .groupBy(Contact.Birthdate)
            .run();
        System.debug(results);

        results = (List<AggregateResult>) Query.of(Contact.SObjectType)
            .selectBy(
                selector()
                    .add(DAY_ONLY(Contact.CreatedDate))
                    .add(HOUR_IN_DAY(Contact.CreatedDate))
                    .add(WEEK_IN_MONTH(Contact.CreatedDate))
                    .add(WEEK_IN_YEAR(Contact.CreatedDate))
            )
            .groupBy(
                grouper()
                    .add(DAY_ONLY(Contact.CreatedDate))
                    .add(HOUR_IN_DAY(Contact.CreatedDate))
                    .add(WEEK_IN_MONTH(Contact.CreatedDate))
                    .add(WEEK_IN_YEAR(Contact.CreatedDate))
            )
            .run();
        System.debug(results);

        results = (List<AggregateResult>) Query.of(Contact.SObjectType)
            .selectBy(
                selector()
                    .add(DAY_ONLY(CONVERT_TIMEZONE(Contact.CreatedDate)))
                    .add(HOUR_IN_DAY(CONVERT_TIMEZONE(Contact.CreatedDate)))
                    .add(WEEK_IN_MONTH(CONVERT_TIMEZONE(Contact.CreatedDate)))
                    .add(WEEK_IN_YEAR(CONVERT_TIMEZONE(Contact.CreatedDate)))
            )
            .groupBy(
                grouper()
                    .add(DAY_ONLY(CONVERT_TIMEZONE(Contact.CreatedDate)))
                    .add(HOUR_IN_DAY(CONVERT_TIMEZONE(Contact.CreatedDate)))
                    .add(WEEK_IN_MONTH(CONVERT_TIMEZONE(Contact.CreatedDate)))
                    .add(WEEK_IN_YEAR(CONVERT_TIMEZONE(Contact.CreatedDate)))
            )
            .run();
        System.debug(results);

        // prettier-ignore
        List<Contact> contacts = (List<Contact>) Query.of(Contact.SObjectType)
            .selectBy(Contact.Name)
            .filterBy(
                andx()
                    .add(eq(CALENDAR_YEAR(Contact.Birthdate), 2023))
                    .add(eq(CALENDAR_MONTH(Contact.Birthdate), 1))
                    .add(inx(CALENDAR_MONTH(Contact.Birthdate), 1, 2, 3, 4))
                    .add(between(CALENDAR_MONTH(Contact.Birthdate), 1, 4))
            )
            .run();
        System.debug(contacts);
        Assert.areEqual(4, contacts.size());
    }

    // ! CONVERT_CURRENCY is only suppored in a multi-currency org.
    // TODO: Comment out @isTest before deploy new releases.
    @isTest
    static void testQuery_Functions_Currency() {
        // prettier-ignore
        List<Account> accounts = (List<Account>) Query.of(Account.SObjectType)
                .selectBy(Account.Name)
                .selectBy(CONVERT_CURRENCY(Account.AnnualRevenue))
                .run();
        System.debug(accounts);
        Assert.areEqual(6, accounts.size());

        // prettier-ignore
        accounts = (List<Account>) Query.of(Account.SObjectType)
                .selectBy(Account.Name)
                .selectBy(FORMAT(CONVERT_CURRENCY(Account.AnnualRevenue)))
                .run();
        System.debug(accounts);
        Assert.areEqual(6, accounts.size());

        // prettier-ignore
        accounts = (List<Account>) Query.of(Account.SObjectType)
                .selectBy(Account.Name, Account.AnnualRevenue)
                .filterBy(
                    andx()
                        .add(gt(Account.AnnualRevenue, CNY(0)))
                        .add(lt(Account.AnnualRevenue, CNY(3000)))
                        .add(between(Account.AnnualRevenue, CNY(0), CNY(3000)))
                )
                .run();
        System.debug(accounts);
        Assert.areEqual(6, accounts.size());
    }

    @isTest
    static void testQuery_Functions_Format() {
        // prettier-ignore
        List<Contact> contacts = (List<Contact>) Query.of(Contact.SObjectType)
            .selectBy(Contact.Name)
            .selectBy(FORMAT(Contact.Birthdate), FORMAT(Contact.CreatedDate))
            .run();
        System.debug(contacts);
        Assert.areEqual(4, contacts.size());

        // prettier-ignore
        List<Account> accounts = (List<Account>) Query.of(Account.SObjectType)
            .selectBy(Account.Name)
            .selectBy(FORMAT(Account.AnnualRevenue), FORMAT(Account.NumberOfEmployees))
            .run();
        System.debug(accounts);
        Assert.areEqual(6, accounts.size());
    }

    @isTest
    static void testQuery_OrderBy() {
        List<Account> accountList = (List<Account>) Query.of(Account.SObjectType)
            .selectBy(Account.Name, Account.AnnualRevenue, Account.BillingState)
            .orderBy(Account.BillingCountry, Account.BillingState, Account.AnnualRevenue)
            .run();

        System.debug(accountList);
        Assert.areEqual(6, accountList.size());

        // prettier-ignore
        List<AggregateResult> results = (List<AggregateResult>) Query.of(Account.SObjectType)
            .selectBy(GROUPING(Account.BillingCountry))
            .selectBy(GROUPING(Account.BillingState, 'alias0'))
            .selectBy(MIN(Account.AnnualRevenue))
            .selectBy(MAX(Account.AnnualRevenue))
            .selectBy(AVG(Account.AnnualRevenue, 'average'))
            .selectBy(SUM(Account.AnnualRevenue, 'summary'))
            .groupBy(Account.BillingCountry, Account.BillingState).rollup()
            .orderBy(Account.BillingState).nullsLast().descending()
            .orderBy(GROUPING(Account.BillingCountry), GROUPING(Account.BillingState)).nullsLast().descending()
            .run();
        System.debug(results);
    }

    @isTest
    // prettier-ignore
    static void testQuery_Composite_Style1() {
        Query contactQuery = Query.of(Contact.SObjectType).selectBy(Contact.Name);

        Query query = Query.of(Account.SObjectType);

        Query.Selector fields = selector();
        fields.add(Account.Name, Account.AnnualRevenue);
        fields.add(Account.BillingCountry, Account.BillingState);
        fields.add('Contacts', contactQuery);
        query.selectBy(fields);

        Query.CompositeFilter filters = orx();

        filters.add(andx()
            .add(gt(Account.AnnualRevenue, 1000))
            .add(eq(Account.BillingCountry, 'China'))
            .add(eq(Account.BillingState, 'Beijing'))
        );

        filters.add(andx()
            .add(lt(Account.AnnualRevenue, 1000))
            .add(eq(Account.BillingCountry, 'China'))
            .add(eq(Account.BillingState, 'Shanghai'))
        );

        query.filterBy(filters);

        query.orderBy(Account.AnnualRevenue).descending().nullsLast();

        List<Account> accountList = (List<Account>) query.run();
        Assert.areEqual(2, accountList.size());
        Assert.areEqual(1500, accountList[0].AnnualRevenue);
        Assert.areEqual('Beijing', accountList[0].BillingState);
        Assert.areEqual(500, accountList[1].AnnualRevenue);
        Assert.areEqual('Shanghai', accountList[1].BillingState);
    }

    @isTest
    // prettier-ignore
    static void testQuery_Composite_Style2() {
        Query contactQuery = Query.of(Contact.SObjectType).selectBy(Contact.Name);

        Query query = Query.of(Account.SObjectType);

        query.selectBy(Account.Name, Account.AnnualRevenue);
        query.selectBy(Account.BillingCountry, Account.BillingState);
        query.selectBy('Contacts', contactQuery);

        Query.CompositeFilter filters = orx();

        filters.add(andx()
            .add(gt(Account.AnnualRevenue, 1000))
            .add(eq(Account.BillingCountry, 'China'))
            .add(eq(Account.BillingState, 'Beijing'))
        );

        filters.add(andx()
            .add(lt(Account.AnnualRevenue, 1000))
            .add(eq(Account.BillingCountry, 'China'))
            .add(eq(Account.BillingState, 'Shanghai'))
        );

        query.filterBy(filters);

        query.orderBy(Account.AnnualRevenue).descending().nullsLast();

        List<Account> accountList = (List<Account>) query.run();
        Assert.areEqual(2, accountList.size());
        Assert.areEqual(1500, accountList[0].AnnualRevenue);
        Assert.areEqual('Beijing', accountList[0].BillingState);
        Assert.areEqual(500, accountList[1].AnnualRevenue);
        Assert.areEqual('Shanghai', accountList[1].BillingState);
    }

    @isTest
    static void testQuery_Filter_Style1() {
        // prettier-ignore
        List<Contact> contactList = (List<Contact>) Query.of(Contact.SObjectType).selectBy(Contact.Id, Contact.Name).run();
        // prettier-ignore
        List<Account> accountList = (List<Account>) Query.of(Account.SObjectType)
            .selectBy(Account.Name, Account.AnnualRevenue, Account.BillingCountry, Account.BillingState)
            .selectBy('Contacts', Query.of(Contact.SObjectType).selectBy(Contact.Name).filterBy(inx(Contact.Id, contactList)))
            .filterBy(andx()
                .add(inx(Account.Id, Query.of(Contact.SObjectType).selectBy(Contact.AccountId)))
                .add(orx()
                    .add(andx()
                        .add(gt(Account.AnnualRevenue, 1000))
                        .add(eq(Account.BillingCountry, 'China'))
                        .add(eq(Account.BillingState, 'Beijing'))
                    )
                    .add(andx()
                        .add(lt(Account.AnnualRevenue, 1000))
                        .add(eq(Account.BillingCountry, 'China'))
                        .add(eq(Account.BillingState, 'Shanghai'))
                    )
                )
            )
            .orderBy(Account.AnnualRevenue).descending().nullsLast()
            .run();
        Assert.areEqual(2, accountList.size());
        Assert.areEqual(1500, accountList[0].AnnualRevenue);
        Assert.areEqual('Beijing', accountList[0].BillingState);
        Assert.areEqual(500, accountList[1].AnnualRevenue);
        Assert.areEqual('Shanghai', accountList[1].BillingState);
    }

    @isTest
    static void testQuery_Filter_Style2() {
        // prettier-ignore
        List<Contact> contactList = (List<Contact>) Query.of(Contact.SObjectType).selectBy(Contact.Id, Contact.Name).run();
        // prettier-ignore
        List<Account> accountList = (List<Account>) Query.of(Account.SObjectType)
            .selectBy(selector()
                .add(Account.Name, Account.AnnualRevenue, Account.BillingCountry, Account.BillingState)
                .add('Contacts', Query.of(Contact.SObjectType).selectBy(Contact.Name).filterBy(inx(Contact.Id, contactList)))
            )
            .filterBy(andx(
                inx(Account.Id, Query.of(Contact.SObjectType).selectBy(Contact.AccountId)),
                orx(
                    andx(
                        gt(Account.AnnualRevenue, 1000),
                        eq(Account.BillingCountry, 'China'),
                        eq(Account.BillingState, 'Beijing')
                    ),
                    andx(
                        lt(Account.AnnualRevenue, 1000),
                        eq(Account.BillingCountry, 'China'),
                        eq(Account.BillingState, 'Shanghai')
                    )
                )
            ))
            .orderBy(orderer().add(Account.AnnualRevenue).descending().nullsLast())
            .run();
        Assert.areEqual(2, accountList.size());
        Assert.areEqual(1500, accountList[0].AnnualRevenue);
        Assert.areEqual('Beijing', accountList[0].BillingState);
        Assert.areEqual(500, accountList[1].AnnualRevenue);
        Assert.areEqual('Shanghai', accountList[1].BillingState);
    }

    @isTest
    static void testQuery_Filter_Distance() {
        // prettier-ignore
        List<Account> accountList = (List<Account>) Query.of(Account.SObjectType)
            .selectBy(Account.Name, Account.AnnualRevenue, Account.BillingCountry, Account.BillingState, Account.ShippingAddress)
            .filterBy(
                lt(DISTANCE_IN_KILOMETER(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800)), 20)
            )
            .orderBy(DISTANCE_IN_MILE(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800))).ascending().nullsLast()
            .run();
        Assert.areEqual(2, accountList.size());
        Assert.areEqual(1500, accountList[0].AnnualRevenue);
        Assert.areEqual('Beijing', accountList[0].BillingState);
        Assert.areEqual(500, accountList[1].AnnualRevenue);
        Assert.areEqual('Shanghai', accountList[1].BillingState);
    }

    @isTest
    static void testQuery_Filter_Like_Escaped() {
        // prettier-ignore
        List<Account> accountList = (List<Account>) Query.of(Account.SObjectType)
            .selectBy(Account.Name, Account.AnnualRevenue, Account.BillingCountry, Account.BillingState)
            .filterBy(
                likex(Account.Name, '%\'%')
            )
            .run();
        Assert.areEqual(2, accountList.size());
    }

    @isTest
    static void testQuery_Filter_Like_Injected() {
        // prettier-ignore
        List<Account> accountList = (List<Account>) Query.of(Account.SObjectType)
            .selectBy(Account.Name, Account.AnnualRevenue, Account.BillingCountry, Account.BillingState)
            .filterBy(
                likex(Account.Name, '%\' AND Name LIKE \'%')
            )
            .run();
        Assert.areEqual(0, accountList.size());
    }

    @isTest
    static void testQuery_Filter_Between() {
        // prettier-ignore
        List<Account> accountList = (List<Account>) Query.of(Account.SObjectType)
            .selectBy(Account.Name, Account.AnnualRevenue, Account.BillingCountry, Account.BillingState)
            .filterBy(
                between(Account.BillingState, 'Bd', 'Si') // bd < Beijing < Shanghai < Si
            )
            .run();
        Assert.areEqual(4, accountList.size());

        // prettier-ignore
        accountList = (List<Account>) Query.of(Account.SObjectType)
            .selectBy(Account.Name, Account.AnnualRevenue, Account.BillingCountry, Account.BillingState)
            .filterBy(between(Account.CreatedDate, LAST_N_DAYS(2), NEXT_N_DAYS(2)))
            .run();
        Assert.areEqual(6, accountList.size());
    }

    @isTest
    static void testQuery_GroupBy() {
        // prettier-ignore
        List<AggregateResult> results = (List<AggregateResult>) Query.of(Account.SObjectType)
            .selectBy(GROUPING(Account.BillingCountry))
            .selectBy(GROUPING(Account.BillingState, 'alias0'))
            .selectBy(MIN(Account.AnnualRevenue))
            .selectBy(MAX(Account.AnnualRevenue))
            .selectBy(AVG(Account.AnnualRevenue, 'average'))
            .selectBy(SUM(Account.AnnualRevenue, 'summary'))
            .groupBy(Account.BillingCountry, Account.BillingState).rollup()
            .orderBy(GROUPING(Account.BillingCountry), GROUPING(Account.BillingState)).nullsLast().descending()
            .run();
        System.debug(results);

        // prettier-ignore
        results = (List<AggregateResult>) Query.of(Account.SObjectType)
            .selectBy(GROUPING(Account.BillingCountry))
            .selectBy(GROUPING(Account.BillingState, 'alias0'))
            .selectBy(MIN(Account.AnnualRevenue))
            .selectBy(MAX(Account.AnnualRevenue))
            .selectBy(AVG(Account.AnnualRevenue, 'average'))
            .selectBy(SUM(Account.AnnualRevenue, 'summary'))
            .groupBy(Account.BillingCountry, Account.BillingState).cube()
            .orderBy(GROUPING(Account.BillingCountry), GROUPING(Account.BillingState)).nullsLast().descending()
            .run();
        System.debug(results);

        // prettier-ignore
        results = (List<AggregateResult>) Query.of(Account.SObjectType)
            .selectBy(GROUPING(Account.BillingCountry))
            .selectBy(GROUPING(Account.BillingState, 'alias0'))
            .selectBy(MIN(Account.AnnualRevenue))
            .selectBy(MAX(Account.AnnualRevenue))
            .selectBy(AVG(Account.AnnualRevenue, 'average'))
            .selectBy(SUM(Account.AnnualRevenue, 'summary'))
            .groupBy(Account.BillingCountry, Account.BillingState).rollup()
            .havingBy(
                andx()
                    .add(between(AVG(Account.AnnualRevenue), 0, 2000))
                    .add(eq(SUM(Account.AnnualRevenue), 2000))
            )
            .orderBy(GROUPING(Account.BillingCountry), GROUPING(Account.BillingState)).nullsLast().descending()
            .run();
        System.debug(results);

        // prettier-ignore
        results = (List<AggregateResult>) Query.of(Account.SObjectType)
            .selectBy(GROUPING(Account.BillingCountry))
            .selectBy(MIN(Account.BillingState))
            .selectBy(MAX(Account.BillingState))
            .groupBy(Account.BillingCountry).rollup()
            .havingBy(
                andx()
                    .add(likex(MIN(Account.BillingState), '%i%'))
                    .add(inx(MIN(Account.BillingState), 'Shanghai', 'Beijing'))
                    .add(likex(MAX(Account.BillingState), '%i%'))
                    .add(inx(MAX(Account.BillingState), 'Shanghai', 'Beijing'))
            )
            .orderBy(GROUPING(Account.BillingCountry)).nullsLast().descending()
            .run();
        System.debug(results);
    }

    @isTest
    static void testQuery_GroupBy_Count() {
        List<AggregateResult> results = (List<AggregateResult>) Query.of(Account.SObjectType)
            .selectBy(COUNT(Account.AnnualRevenue))
            .groupBy(Account.BillingCountry, Account.BillingState)
            .run();
        System.debug(results);
        Assert.areEqual(2, results[0].get('expr0'));
        Assert.areEqual(2, results[1].get('expr0'));
        Assert.areEqual(2, results[2].get('expr0'));

        results = (List<AggregateResult>) Query.of(Account.SObjectType)
            .selectBy(COUNT(Account.AnnualRevenue, 'count_of_account'))
            .groupBy(Account.BillingCountry, Account.BillingState)
            .run();
        System.debug(results);
        Assert.areEqual(2, results[0].get('count_of_account'));
        Assert.areEqual(2, results[1].get('count_of_account'));
        Assert.areEqual(2, results[2].get('count_of_account'));

        results = (List<AggregateResult>) Query.of(Account.SObjectType)
            .selectBy(COUNT(Account.AnnualRevenue, 'count_of_account'))
            .run();
        System.debug(results);
        Assert.areEqual(6, results[0].get('count_of_account'));

        results = (List<AggregateResult>) Query.of(Account.SObjectType)
            .selectBy(COUNT(Account.AnnualRevenue, 'count_of_account'))
            .run();
        System.debug(results);
        Assert.areEqual(6, results[0].get('count_of_account'));

        Integer count = Query.of(Account.SObjectType).selectBy(COUNT()).getCount();
        Assert.areEqual(6, count);

        results = (List<AggregateResult>) Query.of(Account.SObjectType)
            .selectBy(COUNT_DISTINCT(Account.BillingState))
            .run();
        System.debug(results);
        Assert.areEqual(2, results[0].get('expr0'));

        results = (List<AggregateResult>) Query.of(Account.SObjectType)
            .selectBy(Account.BillingCountry)
            .selectBy(COUNT_DISTINCT(Account.BillingState))
            .groupBy(Account.BillingCountry)
            .run();
        System.debug(results);
        Assert.areEqual(2, results[0].get('expr0'));
        Assert.areEqual(0, results[1].get('expr0'));
    }

    @isTest
    static void testQuery_ValueObject_Filter() {
        Assert.areEqual(eq(Account.Name, 123), eq(Account.Name, 123));
        Assert.areEqual(ne(Account.Name, 123), ne(Account.Name, 123));
        Assert.areEqual(gt(Account.Name, 123), gt(Account.Name, 123));
        Assert.areEqual(gte(Account.Name, 123), gte(Account.Name, 123));
        Assert.areEqual(lt(Account.Name, 123), lt(Account.Name, 123));
        Assert.areEqual(lte(Account.Name, 123), lte(Account.Name, 123));
        Assert.areEqual(likex(Account.Name, '123'), likex(Account.Name, '123'));
        Assert.areEqual(nlike(Account.Name, '123'), nlike(Account.Name, '123'));
        Assert.areEqual(
            includes(Account.Name, new List<String>{ '123' }),
            includes(Account.Name, new List<String>{ '123' })
        );
        Assert.areEqual(
            excludes(Account.Name, new List<String>{ '123' }),
            excludes(Account.Name, new List<String>{ '123' })
        );
        Assert.areEqual(inx(Account.Name, new List<String>{ '123' }), inx(Account.Name, new List<String>{ '123' }));
        Assert.areEqual(nin(Account.Name, new List<String>{ '123' }), nin(Account.Name, new List<String>{ '123' }));
        Assert.areEqual(nin(Account.Name, new List<String>{ '123' }), nin(Account.Name, new List<String>{ '123' }));
        Assert.areEqual(
            inx(Account.Name, Query.of(Account.SObjectType).selectBy(Account.Id)),
            inx(Account.Name, Query.of(Account.SObjectType).selectBy(Account.Id))
        );
        Assert.areEqual(
            nin(Account.Name, Query.of(Account.SObjectType).selectBy(Account.Id)),
            nin(Account.Name, Query.of(Account.SObjectType).selectBy(Account.Id))
        );

        Assert.areEqual(
            DISTANCE_IN_MILE(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800)),
            DISTANCE_IN_MILE(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800))
        );

        Assert.areEqual(
            DISTANCE_IN_KILOMETER(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800)),
            DISTANCE_IN_KILOMETER(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800))
        );

        Assert.areEqual(
            lt(DISTANCE_IN_KILOMETER(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800)), 20),
            lt(DISTANCE_IN_KILOMETER(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800)), 20)
        );

        // Date Literal
        Assert.areEqual(YESTERDAY(), YESTERDAY());
        Assert.areEqual(TODAY(), TODAY());
        Assert.areEqual(TOMORROW(), TOMORROW());
        Assert.areEqual(LAST_WEEK(), LAST_WEEK());
        Assert.areEqual(THIS_WEEK(), THIS_WEEK());
        Assert.areEqual(NEXT_WEEK(), NEXT_WEEK());
        Assert.areEqual(LAST_MONTH(), LAST_MONTH());
        Assert.areEqual(THIS_MONTH(), THIS_MONTH());
        Assert.areEqual(NEXT_MONTH(), NEXT_MONTH());
        Assert.areEqual(LAST_90_DAYS(), LAST_90_DAYS());
        Assert.areEqual(NEXT_90_DAYS(), NEXT_90_DAYS());
        Assert.areEqual(THIS_QUARTER(), THIS_QUARTER());
        Assert.areEqual(LAST_QUARTER(), LAST_QUARTER());
        Assert.areEqual(NEXT_QUARTER(), NEXT_QUARTER());
        Assert.areEqual(THIS_YEAR(), THIS_YEAR());
        Assert.areEqual(LAST_YEAR(), LAST_YEAR());
        Assert.areEqual(NEXT_YEAR(), NEXT_YEAR());
        Assert.areEqual(THIS_FISCAL_QUARTER(), THIS_FISCAL_QUARTER());
        Assert.areEqual(LAST_FISCAL_QUARTER(), LAST_FISCAL_QUARTER());
        Assert.areEqual(NEXT_FISCAL_QUARTER(), NEXT_FISCAL_QUARTER());
        Assert.areEqual(THIS_FISCAL_YEAR(), THIS_FISCAL_YEAR());
        Assert.areEqual(LAST_FISCAL_YEAR(), LAST_FISCAL_YEAR());
        Assert.areEqual(NEXT_FISCAL_YEAR(), NEXT_FISCAL_YEAR());
        Assert.areEqual(LAST_N_DAYS(123), LAST_N_DAYS(123));
        Assert.areEqual(NEXT_N_DAYS(123), NEXT_N_DAYS(123));
        Assert.areEqual(N_DAYS_AGO(123), N_DAYS_AGO(123));
        Assert.areEqual(NEXT_N_WEEKS(123), NEXT_N_WEEKS(123));
        Assert.areEqual(LAST_N_WEEKS(123), LAST_N_WEEKS(123));
        Assert.areEqual(N_WEEKS_AGO(123), N_WEEKS_AGO(123));
        Assert.areEqual(NEXT_N_MONTHS(123), NEXT_N_MONTHS(123));
        Assert.areEqual(LAST_N_MONTHS(123), LAST_N_MONTHS(123));
        Assert.areEqual(N_MONTHS_AGO(123), N_MONTHS_AGO(123));
        Assert.areEqual(NEXT_N_QUARTERS(123), NEXT_N_QUARTERS(123));
        Assert.areEqual(LAST_N_QUARTERS(123), LAST_N_QUARTERS(123));
        Assert.areEqual(N_QUARTERS_AGO(123), N_QUARTERS_AGO(123));
        Assert.areEqual(NEXT_N_YEARS(123), NEXT_N_YEARS(123));
        Assert.areEqual(LAST_N_YEARS(123), LAST_N_YEARS(123));
        Assert.areEqual(N_YEARS_AGO(123), N_YEARS_AGO(123));
        Assert.areEqual(NEXT_N_FISCAL_QUARTERS(123), NEXT_N_FISCAL_QUARTERS(123));
        Assert.areEqual(N_FISCAL_QUARTERS_AGO(123), N_FISCAL_QUARTERS_AGO(123));
        Assert.areEqual(NEXT_N_FISCAL_YEARS(123), NEXT_N_FISCAL_YEARS(123));
        Assert.areEqual(LAST_N_FISCAL_YEARS(123), LAST_N_FISCAL_YEARS(123));
        Assert.areEqual(N_FISCAL_YEARS_AGO(123), N_FISCAL_YEARS_AGO(123));

        Assert.areEqual(gt(Account.Name, N_FISCAL_YEARS_AGO(123)), gt(Account.Name, N_FISCAL_YEARS_AGO(123)));
        Assert.areEqual(gte(Account.Name, N_FISCAL_YEARS_AGO(123)), gte(Account.Name, N_FISCAL_YEARS_AGO(123)));
        Assert.areEqual(lt(Account.Name, N_FISCAL_YEARS_AGO(123)), lt(Account.Name, N_FISCAL_YEARS_AGO(123)));
        Assert.areEqual(lte(Account.Name, N_FISCAL_YEARS_AGO(123)), lte(Account.Name, N_FISCAL_YEARS_AGO(123)));

        // Date, Datetime, Time
        Assert.areEqual(gt(Account.Name, Date.newInstance(2023, 1, 1)), gt(Account.Name, Date.newInstance(2023, 1, 1)));
        Assert.areEqual(
            gte(Account.Name, Date.newInstance(2023, 1, 1)),
            gte(Account.Name, Date.newInstance(2023, 1, 1))
        );
        Assert.areEqual(lt(Account.Name, Date.newInstance(2023, 1, 1)), lt(Account.Name, Date.newInstance(2023, 1, 1)));
        Assert.areEqual(
            lte(Account.Name, Date.newInstance(2023, 1, 1)),
            lte(Account.Name, Date.newInstance(2023, 1, 1))
        );

        Assert.areEqual(
            gt(Account.Name, Datetime.newInstance(2023, 1, 1)),
            gt(Account.Name, Datetime.newInstance(2023, 1, 1))
        );
        Assert.areEqual(
            gte(Account.Name, Datetime.newInstance(2023, 1, 1)),
            gte(Account.Name, Datetime.newInstance(2023, 1, 1))
        );
        Assert.areEqual(
            lt(Account.Name, Datetime.newInstance(2023, 1, 1)),
            lt(Account.Name, Datetime.newInstance(2023, 1, 1))
        );
        Assert.areEqual(
            lte(Account.Name, Datetime.newInstance(2023, 1, 1)),
            lte(Account.Name, Datetime.newInstance(2023, 1, 1))
        );

        Assert.areEqual(
            gt(Account.Name, Time.newInstance(12, 0, 0, 0)),
            gt(Account.Name, Time.newInstance(12, 0, 0, 0))
        );
        Assert.areEqual(
            gte(Account.Name, Time.newInstance(12, 0, 0, 0)),
            gte(Account.Name, Time.newInstance(12, 0, 0, 0))
        );
        Assert.areEqual(
            lt(Account.Name, Time.newInstance(12, 0, 0, 0)),
            lt(Account.Name, Time.newInstance(12, 0, 0, 0))
        );
        Assert.areEqual(
            lte(Account.Name, Time.newInstance(12, 0, 0, 0)),
            lte(Account.Name, Time.newInstance(12, 0, 0, 0))
        );

        Assert.areEqual(
            new List<Query.Filter>{
                eq(Account.Name, 123),
                likex(Account.Name, '123'),
                inx(Account.Name, new List<String>{ '123' }),
                gt(Account.Name, N_FISCAL_YEARS_AGO(123))
            },
            new List<Query.Filter>{
                eq(Account.Name, 123),
                likex(Account.Name, '123'),
                inx(Account.Name, new List<String>{ '123' }),
                gt(Account.Name, N_FISCAL_YEARS_AGO(123))
            }
        );

        Assert.areEqual(between(Account.BillingState, 'Bd', 'Si'), between(Account.BillingState, 'Bd', 'Si'));
    }

    @isTest
    static void testQuery_ValueObject_Query() {
        Query q = Query.of(Account.SObjectType);
        Assert.areEqual(q, q);

        Assert.areEqual(
            Query.of(Account.SObjectType)
                .OrderBy(Account.BillingCountry, Account.BillingState)
                .OrderBy(Account.BillingCountry, Account.BillingState, Account.BillingState)
                .OrderBy(Account.BillingCountry, Account.BillingState, Account.BillingState, Account.BillingState)
                .OrderBy(
                    Account.BillingCountry,
                    Account.BillingState,
                    Account.BillingState,
                    Account.BillingState,
                    Account.BillingState
                )
                .nullsFirst(),
            Query.of(Account.SObjectType)
                .OrderBy(Account.BillingCountry, Account.BillingState)
                .OrderBy(Account.BillingCountry, Account.BillingState, Account.BillingState)
                .OrderBy(Account.BillingCountry, Account.BillingState, Account.BillingState, Account.BillingState)
                .OrderBy(
                    Account.BillingCountry,
                    Account.BillingState,
                    Account.BillingState,
                    Account.BillingState,
                    Account.BillingState
                )
                .nullsFirst()
        );

        Assert.areEqual(
            Query.of(Account.SObjectType)
                .selectBy(GROUPING(Account.BillingCountry))
                .selectBy(GROUPING(Account.BillingState, 'alias0'))
                .selectBy(MIN(Account.AnnualRevenue, 'minimum'))
                .selectBy(MIN(Account.AnnualRevenue))
                .selectBy(MAX(Account.AnnualRevenue, 'maximum'))
                .selectBy(MAX(Account.AnnualRevenue))
                .selectBy(AVG(Account.AnnualRevenue, 'average'))
                .selectBy(AVG(Account.AnnualRevenue))
                .selectBy(SUM(Account.AnnualRevenue, 'summary'))
                .selectBy(SUM(Account.AnnualRevenue))
                .groupBy(Account.BillingCountry)
                .groupBy(Account.BillingCountry, Account.BillingState)
                .groupBy(Account.BillingCountry, Account.BillingState, Account.BillingState)
                .groupBy(Account.BillingCountry, Account.BillingState, Account.BillingState, Account.BillingState)
                .groupBy(
                    Account.BillingCountry,
                    Account.BillingState,
                    Account.BillingState,
                    Account.BillingState,
                    Account.BillingState
                )
                .rollup()
                .orderBy(grouping(Account.BillingCountry), grouping(Account.BillingState))
                .nullsLast()
                .descending(),
            Query.of(Account.SObjectType)
                .selectBy(GROUPING(Account.BillingCountry))
                .selectBy(GROUPING(Account.BillingState, 'alias0'))
                .selectBy(MIN(Account.AnnualRevenue, 'minimum'))
                .selectBy(MIN(Account.AnnualRevenue))
                .selectBy(MAX(Account.AnnualRevenue, 'maximum'))
                .selectBy(MAX(Account.AnnualRevenue))
                .selectBy(AVG(Account.AnnualRevenue, 'average'))
                .selectBy(AVG(Account.AnnualRevenue))
                .selectBy(SUM(Account.AnnualRevenue, 'summary'))
                .selectBy(SUM(Account.AnnualRevenue))
                .groupBy(Account.BillingCountry)
                .groupBy(Account.BillingCountry, Account.BillingState)
                .groupBy(Account.BillingCountry, Account.BillingState, Account.BillingState)
                .groupBy(Account.BillingCountry, Account.BillingState, Account.BillingState, Account.BillingState)
                .groupBy(
                    Account.BillingCountry,
                    Account.BillingState,
                    Account.BillingState,
                    Account.BillingState,
                    Account.BillingState
                )
                .rollup()
                .orderBy(grouping(Account.BillingCountry), grouping(Account.BillingState))
                .nullsLast()
                .descending()
        );
    }

    @isTest
    static void testQuery_ValueObject_Selector() {
        Assert.areEqual(
            selector()
                .add(Account.Name)
                .add(Account.Name, Account.Name)
                .add(Account.Name, Account.Name, Account.Name)
                .add(Account.Name, Account.Name, Account.Name, Account.Name)
                .add(Account.Name, Account.Name, Account.Name, Account.Name, Account.Name),
            selector()
                .add(Account.Name)
                .add(Account.Name, Account.Name)
                .add(Account.Name, Account.Name, Account.Name)
                .add(Account.Name, Account.Name, Account.Name, Account.Name)
                .add(Account.Name, Account.Name, Account.Name, Account.Name, Account.Name)
        );
    }
}
