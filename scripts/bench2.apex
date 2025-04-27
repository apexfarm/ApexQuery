class QueryTest extends Query {
    public void test() {
        // prettier-ignore
        Query parentAccount = Query.of('Account')
            .selectFields('Name', FORMAT(CONVERT_CURRENCY('AnnualRevenue')), 'BillingState')
            .selectParent('Parent', Query.of('Account').selectFields('Name', 'AnnualRevenue', 'BillingState'));

        // prettier-ignore
        Query q = Query.of('Account')
            .selectFields('Name', CONVERT_CURRENCY('AnnualRevenue'), 'BillingState')
            .selectParent('Parent', parentAccount)
            .selectChild('Contacts', Query.of('Contact').selectFields('Name'))
            .whereBy(orx()
                .add(andx()
                    .add(gt('AnnualRevenue', CNY(1000)))
                    .add(eq('BillingCountry', 'China'))
                    .add(eq('BillingState', 'Beijing'))
                    .add(includes('Industry', new List<String>{'Finance', 'Insurance'}))
                )
                .add(andx()
                    .add(lt('AnnualRevenue', CNY(1000)))
                    .add(eq('BillingCountry', 'China'))
                    .add(eq('BillingState', 'Shanghai'))
                )
            )
            .groupBy('Name', CALENDAR_MONTH('createdDate'), 'BillingState')
            .havingBy(gt(SUM('AnnualRevenue'), CNY(1000)))
            .orderBy(orderBy('Name').ascending().nullsLast(), orderBy('AnnualRevenue').descending())
            .limitx(10)
            .forView();
        System.debug(q.build());
    }
}

Integer startCPU = Limits.getCpuTime();
for (Integer i = 0; i < 1; i++) {
    QueryTest test = new QueryTest();
    test.test();
}
Integer endCPU = Limits.getCpuTime();
System.debug(LoggingLevel.INFO, '(CPU): ' + (endCPU - startCPU));
