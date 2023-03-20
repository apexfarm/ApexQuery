//prettier-ignore
List<Account> accountList = (List<Account>) Query.of(Account.SObjectType)
    .selectBy(Account.Name, Account.BillingCountry, Account.BillingState)
    .selectBy(FORMAT(CONVERT_CURRENCY(Account.AnnualRevenue)))
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
    .run();
//prettier-ignore
Query.Selector selector = selector()
    .add(Account.Name, Account.BillingCountry, Account.BillingState)
    .add(Query.FORMAT(Query.CONVERT_CURRENCY(Account.AnnualRevenue)))
    .add('Contacts', Query.of(Contact.SObjectType).selectBy(Contact.Name));
//prettier-ignore
Query.Filter filter = orx(
    andx(
        gt(Account.AnnualRevenue, 1000),
        eq(Account.BillingCountry, 'China'),
        eq(Account.BillingState, 'Beijing')
    ),
    andx(
        lt(Account.AnnualRevenue, 1000),
        eq(Account.BillingCountry, 'China'),
        eq(Account.BillingState, 'Shanghai')
    ));


Query.of(Task.SObjecType)
    .selectBy(typeOf(Task.What)
        .when(Account.SObjectType).then(Account.Phone, Account.NumberOfEmployees)
        .when(Opportunity.SObjectType).then(Opportunity.Amount, Opportunity.CloseDate)
        .elsex(Task.Name))

