# Apex Query

![](https://img.shields.io/badge/version-1.0-brightgreen.svg) ![](https://img.shields.io/badge/build-passing-brightgreen.svg) ![](https://img.shields.io/badge/coverage-%3E95%25-brightgreen.svg)

An Apex SOQL query builder to dynamically build SOQL supporting almost all syntaxes.

| Environment           | Installation Link                                            | Version |
| --------------------- | ------------------------------------------------------------ | ------- |
| Production, Developer | <a target="_blank" href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04t2v000007CfgQAAS"><img src="docs/images/deploy-button.png"></a> | ver 1.0 |
| Sandbox               | <a target="_blank" href="https://test.salesforce.com/packaging/installPackage.apexp?p0=04t2v000007CfgQAAS"><img src="docs/images/deploy-button.png"></a> | ver 1.0 |

## Table of Contents





## 1. Design Principles

1. **Highly Compatible**: Support all syntaxes and features of SOQL, except the following features as of current state: 

   - `TYPEOF` statement.
   - `USING SCOPE` statement.
   - `WITH [DATA CATEGORY]` statement.

2. **Highly Composable**: Clauses can be created standalone for select, where, order by and group by statements. They can be passed around, modified, and composed into queries in a later stage. This is the sole reason we choose a query builder.

3. **Value Objects**: Queries and all clauses are value objects, which means different query instances are considered equal when built with same parameters in the same order.

   ```java
   // Queries for the same sObject and with same fields selected in the same order
   Assert.areEqual(
       Query.of(Account.SObjectType).selectBy(Account.Id, Account.Name)),
       Query.of(Account.SObjectType).selectBy(Account.Id, Account.Name))
   );
   ```

4. **Strong Types**: Strong types are enforced when possible, not only for the field parameters, but also for other inputs, so developers can make less mistakes when construct queries.

   ````java
   // Example 1: date function can only be compared with an Integer.
   qt(CALENDAR_MONTH(Contact.Birthdate), 1);   // pass
   qt(CALENDAR_MONTH(Contact.Birthdate), 'A'); // fail
   ````


## 2. Naming Conventions

<p align="center">
    <img src="./docs/images/query-sample-1.png#2023-03-19" width=700>
</p>

### 2.1 Readability

Here are the naming conventions to increase query readability:

|               | Description                                                  | Naming Convention | Reasoning                                                    | Examples                                                     |
| ------------- | ------------------------------------------------------------ | ----------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **Keywords**  | These are backbone structures of a SOQL.                     | camelCase         | Keywords should easily remind users to their SOQL counterparts. | `selectBy`, `filterBy`, `groupBy`, `havingBy`, `orderBy`     |
| **Operators** | These are mainly logical and comparison operators.           | lower case        | Operators should be small and short to be operator-like, therefore MongoDB operators are used as reference. | `eq`, `ne`, `gt`, `gte`, `lt`, `lte`, `inx`, `nin`           |
| **Functions** | These are used to perform aggregation, formatting, and date accessing etc. | UPPER_CASE        | This gives best readability, because it can be easily noticed when appear among many lower case characters of field names, keywords and operators. | `COUNT`, `MAX`, `TO_LABEL`, `FORMAT`, `CALENDAR_MONTH`, `FISCAL_YEAR` |
| **Literals**  | These are mainly date and currency literals.                 | UPPER_CASE        | Those are constant-like values, so static constant variable naming convention is preferred. | `LAST_90_DAYS()`, `LAST_N_DAYS(30)`, `USD(100)`, `CYN(888)`  |

### 2.2 Confliction

Here are the naming conventions to avoid conflictions with existing keywords or operators.

1.  Use `<keyword>By()` format for SOQL keywords, such as `selectBy`, `filterBy`, `groupBy`, `havingBy`, `orderBy`.
2. Use `<operator>x()` format for conflicted operators only, such as `orx()`, `andx()`, `inx()`, `likex()`. No need to memorize when to follow, the IDE will highlight there is a confliction, then you will know its time to add the x as suffix.  

## 3. Overview

### 3.1 Query Class

When possible, your classes can extend the `Query` class before using it to build queries. Because it gives advantages to not need add `Query` dot before all the static operators, functions and literals in order to reference them.

```java
public with sharing class AccountSelector extends Query {
    
}
```

Otherwise you have to add `Query` dot before them as the example below, which doesn't look bad anyway. All examples are default written in a class extending the `Query` class, except noticed.

```java
List<Account> accountList = (List<Account>) Query.of(Account.SObjectType)
    .selectBy(Account.Name, Account.BillingCountry, Account.BillingState)
    .selectBy(Query.FORMAT(Query.CONVERT_CURRENCY(Account.AnnualRevenue)))
    .selectBy('Contacts', Query.of(Contact.SObjectType).selectBy(Contact.Name))
    .filterBy(Query.andx()
        .add(Query.gt(Account.AnnualRevenue, 1000))
        .add(Query.eq(Account.BillingCountry, 'China'))
        .add(Query.eq(Account.BillingState, 'Beijing'))
    )
    .orderBy(Account.AnnualRevenue).descending().nullsLast()
    .run();
```

### 3.2 Chaining Order

The chaining order of an query doesn't have to be in the order as they defined in the SOQL, when executed each clause will be under its correct order. This gives advantages when query is built in multi-places.

### 3.3 Query Execution

An Id field will be added if no fields are selected.

## 4. Keywords

### 4.1 From  Statement

All queries are created with the a simple call to `Query.of(sobjectType)` API, which can be considered as the SOQL `from ` keyword counterpart.

```java
Query query = Query.of(Account.SOBjectType);
```

### 4.2 Select Statement

#### Inline Select

There are three types of `selectBy()` statements, each accepts different input types:

1. Accept only `SObjectField` as parameters, such as: `Account.Name`. The number of params is from 1 to 5.
2. Accept only functions as parameters, such as: `TO_LABEL(Account.AnnualRevenel)`. The number of params is from 1 to 5.
3. Accept a child relationship subquery as parameter.

**Note**: These `selectBy()` methods can chain from one to another, so developers can select as many fields as they want.

```java
Query query = Query.of(Account.SObjectType)
    // #1. all params are fields
    .selectBy(Account.Name, Account.BillingCountry, Account.BillingState)
    // #2. all params are functions
    .selectBy(FORMAT(CONVERT_CURRENCY(Account.AnnualRevenue)))
    // #3. one subquery for child relationship "Contacts"
    .selectBy('Contacts', Query.of(Contact.SObjectType).selectBy(Contact.Name));
```

#### Outline Select

Use a `selector()` to compose the field selection outside of a query. And one selector can be added to another one for reuse. The selector  `add` methods support the same inputs as the `selectBy()` introduced in the above section.

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

### 4.3 Where Statement

The where statement method is not called ~~whereBy~~ but `filterBy()`. Both comparison expression and logical statement are `Query.Filter` types, so they can be supplied to the `filterBy(Filter filter)` API.

```java
Query query = Query.of(Account.SObjectType)
	.selectBy(Account.Name)
	.filterBy(gt(Account.AnnualRevenue, 2000)); // #1. single comparison

Query query = Query.of(Account.SObjectType)
	.selectBy(Account.Name)
	.filterBy(andx()                            // #2. single logical statement
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

### 4.4 Order By Statement

#### Inline Order By

There are two types of `orderBy()` statements, each accepts different input types:

1. Accept only `SObjectField` as parameters, such as: `Account.Name`. The number of params is from 1 to 5.
2. Accept only functions as parameters, such as: `DISTANCE_IN_MILE(...)`. The number of params is from 1 to 5.

**Note**: These `orderBy()` methods can chain from one to another, so developers can order by as many fields as they want.

```java
Query query = Query.of(Account.SObjectType)
    .selectBy(Account.Name)
    // #1. all params are fields
    .orderBy(Account.BillingCountry, Account.BillingState)
    // #2. all params are functions
    .orderBy(DISTANCE_IN_MILE(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800)));
```

Every `orderBy()` supports an optional trailing call to `descending()` and `nullsLast()`. Ordering fields are default to `ascending()` and `nullsFirst()` behaviors, you can but not necessarily to declare them explicitly. The ascending and nulls logic will be applied to all the fields or functions used by the previous `orderBy()` next to them. If different sorting logics need to be applied to each field, just separate them into different `orderBy()` methods.

```java
Query query = Query.of(Account.SObjectType)
    .selectBy(Account.Name)
    // fields are in the same ordering behavior
    .orderBy(Account.BillingCountry, Account.BillingState).descending().nullsLast();

Query query = Query.of(Account.SObjectType)
    .selectBy(Account.Name)
    // fields are in different ordering behaviors
    .orderBy(Account.BillingCountry).descending().nullsLast()
    .orderBy(Account.BillingState).ascending().nullsFirst();
```

#### Outline Order By

Use a `orderer()` to compose the field ordering logic outside of a query. And one orderer can be added to another one for reuse. The orderer `add` methods support the same inputs as the `orderBy()` introduced in the above section.

```java
Query.Orderer orderer = Query.orderer()
    .orderBy(DISTANCE_IN_MILE(Account.ShippingAddress, Location.newInstance(37.775000, -122.41800)));

Query.Orderer anotherOrderer = Query.orderer()
    .orderBy(Account.BillingCountry, Account.BillingState).descending().nullsLast()
    .add(orderer);            // orderer can be consumed by another orderer

Query query = Query.of(Account.SObjectType)
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
Query query = Query.of(Account.SObjectType)
    .selectBy(AVG(Account.AnnualRevenue))
    .selectBy(SUM(Account.AnnualRevenue, 'summary'))       // optional alias
    .groupBy(Account.BillingCountry, Account.BillingState) // group by fields
    .groupBy(CALENDAR_YEAR(Account.CreatedDate));          // group by dates
```

The aggregate results can be filtered and ordered. The `havingBy(Filter filter)` keyword can be used in the same way as `filterBy()`, just supply a comparison expression or logical statement inside it.

```java
Query query = Query.of(Account.SObjectType)
    .selectBy(AVG(Account.AnnualRevenue), SUM(Account.AnnualRevenue))
    .groupBy(Account.BillingCountry, Account.BillingState).rollup()
    // aggerate result can be filtered
    .havingBy(gt(SUM(Account.AnnualRevenue), 2000))
    // aggerate result can be ordered
    .orderBy(AVG(Account.AnnualRevenue), SUM(Account.AnnualRevenue));
```

Optional `rollup()` or `cube()` methods can be invoked on the query to generate sub total and grand total results.

```java
Query query = Query.of(Account.SObjectType)
    .selectBy(AVG(Account.AnnualRevenue), SUM(Account.AnnualRevenue))
    .groupBy(Account.BillingCountry, Account.BillingState)
    .rollup();
```

#### Outline Group By

Use a `grouper()` to compose the the field grouping outside of a query. And one grouper can be added to another one for reuse. The grouper  `add` methods support the same inputs as the `groupBy()` introduced in the above section.

```java
Query.Grouper grouper = Query.grouper()
    .add(CALENDAR_YEAR(Account.CreatedDate));

Query.Grouper anotherGrouper = Query.grouper()
	.add(Account.BillingCountry, Account.BillingState)
    .add(grouper);            // grouper can be consumed by another grouper

Query query = Query.of(Account.SObjectType)
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

| AND                                                          | Generated Format                         |
| ------------------------------------------------------------ | ---------------------------------------- |
| `andx(Filter filter1, Filter filter2)`                       | `(filter1 AND filter2)`                  |
| `andx(Filter filter1, Filter filter2, ... Filter filter10)`  | `(filter1 AND filter2 ... AND filter10)` |
| `andx(List<Filter> filters)`                                 | `(filter1 AND filter2 ...)`              |
| `andx().add(Filter filter1, Filter filter2)`                 | `(filter1 AND filter2)`                  |
| `andx().add(Filter filter1, Filter filter2, ... Filter filter10)` | `(filter1 AND filter2 ... AND filter10)` |
| **OR**                                                       |                                          |
| `orx(Filter filter1, Filter filter2)`                        | `(filter1 OR filter2)`                   |
| `andx(Filter filter1, Filter filter2, ... Filter filter10)`  | `(filter1 OR filter2 ... OR filter10)`   |
| `orx().add(Filter filter1, Filter filter2)`                  | `(filter1 OR filter2)`                   |
| `orx().add(Filter filter1, Filter filter2, ... Filter filter10)` | `(filter1 OR filter2 ... OR filter10)`   |
| **NOT**                                                      |                                          |
| `notx(Filter filter)`                                        | `NOT(filter)`                            |

### 5.2 Comparison Operators

Some of following params are not typed, this is because they support multiple types. For example, `param1` can be a `SObjectField` and as well as a function operating one a `SObjectField`, i.e. `TO_LABEL(Account.AnnualRevenue)`.

| SOQL Operators | Apex Query Operators                    | Generated Format                  |
| -------------- | --------------------------------------- | --------------------------------- |
| **=**          | `eq(param1, param2)`                    | `param1 = param2`                 |
| **!=**         | `ne(param1, param2)`                    | `param1 != param2`                |
| **\<**         | `lt(param1, param2)`                    | `param1 < param2`                 |
| **\<=**        | `lte(param1, param2)`                   | `param1 <= param2`                |
| **\>**         | `gt(param1, param2)`                    | `param1 > param2`                 |
| **\>=**        | `gte(param1, param2)`                   | `param1 >= param2`                |
|                | `between(param1, min, max)`             | `param1 >= min AND param1 <= max` |
| **LIKE**       | `likex(param1, param2)`                 | `param1 LIKE param2`              |
| **NOT LIKE**   | `nlike(param1, param2)`                 | `(NOT param1 LIKE param2)`        |
| **IN**         | `inx(param1, List<Object> params)`      | `param1 IN :params`               |
| **NOT IN**     | `nin(param1, List<Object> params)`      | `param1 NOT IN :params`           |
| **INCLUDES**   | `includes(param1, List<String> params)` | `param1 INCLUDES :params`         |
| **EXCLUDES**   | `excludes(param1, List<String> params)` | `param1 EXCLUDES :params`         |

## 6. Function References

#### 6.1 Aggregate Functions

| Function                             |      |      |
| ------------------------------------ | ---- | ---- |
| `COUNT(SObjectField field)`          |      |      |
| `COUNT_DISTINCT(SObjectField field)` |      |      |
| `GROUPING(SObjectField field)`       |      |      |
| `SUM(SObjectField field)`            |      |      |
| `AVG(SObjectField field)`            |      |      |
| `MAX(SObjectField field)`            |      |      |
| `MIN(SObjectField field)`            |      |      |

