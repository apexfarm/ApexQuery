@isTest
public with sharing class QueryTest extends Query {
    @isTest
    static void testFrom() {
        Query accountQuery = Query.of('Account');
        Assert.areEqual('SELECT Id FROM Account', accountQuery.buildSOQL());
        Query contactQuery = Query.of('Contact');
        Assert.areEqual('SELECT Id FROM Contact', contactQuery.buildSOQL());
    }

    @isTest
    static void testMisc() {
        Query accountQuery;

        accountQuery = new Query();

        accountQuery = Query.of('Account').updateTracking();
        Assert.areEqual('SELECT Id FROM Account UPDATE TRACKING', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').updateViewstat();
        Assert.areEqual('SELECT Id FROM Account UPDATE VIEWSTAT', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').forView();
        Assert.areEqual('SELECT Id FROM Account FOR VIEW', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').forReference();
        Assert.areEqual('SELECT Id FROM Account FOR REFERENCE', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').forUpdate();
        Assert.areEqual('SELECT Id FROM Account FOR UPDATE', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').limitx(3).offset(3);
        Assert.areEqual('SELECT Id FROM Account LIMIT 3 OFFSET 3', accountQuery.buildSOQL());
    }

    @isTest
    static void testRun() {
        Query accountQuery = Query.of('Account').limitx(3).offset(3);
        accountQuery.run();
        accountQuery.getLocator();
    }

    @isTest
    static void testRun_getCount() {
        Query accountQuery = Query.of('Account').selectBy(count()).whereBy(eq('BillingCountry', 'China'));
        Assert.areEqual('SELECT COUNT() FROM Account WHERE (BillingCountry = :tmpVar1)', accountQuery.buildSOQL());
        Integer count = accountQuery.getCount();
        Assert.areEqual(0, count);
    }

    @isTest
    static void testRun_VAR() {
        Query.Filter filter = eq('BillingCountry', var('country'));
        Query accountQuery = Query.of('Account').whereBy(filter);
        Assert.areEqual('SELECT Id FROM Account WHERE (BillingCountry = :country)', accountQuery.buildSOQL());

        accountQuery.run(new Map<String, Object>{ 'country' => 'China' });

        accountQuery = Query.of('Account').whereBy(filter);
        accountQuery.getLocator(new Map<String, Object>{ 'country' => 'China' });

        accountQuery = Query.of('Account').whereBy(filter);
        accountQuery.getCount(new Map<String, Object>{ 'country' => 'China' });
    }

    @isTest
    static void testRun_VAR_SpecialOperators() {
        Query.Filter filter;
        // Field Name
        filter = likex('BillingCountry', var('country'));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry LIKE :country)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = nlike('BillingCountry', var('country'));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE ((NOT BillingCountry LIKE :country))',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = inx('BillingCountry', var('countries'));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry IN :countries)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = nin('BillingCountry', var('countries'));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry NOT IN :countries)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        // ToLabelFunction
        filter = likex(toLabel('BillingCountry'), var('country'));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (toLabel(BillingCountry) LIKE :country)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = nlike(toLabel('BillingCountry'), var('country'));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE ((NOT toLabel(BillingCountry) LIKE :country))',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = inx(toLabel('BillingCountry'), var('countries'));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (toLabel(BillingCountry) IN :countries)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = nin(toLabel('BillingCountry'), var('countries'));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (toLabel(BillingCountry) NOT IN :countries)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );
    }

    @isTest
    static void testRun_VAR_BindingVars() {
        Query.Filter filter = andx().add(eq('BillingCountry', var('country'))).add(gt('AnnualRevenue', 1000));
        Query accountQuery = Query.of('Account').whereBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = :country AND AnnualRevenue > :tmpVar1)',
            accountQuery.buildSOQL()
        );

        Map<String, Object> bindingVars;
        bindingVars = new Map<String, Object>{ 'country' => 'China' };
        accountQuery.run(bindingVars);
        Assert.areEqual('China', bindingVars.get('country'));
        Assert.areEqual(1000, bindingVars.get('tmpVar1'));

        bindingVars = new Map<String, Object>{ 'country' => 'Japan' };
        accountQuery.run(bindingVars);
        Assert.areEqual('Japan', bindingVars.get('country'));
        Assert.areEqual(1000, bindingVars.get('tmpVar1'));
    }

    // ======================
    // #region Logical Filter

    @isTest
    static void testLogical_And() {
        Query.Filter filter = andx()
            .add(eq('BillingCountry', 'China'))
            .add(eq('BillingCountry', 'China'))
            .add(eq('BillingCountry', 'China'));
        Query accountQuery = Query.of('Account').whereBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = :tmpVar1 ' +
                'AND BillingCountry = :tmpVar2 ' +
                'AND BillingCountry = :tmpVar3)',
            accountQuery.buildSOQL()
        );

        filter = andx()
            .addAll(
                new List<Filter>{
                    eq('BillingCountry', 'China'),
                    eq('BillingCountry', 'China'),
                    eq('BillingCountry', 'China')
                }
            );
        accountQuery = Query.of('Account').whereBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = :tmpVar1 ' +
                'AND BillingCountry = :tmpVar2 ' +
                'AND BillingCountry = :tmpVar3)',
            accountQuery.buildSOQL()
        );
    }

    @isTest
    static void testLogical_Or() {
        Query.Filter filter = orx()
            .add(eq('BillingCountry', 'China'))
            .add(eq('BillingCountry', 'China'))
            .add(eq('BillingCountry', 'China'));
        Query accountQuery = Query.of('Account').whereBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = :tmpVar1 ' +
                'OR BillingCountry = :tmpVar2 ' +
                'OR BillingCountry = :tmpVar3)',
            accountQuery.buildSOQL()
        );

        filter = orx()
            .addAll(
                new List<Filter>{
                    eq('BillingCountry', 'China'),
                    eq('BillingCountry', 'China'),
                    eq('BillingCountry', 'China')
                }
            );
        accountQuery = Query.of('Account').whereBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = :tmpVar1 ' +
                'OR BillingCountry = :tmpVar2 ' +
                'OR BillingCountry = :tmpVar3)',
            accountQuery.buildSOQL()
        );
    }

    @isTest
    static void testLogical_Not() {
        Query.Filter filter = notx(eq('BillingCountry', 'China'));
        Query accountQuery = Query.of('Account').whereBy(filter);
        Assert.areEqual('SELECT Id FROM Account WHERE NOT(BillingCountry = :tmpVar1)', accountQuery.buildSOQL());

        filter = notx(
            andx().add(eq('BillingCountry', 'China')).add(eq('BillingState', 'Shanghai')).add(eq('AnnualRevenue', 1500))
        );
        accountQuery = Query.of('Account').whereBy(filter);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE NOT(BillingCountry = :tmpVar1 ' +
                'AND BillingState = :tmpVar2 ' +
                'AND AnnualRevenue = :tmpVar3)',
            accountQuery.buildSOQL()
        );
    }

    @isTest // prettier-ignore
    static void testLogical_Where() {
        Filter filter = eq('BillingCountry', 'China');

        // empty where clause
        Query accountQuery = Query.of('Account').whereBy(orx());
        Assert.areEqual('SELECT Id FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').whereBy(andx());
        Assert.areEqual('SELECT Id FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account');
        accountQuery.whereBy();
        Assert.areEqual('SELECT Id FROM Account', accountQuery.buildSOQL());


        // single filter in logical operator
        accountQuery = Query.of('Account').whereBy(orx());
        accountQuery.whereBy().add(filter);
        Assert.areEqual('SELECT Id FROM Account WHERE (BillingCountry = :tmpVar1)', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').whereBy(andx());
        accountQuery.whereBy().add(filter);
        Assert.areEqual('SELECT Id FROM Account WHERE (BillingCountry = :tmpVar1)', accountQuery.buildSOQL());

        accountQuery = Query.of('Account');
        accountQuery.whereBy().add(filter);
        Assert.areEqual('SELECT Id FROM Account WHERE (BillingCountry = :tmpVar1)', accountQuery.buildSOQL());

        // double filters in logical operator
        accountQuery = Query.of('Account').whereBy(orx());
        accountQuery.whereBy().add(filter);
        accountQuery.whereBy().add(filter);
        Assert.areEqual('SELECT Id FROM Account WHERE (BillingCountry = :tmpVar1 OR BillingCountry = :tmpVar2)', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').whereBy(andx());
        accountQuery.whereBy().add(filter);
        accountQuery.whereBy().add(filter);
        Assert.areEqual('SELECT Id FROM Account WHERE (BillingCountry = :tmpVar1 AND BillingCountry = :tmpVar2)', accountQuery.buildSOQL());

        accountQuery = Query.of('Account');
        accountQuery.whereBy().add(filter);
        accountQuery.whereBy().add(filter);
        Assert.areEqual('SELECT Id FROM Account WHERE (BillingCountry = :tmpVar1 AND BillingCountry = :tmpVar2)', accountQuery.buildSOQL());

        // double filters in logical operator
        accountQuery = Query.of('Account').whereBy(orx().add(filter));
        accountQuery.whereBy().add(filter);
        Assert.areEqual('SELECT Id FROM Account WHERE (BillingCountry = :tmpVar1 OR BillingCountry = :tmpVar2)', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').whereBy(andx().add(filter));
        accountQuery.whereBy().add(filter);
        Assert.areEqual('SELECT Id FROM Account WHERE (BillingCountry = :tmpVar1 AND BillingCountry = :tmpVar2)', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').whereBy(filter);
        accountQuery.whereBy().add(filter);
        Assert.areEqual('SELECT Id FROM Account WHERE (BillingCountry = :tmpVar1 AND BillingCountry = :tmpVar2)', accountQuery.buildSOQL());
    }

    @isTest // prettier-ignore
    static void testLogical_Having() {
        Filter filter = eq('BillingCountry', 'China');

        // empty where clause
        Query accountQuery = Query.of('Account').havingBy(orx());
        Assert.areEqual('SELECT Id FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').havingBy(andx());
        Assert.areEqual('SELECT Id FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account');
        accountQuery.havingBy();
        Assert.areEqual('SELECT Id FROM Account', accountQuery.buildSOQL());


        // single filter in logical operator
        accountQuery = Query.of('Account').havingBy(orx());
        accountQuery.havingBy().add(filter);
        Assert.areEqual('SELECT Id FROM Account HAVING (BillingCountry = :tmpVar1)', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').havingBy(andx());
        accountQuery.havingBy().add(filter);
        Assert.areEqual('SELECT Id FROM Account HAVING (BillingCountry = :tmpVar1)', accountQuery.buildSOQL());

        accountQuery = Query.of('Account');
        accountQuery.havingBy().add(filter);
        Assert.areEqual('SELECT Id FROM Account HAVING (BillingCountry = :tmpVar1)', accountQuery.buildSOQL());

        // double filters in logical operator
        accountQuery = Query.of('Account').havingBy(orx());
        accountQuery.havingBy().add(filter);
        accountQuery.havingBy().add(filter);
        Assert.areEqual('SELECT Id FROM Account HAVING (BillingCountry = :tmpVar1 OR BillingCountry = :tmpVar2)', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').havingBy(andx());
        accountQuery.havingBy().add(filter);
        accountQuery.havingBy().add(filter);
        Assert.areEqual('SELECT Id FROM Account HAVING (BillingCountry = :tmpVar1 AND BillingCountry = :tmpVar2)', accountQuery.buildSOQL());

        accountQuery = Query.of('Account');
        accountQuery.havingBy().add(filter);
        accountQuery.havingBy().add(filter);
        Assert.areEqual('SELECT Id FROM Account HAVING (BillingCountry = :tmpVar1 AND BillingCountry = :tmpVar2)', accountQuery.buildSOQL());
    }

    // #endregion
    // ======================

    // =========================
    // #region Comparison Filter

    @isTest // prettier-ignore
    static void testComparison_EQ() {
        // param1 are Strings
        Query.Filter filter = eq('BillingCountry', 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = eq('BillingCountry', true);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = eq('BillingCountry', 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = eq('BillingCountry', Datetime.newInstance(2023, 1, 1, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = eq('BillingCountry', Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = eq('BillingCountry', Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = eq('BillingCountry', LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = LAST_N_DAYS:2)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = eq('BillingCountry', CURRENCY('CNY', 2000));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = CNY2000)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = eq('BillingCountry', null);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry = NULL)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        // param1 are others
        filter = eq(distance('ShippingAddress', Location.newInstance(37.775001, -122.41801), 'km'), 12.3);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (DISTANCE(ShippingAddress, GEOLOCATION(37.775001, -122.41801), \'km\') = :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = eq(calendarMonth('CreatedDate'), 2);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (CALENDAR_MONTH(CreatedDate) = :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = eq(toLabel('AccountSource'), 'Advertisement');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (toLabel(AccountSource) = :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = eq(max('BillingCountry'), 'China');
        Assert.areEqual(
            'SELECT Id FROM Account HAVING (MAX(BillingCountry) = :tmpVar1)',
            Query.of('Account').havingBy(filter).buildSOQL()
        );
    }

    @isTest // prettier-ignore
    static void testOperator_Comparison_NE() {
        // param1 are Strings
        Query.Filter filter = ne('BillingCountry', 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry != :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = ne('BillingCountry', true);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry != :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = ne('BillingCountry', 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry != :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = ne('BillingCountry', Datetime.newInstance(2023, 1, 1, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry != :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = ne('BillingCountry', Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry != :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = ne('BillingCountry', Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry != :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = ne('BillingCountry', LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry != LAST_N_DAYS:2)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = ne('BillingCountry', CURRENCY('CNY', 2000));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry != CNY2000)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = ne('BillingCountry', null);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry != NULL)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        // param1 are others
        filter = ne(distance('ShippingAddress', Location.newInstance(37.775001, -122.41801), 'km'), 12.3);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (DISTANCE(ShippingAddress, GEOLOCATION(37.775001, -122.41801), \'km\') != :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = ne(calendarMonth('CreatedDate'), 2);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (CALENDAR_MONTH(CreatedDate) != :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = ne(toLabel('AccountSource'), 'Advertisement');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (toLabel(AccountSource) != :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = ne(max('BillingCountry'), 'China');
        Assert.areEqual(
            'SELECT Id FROM Account HAVING (MAX(BillingCountry) != :tmpVar1)',
            Query.of('Account').havingBy(filter).buildSOQL()
        );
    }

    @isTest // prettier-ignore
    static void testComparison_BETWEEN() {
        // param1 are Strings
        Query.Filter filter = between('BillingCountry', 'China', 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= :tmpVar1 AND BillingCountry <= :tmpVar2)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = between('BillingCountry', 123.456, 123.456);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= :tmpVar1 AND BillingCountry <= :tmpVar2)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = between(
            'BillingCountry',
            Datetime.newInstance(2023, 1, 1, 12, 12, 12),
            Datetime.newInstance(2023, 1, 1, 12, 12, 12)
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= :tmpVar1 AND BillingCountry <= :tmpVar2)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = between('BillingCountry', Date.newInstance(2023, 1, 1), Date.newInstance(2023, 1, 1));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= :tmpVar1 AND BillingCountry <= :tmpVar2)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = between('BillingCountry', Time.newInstance(12, 12, 12, 12), Time.newInstance(12, 12, 12, 12));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= :tmpVar1 AND BillingCountry <= :tmpVar2)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = between('BillingCountry', LAST_N_DAYS(2), LAST_N_DAYS(2));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= LAST_N_DAYS:2 AND BillingCountry <= LAST_N_DAYS:2)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = between('BillingCountry', CURRENCY('CNY', 2000), CURRENCY('CNY', 2000));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= CNY2000 AND BillingCountry <= CNY2000)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        // param1 are others
        filter = between(
            DISTANCE('ShippingAddress', Location.newInstance(37.775001, -122.41801), 'km'),
            12.3,
            12.3
        );
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (DISTANCE(ShippingAddress, GEOLOCATION(37.775001, -122.41801), \'km\') >= :tmpVar1 AND DISTANCE(ShippingAddress, GEOLOCATION(37.775001, -122.41801), \'km\') <= :tmpVar2)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = between(calendarMonth('CreatedDate'), 2, 2);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (CALENDAR_MONTH(CreatedDate) >= :tmpVar1 AND CALENDAR_MONTH(CreatedDate) <= :tmpVar2)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = between(toLabel('AccountSource'), 'Advertisement', 'Advertisement');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (toLabel(AccountSource) >= :tmpVar1 AND toLabel(AccountSource) <= :tmpVar2)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = between(max('BillingCountry'), 'China', 'China');
        Assert.areEqual(
            'SELECT Id FROM Account HAVING (MAX(BillingCountry) >= :tmpVar1 AND MAX(BillingCountry) <= :tmpVar2)',
            Query.of('Account').havingBy(filter).buildSOQL()
        );

    }

    @isTest
    static void testComparison_LT_GT() {
        // param1 are Strings
        Query.Filter filter = lt('BillingCountry', 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry < :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = lte('BillingCountry', 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry <= :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = gt('BillingCountry', 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry > :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = gte('BillingCountry', 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry >= :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = lt(toLabel('BillingCountry'), 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (toLabel(BillingCountry) < :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = lte(toLabel('BillingCountry'), 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (toLabel(BillingCountry) <= :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = gt(toLabel('BillingCountry'), 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (toLabel(BillingCountry) > :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = gte(toLabel('BillingCountry'), 'China');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (toLabel(BillingCountry) >= :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );
    }

    @isTest // prettier-ignore
    static void testComparison_LIKE() {
        Query.Filter filter;
        filter = likex('BillingCountry', '%China%');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry LIKE :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = likex(toLabel('BillingCountry'), '%China%');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (toLabel(BillingCountry) LIKE :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = likex(max('BillingCountry'), '%China%');
        Assert.areEqual(
            'SELECT Id FROM Account HAVING (MAX(BillingCountry) LIKE :tmpVar1)',
            Query.of('Account').havingBy(filter).buildSOQL()
        );
    }

    @isTest // prettier-ignore
    static void testComparison_NLIKE() {
        Query.Filter filter;
        filter = nlike('BillingCountry', '%China%');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE ((NOT BillingCountry LIKE :tmpVar1))',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = nlike(toLabel('BillingCountry'), '%China%');
        Assert.areEqual(
            'SELECT Id FROM Account WHERE ((NOT toLabel(BillingCountry) LIKE :tmpVar1))',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = nlike(max('BillingCountry'), '%China%');
        Assert.areEqual(
            'SELECT Id FROM Account HAVING ((NOT MAX(BillingCountry) LIKE :tmpVar1))',
            Query.of('Account').havingBy(filter).buildSOQL()
        );
    }

    @isTest // prettier-ignore
    static void testComparison_INCLUDES() {
        Query.Filter filter;
        filter = includes('BillingCountry', new List<String>{ 'AAA', 'BBB', 'CCC', 'DDD', 'EEE' });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry INCLUDES (:tmpVar1, :tmpVar2, :tmpVar3, :tmpVar4, :tmpVar5))',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = excludes('BillingCountry', new List<String>{ 'AAA', 'BBB', 'CCC', 'DDD', 'EEE' });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry EXCLUDES (:tmpVar1, :tmpVar2, :tmpVar3, :tmpVar4, :tmpVar5))',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = includes(toLabel('BillingCountry'), new List<String>{ 'AAA', 'BBB', 'CCC', 'DDD', 'EEE' });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (toLabel(BillingCountry) INCLUDES (:tmpVar1, :tmpVar2, :tmpVar3, :tmpVar4, :tmpVar5))',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = excludes(toLabel('BillingCountry'), new List<String>{ 'AAA', 'BBB', 'CCC', 'DDD', 'EEE' });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (toLabel(BillingCountry) EXCLUDES (:tmpVar1, :tmpVar2, :tmpVar3, :tmpVar4, :tmpVar5))',
            Query.of('Account').whereBy(filter).buildSOQL()
        );
    }

    @isTest // prettier-ignore
    static void testComparison_INX() {
        // String
        Query.Filter filter = inx('BillingCountry', new List<String>{ 'AAA', 'BBB', null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry IN :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = inx(toLabel('BillingCountry'), new List<String>{ 'AAA', 'BBB', null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (toLabel(BillingCountry) IN :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        Query contactQuery = Query.of('Contact').selectBy('AccountId');
        filter = inx('Id', contactQuery);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (Id IN (SELECT AccountId FROM Contact))',
            Query.of('Account').whereBy(filter).buildSOQL()
        );
    }

    @isTest
    static void testOperator_Comparison_NIN() {
        Query.Filter filter = nin('BillingCountry', new List<String>{ 'AAA', 'BBB', null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (BillingCountry NOT IN :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        filter = nin(toLabel('BillingCountry'), new List<String>{ 'AAA', 'BBB', null });
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (toLabel(BillingCountry) NOT IN :tmpVar1)',
            Query.of('Account').whereBy(filter).buildSOQL()
        );

        Query contactQuery = Query.of('Contact').selectBy('AccountId');
        filter = nin('Id', contactQuery);
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (Id NOT IN (SELECT AccountId FROM Contact))',
            Query.of('Account').whereBy(filter).buildSOQL()
        );
    }

    // #endregion
    // =========================

    // =====================
    // #region Select Clause

    @isTest // prettier-ignore
    static void testSelect_Fields() {
        Query accountQuery = Query.of('Account').selectBy('Name1');
        Assert.areEqual('SELECT Name1 FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy('Name1', 'Name2');
        Assert.areEqual('SELECT Name1, Name2 FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy('Name1', 'Name2', 'Name3');
        Assert.areEqual('SELECT Name1, Name2, Name3 FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy('Name1', 'Name2', 'Name3', 'Name4');
        Assert.areEqual('SELECT Name1, Name2, Name3, Name4 FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy('Name1', 'Name2', 'Name3', 'Name4', 'Name5');
        Assert.areEqual('SELECT Name1, Name2, Name3, Name4, Name5 FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy('Name1', 'Name2', 'Name3', 'Name4', 'Name5', 'Name6');
        Assert.areEqual('SELECT Name1, Name2, Name3, Name4, Name5, Name6 FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy('Name1', 'Name2', 'Name3', 'Name4', 'Name5', 'Name6', 'Name7');
        Assert.areEqual('SELECT Name1, Name2, Name3, Name4, Name5, Name6, Name7 FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy('Name1', 'Name2', 'Name3', 'Name4', 'Name5', 'Name6', 'Name7', 'Name8');
        Assert.areEqual('SELECT Name1, Name2, Name3, Name4, Name5, Name6, Name7, Name8 FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy('Name1', 'Name2', 'Name3', 'Name4', 'Name5', 'Name6', 'Name7', 'Name8', 'Name9');
        Assert.areEqual('SELECT Name1, Name2, Name3, Name4, Name5, Name6, Name7, Name8, Name9 FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy('Name1', 'Name2', 'Name3', 'Name4', 'Name5', 'Name6', 'Name7', 'Name8', 'Name9', 'Name10');
        Assert.areEqual('SELECT Name1, Name2, Name3, Name4, Name5, Name6, Name7, Name8, Name9, Name10 FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(new List<String> { 'Name1', 'Name2', 'Name3' });
        Assert.areEqual('SELECT Name1, Name2, Name3 FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account')
            .selectBy(new List<String> { 'Name1', 'Name2', 'Name3' })
            .selectBy(new List<String> { 'Name4', 'Name5', 'Name6' });
        Assert.areEqual('SELECT Name1, Name2, Name3, Name4, Name5, Name6 FROM Account', accountQuery.buildSOQL());
    }

    @isTest // prettier-ignore
    static void testSelect_Functions() {
        Query accountQuery;

        accountQuery = Query.of('Account').selectBy(toLabel('AccountSource'));
        Assert.areEqual('SELECT toLabel(AccountSource) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(convertCurrency('AnnualRevenue'));
        Assert.areEqual('SELECT convertCurrency(AnnualRevenue) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(format('AnnualRevenue'));
        Assert.areEqual('SELECT FORMAT(AnnualRevenue) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(format(convertCurrency('AnnualRevenue')));
        Assert.areEqual('SELECT FORMAT(convertCurrency(AnnualRevenue)) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account')
            .whereBy(lte(DISTANCE('ShippingAddress', Location.newInstance(37.775000, -122.41800), 'mi'), 20));
        Assert.areEqual(
            'SELECT Id FROM Account WHERE (DISTANCE(ShippingAddress, GEOLOCATION(37.775, -122.418), \'mi\') <= :tmpVar1)',
            accountQuery.buildSOQL()
        );

        // with alias
        accountQuery = Query.of('Account').selectBy(toLabel('AccountSource', 'alias'));
        Assert.areEqual('SELECT toLabel(AccountSource) AS alias FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(convertCurrency('AnnualRevenue', 'alias'));
        Assert.areEqual('SELECT convertCurrency(AnnualRevenue) AS alias FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(format('AnnualRevenue', 'alias'));
        Assert.areEqual('SELECT FORMAT(AnnualRevenue) AS alias FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(format(convertCurrency('AnnualRevenue'), 'alias'));
        Assert.areEqual('SELECT FORMAT(convertCurrency(AnnualRevenue)) AS alias FROM Account', accountQuery.buildSOQL());
    }

    @isTest
    static void testSelect_Parent() {
        Query grandGrandParentAccountQuery = Query.of('Account');

        Query grandParentAccountQuery = Query.of('Account')
            .selectBy('Name', format(convertCurrency('AnnualRevenue'), 'alias'), toLabel('Industry'))
            .selectParent('Parent', grandGrandParentAccountQuery);

        Query parentAccountQuery = Query.of('Account')
            .selectBy('Name', format(convertCurrency('AnnualRevenue')), toLabel('Industry'))
            .selectParent('Parent', grandParentAccountQuery);

        Query accountQuery = Query.of('Account')
            .selectBy('Name', format(convertCurrency('AnnualRevenue')), toLabel('Industry'))
            .selectParent('Parent', parentAccountQuery);
        Assert.areEqual(
            'SELECT Name, FORMAT(convertCurrency(AnnualRevenue)), toLabel(Industry), ' +
                'Parent.Name, FORMAT(convertCurrency(Parent.AnnualRevenue)), toLabel(Parent.Industry), ' +
                'Parent.Parent.Name, FORMAT(convertCurrency(Parent.Parent.AnnualRevenue)) AS alias, toLabel(Parent.Parent.Industry), ' +
                'Parent.Parent.Parent.Id FROM Account',
            accountQuery.buildSOQL()
        );
    }

    @isTest
    static void testSelect_Child() {
        Query parentAccountQuery = Query.of('Account')
            .selectBy('Name', format(convertCurrency('AnnualRevenue')), toLabel('Industry'));
        Query opprotunityQuery = Query.of('Opportunity').selectParent('Account', parentAccountQuery);
        Query contactQuery = Query.of('Contact').selectChild('Opportunities', opprotunityQuery);

        Query accountQuery = Query.of('Account')
            .selectParent('Parent', parentAccountQuery)
            .selectChild('Contacts', contactQuery);
        Assert.areEqual(
            'SELECT Id, ' +
                'Parent.Name, FORMAT(convertCurrency(Parent.AnnualRevenue)), toLabel(Parent.Industry), ' +
                '(SELECT Id, (SELECT Id, ' +
                'Account.Name, FORMAT(convertCurrency(Account.AnnualRevenue)), toLabel(Account.Industry) ' +
                'FROM Opportunities) FROM Contacts) FROM Account',
            accountQuery.buildSOQL()
        );
    }

    // #endregion
    // =====================

    // =======================
    // #region Group By Clause

    @isTest // prettier-ignore
    static void testGroupBy_Measure() {
        Query accountQuery;
        accountQuery = Query.of('Account').selectBy(count('Name'), count('Name', 'alias'));
        Assert.areEqual('SELECT COUNT(Name), COUNT(Name) alias FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(countDistinct('Name'), countDistinct('Name', 'alias'));
        Assert.areEqual('SELECT COUNT_DISTINCT(Name), COUNT_DISTINCT(Name) alias FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(sum('Name'), sum('Name', 'alias'));
        Assert.areEqual('SELECT SUM(Name), SUM(Name) alias FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(avg('Name'), avg('Name', 'alias'));
        Assert.areEqual('SELECT AVG(Name), AVG(Name) alias FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(max('Name'), max('Name', 'alias'));
        Assert.areEqual('SELECT MAX(Name), MAX(Name) alias FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(min('Name'), min('Name', 'alias'));
        Assert.areEqual('SELECT MIN(Name), MIN(Name) alias FROM Account', accountQuery.buildSOQL());
    }

    @isTest // prettier-ignore
    static void testGroupBy_Dimension() {
        Query accountQuery;

        accountQuery = Query.of('Account').selectBy(grouping('Name'), grouping('Name', 'alias'));
        Assert.areEqual('SELECT GROUPING(Name), GROUPING(Name) alias FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(calendarMonth('CreatedDate'));
        Assert.areEqual('SELECT CALENDAR_MONTH(CreatedDate) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(calendarQuarter('CreatedDate'));
        Assert.areEqual('SELECT CALENDAR_QUARTER(CreatedDate) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(calendarYear('CreatedDate'));
        Assert.areEqual('SELECT CALENDAR_YEAR(CreatedDate) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(dayInMonth('CreatedDate'));
        Assert.areEqual('SELECT DAY_IN_MONTH(CreatedDate) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(dayInWeek('CreatedDate'));
        Assert.areEqual('SELECT DAY_IN_WEEK(CreatedDate) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(dayInYear('CreatedDate'));
        Assert.areEqual('SELECT DAY_IN_YEAR(CreatedDate) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(dayOnly('CreatedDate'));
        Assert.areEqual('SELECT DAY_ONLY(CreatedDate) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(fiscalMonth('CreatedDate'));
        Assert.areEqual('SELECT FISCAL_MONTH(CreatedDate) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(fiscalQuarter('CreatedDate'));
        Assert.areEqual('SELECT FISCAL_QUARTER(CreatedDate) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(fiscalYear('CreatedDate'));
        Assert.areEqual('SELECT FISCAL_YEAR(CreatedDate) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(hourInDay('CreatedDate'));
        Assert.areEqual('SELECT HOUR_IN_DAY(CreatedDate) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(weekInMonth('CreatedDate'));
        Assert.areEqual('SELECT WEEK_IN_MONTH(CreatedDate) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(weekInYear('CreatedDate'));
        Assert.areEqual('SELECT WEEK_IN_YEAR(CreatedDate) FROM Account', accountQuery.buildSOQL());


        // convertTimezone
        accountQuery = Query.of('Account').selectBy(calendarMonth(convertTimezone('CreatedDate')));
        Assert.areEqual('SELECT CALENDAR_MONTH(convertTimezone(CreatedDate)) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(calendarQuarter(convertTimezone('CreatedDate')));
        Assert.areEqual('SELECT CALENDAR_QUARTER(convertTimezone(CreatedDate)) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(calendarYear(convertTimezone('CreatedDate')));
        Assert.areEqual('SELECT CALENDAR_YEAR(convertTimezone(CreatedDate)) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(dayInMonth(convertTimezone('CreatedDate')));
        Assert.areEqual('SELECT DAY_IN_MONTH(convertTimezone(CreatedDate)) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(dayInWeek(convertTimezone('CreatedDate')));
        Assert.areEqual('SELECT DAY_IN_WEEK(convertTimezone(CreatedDate)) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(dayInYear(convertTimezone('CreatedDate')));
        Assert.areEqual('SELECT DAY_IN_YEAR(convertTimezone(CreatedDate)) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(dayOnly(convertTimezone('CreatedDate')));
        Assert.areEqual('SELECT DAY_ONLY(convertTimezone(CreatedDate)) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(fiscalMonth(convertTimezone('CreatedDate')));
        Assert.areEqual('SELECT FISCAL_MONTH(convertTimezone(CreatedDate)) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(fiscalQuarter(convertTimezone('CreatedDate')));
        Assert.areEqual('SELECT FISCAL_QUARTER(convertTimezone(CreatedDate)) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(fiscalYear(convertTimezone('CreatedDate')));
        Assert.areEqual('SELECT FISCAL_YEAR(convertTimezone(CreatedDate)) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(hourInDay(convertTimezone('CreatedDate')));
        Assert.areEqual('SELECT HOUR_IN_DAY(convertTimezone(CreatedDate)) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(weekInMonth(convertTimezone('CreatedDate')));
        Assert.areEqual('SELECT WEEK_IN_MONTH(convertTimezone(CreatedDate)) FROM Account', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').selectBy(weekInYear(convertTimezone('CreatedDate')));
        Assert.areEqual('SELECT WEEK_IN_YEAR(convertTimezone(CreatedDate)) FROM Account', accountQuery.buildSOQL());
    }

    @isTest // prettier-ignore
    static void testGroupBy() {
        // String
        Query accountQuery = Query.of('Account').groupBy('Name');
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').groupBy('Name', 'Name');
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').groupBy('Name', 'Name', 'Name');
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').groupBy('Name', 'Name', 'Name', 'Name');
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').groupBy('Name', 'Name', 'Name', 'Name', 'Name');
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name, Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').groupBy('Name', 'Name', 'Name', 'Name', 'Name', 'Name');
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name, Name, Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').groupBy('Name', 'Name', 'Name', 'Name', 'Name', 'Name', 'Name');
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name, Name, Name, Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').groupBy('Name', 'Name', 'Name', 'Name', 'Name', 'Name', 'Name', 'Name');
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name, Name, Name, Name, Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').groupBy('Name', 'Name', 'Name', 'Name', 'Name', 'Name', 'Name', 'Name', 'Name');
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name, Name, Name, Name, Name, Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').groupBy('Name', 'Name', 'Name', 'Name', 'Name', 'Name', 'Name', 'Name', 'Name', 'Name');
        Assert.areEqual('SELECT Id FROM Account GROUP BY Name, Name, Name, Name, Name, Name, Name, Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account')
            .groupBy(new List<String>{ 'Name', 'Name', calendarMonth('CreatedDate') });
        Assert.areEqual(
            'SELECT Id FROM Account GROUP BY Name, Name, CALENDAR_MONTH(CreatedDate)',
            accountQuery.buildSOQL()
        );

        // Function
        accountQuery = Query.of('Account').groupBy(calendarMonth('CreatedDate'));
        Assert.areEqual('SELECT Id FROM Account GROUP BY CALENDAR_MONTH(CreatedDate)', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').groupBy(calendarMonth(convertTimezone('CreatedDate')));
        Assert.areEqual('SELECT Id FROM Account GROUP BY CALENDAR_MONTH(convertTimezone(CreatedDate))', accountQuery.buildSOQL());
    }

    @isTest // prettier-ignore
    static void testGroupBy_Options() {
        // String
        Query accountQuery = Query.of('Account').groupBy('Name', calendarMonth('CreatedDate')).rollup();
        Assert.areEqual('SELECT Id FROM Account GROUP BY ROLLUP(Name, CALENDAR_MONTH(CreatedDate))', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').groupBy('Name', calendarMonth('CreatedDate')).cube();
        Assert.areEqual('SELECT Id FROM Account GROUP BY CUBE(Name, CALENDAR_MONTH(CreatedDate))', accountQuery.buildSOQL());
    }

    // #endregion
    // =======================

    // =======================
    // #region Order By Clause

    @isTest // prettier-ignore
    static void testOrderBy() {
        // String
        Query.OrderField orderField = orderField('Name');
        Query accountQuery = Query.of('Account').orderBy(orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').orderBy(orderField, orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').orderBy(orderField, orderField, orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').orderBy(orderField, orderField, orderField, orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').orderBy(orderField, orderField, orderField, orderField, orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').orderBy(orderField, orderField, orderField, orderField, orderField,
            orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').orderBy(orderField, orderField, orderField, orderField, orderField,
            orderField, orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name, Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').orderBy(orderField, orderField, orderField, orderField, orderField,
            orderField, orderField, orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name, Name, Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').orderBy(orderField, orderField, orderField, orderField, orderField,
            orderField, orderField, orderField, orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name, Name, Name, Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').orderBy(orderField, orderField, orderField, orderField, orderField,
            orderField, orderField, orderField, orderField, orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name, Name, Name, Name, Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').orderBy(new List<Query.OrderField>{ orderField, orderField, orderField });
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name', accountQuery.buildSOQL());

        // Function
        accountQuery = Query.of('Account').orderBy(orderField(max('Name')));
        Assert.areEqual('SELECT Id FROM Account ORDER BY MAX(Name)', accountQuery.buildSOQL());

        // Mixing
        accountQuery = Query.of('Account').orderBy(new List<OrderField>{ orderField, orderField(max('Name')) });
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, MAX(Name)', accountQuery.buildSOQL());
    }

    @isTest // prettier-ignore
    static void testOrderBy_StringInputs() {
        // String
        String orderField = 'Name';
        Query accountQuery = Query.of('Account').orderBy(orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').orderBy(orderField, orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').orderBy(orderField, orderField, orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').orderBy(orderField, orderField, orderField, orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').orderBy(orderField, orderField, orderField, orderField, orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').orderBy(orderField, orderField, orderField, orderField, orderField,
            orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').orderBy(orderField, orderField, orderField, orderField, orderField,
            orderField, orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name, Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').orderBy(orderField, orderField, orderField, orderField, orderField,
            orderField, orderField, orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name, Name, Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').orderBy(orderField, orderField, orderField, orderField, orderField,
            orderField, orderField, orderField, orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name, Name, Name, Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').orderBy(orderField, orderField, orderField, orderField, orderField,
            orderField, orderField, orderField, orderField, orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name, Name, Name, Name, Name, Name, Name, Name', accountQuery.buildSOQL());

        accountQuery = Query.of('Account').orderBy(new List<Object>{ orderField, orderField, orderField });
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name, Name', accountQuery.buildSOQL());

        // Function
        accountQuery = Query.of('Account').orderBy(max('Name'));
        Assert.areEqual('SELECT Id FROM Account ORDER BY MAX(Name)', accountQuery.buildSOQL());

        // Mixing
        accountQuery = Query.of('Account').orderBy(new List<Object>{ orderField, max('Name') });
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, MAX(Name)', accountQuery.buildSOQL());
    }

    @isTest
    static void testOrderBy_Options() {
        Query.OrderField orderField = orderField('Name').ascending().nullsFirst();
        Query accountQuery = Query.of('Account').orderBy(orderField, orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name', accountQuery.buildSOQL());

        orderField = orderField('Name').descending().nullsLast().ascending().nullsFirst();
        accountQuery = Query.of('Account').orderBy(orderField, orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name', accountQuery.buildSOQL());

        orderField = orderField('Name').descending().nullsLast();
        accountQuery = Query.of('Account').orderBy(orderField, orderField);
        Assert.areEqual(
            'SELECT Id FROM Account ORDER BY Name DESC NULLS LAST, Name DESC NULLS LAST',
            accountQuery.buildSOQL()
        );

        orderField = orderField('Name').ascending().nullsFirst().descending().nullsLast();
        accountQuery = Query.of('Account').orderBy(orderField, orderField);
        Assert.areEqual(
            'SELECT Id FROM Account ORDER BY Name DESC NULLS LAST, Name DESC NULLS LAST',
            accountQuery.buildSOQL()
        );
    }

    @isTest
    static void testOrderBy_Options_StringInputs() {
        String orderField = 'Name';
        Query accountQuery = Query.of('Account').orderBy(orderField, orderField);
        Assert.areEqual('SELECT Id FROM Account ORDER BY Name, Name', accountQuery.buildSOQL());

        orderField = 'Name DESC NULLS LAST';
        accountQuery = Query.of('Account').orderBy(orderField, orderField);
        Assert.areEqual(
            'SELECT Id FROM Account ORDER BY Name DESC NULLS LAST, Name DESC NULLS LAST',
            accountQuery.buildSOQL()
        );
    }

    // #endregion
    // =======================

    // ===============
    // #region Literal

    @isTest
    static void testLiteral_Date() {
        Query accountQuery = Query.of('Account')
            .whereBy(
                orx()
                    .add(eq('CreatedDate', YESTERDAY()))
                    .add(eq('CreatedDate', TODAY()))
                    .add(eq('CreatedDate', TOMORROW()))
                    .add(eq('CreatedDate', LAST_WEEK()))
                    .add(eq('CreatedDate', THIS_WEEK()))
                    .add(eq('CreatedDate', NEXT_WEEK()))
                    .add(eq('CreatedDate', LAST_MONTH()))
                    .add(eq('CreatedDate', THIS_MONTH()))
                    .add(eq('CreatedDate', NEXT_MONTH()))
                    .add(eq('CreatedDate', LAST_90_DAYS()))
                    .add(eq('CreatedDate', NEXT_90_DAYS()))
                    .add(eq('CreatedDate', THIS_QUARTER()))
                    .add(eq('CreatedDate', LAST_QUARTER()))
                    .add(eq('CreatedDate', NEXT_QUARTER()))
                    .add(eq('CreatedDate', THIS_YEAR()))
                    .add(eq('CreatedDate', LAST_YEAR()))
                    .add(eq('CreatedDate', NEXT_YEAR()))
                    .add(eq('CreatedDate', THIS_FISCAL_QUARTER()))
                    .add(eq('CreatedDate', LAST_FISCAL_QUARTER()))
                    .add(eq('CreatedDate', NEXT_FISCAL_QUARTER()))
                    .add(eq('CreatedDate', THIS_FISCAL_YEAR()))
                    .add(eq('CreatedDate', LAST_FISCAL_YEAR()))
                    .add(eq('CreatedDate', NEXT_FISCAL_YEAR()))
                    .add(eq('CreatedDate', LAST_N_DAYS(3)))
                    .add(eq('CreatedDate', NEXT_N_DAYS(3)))
                    .add(eq('CreatedDate', N_DAYS_AGO(3)))
                    .add(eq('CreatedDate', NEXT_N_WEEKS(3)))
                    .add(eq('CreatedDate', LAST_N_WEEKS(3)))
                    .add(eq('CreatedDate', N_WEEKS_AGO(3)))
                    .add(eq('CreatedDate', NEXT_N_MONTHS(3)))
                    .add(eq('CreatedDate', LAST_N_MONTHS(3)))
                    .add(eq('CreatedDate', N_MONTHS_AGO(3)))
                    .add(eq('CreatedDate', NEXT_N_QUARTERS(3)))
                    .add(eq('CreatedDate', LAST_N_QUARTERS(3)))
                    .add(eq('CreatedDate', N_QUARTERS_AGO(3)))
                    .add(eq('CreatedDate', NEXT_N_YEARS(3)))
                    .add(eq('CreatedDate', LAST_N_YEARS(3)))
                    .add(eq('CreatedDate', N_YEARS_AGO(3)))
                    .add(eq('CreatedDate', NEXT_N_FISCAL_QUARTERS(3)))
                    .add(eq('CreatedDate', N_FISCAL_QUARTERS_AGO(3)))
                    .add(eq('CreatedDate', NEXT_N_FISCAL_YEARS(3)))
                    .add(eq('CreatedDate', LAST_N_FISCAL_YEARS(3)))
                    .add(eq('CreatedDate', N_FISCAL_YEARS_AGO(3)))
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
            accountQuery.buildSOQL()
        );
    }

    @isTest
    static void testLiteral_Currency() {
        Query accountQuery = Query.of('Account').whereBy(eq('AnnualRevenue', CURRENCY('TRY', 100)));
        Assert.areEqual('SELECT Id FROM Account WHERE (AnnualRevenue = TRY100)', accountQuery.buildSOQL());
    }

    // #endregion
    // ===============
}
