class QueryTest extends Query {
    public void test() {
        // prettier-ignore
        Query q = Query.of(Account.SObjectType)
            .selectBy(selectBy()
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
            .forView();
        q.run();
    }
}

Integer startCPU = Limits.getCpuTime();
for (Integer i = 0; i < 100; i++) {
    QueryTest test = new QueryTest();
    test.test();
}
Integer endCPU = Limits.getCpuTime();
System.debug(LoggingLevel.INFO, '(CPU): ' + (endCPU - startCPU));
