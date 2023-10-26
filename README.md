# Apex Query

![](https://img.shields.io/badge/version-2.0.0-brightgreen.svg) ![](https://img.shields.io/badge/build-passing-brightgreen.svg) ![](https://img.shields.io/badge/coverage-99%25-brightgreen.svg)

Using a query builder to build dynamic SOQL gives many advantages:

1. **More efficient**: No need to deal with string concatenation, and handsfree from handling binding variable names.
2. **Less error-prone**: APIs are carefully designed with strong types, cannot pass wrong values.

| Environment           | Installation Link                                                                                                                                         | Version |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| Production, Developer | <a target="_blank" href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04t2v000007OimYAAS"><img src="docs/images/deploy-button.png"></a> | ver 2.0 |
| Sandbox               | <a target="_blank" href="https://test.salesforce.com/packaging/installPackage.apexp?p0=04t2v000007OimYAAS"><img src="docs/images/deploy-button.png"></a>  | ver 2.0 |

### Online Articles

- [Advantages of Using SOQL Builder in Salesforce](https://medium.com/@jeff.jianfeng.jin/advantages-of-using-soql-builder-in-salesforce-9e82925a74b0) (medium link)

---

### Release v2.0.0

Small changes but they are breaking v1.x. However v1.x will be maintained in a separate branch for bug fixes, in case some projects don't want to upgrade.

1. Renamed the following types and methods, so the they are more consistent to their keyword counterparts and easy to remember.

   - `Query.Selector` -> `Query.SelectBy`

   - `Query.selector()` -> `Query.selectBy()`

   - `Query.Orderer` -> `Query.OrderBy`

   - `Query.orderer()` -> `Query.orderBy()`

   - `Query.Grouper` -> `Query.GroupBy`

   - `Query.grouper()` -> `Query.groupBy()`

2. Deprecated two functions `DISTANCE_IN_KM()` and `DISTANCE_IN_MI()`, but introduced `DISTANCE()`, which is more flexible since units are passed as parameters instead.

---

## Table of Contents

- [1. Design Principles](#1-design-principles)
- [2. Naming Conventions](#2-naming-conventions)
  - [2.1 Naming Readability](#21-naming-readability)
  - [2.2 Naming Confliction](#22-naming-confliction)
- [3. Overview](#3-overview)
  - [3.1 Query Class](#31-query-class)
  - [3.2 Query Execution](#32-query-execution)
- [4. Keywords](#4-keywords)
  - [4.1 From Statement](#41-from-statement)
  - [4.2 Select Statement](#42-select-statement)
  - [4.3 Where Statement](#43-where-statement)
  - [4.4 Order By Statement](#44-order-by-statement)
  - [4.5 Group By Statement](#45-group-by-statement)
- [5. Operators](#5-operators)
  - [5.1 Logical Operators](#51-logical-operators)
  - [5.2 Comparison Operators](#52-comparison-operators)
- [6. Functions](#6-functions)
  - [6.1 Aggregate Functions](#61-aggregate-functions)
  - [6.2 Date/Time Functions](#62-date-time-functions)
  - [6.3 Other Functions](#63-other-functions)
- [7. Literals](#7-literals)
  - [7.1 Date Literals](#71-date-literals)
  - [7.2 Currency Literals](#72-currency-literals)
- [8. License](#8-license)

## 1. Design Principles

1. **Highly Compatible**: Support all syntaxes and functions of SOQL, except the following syntaxes as of current state:

   - `USING SCOPE` statement.
   - `WITH [DATA CATEGORY]` statement.

2. **Highly Composable**: Clauses can be created standalone, then passed around, modified and composed into queries in a later stage.

   ```java
   Query.SelectBy selectBy = selectBy().add(Account.Id, Account.Name);
   Query.Filter filter = andx(
       gt(Account.AnnualRevenue, 2000),
       lt(Account.AnnualRevenue, 2000));
   Query.OrderBy orderBy = orderBy().add(Account.CreatedDate).descending().nullsLast();

   List<Account> accounts = (List<Account>) Query.of(Account.SObjecType)
       .selectBy(selectBy).filterBy(filter).orderBy(orderBy)
       .run();
   ```

3. **Value Objects**: Queries and all clauses are value objects, which means different query instances are considered equal when built with same parameters in the same order.

   ```java
   Assert.areEqual(
       Query.of(Account.SObjectType).selectBy(Account.Id, Account.Name)),
       Query.of(Account.SObjectType).selectBy(Account.Id, Account.Name))
   );
   ```

4. **Strong Types**: Strong types are enforced when possible, so developers can make less mistakes when construct queries.

   ```java
   // Example 1: date function can only be compared with an Integer.
   qt(CALENDAR_MONTH(Contact.Birthdate), 1);   // pass
   qt(CALENDAR_MONTH(Contact.Birthdate), 'A'); // fail
   ```

## 2. Naming Conventions

### 2.1 Naming Readability

Here are the naming conventions used to increase query readability:

|               | Description                                                                | Naming Convention | Reasoning                                                                                                                                             | Example                                                               |
| ------------- | -------------------------------------------------------------------------- | ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| **Keywords**  | These are backbone structures of a SOQL.                                   | camelCase         | Keywords should easily remind users to their SOQL counterparts.                                                                                       | `selectBy`, `filterBy`, `groupBy`, `havingBy`, `orderBy`              |
| **Operators** | These are mainly logical and comparison operators.                         | camelCase         | Operators should be small and short to be operator-like, abbreviation is used when appropriate.                                                       | `eq`, `ne`, `gt`, `gte`, `lt`, `lte`, `inx`, `nin`                    |
| **Functions** | These are used to perform aggregation, formatting, and date accessing etc. | UPPER_CASE        | This gives best readability, because it can be easily noticed when appearing among many lower case characters of field names, keywords and operators. | `COUNT`, `MAX`, `TO_LABEL`, `FORMAT`, `CALENDAR_MONTH`, `FISCAL_YEAR` |
| **Literals**  | There are only date and currency literals.                                 | UPPER_CASE        | Those are constant-like values, so static constant variable naming convention is preferred.                                                           | `LAST_90_DAYS()`, `LAST_N_DAYS(30)`, `USD(100)`, `CYN(888)`           |

### 2.2 Naming Confliction

Here are the naming conventions to avoid conflictions with existing keywords or operators.

1.  Use `<keyword>By()` format for SOQL keywords, such as `selectBy`, `filterBy`, `groupBy`, `havingBy`, `orderBy`.
2.  Use `<operator>x()` format for conflicted operators only, such as `orx()`, `andx()`, `inx()`, `likex()`. No need to memorize when to follow this pattern, the IDE will highlight there is a confliction, then you will know its time to add the x suffix.

## 3. Overview

### 3.1 Query Class

All operators and functions are built as static methods of the Query class, to reference them with a `Query` dot every time is tedious. When possible, please extend the `Query` class, where all static methods can be referenced directly. All examples in this README are written in such context.

```java
public with sharing class AccountQuery extends Query {
    public List<Account> listAccount() {
        return (List<Account>) Query.of(Account.SObjectType)
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
    }
}
```

### 3.2 Query Execution

There are three ways to invoke a `Query`. And by default they are running in system mode, `AccessLevel` can be supplied to change their running mode, i.e. `run(AccessLevel.USER_MODE)`.

|       | API            | API with Access Level     | Description                                                                              |
| ----- | -------------- | ------------------------- | ---------------------------------------------------------------------------------------- |
| **1** | `run()`        | `run(AccessLevel)`        | Return a `List<SObject>` from Salesforce database.                                       |
| **2** | `getLocator()` | `getLocator(AccessLevel)` | Return a `Database.QueryLocator` to be used by a batch class start method.               |
| **3** | `getCount()`   | `getCount(AccessLevel)`   | Return an integer of the number of records, must be used together with `SELECT COUNT()`. |

```java
List<Account> accounts = (List<Account>) Query.of(Account.SObjectType)
    .run();        // #1

Database.QueryLocator locator = Query.of(Account.SObjectType)
    .selectBy(Account.Name, Account.AnnualRevenue)
    .getLocator(); // #2

Integer count = Query.of(Account.SObjectType).selectBy(COUNT())
    .getCount();   // #3
```

## 4. Keywords

### 4.1 From Statement

All queries are created with a simple call to `Query.of(sobjectType)` API. A default `Id` field is used if no other fields are selected.

```java
// SELECT Id FROM Account
Query accountQuery = Query.of(Account.SOBjectType);
```

### 4.2 Select Statement

#### Inline Select

There are five types of `selectBy()` statements, each accept different input types. They can chain from one after another, so developers can select as many fields as they want.

|       | API                                                  | Description                                                                            |
| ----- | ---------------------------------------------------- | -------------------------------------------------------------------------------------- |
| **1** | `selectBy(SObjectField ... )`                        | Select `SObjectField`, up to 5 params are supported                                    |
| **2** | `selectBy(Function ... )`                            | Select functions, up to 5 params are supported.                                        |
| **3** | `selectBy(String ... )`                              | Select strings, up to 5 params are supported. Mainly used for parent field references. |
| **4** | `selectBy(String childRelationName, Query subQuery)` | Select subquery, a subquery is built in the same way as a standard query.              |
| **5** | `selectBy(List<Object>)`                             | Select a `List<Object>` mixing of fields, functions and strings, but not queries.      |

```java
Query accountQuery = Query.of(Account.SObjectType)
    // #1. all params are sobject fields
    .selectBy(Account.Name, Account.BillingCountry, Account.BillingState)
    // #2. all params are functions
    .selectBy(FORMAT(CONVERT_CURRENCY(Account.AnnualRevenue)), TO_LABEL('Owner.LocaleSidKey'))
    // #3. all params are strings
    .selectBy('Owner.Profile.Id', 'TOLABEL(Owner.EmailEncodingKey)')
    // #4. one subquery for child relationship "Contacts"
    .selectBy('Contacts', Query.of(Contact.SObjectType).selectBy(Contact.Name))
    // #5. a list of objects mixing with sobject fields, funcitons and strings
    .selectBy(new List<Object> { Account.Description, FORMAT(Account.CreatedDate), 'Owner.Name' });
```

#### Compose with SelectBy

Use a `selectBy()` to compose the field selection outside of a query. And one `SelectBy` can be added to another one for reuse.

```java
Query.SelectBy selectBy = Query.selectBy()
    .add(Account.Name, Account.BillingCountry, Account.BillingState)
    .add(FORMAT(CONVERT_CURRENCY(Account.AnnualRevenue)))
    .add('Contacts', Query.of(Contact.SObjectType).selectBy(Contact.Name));

Query.SelectBy anotherSelectBy = Query.selectBy()
    .add(Account.Description, Account.NumberOfEmployees)
    .add(selectBy);             // selectBy can be consumed by another selectBy

Query accountQuery = Query.of(Account.SObjectType)
    .selectBy(anotherSelectBy); // selectBy can be comsumed by a query
```

**Note**: If variable `selectBy` is modified later, it won't impact the `SelectBy` or queries composed earlier.

```java
selectBy.add(Account.CreatedDate);
// both anotherSelectBy and accountQuery are not impacted.
```

#### TYPEOF Select

Use `typeof()` to construct a SOQL TYPEOF statement.

1. Multiple `then()` methods can be chained to add more fields.
2. Multiple `when()` methods can be used for the same `SObjectType`.
3. Multiple `elsex()` methods can be chained to add more fields.
4. The `typeof()` can be create standalone outside of a query.

```java
Query accountQuery = Query.of(Task.SObjecType)
    .selectBy(typeof('What')
        .when(Account.SObjectType)
              .then(Account.Phone, Account.NumberOfEmployees)
        .when(Opportunity.SObjectType) // #1 multiple then methods can be chained
              .then(Opportunity.Amount, Opportunity.CloseDate)
              .then('ExpectedRevenue', 'Description')
        .when(Account.SObjectType)     // #2 previously used SObjectType can be used again
              .then(Account.BillingCountry, Account.BillingState)
        .elsex(Task.Id, Task.Status)
        .elsex('Email', 'Phone')       // #3 multiple elsex methods can be chained
    );

Query.TypeOf typeOfWhat = typeof(Task.SObjecType)
    .when().then().elsex() ... ;      // #4 TypeOf can be created standalone
```

| API                        | API with String      | Description                   |
| -------------------------- | -------------------- | ----------------------------- |
| `typeof(SObjectField)`     | `typeof(String)`     |                               |
| `when(SObjectType)`        |                      |                               |
| `then(SObjectField ... )`  | `then(String ... )`  | Up to 5 params are supported. |
| `elsex(SObjectField ... )` | `elsex(String ... )` | Up to 5 params are supported. |

### 4.3 Where Statement

The where statement method is called `filterBy()` but not ~~whereBy~~. Both comparison expression and logical statement are `Query.Filter` types, which can be supplied to the `filterBy(Filter filter)` API.

```java
Query accountQuery = Query.of(Account.SObjectType)
    .selectBy(Account.Name)
    .filterBy(gt(Account.AnnualRevenue, 2000)); // #1. a single comparison expression

Query accountQuery = Query.of(Account.SObjectType)
    .selectBy(Account.Name)
    .filterBy(andx()                            // #2. a single logical statement
        .add(gt(Account.AnnualRevenue, 2000))
        .add(lt(Account.AnnualRevenue, 6000))
    );
```

Each `Query` only supports a single method call to `filterBy()`. If there are multiple calls to `filterBy()` are made, the latter will override the former. This is because the filters used by where statement is a tree structure with a single root. Filters can be created and composed outside of the `Query` natively, and the following sections are going introduce two styles to compose them.

#### Traditional Composition

Many existing libraries use this kind of filter composition. One thing should take a note, if you prefer to use this style. The `orx`, `andx` only support adding 2 to 10 filters out of the box. When more filters need to be added, please use `orx(List<Filter> filters)` and `andx(List<Filter> filters)` APIs instead.

```java
Query.Filter filter = orx(
    andx( // only support up to 10 filters
        gt(Account.AnnualRevenue, 1000),
        eq(Account.BillingCountry, 'China'),
        eq(Account.BillingState, 'Beijing')
    ),
    andx(new List<Filter> {
        lt(Account.AnnualRevenue, 1000),
        eq(Account.BillingCountry, 'China'),
        eq(Account.BillingState, 'Shanghai')
    }));
```

#### Comma-free Composition

The above traditional composition style is more compact, while the following style gives one advantage: no trailing commas. So developers don't need to worry about when to add/remove them.

```java
Query.Filter filter = orx()
    .add(andx()
        .add(gt(Account.AnnualRevenue, 1000))
        .add(eq(Account.BillingCountry, 'China'))
        .add(eq(Account.BillingState, 'Beijing'))
    )
    .add(andx()
        .add(lt(Account.AnnualRevenue, 1000))
        .add(eq(Account.BillingCountry, 'China'))
        .add(eq(Account.BillingState, 'Shanghai'))
    );
```

#### Compare with Null

We can compare a field against null with `eqNull()` and `neNull()` operators. They are invented due to `eq()` and `ne()` only support strongly typed parameters, and cannot pass null values. And the `inx()` and `nin()` operators also support null checking.

```java
Query.Filter filter = andx()
    .add(eqNull(Account.BillingCountry))
    .add(neNull(Account.AnnualRevenue))
    .add(inx(Account.BillingState, new List<String> { 'Beijing', null }))
    .add(nin(Account.BillingState, new List<String> { 'Shanghai', null }))
);
```

#### Compare with List

In Apex Query, only `inx()`, `nin()` operators can be used to compare Id field against `List<SObject>`, but not `eq()` and `ne()`.

```java
List<Account> accounts = ... ; // some accounts queried elsewhere
List<Contact> contacts = List<Contact> Query.of(Contact.SObjectType)
    .selectBy(Contact.Id, Contact.Name)
    .filterBy(inx(Contact.AccountId, accounts))
    .run();
```

### 4.4 Order By Statement

#### Inline Order By

There are four types of `orderBy()` statements, each accepts different input types:

|       | API                         | Description                                                                                         |
| ----- | --------------------------- | --------------------------------------------------------------------------------------------------- |
| **1** | `orderBy(SObjectField ...)` | Accept only `SObjectField` as parameters. The number of params is from 1 to 5.                      |
| **2** | `orderBy(String ...)`       | Accept only `String` as parameters. The number of params is from 1 to 5.                            |
| **3** | `orderBy(Function ...)`     | Accept only functions as parameters, such as: `DISTANCE(...)`. The number of params is from 1 to 5. |
| **4** | `orderBy(List<Object>)`     | Accept a `List<Object>` mixing of fields, strings and functions.                                    |

**Note**: These `orderBy()` methods can chain from one to another, so developers can order by as many fields as they want.

```java
Query accountQuery = Query.of(Account.SObjectType)
    .selectBy(Account.Name)
    // #1. all params are fields
    .orderBy(Account.BillingCountry, Account.BillingState)
    // #2. all params are strings
    .orderBy('Owner.Profile.Name')
    // #3. all params are functions
    .orderBy(DISTANCE(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800), 'km'))
    // #4. a list of objects mixing of fields, strings and funcitons
    .orderBy(new List<Object>{ Account.BillingCountry, 'Owner.Profile.Name' });
```

Every `orderBy()` supports an optional trailing call to `descending()` and `nullsLast()`. Ordering fields are default to `ascending()` and `nullsFirst()` behaviors, you can but not necessarily to declare them explicitly. The ascending and nulls logic will be applied to all the fields or functions used by the previous `orderBy()` next to them. If different sorting logics need to be applied to each field, just separate them into different `orderBy()` methods.

```java
Query accountQuery = Query.of(Account.SObjectType)
    .selectBy(Account.Name)
    // fields are in the same ordering behavior
    .orderBy(Account.BillingCountry, Account.BillingState).descending().nullsLast();

Query accountQuery = Query.of(Account.SObjectType)
    .selectBy(Account.Name)
    // fields are in different ordering behaviors
    .orderBy(Account.BillingCountry).descending().nullsLast()
    .orderBy(Account.BillingState).ascending().nullsFirst();
```

#### Compose with OrderBy

Use a `orderBy()` to compose the field ordering logic outside of a query. And one `OrderBy` can be added to another one for reuse.

```java
Query.OrderBy orderBy = Query.orderBy()
    .add(DISTANCE(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800), 'km'));

Query.OrderBy anotherOrderBy = Query.orderBy()
    .add(Account.BillingCountry, Account.BillingState).descending().nullsLast()
    .add(orderBy);            // orderBy can be consumed by another orderBy

Query accountQuery = Query.of(Account.SObjectType)
    .selectBy(Account.Name)
    .orderBy(anotherOrderBy); // orderBy can be comsumed by a query
```

**Note**: If variable `orderBy` is modified later, it won't impact the `OrderBy` or queries composed earlier.

```java
orderBy.add(Account.CreatedDate);
// both anotherOrderBy and accountQuery are not impacted.
```

### 4.5 Group By Statement

#### Inline Group By

There are four types of `groupBy()` statements, each accepts different input types:

|       | API                         | Description                                                                                              |
| ----- | --------------------------- | -------------------------------------------------------------------------------------------------------- |
| **1** | `groupBy(SObjectField ...)` | Accept only `SObjectField` as parameters. The number of params is from 1 to 5.                           |
| **2** | `groupBy(String ...)`       | Accept only `String` as parameters. The number of params is from 1 to 5.                                 |
| **3** | `groupBy(Function ...)`     | Accept only functions as parameters, such as: `CALENDAR_YEAR(...)`. The number of params is from 1 to 5. |
| **4** | `groupBy(List<Object>)`     | Accept a `List<Object>` mixing of fields, strings and functions.                                         |

**Note**: These `groupBy()` methods can chain from one to another, so developers can group by as many fields as they want.

```java
Query accountQuery = Query.of(Account.SObjectType)
    .selectBy(AVG(Account.AnnualRevenue))
    .selectBy(SUM(Account.AnnualRevenue, 'summary')) // optional alias
    // #1. group by fields
    .groupBy(Account.BillingCountry, Account.BillingState)
    // #2. group by strings
    .groupBy('Owner.Profile.Name')
    // #3. group by date functions
    .groupBy(CALENDAR_YEAR(Account.CreatedDate))
    // #3. a list of objects mixing of fields, strings and functions
    .groupBy(new List<Object>{ Account.BillingCountry, 'Owner.Profile.Name' });
```

The aggregate results can be filtered and ordered with `havingBy()`. The `havingBy(Filter filter)` can be used in the same way as `filterBy()`, just supply a comparison expression or logical statement inside it.

```java
Query accountQuery = Query.of(Account.SObjectType)
    .selectBy(AVG(Account.AnnualRevenue), SUM(Account.AnnualRevenue))
    .groupBy(Account.BillingCountry, Account.BillingState).rollup()
    // aggerate result can be filtered
    .havingBy(gt(SUM(Account.AnnualRevenue), 2000))
    // aggerate result can be ordered
    .orderBy(AVG(Account.AnnualRevenue), SUM(Account.AnnualRevenue));
```

Optional `rollup()` or `cube()` methods can be invoked on the query to generate sub totals and grand totals.

```java
Query accountQuery = Query.of(Account.SObjectType)
    .selectBy(AVG(Account.AnnualRevenue), SUM(Account.AnnualRevenue))
    .groupBy(Account.BillingCountry, Account.BillingState)
    .rollup();
```

#### Compose with GroupBy

Use a `groupBy()` to compose the the field grouping outside of a query. And one `GroupBy` can be added to another one for reuse.

```java
Query.GroupBy groupBy = Query.groupBy()
    .add(CALENDAR_YEAR(Account.CreatedDate));

Query.GroupBy anotherGroupBy = Query.groupBy()
	.add(Account.BillingCountry, Account.BillingState)
    .add(groupBy);            // groupBy can be consumed by another groupBy

Query accountQuery = Query.of(Account.SObjectType)
    .selectBy(AVG(Account.AnnualRevenue), SUM(Account.AnnualRevenue))
    .groupBy(anotherGroupBy); // groupBy can be comsumed by a query
```

**Note**: If variable `groupBy` is modified later, it won't impact the `GroupBy` or queries composed earlier.

```java
groupBy.add(DAY_ONLY(CONVERT_TIMEZONE(Account.CreatedDate)));
// both anotherGroupBy and accountQuery are not impacted.
```

### 4.6 Other Statement

| API                 | Generated Format  |
| ------------------- | ----------------- |
| `limitx(Integer n)` | `LIMIT n`         |
| `offset(Integer n)` | `OFFSET n`        |
| `forView()`         | `FOR VIEW`        |
| `forReference()`    | `FOR REFERENCE`   |
| `forUpdate()`       | `FOR UPDATE`      |
| `updateTracking()`  | `UPDATE TRACKING` |
| `updateViewstat()`  | `UPDATE VIEWSTAT` |

## 5. Operators

### 5.1 Logical Operators

There are three logical operators, each function the same as their SOQL counterparts.

```java
// traditional composition style
andx(filter1, filter2, filter3, filter4);
andx(new List<Filter> { filter1, filter2, filter3, filter4 });
// comma-free composition style
andx().add(filter1, filter2, filter3, filter4);
andx().add(filter1, filter2).add(filter3, filter4);
```

| AND                                                         | Generated Format                         |
| ----------------------------------------------------------- | ---------------------------------------- |
| `andx(Filter filter1, Filter filter2)`                      | `(filter1 AND filter2)`                  |
| `andx(Filter filter1, Filter filter2, ... Filter filter10)` | `(filter1 AND filter2 ... AND filter10)` |
| `andx(List<Filter> filters)`                                | `(filter1 AND filter2 ...)`              |
| `andx().add(Filter filter1).add(Filter filter2) ...`        | `(filter1 AND filter2 ...)`              |
| **OR**                                                      |                                          |
| `orx(Filter filter1, Filter filter2)`                       | `(filter1 OR filter2)`                   |
| `orx(Filter filter1, Filter filter2, ... Filter filter10)`  | `(filter1 OR filter2 ... OR filter10)`   |
| `orx(List<Filter> filters)`                                 | `(filter1 OR filter2 ...)`               |
| `orx().add(Filter filter1).add(Filter filter2) ...`         | `(filter1 OR filter2 ...)`               |
| **NOT**                                                     |                                          |
| `notx(Filter filter)`                                       | `NOT(filter)`                            |

### 5.2 Comparison Operators

As a rule of thumb, there are three different types can be used for `param`:

1. An `SObjectField` such as `Account.AnnualRevenue`.
2. An function for picklist label, date, distance and aggregation, i.e. `TO_LABEL(Account.AccountSource)`, `CALENDAR_MONTH(CreatedDate)`.
3. A string such as `'Owner.Profile.Name'`. This is mainly used for parent field referencing.

| SOQL Operators | Apex Query Operators                   | Generated Format                          |
| -------------- | -------------------------------------- | ----------------------------------------- |
| **=**          | `eq(param, value)`                     | `param = value`                           |
|                | `eqNull(param)`                        | `param = NULL`                            |
| **!=**         | `ne(param, value)`                     | `param != value`                          |
|                | `neNull(param)`                        | `param != NULL`                           |
| **\<**         | `lt(param, value)`                     | `param < value`                           |
| **\<=**        | `lte(param, value)`                    | `param <= value`                          |
| **\>**         | `gt(param, value)`                     | `param > value`                           |
| **\>=**        | `gte(param, value)`                    | `param >= value`                          |
|                | `between(param, minValue, maxValue)`   | `param >= minValue AND param <= maxValue` |
| **LIKE**       | `likex(param, value)`                  | `param LIKE value`                        |
| **NOT LIKE**   | `nlike(param, value)`                  | `(NOT param LIKE value)`                  |
| **IN**         | `inx(param, List<Object> values)`      | `param IN :values`                        |
| **NOT IN**     | `nin(param, List<Object> values)`      | `param NOT IN :values`                    |
| **INCLUDES**   | `includes(param, List<String> values)` | `param INCLUDES (:value1, :value2)`       |
| **EXCLUDES**   | `excludes(param, List<String> values)` | `param EXCLUDES (:value1, :value2)`       |

## 6. Functions

### 6.1 Aggregate Functions

| Static Methods                 | Generated Format              |
| ------------------------------ | ----------------------------- |
| `COUNT(field)`                 | `COUNT(field)`                |
| `COUNT(field, alias)`          | `COUNT(field) alias`          |
| `COUNT_DISTINCT(field)`        | `COUNT_DISTINCT(field)`       |
| `COUNT_DISTINCT(field, alias)` | `COUNT_DISTINCT(field) alias` |
| `GROUPING(field)`              | `GROUPING(field)`             |
| `GROUPING(field, alias)`       | `GROUPING(field) alias`       |
| `SUM(field)`                   | `SUM(field)`                  |
| `SUM(field, alias)`            | `SUM(field) alias`            |
| `AVG(field)`                   | `AVG(field)`                  |
| `AVG(field, alias)`            | `AVG(field) alias`            |
| `MAX(field)`                   | `MAX(field)`                  |
| `MAX(field, alias)`            | `MAX(field) alias`            |
| `MIN(field)`                   | `MIN(field)`                  |
| `MIN(field, alias)`            | `MIN(field) alias`            |

### 6.2 Date/Time Functions

The following functions operating on Date, Time and Datetime fields. **Note**: Date functions can only be used in where conditions, and group by statements. When used in group by, of course it can appear in select and having as well. Date functions cannot be used inside any other functions, as well as the above aggregate functions.

```java
Query accountQuery = Query.of(Opportunity.SObjectType)
    .selectBy(CALENDAR_YEAR(Opportunity.CreatedDate), SUM(Opportunity.Amount))
    .groupBy(CALENDAR_YEAR(Opportunity.CreatedDate));
```

| Static Methods            | Description                                                                                                          |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `CONVERT_TIMEZONE(field)` | Convert datetime fields to the user’s time zone. **Note**: You can only use `CONVERT_TIMEZONE()` in a date function. |
| `CALENDAR_MONTH(field)`   | Returns a number representing the calendar month of a date field.                                                    |
| `CALENDAR_QUARTER(field)` | Returns a number representing the calendar quarter of a date field.                                                  |
| `CALENDAR_YEAR(field)`    | Returns a number representing the calendar year of a date field.                                                     |
| `DAY_IN_MONTH(field)`     | Returns a number representing the day in the month of a date field.                                                  |
| `DAY_IN_WEEK(field)`      | Returns a number representing the day of the week for a date field.                                                  |
| `DAY_IN_YEAR(field)`      | Returns a number representing the day in the year for a date field.                                                  |
| `DAY_ONLY(field)`         | Returns a date representing the day portion of a datetime field.                                                     |
| `FISCAL_MONTH(field)`     | Returns a number representing the fiscal month of a date field.                                                      |
| `FISCAL_QUARTER(field)`   | Returns a number representing the fiscal quarter of a date field.                                                    |
| `FISCAL_YEAR(field)`      | Returns a number representing the fiscal year of a date field.                                                       |
| `HOUR_IN_DAY(field)`      | Returns a number representing the hour in the day for a datetime field.                                              |
| `WEEK_IN_MONTH(field)`    | Returns a number representing the week in the month for a date field.                                                |
| `WEEK_IN_YEAR(field)`     | Returns a number representing the week in the year for a date field.                                                 |

### 6.3 Other Functions

Here is an example how to generate a location-based comparison expression.

```java
Query.Filter filter = lt(DISTANCE(Account.ShippingAddreess, Location.newInstance(37.775000, -122.41800)), 20, 'km');
```

| Static Methods                               | Generated Format                                                |
| -------------------------------------------- | --------------------------------------------------------------- |
| `TO_LABEL(field) `                           | `TOLABEL(field)`                                                |
| `FORMAT(field)`                              | `FORMAT(field)`                                                 |
| `CONVERT_CURRENCY(field)`                    | `CONVERTCURRENCY(field)`                                        |
| `DISTANCE(field, Location geo, string unit)` | `DISTANCE(ShippingAddress, GEOLOCATION(37.775,-122.418), 'km')` |

## 7. Literals

### 7.1 Date Literals

Here are all the available date literals referenced from Salesforce ([link](https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_dateformats.htm)). They can be created with corresponding methods, and passed into comparison operators working with them.

```java
Query.Filter filter = orx()
    .add(eq(Account.CreatedDate, YESTERDAY()))
    .add(eq(Account.AnnualRevenual, LAST_N_DAYS(5)))
);
```

> `YESTERDAY()`, `TODAY()`, `TOMORROW()`, `LAST_WEEK()`, `THIS_WEEK()`, `NEXT_WEEK()`, `LAST_MONTH()`, `THIS_MONTH()`, `NEXT_MONTH()`, `LAST_90_DAYS()`, `NEXT_90_DAYS()`, `THIS_QUARTER()`, `LAST_QUARTER()`, `NEXT_QUARTER()`, `THIS_YEAR()`, `LAST_YEAR()`, `NEXT_YEAR()`, `THIS_FISCAL_QUARTER()`, `LAST_FISCAL_QUARTER()`, `NEXT_FISCAL_QUARTER()`, `THIS_FISCAL_YEAR()`, `LAST_FISCAL_YEAR()`, `NEXT_FISCAL_YEAR()`
>
> `LAST_N_DAYS(Integer n)`, `NEXT_N_DAYS(Integer n)`, `N_DAYS_AGO(Integer n)`, `NEXT_N_WEEKS(Integer n)`, `LAST_N_WEEKS(Integer n)`, `N_WEEKS_AGO(Integer n)`, `NEXT_N_MONTHS(Integer n)`, `LAST_N_MONTHS(Integer n)`, `N_MONTHS_AGO(Integer n)`, `NEXT_N_QUARTERS(Integer n)`, `LAST_N_QUARTERS(Integer n)`, `N_QUARTERS_AGO(Integer n)`, `NEXT_N_YEARS(Integer n)`, `LAST_N_YEARS(Integer n)`, `N_YEARS_AGO(Integer n)`, `NEXT_N_FISCAL_QUARTERS(Integer n)`, `N_FISCAL_QUARTERS_AGO(Integer n)`, `NEXT_N_FISCAL_YEARS(Integer n)`, `LAST_N_FISCAL_YEARS(Integer n)`, `N_FISCAL_YEARS_AGO(Integer n)`

### 7.2 Currency Literals

Here are all the available currency ISO codes referenced from Salesforce ([link](https://help.salesforce.com/s/articleView?language=en_US&id=sf.admin_supported_currencies.htm)). They can be created with corresponding methods, and passed into comparison operators working with them.

```java
Query.Filter filter = orx()
    .add(eq(Account.AnnualRevenual, USD(2000)))
    .add(eq(Account.AnnualRevenual, CNY(2000)))
    .add(eq(Account.AnnualRevenual, CURRENCY('TRY', 2000)))
);
```

**NOTE**: TRY is an Apex keyword, so it can not have a corresponding method, instead TRY currency can be generated with a general `CURRENCY` method. In case Salesforce is introducing new currencies, which are not ported into the library, `CURRENCY` method can be used temporarily as well.

> AED, AFN, ALL, AMD, ANG, AOA, ARS, AUD, AWG, AZN, BAM, BBD, BDT, BGN, BHD, BIF, BMD, BND, BOB, BRL, BSD, BTN, BWP, BYN, BZD, CAD, CDF, CHF, CLP, CNY, COP, CRC, CSD, CUP, CVE, CZK, DJF, DKK, DOP, DZD, EGP, ERN, ETB, EUR, FJD, FKP, GBP, GEL, GHS, GIP, GMD, GNF, GTQ, GYD, HKD, HNL, HRK, HTG, HUF, IDR, ILS, INR, IQD, IRR, ISK, JMD, JOD, JPY, KES, KGS, KHR, KMF, KPW, KRW, KWD, KYD, KZT, LAK, LBP, LKR, LRD, LYD, MAD, MDL, MGA, MKD, MMK, MOP, MRU, MUR, MWK, MXN, MYR, MZN, NAD, NGN, NIO, NOK, NPR, NZD, OMR, PAB, PEN, PGK, PHP, PKR, PLN, PYG, QAR, RON, RSD, RUB, RWF, SAR, SBD, SCR, SDG, SEK, SGD, SHP, SLE, SLL, SOS, SRD, STN, SYP, SZL, THB, TJS, TND, TOP, ~~TRY~~, TTD, TWD, TZS, UAH, UGX, USD, UYU, UZS, VES, VND, VUV, WST, XAF, XCD, XOF, XPF, YER, ZAR

## 8. **License**

Apache 2.0
