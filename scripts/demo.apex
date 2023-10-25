// prettier-ignore
public List<Account> findAccounts(
    List<Id> accountIds,
    String countryName,
    Decimal minAmount,
    Decimal maxAmount
) {
    Query.Selector selector = selector()
        .add(Account.Name, Account.BillingCountry, Account.BillingState)
        .add(FORMAT(CONVERT_CURRENCY(Account.AnnualRevenue)))
        .add('Contacts', Query.of(Contact.SObjectType).selectBy('Name'));

    Query.Filter filter = andx()
        .add(inx(Account.Id, accountIds))
        .add(between(Account.AnnualRevenue, USD(minAmount), USD(maxAmount)))
        .add(eq(Account.BillingCountry, countryName));

    Query.Orderer orderer = orderer()
        .add(Account.AnnualRevenue)
        .descending()
        .nullsLast();

    return (List<Account>) Query.of(Account.SObjectType)
        .selectBy(selector)
        .filterBy(filter)
        .orderBy(orderer)
        .run();
}
// prettier-ignore
public List<Account> listAccounts(String Country, Decimal minAmount, Decimal maxAmount) {
    String query = 'SELECT ' +
        '    Name, BillingCountry, BillingState, ' +
        '    FORMAT(CONVERT_CURRENCY(AnnualRevenue)), ' +
        '    (SELECT Name FROM Contacts) ' +
        'FROM Account ' +
        'WHERE ' +
        '    Id IN :accountIds ' +
        '    AND (AnnualRevenue > USD' + minAmount + ' AND AnnualRevenue < USD'  + maxAmount + ') ' +
        '    AND BillingCountry = \'' + countryName + '\' ' +
        'ORDER BY AnnualRevenue DESC NULLS LAST';
    return Database.query(query);
}
// prettier-ignore
List<Account> accounts = [SELECT
    Name, BillingCountry, BillingState,
    FORMAT(CONVERT_CURRENCY(AnnualRevenue)),
    (SELECT Name FROM Contacts)
FROM Account
WHERE
    Id IN :accountIds
    AND (AnnualRevenue > USD1000 AND AnnualRevenue < USD2000)
    AND BillingCountry = 'China'
ORDER BY AnnualRevenue DESC NULLS LAST];
// prettier-ignore

public List<Account> findAccounts(
    List<Id> accountIds, String countryName,
    Decimal minAmount, Decimal maxAmount) {

    return (List<Account>) Query.of(Account.SObjectType)
        .selectBy(Account.Name, Account.BillingCountry, Account.BillingState)
        .selectBy(FORMAT(CONVERT_CURRENCY(Account.AnnualRevenue)))
        .selectBy('Contacts', Query.of(Contact.SObjectType).selectBy(Contact.Name))
        .filterBy(andx()
            .add(inx(Account.Id, accountIds))
            .add(between(Account.AnnualRevenue, USD(minAmount), USD(maxAmount)))
            .add(eq(Account.BillingCountry, countryName))
        )
        .orderBy(Account.AnnualRevenue).descending().nullsLast()
        .run();
}
String minAmount = 'CNY1000';
List<Id> accountIds = new List<Id>();

List<Account> accounts = [
    SELECT Name, BillingCountry, BillingState, FORMAT(CONVERTCURRENCY(AnnualRevenue)), (SELECT Name FROM Contacts)
    FROM Account
    WHERE Id IN :accountIds AND AnnualRevenue > :minAmount AND AnnualRevenue < CNY2000 AND BillingCountry = 'China'
    ORDER BY AnnualRevenue DESC NULLS LAST
];
