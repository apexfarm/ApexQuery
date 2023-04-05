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
    static Id getFakeId(Schema.SObjectType objectType, Integer index) {
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
    static void testKeyWord_Select_Misc() {
        Query accountQuery;

        accountQuery = Query.of(Account.SObjectType).updateTracking();
        Assert.areEqual('SELECT Id FROM Account UPDATE TRACKING', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).updateViewstat();
        Assert.areEqual('SELECT Id FROM Account UPDATE VIEWSTAT', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).forView();
        Assert.areEqual('SELECT Id FROM Account FOR VIEW', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).forReference();
        Assert.areEqual('SELECT Id FROM Account FOR REFERENCE', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).forUpdate();
        Assert.areEqual('SELECT Id FROM Account FOR UPDATE', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).limitx(3).offset(3);
        Assert.areEqual('SELECT Id FROM Account LIMIT 3 OFFSET 3', accountQuery.build());
    }

    @isTest
    static void testKeyword_Select_TypeOf() {
        // prettier-ignore
        Query accountQuery = Query.of(Account.SObjectType)
            .selectBy(
                typeof('What')
                    .when(Account.SObjectType)
                        .then(Account.Phone, Account.NumberOfEmployees)
                    .when(Contact.SObjectType)
                        .then(Contact.Name, Contact.Birthdate)
                        .then(Contact.Department, Contact.Email)
                    .when(Account.SObjectType)
                        .then(Account.BillingCountry, Account.BillingState)
                    .elsex('Id', 'Status')
                    .elsex('Email', 'Phone')
            );
        Assert.areEqual(
            'SELECT TYPEOF What ' +
            'WHEN Account THEN Phone, NumberOfEmployees, BillingCountry, BillingState ' +
            'WHEN Contact THEN Name, Birthdate, Department, Email ' +
            'ELSE Id, Status, Email, Phone END FROM Account',
            accountQuery.build()
        );

        Query.TypeOf typeOfWhat = typeof('What').when(Account.SObjectType);
        Assert.areEqual(
            'SELECT TYPEOF What WHEN Account END FROM Account',
            Query.of(Account.SObjectType).selectBy(typeOfWhat).build()
        );

        // SObjectFields
        typeOfWhat = typeof('What').when(Account.SObjectType).then(Account.Name).elsex(Contact.Name);
        Assert.areEqual(
            'SELECT TYPEOF What WHEN Account THEN Name ELSE Name END FROM Account',
            Query.of(Account.SObjectType).selectBy(typeOfWhat).build()
        );

        typeOfWhat = typeof('What')
            .when(Account.SObjectType)
            .then(Account.Name, Account.Name)
            .elsex(Contact.Name, Contact.Name);
        Assert.areEqual(
            'SELECT TYPEOF What WHEN Account THEN Name, Name ELSE Name, Name END FROM Account',
            Query.of(Account.SObjectType).selectBy(typeOfWhat).build()
        );

        typeOfWhat = typeof('What')
            .when(Account.SObjectType)
            .then(Account.Name, Account.Name, Account.Name)
            .elsex(Contact.Name, Contact.Name, Contact.Name);
        Assert.areEqual(
            'SELECT TYPEOF What WHEN Account THEN Name, Name, Name ELSE Name, Name, Name END FROM Account',
            Query.of(Account.SObjectType).selectBy(typeOfWhat).build()
        );

        typeOfWhat = typeof('What')
            .when(Account.SObjectType)
            .then(Account.Name, Account.Name, Account.Name, Account.Name)
            .elsex(Contact.Name, Contact.Name, Contact.Name, Contact.Name);
        Assert.areEqual(
            'SELECT TYPEOF What WHEN Account THEN Name, Name, Name, Name ELSE Name, Name, Name, Name END FROM Account',
            Query.of(Account.SObjectType).selectBy(typeOfWhat).build()
        );

        typeOfWhat = typeof('What')
            .when(Account.SObjectType)
            .then(Account.Name, Account.Name, Account.Name, Account.Name, Account.Name)
            .elsex(Contact.Name, Contact.Name, Contact.Name, Contact.Name, Contact.Name);
        Assert.areEqual(
            'SELECT TYPEOF What WHEN Account THEN Name, Name, Name, Name, Name ELSE Name, Name, Name, Name, Name END FROM Account',
            Query.of(Account.SObjectType).selectBy(typeOfWhat).build()
        );

        // Strings
        typeOfWhat = typeof('What').when(Account.SObjectType).then('Name').elsex('Name');
        Assert.areEqual(
            'SELECT TYPEOF What WHEN Account THEN Name ELSE Name END FROM Account',
            Query.of(Account.SObjectType).selectBy(typeOfWhat).build()
        );

        typeOfWhat = typeof('What').when(Account.SObjectType).then('Name', 'Name').elsex('Name', 'Name');
        Assert.areEqual(
            'SELECT TYPEOF What WHEN Account THEN Name, Name ELSE Name, Name END FROM Account',
            Query.of(Account.SObjectType).selectBy(typeOfWhat).build()
        );

        typeOfWhat = typeof('What')
            .when(Account.SObjectType)
            .then('Name', 'Name', 'Name')
            .elsex('Name', 'Name', 'Name');
        Assert.areEqual(
            'SELECT TYPEOF What WHEN Account THEN Name, Name, Name ELSE Name, Name, Name END FROM Account',
            Query.of(Account.SObjectType).selectBy(typeOfWhat).build()
        );

        typeOfWhat = typeof('What')
            .when(Account.SObjectType)
            .then('Name', 'Name', 'Name', 'Name')
            .elsex('Name', 'Name', 'Name', 'Name');
        Assert.areEqual(
            'SELECT TYPEOF What WHEN Account THEN Name, Name, Name, Name ELSE Name, Name, Name, Name END FROM Account',
            Query.of(Account.SObjectType).selectBy(typeOfWhat).build()
        );

        typeOfWhat = typeof('What')
            .when(Account.SObjectType)
            .then('Name', 'Name', 'Name', 'Name', 'Name')
            .elsex('Name', 'Name', 'Name', 'Name', 'Name');
        Assert.areEqual(
            'SELECT TYPEOF What WHEN Account THEN Name, Name, Name, Name, Name ELSE Name, Name, Name, Name, Name END FROM Account',
            Query.of(Account.SObjectType).selectBy(typeOfWhat).build()
        );
    }

    @isTest
    static void testKeyword_Select() {
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
            .selectBy(
                new List<Object>{
                    Account.Id,
                    Account.Name,
                    Account.Description,
                    Account.BillingCountry,
                    Account.BillingState
                }
            );
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

        // Strings
        accountQuery = Query.of(Account.SObjectType).selectBy('Id');
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

        // Function
        accountQuery = Query.of(Account.SObjectType).selectBy(TO_LABEL(Account.Id));
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
    }

    @isTest
    static void testKeyword_Select_Selector() {
        Query accountQuery;
        Query.Selector selector;
        Query.Selector anotherSelector;
        // SObjectField
        selector = Query.selector().add(Account.Id);
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
            .add(
                new List<Object>{
                    Account.Id,
                    Account.Name,
                    Account.Description,
                    Account.BillingCountry,
                    Account.BillingState
                }
            );
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
        anotherSelector = Query.selector().add(Account.Id, Account.Name).add(selector);
        accountQuery = Query.of(Account.SObjectType).selectBy(anotherSelector);
        Assert.areEqual(
            'SELECT Id, Name, Description, BillingCountry, BillingState FROM Account',
            accountQuery.build()
        );

        // String
        selector = Query.selector().add('Id');
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
        anotherSelector = Query.selector().add('Id', 'Name').add(selector);
        accountQuery = Query.of(Account.SObjectType).selectBy(anotherSelector);
        Assert.areEqual(
            'SELECT Id, Name, Description, BillingCountry, BillingState FROM Account',
            accountQuery.build()
        );

        // Function
        selector = Query.selector().add(TO_LABEL(Account.Id));
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
        anotherSelector = Query.selector().add(TO_LABEL(Account.Id), TO_LABEL(Account.Name)).add(selector);
        accountQuery = Query.of(Account.SObjectType).selectBy(anotherSelector);
        Assert.areEqual(
            'SELECT TOLABEL(Id), TOLABEL(Name), TOLABEL(Description), TOLABEL(BillingCountry), TOLABEL(BillingState) FROM Account',
            accountQuery.build()
        );
    }

    @isTest
    static void testKeyword_Select_Selector_Clone() {
        Query accountQuery;

        Query.Selector selector = Query.selector().add(Account.Id);
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        selector.add(Account.CreatedDate); // this will not be added to query
        Assert.areEqual('SELECT Id FROM Account', accountQuery.build());

        selector = Query.selector().add('Id');
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        selector.add('CreatedDate'); // this will not be added to query
        Assert.areEqual('SELECT Id FROM Account', accountQuery.build());

        selector = Query.selector().add(TO_LABEL(Account.Id));
        accountQuery = Query.of(Account.SObjectType).selectBy(selector);
        selector.add(FORMAT(Account.CreatedDate)); // this will not be added to query
        Assert.areEqual('SELECT TOLABEL(Id) FROM Account', accountQuery.build());
    }

    @isTest
    static void testKeyword_Select_Relations() {
        Query accountQuery;
        Query contactQuery;

        // Strings - Parent
        contactQuery = Query.of(Contact.SObjectType)
            .selectBy(Contact.Id, Contact.Name)
            .selectBy('Account.Owner.Name')
            .selectBy('FORMAT(Account.AnnualRevenue)', 'TOLABEL(Account.AccountSource)');
        Assert.areEqual(
            'SELECT Id, Name, Account.Owner.Name, FORMAT(Account.AnnualRevenue), TOLABEL(Account.AccountSource) FROM Contact',
            contactQuery.build()
        );

        // Queries - Inline Styles
        contactQuery = Query.of(Contact.SObjectType);
        accountQuery = Query.of(Account.SObjectType).selectBy('Contacts', contactQuery);
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

        // Queries - Outline Styles
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

        // Traditional Style
        filter = orx(
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
        );
        accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE ((AnnualRevenue > 1000 AND BillingCountry = \'China\' AND BillingState = \'Beijing\') ' +
            'OR (AnnualRevenue < 1000 AND BillingCountry = \'China\' AND BillingState = \'Shanghai\'))',
            accountQuery.build()
        );
    }

    // #endregion
    // =====================

    // ==========================
    // #region Operator - Logical

    @isTest
    static void testOperator_Logical_Not() {
        Query.Filter filter = notx(eq(Account.BillingCountry, 'China'));
        Query accountQuery = Query.of(Account.SObjectType).filterBy(filter);
        Assert.areEqual('SELECT Id FROM Account WHERE NOT(BillingCountry = \'China\')', accountQuery.build());

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
    // ==========================

    // =============================
    // #region Operator - Comparison

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
            'SELECT Id FROM Account WHERE BillingCountry = \'001000zzzz00000AAA\'',
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
            'SELECT Id FROM Account WHERE BillingCountry = \'001000zzzz00000AAA\'',
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
            'SELECT Id FROM Account HAVING MAX(BillingCountry) = \'001000zzzz00000AAA\'',
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
        filter = eq(DISTANCE_IN_KM(Account.ShippingAddress, Location.newInstance(37.775001, -122.41801)), 12.3);
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
            'SELECT Id FROM Account WHERE BillingCountry != \'001000zzzz00000AAA\'',
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
            'SELECT Id FROM Account WHERE BillingCountry != \'001000zzzz00000AAA\'',
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
            'SELECT Id FROM Account HAVING MAX(BillingCountry) != \'001000zzzz00000AAA\'',
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
        filter = ne(DISTANCE_IN_KM(Account.ShippingAddress, Location.newInstance(37.775001, -122.41801)), 12.3);
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
            'SELECT Id FROM Account WHERE BillingCountry > \'001000zzzz00000AAA\'',
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
            'SELECT Id FROM Account WHERE BillingCountry > \'001000zzzz00000AAA\'',
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
            'SELECT Id FROM Account HAVING MAX(BillingCountry) > \'001000zzzz00000AAA\'',
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
        filter = gt(DISTANCE_IN_KM(Account.ShippingAddress, Location.newInstance(37.775001, -122.41801)), 12.3);
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
            'SELECT Id FROM Account WHERE BillingCountry >= \'001000zzzz00000AAA\'',
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
            'SELECT Id FROM Account WHERE BillingCountry >= \'001000zzzz00000AAA\'',
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
            'SELECT Id FROM Account HAVING MAX(BillingCountry) >= \'001000zzzz00000AAA\'',
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
        filter = gte(DISTANCE_IN_KM(Account.ShippingAddress, Location.newInstance(37.775001, -122.41801)), 12.3);
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
            'SELECT Id FROM Account WHERE BillingCountry < \'001000zzzz00000AAA\'',
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
            'SELECT Id FROM Account WHERE BillingCountry < \'001000zzzz00000AAA\'',
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
            'SELECT Id FROM Account HAVING MAX(BillingCountry) < \'001000zzzz00000AAA\'',
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
        filter = lt(DISTANCE_IN_KM(Account.ShippingAddress, Location.newInstance(37.775001, -122.41801)), 12.3);
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
            'SELECT Id FROM Account WHERE BillingCountry <= \'001000zzzz00000AAA\'',
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
            'SELECT Id FROM Account WHERE BillingCountry <= \'001000zzzz00000AAA\'',
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
            'SELECT Id FROM Account HAVING MAX(BillingCountry) <= \'001000zzzz00000AAA\'',
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
        filter = lte(DISTANCE_IN_KM(Account.ShippingAddress, Location.newInstance(37.775001, -122.41801)), 12.3);
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
            'SELECT Id FROM Account WHERE (BillingCountry >= \'001000zzzz00000AAA\' AND BillingCountry <= \'001000zzzz00000AAA\')',
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
            'SELECT Id FROM Account WHERE (BillingCountry >= \'001000zzzz00000AAA\' AND BillingCountry <= \'001000zzzz00000AAA\')',
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
            'SELECT Id FROM Account HAVING (MAX(BillingCountry) >= \'001000zzzz00000AAA\' AND MAX(BillingCountry) <= \'001000zzzz00000AAA\')',
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
            DISTANCE_IN_KM(Account.ShippingAddress, Location.newInstance(37.775001, -122.41801)),
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

    @isTest
    static void testOperator_Comparison_LIKE() {
        Query.Filter filter;
        filter = likex(Account.BillingCountry, '%China%');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry LIKE \'%China%\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = likex('BillingCountry', '%China%');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry LIKE \'%China%\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = likex(MAX(Account.BillingCountry), '%China%');
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) LIKE \'%China%\'',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = likex(TO_LABEL(Account.BillingCountry), '%China%');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE TOLABEL(BillingCountry) LIKE \'%China%\'',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nlike(Account.BillingCountry, '%China%');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (NOT BillingCountry LIKE \'%China%\')',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nlike('BillingCountry', '%China%');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (NOT BillingCountry LIKE \'%China%\')',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nlike(MAX(Account.BillingCountry), '%China%');
        Assert.areEqual(
            'SELECT Id FROM Account HAVING (NOT MAX(BillingCountry) LIKE \'%China%\')',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = nlike(TO_LABEL(Account.BillingCountry), '%China%');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (NOT TOLABEL(BillingCountry) LIKE \'%China%\')',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );
    }

    @isTest
    static void testOperator_Comparison_INCLUDES() {
        Query.Filter filter;
        filter = includes(Account.BillingCountry, new List<String>{ 'AAA', 'BBB', 'CCC', 'DDD', 'EEE' });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry INCLUDES :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = includes('BillingCountry', new List<String>{ 'AAA', 'BBB', 'CCC', 'DDD', 'EEE' });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry INCLUDES :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );
    }

    @isTest
    static void testOperator_Comparison_EXCLUDES() {
        Query.Filter filter;
        filter = excludes(Account.BillingCountry, new List<String>{ 'AAA', 'BBB', 'CCC', 'DDD', 'EEE' });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry EXCLUDES :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = excludes('BillingCountry', new List<String>{ 'AAA', 'BBB', 'CCC', 'DDD', 'EEE' });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry EXCLUDES :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );
    }

    @isTest
    static void testOperator_Comparison_INX() {
        Query contactQuery = Query.of(Contact.SObjectType).selectBy(Contact.AccountId);
        Query.Filter filter;

        // SObjectField
        filter = inx(Account.BillingCountry, new List<String>{ 'AAA', 'BBB', null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx(
            Account.BillingCountry,
            new List<Id>{ getFakeId(Account.SObjectType, 0), getFakeId(Account.SObjectType, 1), null }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx(
            Account.BillingCountry,
            new List<Account>{
                new Account(Id = getFakeId(Account.SObjectType, 0)),
                new Account(Id = getFakeId(Account.SObjectType, 1)),
                null
            }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx(Account.BillingCountry, new List<Boolean>{ true, false, null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx(Account.BillingCountry, new List<Decimal>{ 123.456, 789, null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx(
            Account.BillingCountry,
            new List<Datetime>{
                Datetime.newInstance(2023, 1, 1, 12, 12, 12),
                Datetime.newInstance(2023, 2, 2, 12, 12, 12),
                null
            }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx(
            Account.BillingCountry,
            new List<Date>{ Date.newInstance(2023, 1, 1), Date.newInstance(2023, 2, 2), null }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx(
            Account.BillingCountry,
            new List<Time>{ Time.newInstance(12, 0, 0, 0), Time.newInstance(11, 0, 0, 0), null }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx(Account.BillingCountry, new List<DateLiteral>{ YESTERDAY(), TODAY(), null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx(Account.BillingCountry, new List<CurrencyLiteral>{ CNY(2000), USD(3000), null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx(Account.BillingCountry, new List<CurrencyLiteral>{ CNY(2000), USD(3000), null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx(Account.Id, contactQuery);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact)',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        // String
        filter = inx('BillingCountry', new List<String>{ 'AAA', 'BBB', null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx(
            'BillingCountry',
            new List<Id>{ getFakeId(Account.SObjectType, 0), getFakeId(Account.SObjectType, 1), null }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx(
            'BillingCountry',
            new List<Account>{
                new Account(Id = getFakeId(Account.SObjectType, 0)),
                new Account(Id = getFakeId(Account.SObjectType, 1)),
                null
            }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx('BillingCountry', new List<Boolean>{ true, false, null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx('BillingCountry', new List<Decimal>{ 123.456, 789, null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx(
            'BillingCountry',
            new List<Datetime>{
                Datetime.newInstance(2023, 1, 1, 12, 12, 12),
                Datetime.newInstance(2023, 2, 2, 12, 12, 12),
                null
            }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx(
            'BillingCountry',
            new List<Date>{ Date.newInstance(2023, 1, 1), Date.newInstance(2023, 2, 2), null }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx(
            'BillingCountry',
            new List<Time>{ Time.newInstance(12, 0, 0, 0), Time.newInstance(11, 0, 0, 0), null }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx('BillingCountry', new List<DateLiteral>{ YESTERDAY(), TODAY(), null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx('BillingCountry', new List<CurrencyLiteral>{ CNY(2000), USD(3000), null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx('BillingCountry', new List<CurrencyLiteral>{ CNY(2000), USD(3000), null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx('Id', contactQuery);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact)',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        // AggregateFunction
        filter = inx(MAX(Account.BillingCountry), new List<String>{ 'AAA', 'BBB', null });
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = inx(
            MAX(Account.BillingCountry),
            new List<Id>{ getFakeId(Account.SObjectType, 0), getFakeId(Account.SObjectType, 1), null }
        );
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = inx(
            MAX(Account.BillingCountry),
            new List<Account>{
                new Account(Id = getFakeId(Account.SObjectType, 0)),
                new Account(Id = getFakeId(Account.SObjectType, 1)),
                null
            }
        );
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = inx(MAX(Account.BillingCountry), new List<Boolean>{ true, false, null });
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = inx(MAX(Account.BillingCountry), new List<Decimal>{ 123.456, 789, null });
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = inx(
            MAX(Account.BillingCountry),
            new List<Datetime>{
                Datetime.newInstance(2023, 1, 1, 12, 12, 12),
                Datetime.newInstance(2023, 2, 2, 12, 12, 12),
                null
            }
        );
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = inx(
            MAX(Account.BillingCountry),
            new List<Date>{ Date.newInstance(2023, 1, 1), Date.newInstance(2023, 2, 2), null }
        );
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = inx(
            MAX(Account.BillingCountry),
            new List<Time>{ Time.newInstance(12, 0, 0, 0), Time.newInstance(11, 0, 0, 0), null }
        );
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = inx(MAX(Account.BillingCountry), new List<DateLiteral>{ YESTERDAY(), TODAY(), null });
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = inx(MAX(Account.BillingCountry), new List<CurrencyLiteral>{ CNY(2000), USD(3000), null });
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = inx(MAX(Account.BillingCountry), new List<CurrencyLiteral>{ CNY(2000), USD(3000), null });
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        // Other Functions
        filter = inx(
            DISTANCE_IN_KM(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800)),
            new List<Decimal>{ 12.3, 45.6, null }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE DISTANCE(ShippingAddress, GEOLOCATION(37.775, -122.418), \'km\') IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = inx(CALENDAR_MONTH(Account.CreatedDate), new List<Integer>{ 1, 2, null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE CALENDAR_MONTH(CreatedDate) IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );
    }

    @isTest
    static void testOperator_Comparison_NIN() {
        Query contactQuery = Query.of(Contact.SObjectType).selectBy(Contact.AccountId);
        Query.Filter filter;

        // SObjectField
        filter = nin(Account.BillingCountry, new List<String>{ 'AAA', 'BBB', null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin(
            Account.BillingCountry,
            new List<Id>{ getFakeId(Account.SObjectType, 0), getFakeId(Account.SObjectType, 1), null }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin(
            Account.BillingCountry,
            new List<Account>{
                new Account(Id = getFakeId(Account.SObjectType, 0)),
                new Account(Id = getFakeId(Account.SObjectType, 1)),
                null
            }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin(Account.BillingCountry, new List<Boolean>{ true, false, null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin(Account.BillingCountry, new List<Decimal>{ 123.456, 789, null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin(
            Account.BillingCountry,
            new List<Datetime>{
                Datetime.newInstance(2023, 1, 1, 12, 12, 12),
                Datetime.newInstance(2023, 2, 2, 12, 12, 12),
                null
            }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin(
            Account.BillingCountry,
            new List<Date>{ Date.newInstance(2023, 1, 1), Date.newInstance(2023, 2, 2), null }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin(
            Account.BillingCountry,
            new List<Time>{ Time.newInstance(12, 0, 0, 0), Time.newInstance(11, 0, 0, 0), null }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin(Account.BillingCountry, new List<DateLiteral>{ YESTERDAY(), TODAY(), null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin(Account.BillingCountry, new List<CurrencyLiteral>{ CNY(2000), USD(3000), null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin(Account.BillingCountry, new List<CurrencyLiteral>{ CNY(2000), USD(3000), null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin(Account.Id, contactQuery);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact)',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        // String
        filter = nin('BillingCountry', new List<String>{ 'AAA', 'BBB', null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin(
            'BillingCountry',
            new List<Id>{ getFakeId(Account.SObjectType, 0), getFakeId(Account.SObjectType, 1), null }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin(
            'BillingCountry',
            new List<Account>{
                new Account(Id = getFakeId(Account.SObjectType, 0)),
                new Account(Id = getFakeId(Account.SObjectType, 1)),
                null
            }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin('BillingCountry', new List<Boolean>{ true, false, null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin('BillingCountry', new List<Decimal>{ 123.456, 789, null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin(
            'BillingCountry',
            new List<Datetime>{
                Datetime.newInstance(2023, 1, 1, 12, 12, 12),
                Datetime.newInstance(2023, 2, 2, 12, 12, 12),
                null
            }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin(
            'BillingCountry',
            new List<Date>{ Date.newInstance(2023, 1, 1), Date.newInstance(2023, 2, 2), null }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin(
            'BillingCountry',
            new List<Time>{ Time.newInstance(12, 0, 0, 0), Time.newInstance(11, 0, 0, 0), null }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin('BillingCountry', new List<DateLiteral>{ YESTERDAY(), TODAY(), null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin('BillingCountry', new List<CurrencyLiteral>{ CNY(2000), USD(3000), null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin('BillingCountry', new List<CurrencyLiteral>{ CNY(2000), USD(3000), null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE BillingCountry NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin('Id', contactQuery);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact)',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        // AggregateFunction
        filter = nin(MAX(Account.BillingCountry), new List<String>{ 'AAA', 'BBB', null });
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) NOT IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = nin(
            MAX(Account.BillingCountry),
            new List<Id>{ getFakeId(Account.SObjectType, 0), getFakeId(Account.SObjectType, 1), null }
        );
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) NOT IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = nin(
            MAX(Account.BillingCountry),
            new List<Account>{
                new Account(Id = getFakeId(Account.SObjectType, 0)),
                new Account(Id = getFakeId(Account.SObjectType, 1)),
                null
            }
        );
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) NOT IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = nin(MAX(Account.BillingCountry), new List<Boolean>{ true, false, null });
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) NOT IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = nin(MAX(Account.BillingCountry), new List<Decimal>{ 123.456, 789, null });
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) NOT IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = nin(
            MAX(Account.BillingCountry),
            new List<Datetime>{
                Datetime.newInstance(2023, 1, 1, 12, 12, 12),
                Datetime.newInstance(2023, 2, 2, 12, 12, 12),
                null
            }
        );
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) NOT IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = nin(
            MAX(Account.BillingCountry),
            new List<Date>{ Date.newInstance(2023, 1, 1), Date.newInstance(2023, 2, 2), null }
        );
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) NOT IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = nin(
            MAX(Account.BillingCountry),
            new List<Time>{ Time.newInstance(12, 0, 0, 0), Time.newInstance(11, 0, 0, 0), null }
        );
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) NOT IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = nin(MAX(Account.BillingCountry), new List<DateLiteral>{ YESTERDAY(), TODAY(), null });
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) NOT IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = nin(MAX(Account.BillingCountry), new List<CurrencyLiteral>{ CNY(2000), USD(3000), null });
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) NOT IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        filter = nin(MAX(Account.BillingCountry), new List<CurrencyLiteral>{ CNY(2000), USD(3000), null });
        Assert.areEqual(
            'SELECT Id FROM Account HAVING MAX(BillingCountry) NOT IN :tmpVar1',
            Query.of(Account.SObjectType).havingBy(filter).build()
        );

        // Other Functions
        filter = nin(
            DISTANCE_IN_KM(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800)),
            new List<Decimal>{ 12.3, 45.6, null }
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE DISTANCE(ShippingAddress, GEOLOCATION(37.775, -122.418), \'km\') NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );

        filter = nin(CALENDAR_MONTH(Account.CreatedDate), new List<Integer>{ 1, 2, null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE CALENDAR_MONTH(CreatedDate) NOT IN :tmpVar1',
            Query.of(Account.SObjectType).filterBy(filter).build()
        );
    }
    // #endregion
    // =============================

    // ================
    // #region Function

    @isTest
    static void testFunction_Aggregate() {
        Query accountQuery;

        // SObjectField
        accountQuery = Query.of(Account.SObjectType).selectBy(GROUPING(Account.Name), GROUPING(Account.Name, 'alias'));
        Assert.areEqual('SELECT GROUPING(Name), GROUPING(Name) alias FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(COUNT(Account.Name), COUNT(Account.Name, 'alias'));
        Assert.areEqual('SELECT COUNT(Name), COUNT(Name) alias FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType)
            .selectBy(COUNT_DISTINCT(Account.Name), COUNT_DISTINCT(Account.Name, 'alias'));
        Assert.areEqual('SELECT COUNT_DISTINCT(Name), COUNT_DISTINCT(Name) alias FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(SUM(Account.Name), SUM(Account.Name, 'alias'));
        Assert.areEqual('SELECT SUM(Name), SUM(Name) alias FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(AVG(Account.Name), AVG(Account.Name, 'alias'));
        Assert.areEqual('SELECT AVG(Name), AVG(Name) alias FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(MAX(Account.Name), MAX(Account.Name, 'alias'));
        Assert.areEqual('SELECT MAX(Name), MAX(Name) alias FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(MIN(Account.Name), MIN(Account.Name, 'alias'));
        Assert.areEqual('SELECT MIN(Name), MIN(Name) alias FROM Account', accountQuery.build());

        // String
        accountQuery = Query.of(Account.SObjectType).selectBy(GROUPING('Name'), GROUPING('Name', 'alias'));
        Assert.areEqual('SELECT GROUPING(Name), GROUPING(Name) alias FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(COUNT('Name'), COUNT('Name', 'alias'));
        Assert.areEqual('SELECT COUNT(Name), COUNT(Name) alias FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(COUNT_DISTINCT('Name'), COUNT_DISTINCT('Name', 'alias'));
        Assert.areEqual('SELECT COUNT_DISTINCT(Name), COUNT_DISTINCT(Name) alias FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(SUM('Name'), SUM('Name', 'alias'));
        Assert.areEqual('SELECT SUM(Name), SUM(Name) alias FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(AVG('Name'), AVG('Name', 'alias'));
        Assert.areEqual('SELECT AVG(Name), AVG(Name) alias FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(MAX('Name'), MAX('Name', 'alias'));
        Assert.areEqual('SELECT MAX(Name), MAX(Name) alias FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(MIN('Name'), MIN('Name', 'alias'));
        Assert.areEqual('SELECT MIN(Name), MIN(Name) alias FROM Account', accountQuery.build());
    }

    @isTest
    static void testFunction_Date() {
        Query accountQuery;

        // SObjecType
        accountQuery = Query.of(Account.SObjectType).selectBy(CALENDAR_MONTH(Account.CreatedDate));
        Assert.areEqual('SELECT CALENDAR_MONTH(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(CALENDAR_QUARTER(Account.CreatedDate));
        Assert.areEqual('SELECT CALENDAR_QUARTER(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(CALENDAR_YEAR(Account.CreatedDate));
        Assert.areEqual('SELECT CALENDAR_YEAR(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(DAY_IN_MONTH(Account.CreatedDate));
        Assert.areEqual('SELECT DAY_IN_MONTH(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(DAY_IN_WEEK(Account.CreatedDate));
        Assert.areEqual('SELECT DAY_IN_WEEK(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(DAY_IN_YEAR(Account.CreatedDate));
        Assert.areEqual('SELECT DAY_IN_YEAR(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(DAY_ONLY(Account.CreatedDate));
        Assert.areEqual('SELECT DAY_ONLY(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(FISCAL_MONTH(Account.CreatedDate));
        Assert.areEqual('SELECT FISCAL_MONTH(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(FISCAL_QUARTER(Account.CreatedDate));
        Assert.areEqual('SELECT FISCAL_QUARTER(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(FISCAL_YEAR(Account.CreatedDate));
        Assert.areEqual('SELECT FISCAL_YEAR(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(HOUR_IN_DAY(Account.CreatedDate));
        Assert.areEqual('SELECT HOUR_IN_DAY(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(WEEK_IN_MONTH(Account.CreatedDate));
        Assert.areEqual('SELECT WEEK_IN_MONTH(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(WEEK_IN_YEAR(Account.CreatedDate));
        Assert.areEqual('SELECT WEEK_IN_YEAR(CreatedDate) FROM Account', accountQuery.build());

        // Strings
        accountQuery = Query.of(Account.SObjectType).selectBy(CALENDAR_MONTH('CreatedDate'));
        Assert.areEqual('SELECT CALENDAR_MONTH(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(CALENDAR_QUARTER('CreatedDate'));
        Assert.areEqual('SELECT CALENDAR_QUARTER(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(CALENDAR_YEAR('CreatedDate'));
        Assert.areEqual('SELECT CALENDAR_YEAR(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(DAY_IN_MONTH('CreatedDate'));
        Assert.areEqual('SELECT DAY_IN_MONTH(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(DAY_IN_WEEK('CreatedDate'));
        Assert.areEqual('SELECT DAY_IN_WEEK(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(DAY_IN_YEAR('CreatedDate'));
        Assert.areEqual('SELECT DAY_IN_YEAR(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(DAY_ONLY('CreatedDate'));
        Assert.areEqual('SELECT DAY_ONLY(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(FISCAL_MONTH('CreatedDate'));
        Assert.areEqual('SELECT FISCAL_MONTH(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(FISCAL_QUARTER('CreatedDate'));
        Assert.areEqual('SELECT FISCAL_QUARTER(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(FISCAL_YEAR('CreatedDate'));
        Assert.areEqual('SELECT FISCAL_YEAR(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(HOUR_IN_DAY('CreatedDate'));
        Assert.areEqual('SELECT HOUR_IN_DAY(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(WEEK_IN_MONTH('CreatedDate'));
        Assert.areEqual('SELECT WEEK_IN_MONTH(CreatedDate) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(WEEK_IN_YEAR('CreatedDate'));
        Assert.areEqual('SELECT WEEK_IN_YEAR(CreatedDate) FROM Account', accountQuery.build());

        // CONVERT_TIMEZONE - Strings
        accountQuery = Query.of(Account.SObjectType).selectBy(CALENDAR_MONTH(CONVERT_TIMEZONE('CreatedDate')));
        Assert.areEqual('SELECT CALENDAR_MONTH(CONVERTTIMEZONE(CreatedDate)) FROM Account', accountQuery.build());

        // CONVERT_TIMEZONE - SObjectField
        accountQuery = Query.of(Account.SObjectType).selectBy(CALENDAR_MONTH(CONVERT_TIMEZONE(Account.CreatedDate)));
        Assert.areEqual('SELECT CALENDAR_MONTH(CONVERTTIMEZONE(CreatedDate)) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(CALENDAR_QUARTER(CONVERT_TIMEZONE(Account.CreatedDate)));
        Assert.areEqual('SELECT CALENDAR_QUARTER(CONVERTTIMEZONE(CreatedDate)) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(CALENDAR_YEAR(CONVERT_TIMEZONE(Account.CreatedDate)));
        Assert.areEqual('SELECT CALENDAR_YEAR(CONVERTTIMEZONE(CreatedDate)) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(DAY_IN_MONTH(CONVERT_TIMEZONE(Account.CreatedDate)));
        Assert.areEqual('SELECT DAY_IN_MONTH(CONVERTTIMEZONE(CreatedDate)) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(DAY_IN_WEEK(CONVERT_TIMEZONE(Account.CreatedDate)));
        Assert.areEqual('SELECT DAY_IN_WEEK(CONVERTTIMEZONE(CreatedDate)) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(DAY_IN_YEAR(CONVERT_TIMEZONE(Account.CreatedDate)));
        Assert.areEqual('SELECT DAY_IN_YEAR(CONVERTTIMEZONE(CreatedDate)) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(DAY_ONLY(CONVERT_TIMEZONE(Account.CreatedDate)));
        Assert.areEqual('SELECT DAY_ONLY(CONVERTTIMEZONE(CreatedDate)) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(FISCAL_MONTH(CONVERT_TIMEZONE(Account.CreatedDate)));
        Assert.areEqual('SELECT FISCAL_MONTH(CONVERTTIMEZONE(CreatedDate)) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(FISCAL_QUARTER(CONVERT_TIMEZONE(Account.CreatedDate)));
        Assert.areEqual('SELECT FISCAL_QUARTER(CONVERTTIMEZONE(CreatedDate)) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(FISCAL_YEAR(CONVERT_TIMEZONE(Account.CreatedDate)));
        Assert.areEqual('SELECT FISCAL_YEAR(CONVERTTIMEZONE(CreatedDate)) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(HOUR_IN_DAY(CONVERT_TIMEZONE(Account.CreatedDate)));
        Assert.areEqual('SELECT HOUR_IN_DAY(CONVERTTIMEZONE(CreatedDate)) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(WEEK_IN_MONTH(CONVERT_TIMEZONE(Account.CreatedDate)));
        Assert.areEqual('SELECT WEEK_IN_MONTH(CONVERTTIMEZONE(CreatedDate)) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(WEEK_IN_YEAR(CONVERT_TIMEZONE(Account.CreatedDate)));
        Assert.areEqual('SELECT WEEK_IN_YEAR(CONVERTTIMEZONE(CreatedDate)) FROM Account', accountQuery.build());
    }

    @isTest
    static void testFunction_Others() {
        Query accountQuery;

        accountQuery = Query.of(Account.SObjectType).selectBy(TO_LABEL(Account.AccountSource));
        Assert.areEqual('SELECT TOLABEL(AccountSource) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(TO_LABEL('AccountSource'));
        Assert.areEqual('SELECT TOLABEL(AccountSource) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(CONVERT_CURRENCY(Account.AnnualRevenue));
        Assert.areEqual('SELECT CONVERTCURRENCY(AnnualRevenue) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(CONVERT_CURRENCY('AnnualRevenue'));
        Assert.areEqual('SELECT CONVERTCURRENCY(AnnualRevenue) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(FORMAT(Account.AnnualRevenue));
        Assert.areEqual('SELECT FORMAT(AnnualRevenue) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(FORMAT('AnnualRevenue'));
        Assert.areEqual('SELECT FORMAT(AnnualRevenue) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).selectBy(FORMAT(CONVERT_CURRENCY(Account.AnnualRevenue)));
        Assert.areEqual('SELECT FORMAT(CONVERTCURRENCY(AnnualRevenue)) FROM Account', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType)
            .filterBy(lt(DISTANCE_IN_MI(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800)), 20));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE DISTANCE(ShippingAddress, GEOLOCATION(37.775, -122.418), \'mi\') < 20',
            accountQuery.build()
        );

        accountQuery = Query.of(Account.SObjectType)
            .filterBy(lt(DISTANCE_IN_MI('ShippingAddress', Location.newInstance(37.775000, -122.41800)), 20));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE DISTANCE(ShippingAddress, GEOLOCATION(37.775, -122.418), \'mi\') < 20',
            accountQuery.build()
        );

        accountQuery = Query.of(Account.SObjectType)
            .filterBy(lt(DISTANCE_IN_KM(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800)), 20));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE DISTANCE(ShippingAddress, GEOLOCATION(37.775, -122.418), \'km\') < 20',
            accountQuery.build()
        );

        accountQuery = Query.of(Account.SObjectType)
            .filterBy(lt(DISTANCE_IN_KM('ShippingAddress', Location.newInstance(37.775000, -122.41800)), 20));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE DISTANCE(ShippingAddress, GEOLOCATION(37.775, -122.418), \'km\') < 20',
            accountQuery.build()
        );
    }
    // #endregion
    // ================

    // ===============
    // #region Literal
    @isTest
    static void testLiteral_Date() {
        Query accountQuery = Query.of(Account.SObjectType)
            .filterBy(
                orx()
                    .add(eq(Account.CreatedDate, YESTERDAY()))
                    .add(eq(Account.CreatedDate, TODAY()))
                    .add(eq(Account.CreatedDate, TOMORROW()))
                    .add(eq(Account.CreatedDate, LAST_WEEK()))
                    .add(eq(Account.CreatedDate, THIS_WEEK()))
                    .add(eq(Account.CreatedDate, NEXT_WEEK()))
                    .add(eq(Account.CreatedDate, LAST_MONTH()))
                    .add(eq(Account.CreatedDate, THIS_MONTH()))
                    .add(eq(Account.CreatedDate, NEXT_MONTH()))
                    .add(eq(Account.CreatedDate, LAST_90_DAYS()))
                    .add(eq(Account.CreatedDate, NEXT_90_DAYS()))
                    .add(eq(Account.CreatedDate, THIS_QUARTER()))
                    .add(eq(Account.CreatedDate, LAST_QUARTER()))
                    .add(eq(Account.CreatedDate, NEXT_QUARTER()))
                    .add(eq(Account.CreatedDate, THIS_YEAR()))
                    .add(eq(Account.CreatedDate, LAST_YEAR()))
                    .add(eq(Account.CreatedDate, NEXT_YEAR()))
                    .add(eq(Account.CreatedDate, THIS_FISCAL_QUARTER()))
                    .add(eq(Account.CreatedDate, LAST_FISCAL_QUARTER()))
                    .add(eq(Account.CreatedDate, NEXT_FISCAL_QUARTER()))
                    .add(eq(Account.CreatedDate, THIS_FISCAL_YEAR()))
                    .add(eq(Account.CreatedDate, LAST_FISCAL_YEAR()))
                    .add(eq(Account.CreatedDate, NEXT_FISCAL_YEAR()))
                    .add(eq(Account.CreatedDate, LAST_N_DAYS(3)))
                    .add(eq(Account.CreatedDate, NEXT_N_DAYS(3)))
                    .add(eq(Account.CreatedDate, N_DAYS_AGO(3)))
                    .add(eq(Account.CreatedDate, NEXT_N_WEEKS(3)))
                    .add(eq(Account.CreatedDate, LAST_N_WEEKS(3)))
                    .add(eq(Account.CreatedDate, N_WEEKS_AGO(3)))
                    .add(eq(Account.CreatedDate, NEXT_N_MONTHS(3)))
                    .add(eq(Account.CreatedDate, LAST_N_MONTHS(3)))
                    .add(eq(Account.CreatedDate, N_MONTHS_AGO(3)))
                    .add(eq(Account.CreatedDate, NEXT_N_QUARTERS(3)))
                    .add(eq(Account.CreatedDate, LAST_N_QUARTERS(3)))
                    .add(eq(Account.CreatedDate, N_QUARTERS_AGO(3)))
                    .add(eq(Account.CreatedDate, NEXT_N_YEARS(3)))
                    .add(eq(Account.CreatedDate, LAST_N_YEARS(3)))
                    .add(eq(Account.CreatedDate, N_YEARS_AGO(3)))
                    .add(eq(Account.CreatedDate, NEXT_N_FISCAL_QUARTERS(3)))
                    .add(eq(Account.CreatedDate, N_FISCAL_QUARTERS_AGO(3)))
                    .add(eq(Account.CreatedDate, NEXT_N_FISCAL_YEARS(3)))
                    .add(eq(Account.CreatedDate, LAST_N_FISCAL_YEARS(3)))
                    .add(eq(Account.CreatedDate, N_FISCAL_YEARS_AGO(3)))
            );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE ' +
            '(CreatedDate = YESTERDAY OR CreatedDate = TODAY OR CreatedDate = TOMORROW OR ' +
            'CreatedDate = LAST_WEEK OR CreatedDate = THIS_WEEK OR CreatedDate = NEXT_WEEK OR ' +
            'CreatedDate = LAST_MONTH OR CreatedDate = THIS_MONTH OR CreatedDate = NEXT_MONTH OR ' +
            'CreatedDate = LAST_90_DAYS OR CreatedDate = NEXT_90_DAYS OR CreatedDate = THIS_QUARTER OR ' +
            'CreatedDate = LAST_QUARTER OR CreatedDate = NEXT_QUARTER OR CreatedDate = THIS_YEAR OR ' +
            'CreatedDate = LAST_YEAR OR CreatedDate = NEXT_YEAR OR CreatedDate = THIS_FISCAL_QUARTER OR ' +
            'CreatedDate = LAST_FISCAL_QUARTER OR CreatedDate = NEXT_FISCAL_QUARTER OR ' +
            'CreatedDate = THIS_FISCAL_YEAR OR CreatedDate = LAST_FISCAL_YEAR OR CreatedDate = NEXT_FISCAL_YEAR OR ' +
            'CreatedDate = LAST_N_DAYS:3 OR CreatedDate = NEXT_N_DAYS:3 OR CreatedDate = N_DAYS_AGO:3 OR ' +
            'CreatedDate = NEXT_N_WEEKS:3 OR CreatedDate = LAST_N_WEEKS:3 OR CreatedDate = N_WEEKS_AGO:3 OR ' +
            'CreatedDate = NEXT_N_MONTHS:3 OR CreatedDate = LAST_N_MONTHS:3 OR CreatedDate = N_MONTHS_AGO:3 OR ' +
            'CreatedDate = NEXT_N_QUARTERS:3 OR CreatedDate = LAST_N_QUARTERS:3 OR CreatedDate = N_QUARTERS_AGO:3 OR ' +
            'CreatedDate = NEXT_N_YEARS:3 OR CreatedDate = LAST_N_YEARS:3 OR CreatedDate = N_YEARS_AGO:3 OR ' +
            'CreatedDate = NEXT_N_FISCAL_QUARTERS:3 OR CreatedDate = N_FISCAL_QUARTERS_AGO:3 OR ' +
            'CreatedDate = NEXT_N_FISCAL_YEARS:3 OR CreatedDate = LAST_N_FISCAL_YEARS:3 OR CreatedDate = N_FISCAL_YEARS_AGO:3)',
            accountQuery.build()
        );
    }

    @isTest
    static void testLiteral_Currency() {
        Query accountQuery = Query.of(Account.SObjectType)
            .filterBy(
                orx()
                    .add(eq(Account.AnnualRevenue, AED(100)))
                    .add(eq(Account.AnnualRevenue, AFN(100)))
                    .add(eq(Account.AnnualRevenue, ALL(100)))
                    .add(eq(Account.AnnualRevenue, AMD(100)))
                    .add(eq(Account.AnnualRevenue, ANG(100)))
                    .add(eq(Account.AnnualRevenue, AOA(100)))
                    .add(eq(Account.AnnualRevenue, ARS(100)))
                    .add(eq(Account.AnnualRevenue, AUD(100)))
                    .add(eq(Account.AnnualRevenue, AWG(100)))
                    .add(eq(Account.AnnualRevenue, AZN(100)))
                    .add(eq(Account.AnnualRevenue, BAM(100)))
                    .add(eq(Account.AnnualRevenue, BBD(100)))
                    .add(eq(Account.AnnualRevenue, BDT(100)))
                    .add(eq(Account.AnnualRevenue, BGN(100)))
                    .add(eq(Account.AnnualRevenue, BHD(100)))
                    .add(eq(Account.AnnualRevenue, BIF(100)))
                    .add(eq(Account.AnnualRevenue, BMD(100)))
                    .add(eq(Account.AnnualRevenue, BND(100)))
                    .add(eq(Account.AnnualRevenue, BOB(100)))
                    .add(eq(Account.AnnualRevenue, BRL(100)))
                    .add(eq(Account.AnnualRevenue, BSD(100)))
                    .add(eq(Account.AnnualRevenue, BTN(100)))
                    .add(eq(Account.AnnualRevenue, BWP(100)))
                    .add(eq(Account.AnnualRevenue, BYN(100)))
                    .add(eq(Account.AnnualRevenue, BZD(100)))
                    .add(eq(Account.AnnualRevenue, CAD(100)))
                    .add(eq(Account.AnnualRevenue, CDF(100)))
                    .add(eq(Account.AnnualRevenue, CHF(100)))
                    .add(eq(Account.AnnualRevenue, CLP(100)))
                    .add(eq(Account.AnnualRevenue, CNY(100)))
                    .add(eq(Account.AnnualRevenue, COP(100)))
                    .add(eq(Account.AnnualRevenue, CRC(100)))
                    .add(eq(Account.AnnualRevenue, CSD(100)))
                    .add(eq(Account.AnnualRevenue, CUP(100)))
                    .add(eq(Account.AnnualRevenue, CVE(100)))
                    .add(eq(Account.AnnualRevenue, CZK(100)))
                    .add(eq(Account.AnnualRevenue, DJF(100)))
                    .add(eq(Account.AnnualRevenue, DKK(100)))
                    .add(eq(Account.AnnualRevenue, DOP(100)))
                    .add(eq(Account.AnnualRevenue, DZD(100)))
                    .add(eq(Account.AnnualRevenue, EGP(100)))
                    .add(eq(Account.AnnualRevenue, ERN(100)))
                    .add(eq(Account.AnnualRevenue, ETB(100)))
                    .add(eq(Account.AnnualRevenue, EUR(100)))
                    .add(eq(Account.AnnualRevenue, FJD(100)))
                    .add(eq(Account.AnnualRevenue, FKP(100)))
                    .add(eq(Account.AnnualRevenue, GBP(100)))
                    .add(eq(Account.AnnualRevenue, GEL(100)))
                    .add(eq(Account.AnnualRevenue, GHS(100)))
                    .add(eq(Account.AnnualRevenue, GIP(100)))
                    .add(eq(Account.AnnualRevenue, GMD(100)))
                    .add(eq(Account.AnnualRevenue, GNF(100)))
                    .add(eq(Account.AnnualRevenue, GTQ(100)))
                    .add(eq(Account.AnnualRevenue, GYD(100)))
                    .add(eq(Account.AnnualRevenue, HKD(100)))
                    .add(eq(Account.AnnualRevenue, HNL(100)))
                    .add(eq(Account.AnnualRevenue, HRK(100)))
                    .add(eq(Account.AnnualRevenue, HTG(100)))
                    .add(eq(Account.AnnualRevenue, HUF(100)))
                    .add(eq(Account.AnnualRevenue, IDR(100)))
                    .add(eq(Account.AnnualRevenue, ILS(100)))
                    .add(eq(Account.AnnualRevenue, INR(100)))
                    .add(eq(Account.AnnualRevenue, IQD(100)))
                    .add(eq(Account.AnnualRevenue, IRR(100)))
                    .add(eq(Account.AnnualRevenue, ISK(100)))
                    .add(eq(Account.AnnualRevenue, JMD(100)))
                    .add(eq(Account.AnnualRevenue, JOD(100)))
                    .add(eq(Account.AnnualRevenue, JPY(100)))
                    .add(eq(Account.AnnualRevenue, KES(100)))
                    .add(eq(Account.AnnualRevenue, KGS(100)))
                    .add(eq(Account.AnnualRevenue, KHR(100)))
                    .add(eq(Account.AnnualRevenue, KMF(100)))
                    .add(eq(Account.AnnualRevenue, KPW(100)))
                    .add(eq(Account.AnnualRevenue, KRW(100)))
                    .add(eq(Account.AnnualRevenue, KWD(100)))
                    .add(eq(Account.AnnualRevenue, KYD(100)))
                    .add(eq(Account.AnnualRevenue, KZT(100)))
                    .add(eq(Account.AnnualRevenue, LAK(100)))
                    .add(eq(Account.AnnualRevenue, LBP(100)))
                    .add(eq(Account.AnnualRevenue, LKR(100)))
                    .add(eq(Account.AnnualRevenue, LRD(100)))
                    .add(eq(Account.AnnualRevenue, LYD(100)))
                    .add(eq(Account.AnnualRevenue, MAD(100)))
                    .add(eq(Account.AnnualRevenue, MDL(100)))
                    .add(eq(Account.AnnualRevenue, MGA(100)))
                    .add(eq(Account.AnnualRevenue, MKD(100)))
                    .add(eq(Account.AnnualRevenue, MMK(100)))
                    .add(eq(Account.AnnualRevenue, MOP(100)))
                    .add(eq(Account.AnnualRevenue, MRU(100)))
                    .add(eq(Account.AnnualRevenue, MUR(100)))
                    .add(eq(Account.AnnualRevenue, MWK(100)))
                    .add(eq(Account.AnnualRevenue, MXN(100)))
                    .add(eq(Account.AnnualRevenue, MYR(100)))
                    .add(eq(Account.AnnualRevenue, MZN(100)))
                    .add(eq(Account.AnnualRevenue, NAD(100)))
                    .add(eq(Account.AnnualRevenue, NGN(100)))
                    .add(eq(Account.AnnualRevenue, NIO(100)))
                    .add(eq(Account.AnnualRevenue, NOK(100)))
                    .add(eq(Account.AnnualRevenue, NPR(100)))
                    .add(eq(Account.AnnualRevenue, NZD(100)))
                    .add(eq(Account.AnnualRevenue, OMR(100)))
                    .add(eq(Account.AnnualRevenue, PAB(100)))
                    .add(eq(Account.AnnualRevenue, PEN(100)))
                    .add(eq(Account.AnnualRevenue, PGK(100)))
                    .add(eq(Account.AnnualRevenue, PHP(100)))
                    .add(eq(Account.AnnualRevenue, PKR(100)))
                    .add(eq(Account.AnnualRevenue, PLN(100)))
                    .add(eq(Account.AnnualRevenue, PYG(100)))
                    .add(eq(Account.AnnualRevenue, QAR(100)))
                    .add(eq(Account.AnnualRevenue, RON(100)))
                    .add(eq(Account.AnnualRevenue, RSD(100)))
                    .add(eq(Account.AnnualRevenue, RUB(100)))
                    .add(eq(Account.AnnualRevenue, RWF(100)))
                    .add(eq(Account.AnnualRevenue, SAR(100)))
                    .add(eq(Account.AnnualRevenue, SBD(100)))
                    .add(eq(Account.AnnualRevenue, SCR(100)))
                    .add(eq(Account.AnnualRevenue, SDG(100)))
                    .add(eq(Account.AnnualRevenue, SEK(100)))
                    .add(eq(Account.AnnualRevenue, SGD(100)))
                    .add(eq(Account.AnnualRevenue, SHP(100)))
                    .add(eq(Account.AnnualRevenue, SLE(100)))
                    .add(eq(Account.AnnualRevenue, SLL(100)))
                    .add(eq(Account.AnnualRevenue, SOS(100)))
                    .add(eq(Account.AnnualRevenue, SRD(100)))
                    .add(eq(Account.AnnualRevenue, STN(100)))
                    .add(eq(Account.AnnualRevenue, SYP(100)))
                    .add(eq(Account.AnnualRevenue, SZL(100)))
                    .add(eq(Account.AnnualRevenue, THB(100)))
                    .add(eq(Account.AnnualRevenue, TJS(100)))
                    .add(eq(Account.AnnualRevenue, TND(100)))
                    .add(eq(Account.AnnualRevenue, TOP(100)))
                    .add(eq(Account.AnnualRevenue, TTD(100)))
                    .add(eq(Account.AnnualRevenue, TWD(100)))
                    .add(eq(Account.AnnualRevenue, TZS(100)))
                    .add(eq(Account.AnnualRevenue, UAH(100)))
                    .add(eq(Account.AnnualRevenue, UGX(100)))
                    .add(eq(Account.AnnualRevenue, USD(100)))
                    .add(eq(Account.AnnualRevenue, UYU(100)))
                    .add(eq(Account.AnnualRevenue, UZS(100)))
                    .add(eq(Account.AnnualRevenue, VES(100)))
                    .add(eq(Account.AnnualRevenue, VND(100)))
                    .add(eq(Account.AnnualRevenue, VUV(100)))
                    .add(eq(Account.AnnualRevenue, WST(100)))
                    .add(eq(Account.AnnualRevenue, XAF(100)))
                    .add(eq(Account.AnnualRevenue, XCD(100)))
                    .add(eq(Account.AnnualRevenue, XOF(100)))
                    .add(eq(Account.AnnualRevenue, XPF(100)))
                    .add(eq(Account.AnnualRevenue, YER(100)))
                    .add(eq(Account.AnnualRevenue, ZAR(100)))
                    .add(eq(Account.AnnualRevenue, CURRENCY('TRY', 100)))
            );

        Assert.areEqual(
            'SELECT Id FROM Account WHERE ' +
            '(AnnualRevenue = AED100 OR AnnualRevenue = AFN100 OR AnnualRevenue = ALL100 OR ' +
            'AnnualRevenue = AMD100 OR AnnualRevenue = ANG100 OR AnnualRevenue = AOA100 OR ' +
            'AnnualRevenue = ARS100 OR AnnualRevenue = AUD100 OR AnnualRevenue = AWG100 OR ' +
            'AnnualRevenue = AZN100 OR AnnualRevenue = BAM100 OR AnnualRevenue = BBD100 OR ' +
            'AnnualRevenue = BDT100 OR AnnualRevenue = BGN100 OR AnnualRevenue = BHD100 OR ' +
            'AnnualRevenue = BIF100 OR AnnualRevenue = BMD100 OR AnnualRevenue = BND100 OR ' +
            'AnnualRevenue = BOB100 OR AnnualRevenue = BRL100 OR AnnualRevenue = BSD100 OR ' +
            'AnnualRevenue = BTN100 OR AnnualRevenue = BWP100 OR AnnualRevenue = BYN100 OR ' +
            'AnnualRevenue = BZD100 OR AnnualRevenue = CAD100 OR AnnualRevenue = CDF100 OR ' +
            'AnnualRevenue = CHF100 OR AnnualRevenue = CLP100 OR AnnualRevenue = CNY100 OR ' +
            'AnnualRevenue = COP100 OR AnnualRevenue = CRC100 OR AnnualRevenue = CSD100 OR ' +
            'AnnualRevenue = CUP100 OR AnnualRevenue = CVE100 OR AnnualRevenue = CZK100 OR ' +
            'AnnualRevenue = DJF100 OR AnnualRevenue = DKK100 OR AnnualRevenue = DOP100 OR ' +
            'AnnualRevenue = DZD100 OR AnnualRevenue = EGP100 OR AnnualRevenue = ERN100 OR ' +
            'AnnualRevenue = ETB100 OR AnnualRevenue = EUR100 OR AnnualRevenue = FJD100 OR ' +
            'AnnualRevenue = FKP100 OR AnnualRevenue = GBP100 OR AnnualRevenue = GEL100 OR ' +
            'AnnualRevenue = GHS100 OR AnnualRevenue = GIP100 OR AnnualRevenue = GMD100 OR ' +
            'AnnualRevenue = GNF100 OR AnnualRevenue = GTQ100 OR AnnualRevenue = GYD100 OR ' +
            'AnnualRevenue = HKD100 OR AnnualRevenue = HNL100 OR AnnualRevenue = HRK100 OR ' +
            'AnnualRevenue = HTG100 OR AnnualRevenue = HUF100 OR AnnualRevenue = IDR100 OR ' +
            'AnnualRevenue = ILS100 OR AnnualRevenue = INR100 OR AnnualRevenue = IQD100 OR ' +
            'AnnualRevenue = IRR100 OR AnnualRevenue = ISK100 OR AnnualRevenue = JMD100 OR ' +
            'AnnualRevenue = JOD100 OR AnnualRevenue = JPY100 OR AnnualRevenue = KES100 OR ' +
            'AnnualRevenue = KGS100 OR AnnualRevenue = KHR100 OR AnnualRevenue = KMF100 OR ' +
            'AnnualRevenue = KPW100 OR AnnualRevenue = KRW100 OR AnnualRevenue = KWD100 OR ' +
            'AnnualRevenue = KYD100 OR AnnualRevenue = KZT100 OR AnnualRevenue = LAK100 OR ' +
            'AnnualRevenue = LBP100 OR AnnualRevenue = LKR100 OR AnnualRevenue = LRD100 OR ' +
            'AnnualRevenue = LYD100 OR AnnualRevenue = MAD100 OR AnnualRevenue = MDL100 OR ' +
            'AnnualRevenue = MGA100 OR AnnualRevenue = MKD100 OR AnnualRevenue = MMK100 OR ' +
            'AnnualRevenue = MOP100 OR AnnualRevenue = MRU100 OR AnnualRevenue = MUR100 OR ' +
            'AnnualRevenue = MWK100 OR AnnualRevenue = MXN100 OR AnnualRevenue = MYR100 OR ' +
            'AnnualRevenue = MZN100 OR AnnualRevenue = NAD100 OR AnnualRevenue = NGN100 OR ' +
            'AnnualRevenue = NIO100 OR AnnualRevenue = NOK100 OR AnnualRevenue = NPR100 OR ' +
            'AnnualRevenue = NZD100 OR AnnualRevenue = OMR100 OR AnnualRevenue = PAB100 OR ' +
            'AnnualRevenue = PEN100 OR AnnualRevenue = PGK100 OR AnnualRevenue = PHP100 OR ' +
            'AnnualRevenue = PKR100 OR AnnualRevenue = PLN100 OR AnnualRevenue = PYG100 OR ' +
            'AnnualRevenue = QAR100 OR AnnualRevenue = RON100 OR AnnualRevenue = RSD100 OR ' +
            'AnnualRevenue = RUB100 OR AnnualRevenue = RWF100 OR AnnualRevenue = SAR100 OR ' +
            'AnnualRevenue = SBD100 OR AnnualRevenue = SCR100 OR AnnualRevenue = SDG100 OR ' +
            'AnnualRevenue = SEK100 OR AnnualRevenue = SGD100 OR AnnualRevenue = SHP100 OR ' +
            'AnnualRevenue = SLE100 OR AnnualRevenue = SLL100 OR AnnualRevenue = SOS100 OR ' +
            'AnnualRevenue = SRD100 OR AnnualRevenue = STN100 OR AnnualRevenue = SYP100 OR ' +
            'AnnualRevenue = SZL100 OR AnnualRevenue = THB100 OR AnnualRevenue = TJS100 OR ' +
            'AnnualRevenue = TND100 OR AnnualRevenue = TOP100 OR AnnualRevenue = TTD100 OR ' +
            'AnnualRevenue = TWD100 OR AnnualRevenue = TZS100 OR AnnualRevenue = UAH100 OR ' +
            'AnnualRevenue = UGX100 OR AnnualRevenue = USD100 OR AnnualRevenue = UYU100 OR ' +
            'AnnualRevenue = UZS100 OR AnnualRevenue = VES100 OR AnnualRevenue = VND100 OR ' +
            'AnnualRevenue = VUV100 OR AnnualRevenue = WST100 OR AnnualRevenue = XAF100 OR ' +
            'AnnualRevenue = XCD100 OR AnnualRevenue = XOF100 OR AnnualRevenue = XPF100 OR ' +
            'AnnualRevenue = YER100 OR AnnualRevenue = ZAR100 OR AnnualRevenue = TRY100)',
            accountQuery.build()
        );
    }
    // #endregion
    // ===============

    // ================
    // #region Order By

    @isTest
    static void testKeyword_OrderBy() {
        Query accountQuery;

        // Mixing
        accountQuery = Query.of(Account.SObjectType)
            .orderBy(new List<Object>{ Account.Name, 'Name', MAX(Account.Name) });
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, MAX(Name)', accountQuery.build());

        // SObjectField
        accountQuery = Query.of(Account.SObjectType).orderBy(Account.Name);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).orderBy(Account.Name, Account.Name);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).orderBy(Account.Name, Account.Name, Account.Name);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).orderBy(Account.Name, Account.Name, Account.Name, Account.Name);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType)
            .orderBy(Account.Name, Account.Name, Account.Name, Account.Name, Account.Name);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name, Name', accountQuery.build());

        // String
        accountQuery = Query.of(Account.SObjectType).orderBy('Name');
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).orderBy('Name', 'Name');
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).orderBy('Name', 'Name', 'Name');
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).orderBy('Name', 'Name', 'Name', 'Name');
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).orderBy('Name', 'Name', 'Name', 'Name', 'Name');
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name, Name', accountQuery.build());

        // Function
        accountQuery = Query.of(Account.SObjectType).orderBy(MAX(Account.Name));
        Assert.areEqual('SELECT Id FROM Account ORDER BY MAX(Name)', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).orderBy(MAX(Account.Name), MAX(Account.Name));
        Assert.areEqual('SELECT Id FROM Account ORDER BY MAX(Name), MAX(Name)', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).orderBy(MAX(Account.Name), MAX(Account.Name), MAX(Account.Name));
        Assert.areEqual('SELECT Id FROM Account ORDER BY MAX(Name), MAX(Name), MAX(Name)', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType)
            .orderBy(MAX(Account.Name), MAX(Account.Name), MAX(Account.Name), MAX(Account.Name));
        Assert.areEqual(
            'SELECT Id FROM Account ORDER BY MAX(Name), MAX(Name), MAX(Name), MAX(Name)',
            accountQuery.build()
        );
        accountQuery = Query.of(Account.SObjectType)
            .orderBy(MAX(Account.Name), MAX(Account.Name), MAX(Account.Name), MAX(Account.Name), MAX(Account.Name));
        Assert.areEqual(
            'SELECT Id FROM Account ORDER BY MAX(Name), MAX(Name), MAX(Name), MAX(Name), MAX(Name)',
            accountQuery.build()
        );
    }

    @isTest
    static void testKeyword_OrderBy_Orderer() {
        Query accountQuery;
        Query.Orderer orderer;

        // Mixing
        orderer = orderer().add(new List<Object>{ Account.Name, 'Name', MAX(Account.Name) });
        accountQuery = Query.of(Account.SObjectType).orderBy(orderer);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, MAX(Name)', accountQuery.build());

        // SObjectField
        orderer = orderer().add(Account.Name);
        accountQuery = Query.of(Account.SObjectType).orderBy(orderer);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name', accountQuery.build());

        orderer = orderer().add(Account.Name, Account.Name);
        accountQuery = Query.of(Account.SObjectType).orderBy(orderer);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name', accountQuery.build());

        orderer = orderer().add(Account.Name, Account.Name, Account.Name);
        accountQuery = Query.of(Account.SObjectType).orderBy(orderer);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name', accountQuery.build());

        orderer = orderer().add(Account.Name, Account.Name, Account.Name, Account.Name);
        accountQuery = Query.of(Account.SObjectType).orderBy(orderer);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name', accountQuery.build());

        orderer = orderer().add(Account.Name, Account.Name, Account.Name, Account.Name, Account.Name);
        accountQuery = Query.of(Account.SObjectType).orderBy(orderer);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name, Name', accountQuery.build());

        // String
        orderer = orderer().add('Name');
        accountQuery = Query.of(Account.SObjectType).orderBy(orderer);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name', accountQuery.build());

        orderer = orderer().add('Name', 'Name');
        accountQuery = Query.of(Account.SObjectType).orderBy(orderer);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name', accountQuery.build());

        orderer = orderer().add('Name', 'Name', 'Name');
        accountQuery = Query.of(Account.SObjectType).orderBy(orderer);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name', accountQuery.build());

        orderer = orderer().add('Name', 'Name', 'Name', 'Name');
        accountQuery = Query.of(Account.SObjectType).orderBy(orderer);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name', accountQuery.build());

        orderer = orderer().add('Name', 'Name', 'Name', 'Name', 'Name');
        accountQuery = Query.of(Account.SObjectType).orderBy(orderer);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name, Name', accountQuery.build());

        // Function
        orderer = orderer().add(MAX(Account.Name));
        accountQuery = Query.of(Account.SObjectType).orderBy(orderer);
        Assert.areEqual('SELECT Id FROM Account ORDER BY MAX(Name)', accountQuery.build());

        orderer = orderer().add(MAX(Account.Name), MAX(Account.Name));
        accountQuery = Query.of(Account.SObjectType).orderBy(orderer);
        Assert.areEqual('SELECT Id FROM Account ORDER BY MAX(Name), MAX(Name)', accountQuery.build());

        orderer = orderer().add(MAX(Account.Name), MAX(Account.Name), MAX(Account.Name));
        accountQuery = Query.of(Account.SObjectType).orderBy(orderer);
        Assert.areEqual('SELECT Id FROM Account ORDER BY MAX(Name), MAX(Name), MAX(Name)', accountQuery.build());

        orderer = orderer().add(MAX(Account.Name), MAX(Account.Name), MAX(Account.Name), MAX(Account.Name));
        accountQuery = Query.of(Account.SObjectType).orderBy(orderer);
        Assert.areEqual(
            'SELECT Id FROM Account ORDER BY MAX(Name), MAX(Name), MAX(Name), MAX(Name)',
            accountQuery.build()
        );

        orderer = orderer()
            .add(MAX(Account.Name), MAX(Account.Name), MAX(Account.Name), MAX(Account.Name), MAX(Account.Name));
        accountQuery = Query.of(Account.SObjectType).orderBy(orderer);
        Assert.areEqual(
            'SELECT Id FROM Account ORDER BY MAX(Name), MAX(Name), MAX(Name), MAX(Name), MAX(Name)',
            accountQuery.build()
        );
    }

    @isTest
    static void testKeyword_OrderBy_Orderer_Clone() {
        Query accountQuery;

        Query.Orderer orderer = Query.orderer().add(Account.Id).descending().nullsLast();
        accountQuery = Query.of(Account.SObjectType).orderBy(Account.Name).orderBy(orderer);
        orderer.add(Account.CreatedDate); // this will not be added to query
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Id DESC NULLS LAST', accountQuery.build());

        orderer = Query.orderer().add('Id');
        accountQuery = Query.of(Account.SObjectType).orderBy(Account.Name).descending().nullsLast().orderBy(orderer);
        orderer.add('CreatedDate'); // this will not be added to query
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name DESC NULLS LAST, Id', accountQuery.build());

        orderer = Query.orderer().add(MAX(Account.Id)).descending().nullsLast();
        accountQuery = Query.of(Account.SObjectType)
            .orderBy(Account.Name)
            .descending()
            .nullsLast()
            .orderBy(orderer)
            .ascending()
            .nullsFirst();
        orderer.add(MIN(Account.CreatedDate)); // this will not be added to query
        Assert.areEqual(
            'SELECT Id FROM Account ORDER BY Name DESC NULLS LAST, MAX(Id) DESC NULLS LAST',
            accountQuery.build()
        );
    }

    @isTest
    static void testKeyword_OrderBy_Others() {
        Query accountQuery;
        Query.Orderer orderer;

        orderer = orderer().add(Account.Name, Account.Name).ascending().nullsFirst();
        accountQuery = Query.of(Account.SObjectType).orderBy(orderer);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name', accountQuery.build());

        orderer = orderer().add(Account.Name, Account.Name).descending().nullsLast().ascending().nullsFirst();
        accountQuery = Query.of(Account.SObjectType).orderBy(orderer);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name', accountQuery.build());

        orderer = orderer().add(Account.Name, Account.Name).ascending().nullsFirst().descending().nullsLast();
        accountQuery = Query.of(Account.SObjectType).orderBy(orderer);
        Assert.areEqual(
            'SELECT Id FROM Account ORDER BY Name DESC NULLS LAST, Name DESC NULLS LAST',
            accountQuery.build()
        );

        orderer = orderer().add(Account.Name, Account.Name).descending().nullsLast();
        accountQuery = Query.of(Account.SObjectType).orderBy(orderer);
        Assert.areEqual(
            'SELECT Id FROM Account ORDER BY Name DESC NULLS LAST, Name DESC NULLS LAST',
            accountQuery.build()
        );

        orderer = orderer()
            .add(Account.Name, Account.Name)
            .ascending()
            .nullsFirst()
            .add(Account.Name, Account.Name)
            .descending()
            .nullsLast();
        accountQuery = Query.of(Account.SObjectType).orderBy(orderer);
        Assert.areEqual(
            'SELECT Id FROM Account ORDER BY Name, Name, Name DESC NULLS LAST, Name DESC NULLS LAST',
            accountQuery.build()
        );

        accountQuery = Query.of(Account.SObjectType).orderBy(Account.Name, Account.Name).ascending().nullsFirst();
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).orderBy(Account.Name, Account.Name).descending().nullsLast();
        Assert.areEqual(
            'SELECT Id FROM Account ORDER BY Name DESC NULLS LAST, Name DESC NULLS LAST',
            accountQuery.build()
        );

        accountQuery = Query.of(Account.SObjectType)
            .orderBy(Account.Name, Account.Name)
            .ascending()
            .nullsFirst()
            .orderBy(Account.Name, Account.Name)
            .descending()
            .nullsLast();
        Assert.areEqual(
            'SELECT Id FROM Account ORDER BY Name, Name, Name DESC NULLS LAST, Name DESC NULLS LAST',
            accountQuery.build()
        );
    }

    // #endregion
    // ================

    // ================
    // #region Group By

    @isTest
    static void testKeyword_GroupBy() {
        Query accountQuery;

        // Mixing
        accountQuery = Query.of(Account.SObjectType)
            .groupBy(new List<Object>{ Account.Name, 'Name', CALENDAR_MONTH(Account.CreatedDate) });
        Assert.areEqual(
            'SELECT Id FROM Account GROUP BY Name, Name, CALENDAR_MONTH(CreatedDate)',
            accountQuery.build()
        );

        // SObjectField
        accountQuery = Query.of(Account.SObjectType).groupBy(Account.Name);
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).groupBy(Account.Name, Account.Name);
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).groupBy(Account.Name, Account.Name, Account.Name);
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name, Name', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).groupBy(Account.Name, Account.Name, Account.Name, Account.Name);
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name, Name, Name', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType)
            .groupBy(Account.Name, Account.Name, Account.Name, Account.Name, Account.Name);
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name, Name, Name, Name', accountQuery.build());

        // String
        accountQuery = Query.of(Account.SObjectType).groupBy('Name');
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).groupBy('Name', 'Name');
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).groupBy('Name', 'Name', 'Name');
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name, Name', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).groupBy('Name', 'Name', 'Name', 'Name');
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name, Name, Name', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType).groupBy('Name', 'Name', 'Name', 'Name', 'Name');
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name, Name, Name, Name', accountQuery.build());

        // Function
        accountQuery = Query.of(Account.SObjectType).groupBy(CALENDAR_MONTH(Account.CreatedDate));
        Assert.areEqual('SELECT Id FROM Account GROUP BY CALENDAR_MONTH(CreatedDate)', accountQuery.build());

        accountQuery = Query.of(Account.SObjectType)
            .groupBy(CALENDAR_MONTH(Account.CreatedDate), CALENDAR_MONTH(Account.CreatedDate));
        Assert.areEqual(
            'SELECT Id FROM Account GROUP BY CALENDAR_MONTH(CreatedDate), CALENDAR_MONTH(CreatedDate)',
            accountQuery.build()
        );

        accountQuery = Query.of(Account.SObjectType)
            .groupBy(
                CALENDAR_MONTH(Account.CreatedDate),
                CALENDAR_MONTH(Account.CreatedDate),
                CALENDAR_MONTH(Account.CreatedDate)
            );
        Assert.areEqual(
            'SELECT Id FROM Account GROUP BY CALENDAR_MONTH(CreatedDate), CALENDAR_MONTH(CreatedDate), CALENDAR_MONTH(CreatedDate)',
            accountQuery.build()
        );

        accountQuery = Query.of(Account.SObjectType)
            .groupBy(
                CALENDAR_MONTH(Account.CreatedDate),
                CALENDAR_MONTH(Account.CreatedDate),
                CALENDAR_MONTH(Account.CreatedDate),
                CALENDAR_MONTH(Account.CreatedDate)
            );
        Assert.areEqual(
            'SELECT Id FROM Account GROUP BY CALENDAR_MONTH(CreatedDate), CALENDAR_MONTH(CreatedDate), CALENDAR_MONTH(CreatedDate), CALENDAR_MONTH(CreatedDate)',
            accountQuery.build()
        );
        accountQuery = Query.of(Account.SObjectType)
            .groupBy(
                CALENDAR_MONTH(Account.CreatedDate),
                CALENDAR_MONTH(Account.CreatedDate),
                CALENDAR_MONTH(Account.CreatedDate),
                CALENDAR_MONTH(Account.CreatedDate),
                CALENDAR_MONTH(Account.CreatedDate)
            );
        Assert.areEqual(
            'SELECT Id FROM Account GROUP BY CALENDAR_MONTH(CreatedDate), CALENDAR_MONTH(CreatedDate), CALENDAR_MONTH(CreatedDate), CALENDAR_MONTH(CreatedDate), CALENDAR_MONTH(CreatedDate)',
            accountQuery.build()
        );
    }

    @isTest
    static void testKeyword_GroupBy_Grouper() {
        Query accountQuery;
        Query.Grouper grouper;

        // Mixing
        grouper = grouper().add(new List<Object>{ Account.Name, 'Name', CALENDAR_MONTH(Account.CreatedDate) });
        accountQuery = Query.of(Account.SObjectType).groupBy(grouper);
        Assert.areEqual(
            'SELECT Id FROM Account GROUP BY Name, Name, CALENDAR_MONTH(CreatedDate)',
            accountQuery.build()
        );

        // SObjectField
        grouper = grouper().add(Account.Name);
        accountQuery = Query.of(Account.SObjectType).groupBy(grouper);
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name', accountQuery.build());

        grouper = grouper().add(Account.Name, Account.Name);
        accountQuery = Query.of(Account.SObjectType).groupBy(grouper);
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name', accountQuery.build());

        grouper = grouper().add(Account.Name, Account.Name, Account.Name);
        accountQuery = Query.of(Account.SObjectType).groupBy(grouper);
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name, Name', accountQuery.build());

        grouper = grouper().add(Account.Name, Account.Name, Account.Name, Account.Name);
        accountQuery = Query.of(Account.SObjectType).groupBy(grouper);
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name, Name, Name', accountQuery.build());

        grouper = grouper().add(Account.Name, Account.Name, Account.Name, Account.Name, Account.Name);
        accountQuery = Query.of(Account.SObjectType).groupBy(grouper);
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name, Name, Name, Name', accountQuery.build());

        // String
        grouper = grouper().add('Name');
        accountQuery = Query.of(Account.SObjectType).groupBy(grouper);
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name', accountQuery.build());

        grouper = grouper().add('Name', 'Name');
        accountQuery = Query.of(Account.SObjectType).groupBy(grouper);
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name', accountQuery.build());

        grouper = grouper().add('Name', 'Name', 'Name');
        accountQuery = Query.of(Account.SObjectType).groupBy(grouper);
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name, Name', accountQuery.build());

        grouper = grouper().add('Name', 'Name', 'Name', 'Name');
        accountQuery = Query.of(Account.SObjectType).groupBy(grouper);
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name, Name, Name', accountQuery.build());

        grouper = grouper().add('Name', 'Name', 'Name', 'Name', 'Name');
        accountQuery = Query.of(Account.SObjectType).groupBy(grouper);
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name, Name, Name, Name', accountQuery.build());

        // Function
        grouper = grouper().add(CALENDAR_MONTH(Account.CreatedDate));
        accountQuery = Query.of(Account.SObjectType).groupBy(grouper);
        Assert.areEqual('SELECT Id FROM Account GROUP BY CALENDAR_MONTH(CreatedDate)', accountQuery.build());

        grouper = grouper().add(CALENDAR_MONTH(Account.CreatedDate), CALENDAR_MONTH(Account.CreatedDate));
        accountQuery = Query.of(Account.SObjectType).groupBy(grouper);
        Assert.areEqual(
            'SELECT Id FROM Account GROUP BY CALENDAR_MONTH(CreatedDate), CALENDAR_MONTH(CreatedDate)',
            accountQuery.build()
        );

        grouper = grouper()
            .add(
                CALENDAR_MONTH(Account.CreatedDate),
                CALENDAR_MONTH(Account.CreatedDate),
                CALENDAR_MONTH(Account.CreatedDate)
            );
        accountQuery = Query.of(Account.SObjectType).groupBy(grouper);
        Assert.areEqual(
            'SELECT Id FROM Account GROUP BY CALENDAR_MONTH(CreatedDate), CALENDAR_MONTH(CreatedDate), CALENDAR_MONTH(CreatedDate)',
            accountQuery.build()
        );

        grouper = grouper()
            .add(
                CALENDAR_MONTH(Account.CreatedDate),
                CALENDAR_MONTH(Account.CreatedDate),
                CALENDAR_MONTH(Account.CreatedDate),
                CALENDAR_MONTH(Account.CreatedDate)
            );
        accountQuery = Query.of(Account.SObjectType).groupBy(grouper);
        Assert.areEqual(
            'SELECT Id FROM Account GROUP BY CALENDAR_MONTH(CreatedDate), CALENDAR_MONTH(CreatedDate), CALENDAR_MONTH(CreatedDate), CALENDAR_MONTH(CreatedDate)',
            accountQuery.build()
        );

        grouper = grouper()
            .add(
                CALENDAR_MONTH(Account.CreatedDate),
                CALENDAR_MONTH(Account.CreatedDate),
                CALENDAR_MONTH(Account.CreatedDate),
                CALENDAR_MONTH(Account.CreatedDate),
                CALENDAR_MONTH(Account.CreatedDate)
            );
        accountQuery = Query.of(Account.SObjectType).groupBy(grouper);
        Assert.areEqual(
            'SELECT Id FROM Account GROUP BY CALENDAR_MONTH(CreatedDate), CALENDAR_MONTH(CreatedDate), CALENDAR_MONTH(CreatedDate), CALENDAR_MONTH(CreatedDate), CALENDAR_MONTH(CreatedDate)',
            accountQuery.build()
        );
    }

    @isTest
    static void testKeyword_GroupBy_Grouper_Clone() {
        Query accountQuery;

        Query.Grouper grouper = Query.grouper().add(Account.Id);
        accountQuery = Query.of(Account.SObjectType).groupBy(grouper);
        grouper.add(Account.CreatedDate); // this will not be added to query
        Assert.areEqual('SELECT Id FROM Account GROUP BY Id', accountQuery.build());

        grouper = Query.grouper().add('Id');
        accountQuery = Query.of(Account.SObjectType).groupBy(grouper);
        grouper.add('CreatedDate'); // this will not be added to query
        Assert.areEqual('SELECT Id FROM Account GROUP BY Id', accountQuery.build());

        grouper = Query.grouper().add(CALENDAR_MONTH(Account.CreatedDate));
        accountQuery = Query.of(Account.SObjectType).groupBy(grouper);
        grouper.add(CALENDAR_YEAR(Account.CreatedDate)); // this will not be added to query
        Assert.areEqual('SELECT Id FROM Account GROUP BY CALENDAR_MONTH(CreatedDate)', accountQuery.build());
    }

    // #endregion
    // ================

    //==============
    // #region Query
    @isTest
    static void testQuery_Filter() {
        makeData();

        List<Account> accountList;
        List<Contact> contactList;

        // Filter Style 1
        // prettier-ignore
        accountList = (List<Account>) Query.of(Account.SObjectType)
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

        // prettier-ignore
        contactList = (List<Contact>) Query.of(Contact.SObjectType).selectBy(Contact.Id, Contact.Name).run();
        // prettier-ignore
        accountList = (List<Account>) Query.of(Account.SObjectType)
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

        // Filter Style 2
        // prettier-ignore
        accountList = (List<Account>) Query.of(Account.SObjectType)
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

        // prettier-ignore
        contactList = (List<Contact>) Query.of(Contact.SObjectType).selectBy(Contact.Id, Contact.Name).run();
        // prettier-ignore
        accountList = (List<Account>) Query.of(Account.SObjectType)
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
    static void testQuery_for_View_Reference_Update() {
        makeData();
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
        makeData();
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
                    .add(inx(CALENDAR_MONTH(Contact.Birthdate), new List<Integer> { 1, 2, 3, 4 }))
                    .add(between(CALENDAR_MONTH(Contact.Birthdate), 1, 4))
            )
            .run();
        System.debug(contacts);
        Assert.areEqual(4, contacts.size());
    }

    // ! CONVERT_CURRENCY is only suppored in a multi-currency org.
    // @isTest
    static void testQuery_Functions_Currency() {
        makeData();
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

        throw new IllegalArgumentException('Turn off testQuery_Functions_Currency');
    }

    @isTest
    static void testQuery_Functions_Format() {
        makeData();
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
        makeData();
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
        makeData();
        Query contactQuery = Query.of(Contact.SObjectType).selectBy(Contact.Name);

        Query query = Query.of(Account.SObjectType);

        Query.Selector selector = selector();
        selector = selector.add(Account.Name, Account.AnnualRevenue);
        selector = selector.add(Account.BillingCountry, Account.BillingState);
        selector = selector.add('Contacts', contactQuery);
        query.selectBy(selector);

        Query.CompositeFilter filters = orx();

        filters = filters.add(andx(
            gt(Account.AnnualRevenue, 1000),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingState, 'Beijing')
        ));

        filters = filters.add(andx(
            lt(Account.AnnualRevenue, 1000),
            eq(Account.BillingCountry, 'China'),
            eq(Account.BillingState, 'Shanghai')
        ));

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
        makeData();
        Query contactQuery = Query.of(Contact.SObjectType).selectBy(Contact.Name);

        Query query = Query.of(Account.SObjectType);

        query.selectBy(Account.Name, Account.AnnualRevenue);
        query.selectBy(Account.BillingCountry, Account.BillingState);
        query.selectBy('Contacts', contactQuery);

        Query.CompositeFilter filters = orx();

        filters = filters.add(andx()
            .add(gt(Account.AnnualRevenue, 1000))
            .add(eq(Account.BillingCountry, 'China'))
            .add(eq(Account.BillingState, 'Beijing'))
        );

        filters = filters.add(andx()
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
    static void testQuery_Filter_Distance() {
        makeData();
        // prettier-ignore
        List<Account> accountList = (List<Account>) Query.of(Account.SObjectType)
            .selectBy(Account.Name, Account.AnnualRevenue, Account.BillingCountry, Account.BillingState, Account.ShippingAddress)
            .filterBy(
                lt(DISTANCE_IN_KM(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800)), 20)
            )
            .orderBy(DISTANCE_IN_MI(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800))).ascending().nullsLast()
            .run();
        Assert.areEqual(2, accountList.size());
        Assert.areEqual(1500, accountList[0].AnnualRevenue);
        Assert.areEqual('Beijing', accountList[0].BillingState);
        Assert.areEqual(500, accountList[1].AnnualRevenue);
        Assert.areEqual('Shanghai', accountList[1].BillingState);
    }

    @isTest
    static void testQuery_Filter_Like() {
        makeData();
        // prettier-ignore
        List<Account> accountList = (List<Account>) Query.of(Account.SObjectType)
            .selectBy(Account.Name, Account.AnnualRevenue, Account.BillingCountry, Account.BillingState)
            .filterBy(
                likex(Account.Name, '%\'%')
            )
            .run();
        Assert.areEqual(2, accountList.size());

        // prettier-ignore
        accountList = (List<Account>) Query.of(Account.SObjectType)
            .selectBy(Account.Name, Account.AnnualRevenue, Account.BillingCountry, Account.BillingState)
            .filterBy(
                likex(Account.Name, '%\' AND Name LIKE \'%')
            )
            .run();
        Assert.areEqual(0, accountList.size());
    }

    @isTest
    static void testQuery_Filter_Between() {
        makeData();
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
        makeData();

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
                    .add(inx(MIN(Account.BillingState), new List<String> {'Shanghai', 'Beijing'}))
                    .add(likex(MAX(Account.BillingState), '%i%'))
                    .add(inx(MAX(Account.BillingState), new List<String> {'Shanghai', 'Beijing'}))
            )
            .orderBy(GROUPING(Account.BillingCountry)).nullsLast().descending()
            .run();
        System.debug(results);
    }

    @isTest
    static void testQuery_GroupBy_Count() {
        makeData();

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

    // #endregion
    // =============

    // ====================
    // #region Value Object

    @isTest
    static void testValueObject_Filter() {
        // Logical
        Set<Object> bag = new Set<Object>{ eq(Account.Name, 123) };
        Assert.areEqual(true, bag.contains(eq(Account.Name, 123)));
        Assert.areEqual(eq(Account.Name, 123), eq(Account.Name, 123));

        bag.add(likex(Account.Name, '123'));
        Assert.areEqual(true, bag.contains(likex(Account.Name, '123')));
        Assert.areEqual(likex(Account.Name, '123'), likex(Account.Name, '123'));

        bag.add(includes(Account.Name, new List<String>{ '123' }));
        Assert.areEqual(true, bag.contains(includes(Account.Name, new List<String>{ '123' })));
        Assert.areEqual(
            includes(Account.Name, new List<String>{ '123' }),
            includes(Account.Name, new List<String>{ '123' })
        );

        bag.add(inx(Account.Name, new List<String>{ '123' }));
        Assert.areEqual(true, bag.contains(inx(Account.Name, new List<String>{ '123' })));
        Assert.areEqual(inx(Account.Name, new List<String>{ '123' }), inx(Account.Name, new List<String>{ '123' }));

        bag.add(inx(Account.Name, Query.of(Account.SObjectType).selectBy(Account.Id)));
        Assert.areEqual(true, bag.contains(inx(Account.Name, Query.of(Account.SObjectType).selectBy(Account.Id))));
        Assert.areEqual(
            inx(Account.Name, Query.of(Account.SObjectType).selectBy(Account.Id)),
            inx(Account.Name, Query.of(Account.SObjectType).selectBy(Account.Id))
        );

        bag.add(between(Account.BillingState, 'Bd', 'Si'));
        Assert.areEqual(true, bag.contains(between(Account.BillingState, 'Bd', 'Si')));
        Assert.areEqual(between(Account.BillingState, 'Bd', 'Si'), between(Account.BillingState, 'Bd', 'Si'));

        // Function
        bag.add(MAX(Account.ShippingAddress));
        Assert.areEqual(true, bag.contains(MAX(Account.ShippingAddress)));
        Assert.areEqual(MAX(Account.ShippingAddress), MAX(Account.ShippingAddress));

        bag.add(DISTANCE_IN_MI(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800)));
        Assert.areEqual(
            true,
            bag.contains(DISTANCE_IN_MI(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800)))
        );
        Assert.areEqual(
            DISTANCE_IN_MI(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800)),
            DISTANCE_IN_MI(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800))
        );

        // Literal
        bag.add(YESTERDAY());
        Assert.areEqual(true, bag.contains(YESTERDAY()));
        Assert.areEqual(YESTERDAY(), YESTERDAY());

        bag.add(LAST_N_DAYS(123));
        Assert.areEqual(true, bag.contains(LAST_N_DAYS(123)));
        Assert.areEqual(LAST_N_DAYS(123), LAST_N_DAYS(123));

        bag.add(gt(Account.Name, N_FISCAL_YEARS_AGO(123)));
        Assert.areEqual(true, bag.contains(gt(Account.Name, N_FISCAL_YEARS_AGO(123))));
        Assert.areEqual(gt(Account.Name, N_FISCAL_YEARS_AGO(123)), gt(Account.Name, N_FISCAL_YEARS_AGO(123)));

        bag.add(CNY(123));
        Assert.areEqual(true, bag.contains(CNY(123)));
        Assert.areEqual(CNY(123), CNY(123));

        Assert.areEqual(
            new List<Query.Filter>{
                eq(Account.Name, 123),
                likex(Account.Name, '123'),
                inx(Account.Name, new List<String>{ '123' }),
                gt(Account.Name, N_FISCAL_YEARS_AGO(123)),
                gte(Account.Name, Date.newInstance(2023, 1, 1))
            },
            new List<Query.Filter>{
                eq(Account.Name, 123),
                likex(Account.Name, '123'),
                inx(Account.Name, new List<String>{ '123' }),
                gt(Account.Name, N_FISCAL_YEARS_AGO(123)),
                gte(Account.Name, Date.newInstance(2023, 1, 1))
            }
        );
    }

    @isTest
    static void testValueObject_Query() {
        Query q = Query.of(Account.SObjectType);
        Assert.areEqual(q, q);

        Set<Object> bag = new Set<Object>();

        bag.add(
            Query.selector()
                .add('Name')
                .add(Account.Name)
                .add(MAX(Account.Name))
                .add('Contacts', Query.of(Contact.SObjectType))
        );
        Assert.areEqual(
            true,
            bag.contains(
                Query.selector()
                    .add('Name')
                    .add(Account.Name)
                    .add(MAX(Account.Name))
                    .add('Contacts', Query.of(Contact.SObjectType))
            )
        );
        Assert.areEqual(
            Query.selector()
                .add('Name')
                .add(Account.Name)
                .add(MAX(Account.Name))
                .add('Contacts', Query.of(Contact.SObjectType)),
            Query.selector()
                .add('Name')
                .add(Account.Name)
                .add(MAX(Account.Name))
                .add('Contacts', Query.of(Contact.SObjectType))
        );

        bag.add(Query.orderer().add(Account.BillingCountry, Account.BillingState).descending().nullsFirst());
        Assert.areEqual(
            true,
            bag.contains(Query.orderer().add(Account.BillingCountry, Account.BillingState).descending().nullsFirst())
        );
        Assert.areEqual(
            Query.orderer().add(Account.BillingCountry, Account.BillingState).descending().nullsFirst(),
            Query.orderer().add(Account.BillingCountry, Account.BillingState).descending().nullsFirst()
        );

        bag.add(
            Query.grouper().add(Account.BillingCountry, Account.BillingState).add(CALENDAR_MONTH(Account.CreatedDate))
        );
        Assert.areEqual(
            true,
            bag.contains(
                Query.grouper()
                    .add(Account.BillingCountry, Account.BillingState)
                    .add(CALENDAR_MONTH(Account.CreatedDate))
            )
        );
        Assert.areEqual(
            Query.grouper().add(Account.BillingCountry, Account.BillingState).add(CALENDAR_MONTH(Account.CreatedDate)),
            Query.grouper().add(Account.BillingCountry, Account.BillingState).add(CALENDAR_MONTH(Account.CreatedDate))
        );

        bag.add(
            typeof('What')
                .when(Account.SObjectType)
                .then(Account.Phone, Account.NumberOfEmployees)
                .when(Contact.SObjectType)
                .then(Contact.Name, Contact.Birthdate)
                .then(Contact.Department, Contact.Email)
                .when(Account.SObjectType)
                .then(Account.BillingCountry, Account.BillingState)
                .elsex('Id', 'Status')
                .elsex('Email', 'Phone')
        );
        Assert.areEqual(
            true,
            bag.contains(
                typeof('What')
                    .when(Account.SObjectType)
                    .then(Account.Phone, Account.NumberOfEmployees)
                    .when(Contact.SObjectType)
                    .then(Contact.Name, Contact.Birthdate)
                    .then(Contact.Department, Contact.Email)
                    .when(Account.SObjectType)
                    .then(Account.BillingCountry, Account.BillingState)
                    .elsex('Id', 'Status')
                    .elsex('Email', 'Phone')
            )
        );
        Assert.areEqual(
            typeof('What')
                .when(Account.SObjectType)
                .then(Account.Phone, Account.NumberOfEmployees)
                .when(Contact.SObjectType)
                .then(Contact.Name, Contact.Birthdate)
                .then(Contact.Department, Contact.Email)
                .when(Account.SObjectType)
                .then(Account.BillingCountry, Account.BillingState)
                .elsex('Id', 'Status')
                .elsex('Email', 'Phone'),
            typeof('What')
                .when(Account.SObjectType)
                .then(Account.Phone, Account.NumberOfEmployees)
                .when(Contact.SObjectType)
                .then(Contact.Name, Contact.Birthdate)
                .then(Contact.Department, Contact.Email)
                .when(Account.SObjectType)
                .then(Account.BillingCountry, Account.BillingState)
                .elsex('Id', 'Status')
                .elsex('Email', 'Phone')
        );

        bag.add(Query.of(Account.SObjectType));
        Assert.areEqual(true, bag.contains(Query.of(Account.SObjectType)));
        Assert.areEqual(Query.of(Account.SObjectType), Query.of(Account.SObjectType));

        bag.add(
            Query.of(Account.SObjectType)
                .selectBy(Account.Name)
                .selectBy(typeof('What'))
                .filterBy(neNull(Account.Name))
                .groupBy(Account.Name)
                .rollup()
                .cube()
                .havingBy(neNull(Account.Name))
                .orderBy(Account.Name)
                .descending()
                .nullsLast()
                .limitx(1)
                .offset(1)
                .forView()
                .forReference()
                .forUpdate()
                .updateTracking()
                .updateViewstat()
        );
        Assert.areEqual(
            true,
            bag.contains(
                Query.of(Account.SObjectType)
                    .selectBy(Account.Name)
                    .selectBy(typeof('What'))
                    .filterBy(neNull(Account.Name))
                    .groupBy(Account.Name)
                    .rollup()
                    .cube()
                    .havingBy(neNull(Account.Name))
                    .orderBy(Account.Name)
                    .descending()
                    .nullsLast()
                    .limitx(1)
                    .offset(1)
                    .forView()
                    .forReference()
                    .forUpdate()
                    .updateTracking()
                    .updateViewstat()
            )
        );
        Assert.areEqual(
            Query.of(Account.SObjectType)
                .selectBy(Account.Name)
                .selectBy(typeof('What'))
                .filterBy(neNull(Account.Name))
                .groupBy(Account.Name)
                .rollup()
                .cube()
                .havingBy(neNull(Account.Name))
                .orderBy(Account.Name)
                .descending()
                .nullsLast()
                .limitx(1)
                .offset(1)
                .forView()
                .forReference()
                .forUpdate()
                .updateTracking()
                .updateViewstat(),
            Query.of(Account.SObjectType)
                .selectBy(Account.Name)
                .selectBy(typeof('What'))
                .filterBy(neNull(Account.Name))
                .groupBy(Account.Name)
                .rollup()
                .cube()
                .havingBy(neNull(Account.Name))
                .orderBy(Account.Name)
                .descending()
                .nullsLast()
                .limitx(1)
                .offset(1)
                .forView()
                .forReference()
                .forUpdate()
                .updateTracking()
                .updateViewstat()
        );

        bag.add(
            Query.of(Account.SObjectType)
                .selectBy(GROUPING(Account.BillingCountry))
                .selectBy(GROUPING(Account.BillingState, 'alias0'))
                .groupBy(Account.BillingCountry, Account.BillingState)
                .rollup()
                .orderBy(grouping(Account.BillingCountry), grouping(Account.BillingState))
                .nullsLast()
                .descending()
        );
        Assert.areEqual(
            true,
            bag.contains(
                Query.of(Account.SObjectType)
                    .selectBy(GROUPING(Account.BillingCountry))
                    .selectBy(GROUPING(Account.BillingState, 'alias0'))
                    .groupBy(Account.BillingCountry, Account.BillingState)
                    .rollup()
                    .orderBy(grouping(Account.BillingCountry), grouping(Account.BillingState))
                    .nullsLast()
                    .descending()
            )
        );
        Assert.areEqual(
            Query.of(Account.SObjectType)
                .selectBy(GROUPING(Account.BillingCountry))
                .selectBy(GROUPING(Account.BillingState, 'alias0'))
                .groupBy(Account.BillingCountry, Account.BillingState)
                .rollup()
                .orderBy(grouping(Account.BillingCountry), grouping(Account.BillingState))
                .nullsLast()
                .descending(),
            Query.of(Account.SObjectType)
                .selectBy(GROUPING(Account.BillingCountry))
                .selectBy(GROUPING(Account.BillingState, 'alias0'))
                .groupBy(Account.BillingCountry, Account.BillingState)
                .rollup()
                .orderBy(grouping(Account.BillingCountry), grouping(Account.BillingState))
                .nullsLast()
                .descending()
        );
    }
    // #endregion
    // ====================
}
