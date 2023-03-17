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
    @TestSetup
    static void makeData() {
        // prettier-ignore
        List<Account> accountList = new List<Account> {
            new Account(Name = 'Account 1', AnnualRevenue = 1500, BillingCountry = 'China', BillingState = 'Shanghai'),
            new Account(Name = 'Account 2', AnnualRevenue = 500, BillingCountry = 'China', BillingState = 'Shanghai',
                ShippingLatitude = 37.775002, ShippingLongitude = -122.41802),
            new Account(Name = 'Account 3', AnnualRevenue = 1500, BillingCountry = 'China', BillingState = 'Beijing',
                ShippingLatitude = 37.775001, ShippingLongitude = -122.41801),
            new Account(Name = 'Account 4', AnnualRevenue = 500, BillingCountry = 'China', BillingState = 'Beijing'),
            new Account(Name = 'Account\' 5', AnnualRevenue = 1500),
            new Account(Name = 'Account\' 6', AnnualRevenue = 500)
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
            .orderBy('AnnualRevenue').descending().nullsLast()
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
            .orderBy('AnnualRevenue').descending().nullsLast()
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
    static void testQuery_OrderBy() {
        List<Account> accountList = (List<Account>) Query.of(Account.SObjectType)
            .selectBy(Account.Name, Account.AnnualRevenue, Account.BillingState)
            .orderBy('BillingCountry', 'BillingState', 'AnnualRevenue')
            .run();

        System.debug(accountList);
        Assert.areEqual(6, accountList.size());

        // prettier-ignore
        List<AggregateResult> results = (List<AggregateResult>) Query.of(Account.SObjectType)
            .grouping(Account.BillingCountry)
            .grouping(Account.BillingState, 'alias0')
            .min(Account.AnnualRevenue)
            .max(Account.AnnualRevenue)
            .avg(Account.AnnualRevenue, 'average')
            .sum(Account.AnnualRevenue, 'summary')
            .groupBy(Account.BillingCountry, Account.BillingState).rollup()
            .orderBy('BillingState', 'expr0', 'alias0').nullsLast().descending()
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

        query.orderBy('AnnualRevenue').descending().nullsLast();

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

        query.orderBy('AnnualRevenue').descending().nullsLast();

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
            .orderBy('AnnualRevenue').descending().nullsLast()
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
            .orderBy('AnnualRevenue').descending().nullsLast()
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
            .grouping(Account.BillingCountry)
            .grouping(Account.BillingState, 'alias0')
            .min(Account.AnnualRevenue)
            .max(Account.AnnualRevenue)
            .avg(Account.AnnualRevenue, 'average')
            .sum(Account.AnnualRevenue, 'summary')
            .groupBy(Account.BillingCountry, Account.BillingState).rollup()
            .orderBy('expr0', 'alias0').nullsLast().descending()
            .run();
        System.debug(results);

        // prettier-ignore
        results = (List<AggregateResult>) Query.of(Account.SObjectType)
            .grouping(Account.BillingCountry)
            .grouping(Account.BillingState, 'alias0')
            .min(Account.AnnualRevenue)
            .max(Account.AnnualRevenue)
            .avg(Account.AnnualRevenue, 'average')
            .sum(Account.AnnualRevenue, 'summary')
            .groupBy(Account.BillingCountry, Account.BillingState).cube()
            .orderBy('expr0', 'alias0').nullsLast().descending()
            .run();
        System.debug(results);
    }

    @isTest
    static void testQuery_GroupBy_Count() {
        List<AggregateResult> results = (List<AggregateResult>) Query.of(Account.SObjectType)
            .count(Account.AnnualRevenue)
            .groupBy(Account.BillingCountry, Account.BillingState)
            .run();
        System.debug(results);
        Assert.areEqual(2, results[0].get('expr0'));
        Assert.areEqual(2, results[1].get('expr0'));
        Assert.areEqual(2, results[2].get('expr0'));

        results = (List<AggregateResult>) Query.of(Account.SObjectType)
            .count(Account.AnnualRevenue, 'count_of_account')
            .groupBy(Account.BillingCountry, Account.BillingState)
            .run();
        System.debug(results);
        Assert.areEqual(2, results[0].get('count_of_account'));
        Assert.areEqual(2, results[1].get('count_of_account'));
        Assert.areEqual(2, results[2].get('count_of_account'));

        results = (List<AggregateResult>) Query.of(Account.SObjectType)
            .count(Account.AnnualRevenue, 'count_of_account')
            .run();
        System.debug(results);
        Assert.areEqual(6, results[0].get('count_of_account'));

        results = (List<AggregateResult>) Query.of(Account.SObjectType)
            .count(Account.BillingCountry, 'count_of_account')
            .run();
        System.debug(results);
        Assert.areEqual(4, results[0].get('count_of_account'));

        Integer count = Query.of(Account.SObjectType).count().getCount();
        Assert.areEqual(6, count);
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
                .OrderBy('BillingCountry', 'BillingState')
                .OrderBy('BillingCountry', 'BillingState', 'BillingState')
                .OrderBy('BillingCountry', 'BillingState', 'BillingState', 'BillingState')
                .OrderBy('BillingCountry', 'BillingState', 'BillingState', 'BillingState', 'BillingState')
                .nullsFirst(),
            Query.of(Account.SObjectType)
                .OrderBy('BillingCountry', 'BillingState')
                .OrderBy('BillingCountry', 'BillingState', 'BillingState')
                .OrderBy('BillingCountry', 'BillingState', 'BillingState', 'BillingState')
                .OrderBy('BillingCountry', 'BillingState', 'BillingState', 'BillingState', 'BillingState')
                .nullsFirst()
        );

        Assert.areEqual(
            Query.of(Account.SObjectType)
                .grouping(Account.BillingCountry)
                .grouping(Account.BillingState, 'alias0')
                .min(Account.AnnualRevenue, 'minimum')
                .min(Account.AnnualRevenue)
                .max(Account.AnnualRevenue, 'maximum')
                .max(Account.AnnualRevenue)
                .avg(Account.AnnualRevenue, 'average')
                .avg(Account.AnnualRevenue)
                .sum(Account.AnnualRevenue, 'summary')
                .sum(Account.AnnualRevenue)
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
                .orderBy('expr0', 'alias0')
                .nullsLast()
                .descending(),
            Query.of(Account.SObjectType)
                .grouping(Account.BillingCountry)
                .grouping(Account.BillingState, 'alias0')
                .min(Account.AnnualRevenue, 'minimum')
                .min(Account.AnnualRevenue)
                .max(Account.AnnualRevenue, 'maximum')
                .max(Account.AnnualRevenue)
                .avg(Account.AnnualRevenue, 'average')
                .avg(Account.AnnualRevenue)
                .sum(Account.AnnualRevenue, 'summary')
                .sum(Account.AnnualRevenue)
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
                .orderBy('expr0', 'alias0')
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
                .add(Account.Name, Account.Name, Account.Name, Account.Name, Account.Name)
                .add(new List<SObjectField>{ Account.Name }),
            selector()
                .add(Account.Name)
                .add(Account.Name, Account.Name)
                .add(Account.Name, Account.Name, Account.Name)
                .add(Account.Name, Account.Name, Account.Name, Account.Name)
                .add(Account.Name, Account.Name, Account.Name, Account.Name, Account.Name)
                .add(new List<SObjectField>{ Account.Name })
        );
    }
}
