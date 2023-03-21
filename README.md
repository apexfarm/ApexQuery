# Apex Query

![](https://img.shields.io/badge/version-1.0.1-brightgreen.svg) ![](https://img.shields.io/badge/build-passing-brightgreen.svg) ![](https://img.shields.io/badge/coverage-98%25-brightgreen.svg)

Using a query builder to build dynamic SOQL gives many advantages:

1. **More efficient**: No need to deal with string concatenation, and handsfree from handling binding variable names.
2. **Less error-prone**: APIs are carefully designed with strong types, cannot pass wrong values.

| Environment           | Installation Link                                            | Version   |
| --------------------- | ------------------------------------------------------------ | --------- |
| Production, Developer | <a target="_blank" href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04t2v000007CfibAAC"><img src="docs/images/deploy-button.png"></a> | ver 1.0.1 |
| Sandbox               | <a target="_blank" href="https://test.salesforce.com/packaging/installPackage.apexp?p0=04t2v000007CfibAAC"><img src="docs/images/deploy-button.png"></a> | ver 1.0.1 |

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
- [5. Operator References](#5-operator-references)
  - [5.1 Logical Operators](#51-logical-operators)
  - [5.2 Comparison Operators](#52-comparison-operators)
- [6. Function References](#6-function-references)
  - [6.1 Aggregate Functions](#61-aggregate-functions)
  - [6.2 Date/Time Functions](#62-date-time-functions)
  - [6.3 Other Functions](#63-other-functions)
- [7. Literal References](#7-literal-references)
  - [7.1 Date Literals](#71-date-literals)
  - [7.2 Currency Literals](#72-currency-literals)
- [8. License](#8-license)

## 1. Design Principles

1. **Highly Compatible**: Support all syntaxes and functions of SOQL, except the following syntaxes as of current state:

   - `USING SCOPE` statement.
   - `WITH [DATA CATEGORY]` statement.

2. **Highly Composable**: Clauses can be created standalone, then passed around, modified and composed into queries in a later stage.

   ```java
   Query.Selector selector = selector().add(Account.Id, Account.Name);
   Query.Filter filter = andx(
       gt(Account.AnnualRevenue, 2000),
       lt(Account.AnnualRevenue, 2000));
   Query.Orderer orderer = orderer().add(Account.CreatedDate).descending().nullsLast();

   List<Account> accounts = (List<Account>) Query.of(Account.SObjecType)
       .selectBy(selector).filterBy(filter).orderBy(orderer)
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

<p align="center">
    <img src="./docs/images/query-sample-1.png#2023-03-19" width=650>
</p>

### 2.1 Naming Readability

Here are the naming conventions to increase query readability:

|               | Description                                                  | Naming Convention | Reasoning                                                    | Example                                                      |
| ------------- | ------------------------------------------------------------ | ----------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **Keywords**  | These are backbone structures of a SOQL.                     | camelCase         | Keywords should easily remind users to their SOQL counterparts. | `selectBy`, `filterBy`, `groupBy`, `havingBy`, `orderBy`     |
| **Operators** | These are mainly logical and comparison operators.           | camelCase         | Operators should be small and short to be operator-like, abbreviation is used when appropriate. | `eq`, `ne`, `gt`, `gte`, `lt`, `lte`, `inx`, `nin`           |
| **Functions** | These are used to perform aggregation, formatting, and date accessing etc. | UPPER_CASE        | This gives best readability, because it can be easily noticed when appear among many lower case characters of field names, keywords and operators. | `COUNT`, `MAX`, `TO_LABEL`, `FORMAT`, `CALENDAR_MONTH`, `FISCAL_YEAR` |
| **Literals**  | There are only date and currency literals.                   | UPPER_CASE        | Those are constant-like values, so static constant variable naming convention is preferred. | `LAST_90_DAYS()`, `LAST_N_DAYS(30)`, `USD(100)`, `CYN(888)`  |

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

|       | API            | API with Access Level      | Description                                                  |
| ----- | -------------- | -------------------------- | ------------------------------------------------------------ |
| **1** | ` run()`       | `run(AccessLevel)`         | Return a `List<SObject>` from Salesforce database.           |
| **2** | `getLocator()` | ` getLocator(AccessLevel)` | Return a `Database.QueryLocator` to be used by a batch class start method. |
| **3** | `getCount()`   | `getCount(AccessLevel)`    | Return an integer of the number of records, must be used together with `COUNT()`. |

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

Inline select will build the Query in one goal. There are five types of `selectBy()` statements, each accept different input types:

|       | API                                                        | Description                                                  |
| ----- | ---------------------------------------------------------- | ------------------------------------------------------------ |
| **1** | `Query selectBy(SObjectField ... )`                        | Select `SObjectField`, up to 5 params are supported          |
| **2** | `Query selectBy(Function ... )`                            | Select functions, up to 5 params are supported.              |
| **3** | `Query selectBy(String ... )`                              | Select strings, up to 5 params are supported. Mainly used for parent field references. |
| **4** | `Query selectBy(String childRelationName, Query subQuery)` | Select subquery, a subquery is built in the same way as a standard query. |
| **5** | `Query selectBy(List<Object>)`                             | Select a `List<Object>` mixing of `SObjectField`, functions or `String`, but not queries. |

**Note**: These `selectBy()` methods can chain from one after another, so developers can select as many fields as they want.

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
    // #5. a list of object mixing with sobject fields, funcitons and strings
    .selectBy(new List<Object> { Account.Description, FORMAT(Account.CreatedDate), 'Owner.Name' });
```


#### Outline Select

Use a `selector()` to compose the field selection outside of a query. And one selector can be added to another one for reuse. The selector `add` methods support the same inputs as the `selectBy()` introduced in the above section.

```java
Query.Selector selector = Query.selector()
    .add(Account.Name, Account.BillingCountry, Account.BillingState)
    .add(FORMAT(CONVERT_CURRENCY(Account.AnnualRevenue)))
    .add('Contacts', Query.of(Contact.SObjectType).selectBy(Contact.Name));

Query.Selector anotherSelector = Query.selector()
    .add(Account.Description, Account.NumberOfEmployees)
    .add(selector);             // selector can be consumed by another selector

Query query = Query.of(Account.SObjectType)
    .selectBy(anotherSelector); // selector can be comsumed by a query
```

#### TYPEOF Select

Use `typeof()` to construct a SOQL TYPEOF statement.

1. Multiple `then()` methods can be chained to add more fields.
2. Previously used `SObjectType` can be used by `when()` again, new fields will be added against the same `SObjectType`.
3. multiple `elsex()` methods can be chained to add more fields.
4. The `typeof()` can be create standalone outside fo a query.

```java
Query accountQuery = Query.of(Task.SObjecType)
    .selectBy(typeof('What')
        .when(Account.SObjectType)
              .then(Account.Phone, Account.NumberOfEmployees)
        .when(Opportunity.SObjectType) // #1 multiple then methods can be chained
              .then(Opportunity.Amount, Opportunity.CloseDate)
              .then(Opportunity.ExpectedRevenue, Opportunity.Description)
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

Each `Query` only supports a single method call to `filterBy()`. If there are multiple calls to `filterBy()` are made, the latter will override the former. This is because the filters used by where statement is a tree structure with a single root. Filters can be created and composed outside of the `Query` natively, the following sections introduce two styles to compose them.

#### Traditional Composition

Many existing library use this kind of filter composition. One thing you should take a note, if you are already getting used to this style. The `orx`, `andx` only support adding 2 to 10 filters out of the box. When more filters need to be added, please use `orx(List<Filter> filters)` and `andx(List<Filter> filters)` APIs instead.

```java
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
```

#### Comma-free Composition

The above traditional composition style is more compact, while the following style gives some other advantages:

1. No trailing commas. Developers don't need to worry about when to add/remove the trailing comma, when copy and move existing filters around, as well as when append new filters.
2. There can be unlimited number of `add()` methods chained one after another, developers don't need to create a `new List<Filter>`.

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

We can compare a field against null with `neNull()` and `eqNull()` operators. The `inx()` and `nin()` operators also support null checking.

```java
Query.Filter filter = andx()
    .add(neNull(Account.AnnualRevenue))
    .add(eqNull(Account.BillingCountry))
    .add(inx(Account.BillingState, new List<String> { 'Beijing', null }))
    .add(nin(Account.BillingState, new List<String> { 'Shanghai', null }))
);
```

#### Compare with List

In SOQL, equality operator `=` can be used to compare Id field against `ListM<SObject>`, this is working but not recommended. Suggest to use `IN` operator instead.

```java
// some accounts queried elsewhere
List<Account> accounts = ... ;

// Wrong: = is used
List<Contact> contacts = [SELECT Id, Name FROM Contact WHERE AccountId = :accounts];

// Correct: IN is used
List<Contact> contacts = [SELECT Id, Name FROM Contact WHERE AccountId IN :accounts];
```

And in Apex Query, only `inx`, `nin` operators can be used to compare Id field against `List<SObject>`, but not `eq` and `ne`.

```java
List<Account> accounts = ... ; // some accounts queried elsewhere
List<Contact> contacts = List<Contact> Query.of(Contact.SObjectType)
    .selectBy(Contact.Id, Contact.Name)
    .filterBy(inx(Contact.AccountId, accounts))
    .run();
```

### 4.4 Order By Statement

#### Inline Order By

There are two types of `orderBy()` statements, each accepts different input types:

1. Accept only `SObjectField` as parameters, such as: `Account.Name`. The number of params is from 1 to 5.
2. Accept only functions as parameters, such as: `DISTANCE_IN_KM(...)`. The number of params is from 1 to 5.

**Note**: These `orderBy()` methods can chain from one to another, so developers can order by as many fields as they want.

```java
Query accountQuery = Query.of(Account.SObjectType)
    .selectBy(Account.Name)
    // #1. all params are fields
    .orderBy(Account.BillingCountry, Account.BillingState)
    // #2. all params are functions
    .orderBy(DISTANCE_IN_KM(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800)));
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

#### Outline Order By

Use a `orderer()` to compose the field ordering logic outside of a query. And one orderer can be added to another one for reuse. The orderer `add` methods support the same inputs as the `orderBy()` introduced in the above section.

```java
Query.Orderer orderer = Query.orderer()
    .add(DISTANCE_IN_MI(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800)));

Query.Orderer anotherOrderer = Query.orderer()
    .add(Account.BillingCountry, Account.BillingState).descending().nullsLast()
    .add(orderer);            // orderer can be consumed by another orderer

Query accountQuery = Query.of(Account.SObjectType)
    .selectBy(Account.Name)
    .orderBy(anotherOrderer); // orderer can be comsumed by a query
```

### 4.5 Group By Statement

#### Inline Group By

There are two types of `groupBy()` statements, each accepts different input types:

1. Accept only `SObjectField` as parameters, such as: `Account.BillingCountry`. The number of params is from 1 to 5.
2. Accept only functions as parameters, such as: `CALENDAR_YEAR(Account.CreatedDate)`. The number of params is from 1 to 5.

**Note**: These `groupBy()` methods can chain from one to another, so developers can group by as many fields as they want.

```java
Query accountQuery = Query.of(Account.SObjectType)
    .selectBy(AVG(Account.AnnualRevenue))
    .selectBy(SUM(Account.AnnualRevenue, 'summary'))       // optional alias
    .groupBy(Account.BillingCountry, Account.BillingState) // group by fields
    .groupBy(CALENDAR_YEAR(Account.CreatedDate));          // group by dates
```

The aggregate results can be filtered and ordered. The `havingBy(Filter filter)` keyword can be used in the same way as `filterBy()`, just supply a comparison expression or logical statement inside it.

```java
Query accountQuery = Query.of(Account.SObjectType)
    .selectBy(AVG(Account.AnnualRevenue), SUM(Account.AnnualRevenue))
    .groupBy(Account.BillingCountry, Account.BillingState).rollup()
    // aggerate result can be filtered
    .havingBy(gt(SUM(Account.AnnualRevenue), 2000))
    // aggerate result can be ordered
    .orderBy(AVG(Account.AnnualRevenue), SUM(Account.AnnualRevenue));
```

Optional `rollup()` or `cube()` methods can be invoked on the query to generate sub total and grand total results.

```java
Query accountQuery = Query.of(Account.SObjectType)
    .selectBy(AVG(Account.AnnualRevenue), SUM(Account.AnnualRevenue))
    .groupBy(Account.BillingCountry, Account.BillingState)
    .rollup();
```

#### Outline Group By

Use a `grouper()` to compose the the field grouping outside of a query. And one grouper can be added to another one for reuse. The grouper `add` methods support the same inputs as the `groupBy()` introduced in the above section.

```java
Query.Grouper grouper = Query.grouper()
    .add(CALENDAR_YEAR(Account.CreatedDate));

Query.Grouper anotherGrouper = Query.grouper()
	.add(Account.BillingCountry, Account.BillingState)
    .add(grouper);            // grouper can be consumed by another grouper

Query accountQuery = Query.of(Account.SObjectType)
    .selectBy(AVG(Account.AnnualRevenue), SUM(Account.AnnualRevenue))
    .groupBy(anotherGrouper); // grouper can be comsumed by a query
```

## 5. Operator References

### 5.1 Logical Operators

There are three logical operators, each function the same as their SOQL counterparts. There are two ways to add filters inside an `andx()` and `orx()`.

```java
// all the followings are equivalent, the same apply to orx()
andx(filter1, filter2, filter3, filter4);
andx(new List<Filter> { filter1, filter2, filter3, filter4 });
andx().add(filter1, filter2, filter3, filter4);
andx().add(filter1, filter2).add(filter3, filter4);
```

| AND                                                               | Generated Format                         |
| ----------------------------------------------------------------- | ---------------------------------------- |
| `andx(Filter filter1, Filter filter2)`                            | `(filter1 AND filter2)`                  |
| `andx(Filter filter1, Filter filter2, ... Filter filter10)`       | `(filter1 AND filter2 ... AND filter10)` |
| `andx(List<Filter> filters)`                                      | `(filter1 AND filter2 ...)`              |
| `andx().add(Filter filter1, Filter filter2)`                      | `(filter1 AND filter2)`                  |
| `andx().add(Filter filter1, Filter filter2, ... Filter filter10)` | `(filter1 AND filter2 ... AND filter10)` |
| **OR**                                                            |                                          |
| `orx(Filter filter1, Filter filter2)`                             | `(filter1 OR filter2)`                   |
| `andx(Filter filter1, Filter filter2, ... Filter filter10)`       | `(filter1 OR filter2 ... OR filter10)`   |
| `orx().add(Filter filter1, Filter filter2)`                       | `(filter1 OR filter2)`                   |
| `orx().add(Filter filter1, Filter filter2, ... Filter filter10)`  | `(filter1 OR filter2 ... OR filter10)`   |
| **NOT**                                                           |                                          |
| `notx(Filter filter)`                                             | `NOT(filter)`                            |

### 5.2 Comparison Operators

Some of following params are not labeled with types, this is because they support multiple types. As a rule of thumb, there are three different types can be used for `param`:

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
| **INCLUDES**   | `includes(param, List<String> values)` | `param INCLUDES :values`                  |
| **EXCLUDES**   | `excludes(param, List<String> values)` | `param EXCLUDES :values`                  |

## 6. Function References

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
Query.Filter filter = lt(DISTANCE_IN_KM(Account.ShippingAddreess, Location.newInstance(37.775000, -122.41800)), 20);
```

| Static Methods                        | Generated Format                                                |
| ------------------------------------- | --------------------------------------------------------------- |
| `TO_LABEL(field) `                    | `TOLABEL(field)`                                                |
| `FORMAT(field)`                       | `FORMAT(field)`                                                 |
| `CONVERT_CURRENCY(field)`             | `CONVERTCURRENCY(field)`                                        |
| `DISTANCE_IN_KM(field, Location geo)` | `DISTANCE(ShippingAddress, GEOLOCATION(37.775,-122.418), 'km')` |
| `DISTANCE_IN_MI(field, Location geo)` | `DISTANCE(ShippingAddress, GEOLOCATION(37.775,-122.418), 'mi')` |

## 7. Literal References

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

**NOTE**: TRY is an Apex keyword, so it can not have a corresponding method, instead TRY currency can be generated with a general `CURRENCY` method. In case Salesforce is introducing new currencies, which are not ported into the library, `ISO` method can be used temporarily as well.

> AED, AFN, ALL, AMD, ANG, AOA, ARS, AUD, AWG, AZN, BAM, BBD, BDT, BGN, BHD, BIF, BMD, BND, BOB, BRL, BSD, BTN, BWP, BYN, BZD, CAD, CDF, CHF, CLP, CNY, COP, CRC, CSD, CUP, CVE, CZK, DJF, DKK, DOP, DZD, EGP, ERN, ETB, EUR, FJD, FKP, GBP, GEL, GHS, GIP, GMD, GNF, GTQ, GYD, HKD, HNL, HRK, HTG, HUF, IDR, ILS, INR, IQD, IRR, ISK, JMD, JOD, JPY, KES, KGS, KHR, KMF, KPW, KRW, KWD, KYD, KZT, LAK, LBP, LKR, LRD, LYD, MAD, MDL, MGA, MKD, MMK, MOP, MRU, MUR, MWK, MXN, MYR, MZN, NAD, NGN, NIO, NOK, NPR, NZD, OMR, PAB, PEN, PGK, PHP, PKR, PLN, PYG, QAR, RON, RSD, RUB, RWF, SAR, SBD, SCR, SDG, SEK, SGD, SHP, SLE, SLL, SOS, SRD, STN, SYP, SZL, THB, TJS, TND, TOP, ~~TRY~~, TTD, TWD, TZS, UAH, UGX, USD, UYU, UZS, VES, VND, VUV, WST, XAF, XCD, XOF, XPF, YER, ZAR

## 8. **License**

Apache 2.0
