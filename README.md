# Apex Query

![](https://img.shields.io/badge/version-3.0.0-brightgreen.svg) ![](https://img.shields.io/badge/build-passing-brightgreen.svg) ![](https://img.shields.io/badge/coverage-99%25-brightgreen.svg)

A query builder to build SOQL dynamically.

| Environment           | Installation Link                                                                                                                                         | Version |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| Production, Developer | <a target="_blank" href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04tGC000007TLzwYAG"><img src="docs/images/deploy-button.png"></a> | ver 3.0 |
| Sandbox               | <a target="_blank" href="https://test.salesforce.com/packaging/installPackage.apexp?p0=04tGC000007TLzwYAG"><img src="docs/images/deploy-button.png"></a>  | ver 3.0 |

---

### Release v3.0.0

v2.0 was too complex to maintain and use. v3.0 was trying to be simple, and by far it's the best outcome I can have. During the remake, I am getting started to feel string concatenations are also good options in some cases.

- **Key Updates**
  - Performance is improved by 30%. This isn't much compared a 7 vs 10 CPU time difference.
  - Strings become first class citizens. Most of the functions only return and accept strings now.
  - Rarely used features are removed, such as value object concepts.
- **New Features**:
  - [Query Chaining](#22-query-chaining)
  - [Query Template](#23-query-template)
- **Removed Features**
  - Removed `TYPEOF` statement, use a manually built long string instead.
  - Removed input parameter types of `SObjectType` and `SObjectField`, use `String` names instead.
  - Removed filter composition style: `andx(filter1, filter2)`, use `andx().add(filter1).add(filter2)` instead.
  - Removed currency literals such as `USD(100)`, use `CURRENCY('USD', 100)` instead.
- **API Changes**:
  - Normalized functions (i.e. `max()`) to return strings, instead of strong types.
  - Normalized filters (i.e. `eq()`) to accept objects, instead of strong types.
  - `eqNull` and `neNull` operators are removed, use `eq('Field', null)` and `ne('Field', null)` directly.
  - `Query.of(Account.SobjectType)` => `Query.of('Account')`
  - `Query.filterBy()` => `Query.whereBy()`
  - Rename functions with **camel case** instead of uppercase. for example:
    - `CONVERT_CURRENCY()` => `convertCurrency()`
    - `MAX()` => `max()`

---

## Table of Contents

- [1. Naming Conventions](#1-naming-conventions)
  - [1.1 Naming Readability](#11-naming-readability)
  - [1.2 Naming Confliction](#12-naming-confliction)
- [2. Overview](#2-overview)
  - [2.1 Query Class](#21-query-class)
  - [2.2 Query Chaining](#22-query-chaining)
  - [2.3 Query Template](#23-query-template)
  - [2.4 Query Execution](#24-query-execution)
- [3. Keywords](#3-keywords)
  - [3.1 From Statement](#31-from-statement)
  - [3.2 Select Statement](#32-select-statement)
  - [3.3 Where Statement](#33-where-statement)
  - [3.4 Order By Statement](#34-order-by-statement)
  - [3.5 Group By Statement](#35-group-by-statement)
  - [3.6 Other Keywords](#36-other-keywords)
- [4. Filters](#4-filters)
  - [4.1 Comparison Filter](#41-comparison-filter)
  - [4.2 Logical Filter](#42-logical-filter)
- [5. Functions](#5-functions)
  - [5.1 Aggregate Functions](#51-aggregate-functions)
  - [5.2 Date/Time Functions](#52-datetime-functions)
  - [5.3 Other Functions](#53-other-functions)
- [6. Literals](#6-literals)
  - [6.1 Date Literals](#61-date-literals)
  - [6.2 Currency Literals](#62-currency-literals)
- [7. License](#7-license)

## 1. Naming Conventions

### 1.1 Naming Readability

Here are the naming conventions used to increase query readability:

|               | Description                                                                | Naming Convention | Reasoning                                                                                       | Example                                                            |
| ------------- | -------------------------------------------------------------------------- | ----------------- | ----------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| **Keywords**  | These are backbone structures of a SOQL.                                   | camelCase         | Keywords should easily remind users to their SOQL counterparts.                                 | `selectBy`, `whereBy`, `groupBy`, `havingBy`, `orderBy`            |
| **Operators** | These are mainly logical and comparison operators.                         | lowercase         | Operators should be small and short to be operator-like, abbreviation is used when appropriate. | `eq`, `ne`, `gt`, `gte`, `lt`, `lte`, `inx`, `nin`                 |
| **Functions** | These are used to perform aggregation, formatting, and date accessing etc. | camelCase         | Camel cases are align with Apex method names, and easy to type.                                 | `count`, `max`, `toLabel`, `format`, `calendarMonth`, `fiscalYear` |
| **Literals**  | There are only date and currency literals.                                 | UPPER_CASE        | Those are constant-like values, so static constant variable naming convention is preferred.     | `LAST_90_DAYS()`, `LAST_N_DAYS(30)`, `CURRENCY('USD', 100)`        |

### 1.2 Naming Confliction

Here are the naming conventions to avoid conflictions with existing keywords or operators.

1.  Use `<keyword>By()` format for SOQL keywords, such as `selectBy`, `whereBy`, `groupBy`, `havingBy`, `orderBy`.
2.  Use `<operator>x()` format for conflicted operators only, such as `orx()`, `andx()`, `inx()`, `likex()`.

## 2. Overview

### 2.1 Query Class

All operators and functions are built as static methods of the Query class, to reference them with a `Query` dot every time is tedious. When possible, please extend the `Query` class, then all static methods can be referenced directly.

```java
public with sharing class AccountQuery extends Query {
    public List<Account> listAccount() {
        return (List<Account>) Query.of('Account')
            .selectBy('Name', toLabel('Industry'))
            .whereBy(orx()
                .add(andx()
                    .add(gt('AnnualRevenue', 1000))
                    .add(eq('BillingState', 'Beijing')))
                .add(andx()
                    .add(lt('AnnualRevenue', 1000))
                    .add(eq('BillingState', 'Shanghai')))
            )
            .orderBy(orderBy('AnnualRevenue').descending().nullsLast())
            .run();
    }
}
```

Equivalent to the following SOQL:

```sql
SELECT Name, toLabel(Industry)
FROM Account
WHERE ((AnnualRevenue > 1000 AND BillingState = 'Beijing')
    OR (AnnualRevenue < 1000 AND BillingState = 'Shanghai'))
ORDER BY AnnualRevenue DESC NULLS LAST
```

### 2.2 Query Chaining

The `Query` class can chain existing ones to compose their fields or statements together. However query composition doesn't support queries with group by clause.

```java
public with sharing class AccountQuery extends Query {
    public List<Account> listAccount() {
        Query parentQuery = Query.of('Account')
            .selectBy('Name', format(convertCurrency('AnnualRevenue')));
        Query childQuery = Query.of('Contact').selectBy('Name', 'Email');

        return (List<Account>) Query.of('Account')
            .selectBy('Name', toLabel('Industry'))
            .selectParent('Parent', parentQuery) // Parent Chaining
            .selectChild('Contacts', childQuery) // Child Chaining
            .run();
    }
}
```

Equivalent to the following SOQL:

```sql
SELECT Name, toLabel(Industry),
    Parent.Name, FORMAT(convertCurrency(Parent.AnnualRevenue)) -- Parent Chaining
    (SELECT Name, Email FROM Contacts)                         -- Child Chaining
FROM Account
```

Without query chaining, the following code can also achieve the same result.

```java
public with sharing class AccountQuery extends Query {
    public List<Account> listAccount() {
        return (List<Account>) Query.of('Account')
            .selectBy('Name', toLabel('Industry'),
                'Parent.Name', format(convertCurrency('Parent.AnnualRevenue')),
                '(SELECT Name, Email FROM Contacts)')
            .run();
    }
}
```

### 2.3 Query Template

When the same `Query` is intended to be run with different binding variables, the following pattern can be used. **Note**: Query template must be built with `var()` with binding var names.

```java
public with sharing class AccountQuery extends Query {
    public static Query accQuery {
        get {
            if (accQuery == null) {
                accQuery = Query.of('Account')
                    .selectBy('Name', toLabel('Industry'))
                    .selectChild('Contacts', Query.of('Contact')
                        .selectBy('Name', 'Email')
                        .whereBy(likex('Email', var('emailSuffix')))
                    )
                    .whereBy(andx()
                        .add(gt('AnnualRevenue', var('revenue')))
                        .add(eq('BillingState', var('state')))
                    );
            }
            return accQuery;
    	}
        set;
    }

    public List<Account> listAccount(String state, Decimal revenue) {
        System.debug(accQuery.buildSOQL());
        return (List<Account>) accQuery.run(new Map<String, Object> {
            'revenue' => revenue,
            'state' => state,
            'emailSuffix' => '%gmail.com'
        });
    }
}
```

Equivalent to the following SOQL:

```sql
SELECT Name, toLabel(Industry)
    (SELECT Name, Email FROM Contacts WHERE Email LIKE :emailSuffix)
FROM Account
WHERE (AnnualRevenue > :revenue AND BillingState = :state)
```

### 2.4 Query Execution

Execute with default `AccessLevel.SYSTEM_MODE`:

|       | API            | API with Binding Variables | Return Types                                            |
| ----- | -------------- | -------------------------- | ------------------------------------------------------- |
| **1** | `run()`        | `run(bindingVars)`         | `List<SObject>`                                         |
| **2** | `getLocator()` | `getLocator(bindingVars)`  | `Database.QueryLocator`                                 |
| **3** | `getCount()`   | `getCount(bindingVars)`    | `Integer`, must be used together with `SELECT COUNT()`. |

Execute with any `AccessLevel`, such as `AccessLevel.USER_MODE`:
| | API | API with Access Level | Return Types |
| ----- | ------------------------- | -------------------------------------- | ------------------------------------------------------- |
| **1** | `run(AccessLevel)` | `run(bindingVars, AccessLevel)` | `List<SObject>` |
| **2** | `getLocator(AccessLevel)` | `getLocator(bindingVars, AccessLevel)` | `Database.QueryLocator` |
| **3** | `getCount(AccessLevel)` | `getCount(bindingVars, AccessLevel)` | `Integer`, must be used together with `SELECT COUNT()`. |

## 3. Keywords

### 3.1 From Statement

All queries are created with a simple call to `Query.of(String objectName)` API. A default `Id` field is used if no other fields are selected.

```java
Query accountQuery = Query.of('Account');
```

Equivalent to the following SOQL:

```sql
SELECT Id FROM Account
```

### 3.2 Select Statement

|       | API                                                     | Description                                              |
| ----- | ------------------------------------------------------- | -------------------------------------------------------- |
| **1** | `selectBy(Object ... )`                                 | Select up to 10 field names or functions.                |
| **2** | `selectBy(List<Object>)`                                | Select a `List<Object>` of any field names or functions. |
| **3** | `selectParent(String relationshipName, Query subQuery)` | Parent chaining.                                         |
| **4** | `selectChild(String relationshipName, Query subQuery)`  | Child chaining.                                          |

```java
Query accountQuery = Query.of('Account')
    .selectBy('Name', toLabel('Industry'))
    .selectBy(new List<Object> { 'Owner.Name', FORMAT('CreatedDate') })
    .selectParent('Parent', Query.of('Account')
        .selectBy('Name', format(convertCurrency('AnnualRevenue'))))
    .selectChild('Contacts', Query.of('Contact').selectBy('Name', 'Email'));
```

Equivalent to the following SOQL:

```sql
SELECT Name, toLabel(Industry),
    Owner.Name, FORMAT(CreatedDate)
    Parent.Name, FORMAT(convertCurrency(Parent.AnnualRevenue)) -- Parent Chaining
    (SELECT Name, Email FROM Contacts)                         -- Child Chaining
FROM Account
```

### 3.3 Where Statement

`whereBy(Filter filter)` API accepts either a comparison expression or a logical statement.

```java
Query accountQuery = Query.of('Account')
    .selectBy('Name')
    .whereBy(gt('AnnualRevenue', 2000)); // #1. comparison filter

Query accountQuery = Query.of('Account')
    .selectBy('Name')
    .whereBy(andx()                      // #2. logical filter
        .add(gt('AnnualRevenue', 2000))
        .add(lt('AnnualRevenue', 6000))
    );
```

### 3.4 Order By Statement

|       | API                           | Description                       |
| ----- | ----------------------------- | --------------------------------- |
| **1** | `orderBy(OrderByField...)`    | Order by up to 10 `OrderByField`. |
| **2** | `orderBy(List<OrderByField>)` | Order by `List<OrderByField>`.    |

```java
Query accountQuery = Query.of('Account')
    .selectBy('Name', toLabel('Industry'))
    .orderBy(
        orderBy('BillingCountry').descending().nullsLast(), // OrderByField
        orderBy(DISTANCE('ShippingAddress',
            Location.newInstance(37.775000, -122.41800), 'km'))
    )
    .orderBy(new List<OrderByField>{ orderBy('Owner.Profile.Name') });
```

Equivalent to the following SOQL:

```sql
SELECT Name, toLabel(Industry)
FROM Account
ORDER BY BillingCountry DESC NULLS LAST,
    (DISTANCE(ShippingAddress, GEOLOCATION(37.775001, -122.41801), 'km'),
    Owner.Profile.Name
```

### 3.5 Group By Statement

|       | API                     | Description                     |
| ----- | ----------------------- | ------------------------------- |
| **1** | `groupBy(String ...)`   | Group by up to 10 field names.  |
| **2** | `groupBy(List<String>)` | Group by `List` of field names. |

```java
Query accountQuery = Query.of('Account')
    .selectBy(avg('AnnualRevenue'))
    .selectBy(sum('AnnualRevenue', 'RevenueSUM')) // optional alias
    .groupBy('BillingCountry', calendarYear('CreatedDate'))
    .groupBy(new List<String>{ calendarMonth('CreatedDate') });
```

Equivalent to the following SOQL:

```sql
SELECT AVG(AnnualRevenue), SUM(AnnualRevenue) RevenueSUM
FROM Account
GROUP BY BillingCountry, CALENDAR_YEAR(CreatedDate), CALENDAR_MONTH(CreatedDate)
```

#### Having Clause

The aggregate results can be filtered and ordered with `havingBy()` and `orderBy()`. `havingBy(Filter filter)` can be used in the same way as `whereBy()`.

```java
Query accountQuery = Query.of('Account')
    .selectBy(avg('AnnualRevenue'), sum('AnnualRevenue'))
    .groupBy('BillingCountry', 'BillingState')
    .rollup()
    .havingBy(gt(sum('AnnualRevenue'), 2000))
    .orderBy(orderBy(avg('AnnualRevenue')), orderBy(sum('AnnualRevenue')));
```

Equivalent to the following SOQL:

```sql
SELECT AVG(AnnualRevenue), SUM(AnnualRevenue)
FROM Account
GROUP BY ROLLUP(BillingCountry, BillingState)
HAVING SUM(AnnualRevenue) > 2000
ORDER BY AVG(AnnualRevenue), SUM(AnnualRevenue)
```

#### Rollup Summary

Optional `rollup()` or `cube()` methods can be invoked on the query to generate sub totals or grand totals.

```java
Query accountQuery = Query.of('Account')
    .selectBy(AVG('AnnualRevenue'), SUM('AnnualRevenue'))
    .groupBy('BillingCountry', 'BillingState')
    .rollup();
```

### 3.6 Other Keywords

| API                 | Generated Format  |
| ------------------- | ----------------- |
| `limitx(Integer n)` | `LIMIT n`         |
| `offset(Integer n)` | `OFFSET n`        |
| `forView()`         | `FOR VIEW`        |
| `forReference()`    | `FOR REFERENCE`   |
| `forUpdate()`       | `FOR UPDATE`      |
| `updateTracking()`  | `UPDATE TRACKING` |
| `updateViewstat()`  | `UPDATE VIEWSTAT` |

## 4. Filters

### 4.1 Comparison Filter

| SOQL Operators | Apex Query Operators                   | Generated Format                          |
| -------------- | -------------------------------------- | ----------------------------------------- |
| **=**          | `eq(param, value)`                     | `param = value`                           |
| **!=**         | `ne(param, value)`                     | `param != value`                          |
| **\<**         | `lt(param, value)`                     | `param < value`                           |
| **\<=**        | `lte(param, value)`                    | `param <= value`                          |
| **\>**         | `gt(param, value)`                     | `param > value`                           |
| **\>=**        | `gte(param, value)`                    | `param >= value`                          |
| **BETWEEN**    | `between(param, minValue, maxValue)`   | `param >= minValue AND param <= maxValue` |
| **LIKE**       | `likex(param, String value)`           | `param LIKE value`                        |
| **NOT LIKE**   | `nlike(param, String value)`           | `(NOT param LIKE value)`                  |
| **IN**         | `inx(param, List<Object> values)`      | `param IN :values`                        |
| **NOT IN**     | `nin(param, List<Object> values)`      | `param NOT IN :values`                    |
| **INCLUDES**   | `includes(param, List<String> values)` | `param INCLUDES (:value1, :value2)`       |
| **EXCLUDES**   | `excludes(param, List<String> values)` | `param EXCLUDES (:value1, :value2)`       |

As a rule of thumb, the first param can be:

1. Field names such as `AnnualRevenue`, `'Owner.Profile.Name'`.
2. Functions returning `String` such as
   - date function `calendarMonth('CreatedDate')`
   - distance function `distance('ShippingAddress', Location.newInstance(37.775001, -122.41801), 'km')`
   - aggregate function `sum('AnnualRevenue')`

And it cannot be `toLabel()` function, instead use `eq('toLabel(Industry)', 'Algriculture')` directly.

#### Compare with sObject List

`inx()`, `nin()` operators can also be used to compare an Id field against `List<SObject>`.

```java
List<Account> accounts = ... ; // some accounts queried elsewhere
List<Contact> contacts = List<Contact> Query.of('Contact')
    .selectBy('Name', toLabel('Account.Industry'))
    .whereBy(inx('AccountId', accounts))
    .run();
```

Equivalent to the following SOQL:

```sql
SELECT Name, toLabel(Account.Industry)
FROM Contact
WHERE AccountId IN :accounts
```

### 4.2 Logical Filter

| AND                                                  | Generated Format            |
| ---------------------------------------------------- | --------------------------- |
| `andx().add(Filter filter1).add(Filter filter2) ...` | `(filter1 AND filter2 ...)` |
| `andx().addAll(List<Filter> filters)`                | `(filter1 AND filter2 ...)` |
| **OR**                                               |                             |
| `orx().add(Filter filter1).add(Filter filter2) ...`  | `(filter1 OR filter2 ...)`  |
| `orx().addAll(List<Filter> filters)`                 | `(filter1 OR filter2 ...)`  |
| **NOT**                                              |                             |
| `notx(Filter filter)`                                | `NOT(filter)`               |

The following codes demonstrate various ways to compose a filter.

```java
Query.Filter revenueGreaterThan = gt('AnnualRevenue', 1000);

Query.LogicalFilter shanghaiRevenueLessThan = andx().addAll(new List<Filter> {
        lt('AnnualRevenue', 1000),
        eq('BillingState', 'Shanghai')
    });

Query.LogicalFilter orFilter = orx()
    .add(andx()
        .add(revenueGreaterThan)
        .add(eq('BillingState', 'Beijing'))
    )
    .add(shanghaiRevenueLessThan));
```

Equivalent to the following SOQL:

```sql
(AnnualRevenue > 1000 AND BillingState = 'Beijing')
OR (AnnualRevenue < 1000 AND BillingState = 'Shanghai')
```

## 5. Functions

### 5.1 Aggregate Functions

| Static Methods                | Generated Format              |
| ----------------------------- | ----------------------------- |
| `count(field)`                | `COUNT(field)`                |
| `count(field, alias)`         | `COUNT(field) alias`          |
| `countDistinct(field)`        | `COUNT_DISTINCT(field)`       |
| `countDistinct(field, alias)` | `COUNT_DISTINCT(field) alias` |
| `grouping(field)`             | `GROUPING(field)`             |
| `grouping(field, alias)`      | `GROUPING(field) alias`       |
| `sum(field)`                  | `SUM(field)`                  |
| `sum(field, alias)`           | `SUM(field) alias`            |
| `avg(field)`                  | `AVG(field)`                  |
| `avg(field, alias)`           | `AVG(field) alias`            |
| `max(field)`                  | `MAX(field)`                  |
| `max(field, alias)`           | `MAX(field) alias`            |
| `min(field)`                  | `MIN(field)`                  |
| `min(field, alias)`           | `MIN(field) alias`            |

### 5.2 Date/Time Functions

The following functions operating on Date, Time and Datetime fields.

```java
Query.of('Opportunity')
    .selectBy(calendarYear('CreatedDate'), SUM('Amount'))
    .whereBy(gt(calendarYear('CreatedDate'), 2000))
    .groupBy(calendarYear('CreatedDate'));
```

Equivalent to the following SOQL:

```sql
SELECT CALENDAR_YEAR(CreatedDate), SUM(Amount)
FROM Opportunity
WHERE CALENDAR_YEAR(CreatedDate) > 2000
GROUP BY CALENDAR_YEAR(CreatedDate)
```

| Static Methods           | Description                                                                                                                          |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| `convertTimezone(field)` | Convert datetime fields to the user’s time zone. **Note**: You can only use `convertTimezone()` inside the following date functions. |
| `calendarMonth(field)`   | Returns a number representing the calendar month of a date field.                                                                    |
| `calendarQuarter(field)` | Returns a number representing the calendar quarter of a date field.                                                                  |
| `calendarYear(field)`    | Returns a number representing the calendar year of a date field.                                                                     |
| `dayInMonth(field)`      | Returns a number representing the day in the month of a date field.                                                                  |
| `dayInWeek(field)`       | Returns a number representing the day of the week for a date field.                                                                  |
| `dayInYear(field)`       | Returns a number representing the day in the year for a date field.                                                                  |
| `dayOnly(field)`         | Returns a date representing the day portion of a datetime field.                                                                     |
| `fiscalMonth(field)`     | Returns a number representing the fiscal month of a date field.                                                                      |
| `fiscalQuarter(field)`   | Returns a number representing the fiscal quarter of a date field.                                                                    |
| `fiscalYear(field)`      | Returns a number representing the fiscal year of a date field.                                                                       |
| `hourInDay(field)`       | Returns a number representing the hour in the day for a datetime field.                                                              |
| `weekInMonth(field)`     | Returns a number representing the week in the month for a date field.                                                                |
| `weekInYear(field)`      | Returns a number representing the week in the year for a date field.                                                                 |

### 5.3 Other Functions

Here is an example how to generate a location-based comparison expression.

```java
Query.Filter filter = lt(distance('ShippingAddreess', Location.newInstance(37.775000, -122.41800)), 20, 'km');
```

| Static Methods                               | Generated Format                                                           |
| -------------------------------------------- | -------------------------------------------------------------------------- |
| `toLabel(field) `                            | `toLabel(field)`                                                           |
| `format(field)`                              | `FORMAT(field)`                                                            |
| `convertCurrency(field)`                     | `convertCurrency(field)`. **Note**: It can also be used inside `format()`. |
| `distance(field, Location geo, string unit)` | `DISTANCE(ShippingAddress, GEOLOCATION(37.775,-122.418), 'km')`            |

## 6. Literals

### 6.1 Date Literals

Here are all the available date literals referenced from Salesforce ([link](https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_dateformats.htm)). They can be created with corresponding methods, and passed into comparison operators working with them.

```java
Query.Filter filter = andx()
    .add(eq('LastModifiedDate', YESTERDAY()))
    .add(gt('CreatedDate', LAST_N_DAYS(5)))
);
```

> `YESTERDAY()`, `TODAY()`, `TOMORROW()`, `LAST_WEEK()`, `THIS_WEEK()`, `NEXT_WEEK()`, `LAST_MONTH()`, `THIS_MONTH()`, `NEXT_MONTH()`, `LAST_90_DAYS()`, `NEXT_90_DAYS()`, `THIS_QUARTER()`, `LAST_QUARTER()`, `NEXT_QUARTER()`, `THIS_YEAR()`, `LAST_YEAR()`, `NEXT_YEAR()`, `THIS_FISCAL_QUARTER()`, `LAST_FISCAL_QUARTER()`, `NEXT_FISCAL_QUARTER()`, `THIS_FISCAL_YEAR()`, `LAST_FISCAL_YEAR()`, `NEXT_FISCAL_YEAR()`
>
> `LAST_N_DAYS(Integer n)`, `NEXT_N_DAYS(Integer n)`, `N_DAYS_AGO(Integer n)`, `NEXT_N_WEEKS(Integer n)`, `LAST_N_WEEKS(Integer n)`, `N_WEEKS_AGO(Integer n)`, `NEXT_N_MONTHS(Integer n)`, `LAST_N_MONTHS(Integer n)`, `N_MONTHS_AGO(Integer n)`, `NEXT_N_QUARTERS(Integer n)`, `LAST_N_QUARTERS(Integer n)`, `N_QUARTERS_AGO(Integer n)`, `NEXT_N_YEARS(Integer n)`, `LAST_N_YEARS(Integer n)`, `N_YEARS_AGO(Integer n)`, `NEXT_N_FISCAL_QUARTERS(Integer n)`, `N_FISCAL_QUARTERS_AGO(Integer n)`, `NEXT_N_FISCAL_YEARS(Integer n)`, `LAST_N_FISCAL_YEARS(Integer n)`, `N_FISCAL_YEARS_AGO(Integer n)`

### 6.2 Currency Literals

```java
Query.Filter filter = orx()
    .add(eq('AnnualRevenual', CURRENCY('USD', 2000)))
    .add(eq('AnnualRevenual', CURRENCY('CNY', 2000)))
    .add(eq('AnnualRevenual', CURRENCY('TRY', 2000)))
);
```

## 7. **License**

Apache 2.0
