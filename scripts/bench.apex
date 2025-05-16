class QueryTest extends Query {
    public void test() {
        // prettier-ignore
        Query parentAccount = Query.of('Account')
            .selectBy('Name', format(convertCurrency('AnnualRevenue')), 'BillingState')
            .selectParent('Parent', Query.of('Account').selectBy('Name', 'AnnualRevenue', 'BillingState'));

        // prettier-ignore
        Query q = Query.of('Account')
            .selectBy('Name', convertCurrency('AnnualRevenue'), 'BillingState')
            .selectParent('Parent', parentAccount)
            .selectChildren('Contacts', Query.of('Contact').selectBy('Name'))
            .whereBy(orx()
                .add(andx()
                    .add(gt('AnnualRevenue', CURRENCY('CNY', 1000)))
                    .add(eq('BillingCountry', 'China'))
                    .add(eq('BillingState', 'Beijing'))
                )
                .add(andx()
                    .add(lt('AnnualRevenue', CURRENCY('CNY', 1000)))
                    .add(eq('BillingCountry', 'China'))
                    .add(eq('BillingState', 'Shanghai'))
                )
            )
            // .groupBy('Name', calendarMonth('createdDate'), 'BillingState')
            // .havingBy(gt(SUM('AnnualRevenue'), CURRENCY('CNY', 1000)))
            .orderBy(orderBy('Name').ascending().nullsLast(), orderBy('AnnualRevenue').descending())
            .limitx(10)
            .forView();
        System.debug(q.buildSOQL());
        System.debug(q.run());
    }
}

Integer startCPU = Limits.getCpuTime();
for (Integer i = 0; i < 1; i++) {
    QueryTest test = new QueryTest();
    test.test();
}
Integer endCPU = Limits.getCpuTime();
System.debug(LoggingLevel.INFO, '(CPU): ' + (endCPU - startCPU));
