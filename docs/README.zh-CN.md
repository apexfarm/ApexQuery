# Apex Query（Apex 查询构建器）

![](https://img.shields.io/badge/version-3.0.5-brightgreen.svg) ![](https://img.shields.io/badge/build-passing-brightgreen.svg) ![](https://img.shields.io/badge/coverage-99%25-brightgreen.svg)

一个用于动态 SOQL 构建的查询生成器。

**支持：** 如果你觉得这个库有帮助，请考虑在朋友圈上分享，或推荐给你的朋友或同事。每一个新的 star 都是我的动力（多一个 star，能让我开心一整周！）

| 环境          | 安装链接                                                                                                                                                     | 版本      |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------- |
| 正式/开发环境 | <a target="_blank" href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04tGC000007TPn6YAG"><img src="../docs/images/deploy-button.png"></a> | ver 3.0.5 |
| 沙盒环境      | <a target="_blank" href="https://test.salesforce.com/packaging/installPackage.apexp?p0=04tGC000007TPn6YAG"><img src="../docs/images/deploy-button.png"></a>  | ver 3.0.5 |

---

### 翻译

- [英语](../README.md)

### 版本 v3.0.0

2.0 版本过于复杂，难以维护和使用。3.0 版本追求简洁，虽然改进空间有限。在重构过程中，我也思考过简单字符串拼接是否足够。

- **主要更新**
  - 性能提升约 30%。这是一个温和的提升，大约 7 vs 10 的 CPU 时间差。
  - 字符串现在是一等公民，强类型检查已移除。
  - 移除了很少用到的特性。
- **新特性**：
  - [查询组合](#22-查询组合)
  - [查询链式调用](#23-查询链式调用)
  - [查询模板](#24-查询模板)

---

## 目录

- [1. 命名规范](#1-命名规范)
  - [1.1 可读性](#11-可读性)
  - [1.2 命名冲突](#12-命名冲突)
- [2. 概览](#2-概览)
  - [2.1 Query 类](#21-query-类)
  - [2.2 查询组合](#22-查询组合)
  - [2.3 关系查询](#23-关系查询)
  - [2.4 查询模板](#24-查询模板)
  - [2.5 查询执行](#25-查询执行)
- [3. 关键字](#3-关键字)
  - [3.1 From 语句](#31-from-语句)
  - [3.2 Select 语句](#32-select-语句)
  - [3.3 Where 语句](#33-where-语句)
  - [3.4 Order By 语句](#34-order-by-语句)
  - [3.5 Group By 语句](#35-group-by-语句)
  - [3.6 其他关键字](#36-其他关键字)
- [4. 过滤器](#4-过滤器)
  - [4.1 比较过滤器](#41-比较过滤器)
  - [4.2 逻辑过滤器](#42-逻辑过滤器)
- [5. 函数](#5-函数)
  - [5.1 聚合函数](#51-聚合函数)
  - [5.2 日期/时间函数](#52-日期时间函数)
  - [5.3 其他函数](#53-其他函数)
- [6. 字面量](#6-字面量)
  - [6.1 日期字面量](#61-日期字面量)
  - [6.2 货币字面量](#62-货币字面量)
- [7. 许可证](#7-许可证)

## 1. 命名规范

### 1.1 可读性

以下命名规范用于提升查询的可读性：

|            | 描述                 | 命名规范   | 理由                               | 示例                                                               |
| ---------- | -------------------- | ---------- | ---------------------------------- | ------------------------------------------------------------------ |
| **关键字** | SOQL 的核心结构      | camelCase  | 关键字应与 SOQL 语义一一对应       | `selectBy`, `whereBy`, `groupBy`, `havingBy`, `orderBy`            |
| **操作符** | 逻辑和比较操作符     | 小写       | 操作符应简洁，尽量用缩写           | `eq`, `ne`, `gt`, `gte`, `lt`, `lte`, `inx`, `nin`                 |
| **函数**   | 聚合、格式化、日期等 | camelCase  | 驼峰风格与 Apex 方法一致，易于输入 | `count`, `max`, `toLabel`, `format`, `calendarMonth`, `fiscalYear` |
| **字面量** | 仅日期和货币字面量   | UPPER_CASE | 常量风格，便于区分                 | `LAST_90_DAYS()`, `LAST_N_DAYS(30)`, `CURRENCY('USD', 100)`        |

### 1.2 命名冲突

为避免与现有关键字或操作符冲突，遵循以下规范：

1.  SOQL 关键字采用 `<keyword>By()` 格式，如 `selectBy`, `whereBy`, `groupBy`, `havingBy`, `orderBy`。
2.  有冲突的操作符采用 `<operator>x()` 格式，如 `orx()`, `andx()`, `inx()`, `likex()`。

## 2. 概览

### 2.1 Query 类

所有操作符和函数都作为 Query 类的静态方法实现。每次都用 `Query.` 前缀会很繁琐，建议继承 Query 类后直接调用。

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
            .orderBy(orderField('AnnualRevenue').descending().nullsLast())
            .run();
    }
}
```

上述查询等价于以下 SOQL：

```sql
SELECT Name, toLabel(Industry)
FROM Account
WHERE ((AnnualRevenue > 1000 AND BillingState = 'Beijing')
    OR (AnnualRevenue < 1000 AND BillingState = 'Shanghai'))
ORDER BY AnnualRevenue DESC NULLS LAST
```

### 2.2 查询组合

本库的一大优势在于支持将完整查询灵活拆分为多个片段，并可根据实际需求自由组合、调整顺序。比如，上述 SOQL 查询可以动态地分解为若干部分，然后按需组装：

```java
public with sharing class AccountQuery extends Query {
    public List<Account> runQuery(List<Object> additionalFields,
        Decimal beijingRevenue,
        Decimal shanghaiRevenue) {

        Query q = baseQuery();
        q.selectBy(additionalFields);
        /**
         *  不用担心 where 条件中的 andx() 或 orx() 为空或只有一个过滤器，SOQL 会自动正确生成。
         */
        q.whereBy(orx());
        q.whereBy().add(beijingRevenueGreaterThan(beijingRevenue));
        q.whereBy().add(shanghaiRevenueLessThan(shanghaiRevenue));
        return q.run();
    }

    public Query baseQuery() {
        Query q = Query.of('Account');
        q.selectBy('Name');
        q.selectBy(toLabel('Industry'));
        return q.orderBy(orderField('AnnualRevenue').descending().nullsLast());
    }

    public Filter beijingRevenueGreaterThan(Decimal revenue) {
        return andx()
            .add(gt('AnnualRevenue', revenue))
            .add(eq('BillingState', 'Beijing'));
    }

    public Filter shanghaiRevenueLessThan(Decimal revenue) {
        return andx()
            .add(lt('AnnualRevenue', revenue))
            .add(eq('BillingState', 'Shanghai'));
    }
}
```

### 2.3 关系查询

父子关系可通过链式调用组装，支持多级父子链（分组查询除外）。

```java
public with sharing class AccountQuery extends Query {
    public List<Account> listAccount() {
        Query parentQuery = Query.of('Account')
            .selectBy('Name', format(convertCurrency('AnnualRevenue')));
        Query childQuery = Query.of('Contact').selectBy('Name', 'Email');

        return (List<Account>) Query.of('Account')
            .selectBy('Name', toLabel('Industry'))
            .selectParent('Parent', parentQuery)   // 父级查询
            .selectChild('Contacts', childQuery)   // 子级查询
            .run();
    }
}
```

上述查询等价于以下 SOQL：

```sql
SELECT Name, toLabel(Industry),
    Parent.Name, FORMAT(convertCurrency(Parent.AnnualRevenue)) -- 父级查询
    (SELECT Name, Email FROM Contacts)                         -- 子级查询
FROM Account
```

不使用链式调用，也可以这样实现：

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

### 2.4 查询模板

如需用不同绑定变量多次执行同一 Query，建议用如下模式。**注意**：模板需用 `var(变量名)`。

```java
public with sharing class AccountQuery extends Query {
    public static Query accQuery {
        get {
            if (accQuery == null) {
                accQuery = Query.of('Account')
                    .selectBy('Name', toLabel('Industry'))
                    .selectChild('Contacts', Query.of('Contact')
                        .selectBy('Name', 'Email')
                        .whereBy(likex('Email', var('emailSuffix'))) // 变量 1
                    )
                    .whereBy(andx()
                        .add(gt('AnnualRevenue', var('revenue')))    // 变量 2
                        .add(eq('BillingState', var('state')))       // 变量 3
                    );
            }
            return accQuery;
        }
        set;
    }

    public List<Account> listAccount(String state, Decimal revenue) {
        return (List<Account>) accQuery.run(new Map<String, Object> {
            'revenue' => revenue,
            'state' => state,
            'emailSuffix' => '%gmail.com'
        });
    }
}
```

上述查询等价于以下 SOQL：

```sql
SELECT Name, toLabel(Industry)
    (SELECT Name, Email FROM Contacts WHERE Email LIKE :emailSuffix)
FROM Account
WHERE (AnnualRevenue > :revenue AND BillingState = :state)
```

### 2.5 查询执行

默认以 `AccessLevel.SYSTEM_MODE` 执行：

|       | API            | 带绑定变量的 API          | 返回类型                              |
| ----- | -------------- | ------------------------- | ------------------------------------- |
| **1** | `run()`        | `run(bindingVars)`        | `List<SObject>`                       |
| **2** | `getLocator()` | `getLocator(bindingVars)` | `Database.QueryLocator`               |
| **3** | `getCount()`   | `getCount(bindingVars)`   | `Integer`，需配合 `selectBy(count())` |

以任意 `AccessLevel` 执行，如 `AccessLevel.USER_MODE`：

|       | API                       | 带访问级别的 API                       | 返回类型                              |
| ----- | ------------------------- | -------------------------------------- | ------------------------------------- |
| **1** | `run(AccessLevel)`        | `run(bindingVars, AccessLevel)`        | `List<SObject>`                       |
| **2** | `getLocator(AccessLevel)` | `getLocator(bindingVars, AccessLevel)` | `Database.QueryLocator`               |
| **3** | `getCount(AccessLevel)`   | `getCount(bindingVars, AccessLevel)`   | `Integer`，需配合 `selectBy(count())` |

## 3. 关键字

### 3.1 From 语句

所有查询通过 `Query.of(String objectName)` 创建。若未指定字段，默认选取 `Id` 字段。

```java
Query accountQuery = Query.of('Account');
```

上述查询等价于以下 SOQL：

```sql
SELECT Id FROM Account
```

### 3.2 Select 语句

|       | API                                                     | 描述                  |
| ----- | ------------------------------------------------------- | --------------------- |
| **1** | `selectBy(Object ... )`                                 | 最多选 10 个字段/函数 |
| **2** | `selectBy(List<Object>)`                                | 选取字段/函数列表     |
| **3** | `selectParent(String relationshipName, Query subQuery)` | 父级查询              |
| **4** | `selectChild(String relationshipName, Query subQuery)`  | 子级查询              |

```java
Query accountQuery = Query.of('Account')
    .selectBy('Name', toLabel('Industry'))
    .selectBy(new List<Object> { 'Owner.Name', FORMAT('CreatedDate') })
    .selectParent('Parent', Query.of('Account')
        .selectBy('Name', format(convertCurrency('AnnualRevenue'))))
    .selectChild('Contacts', Query.of('Contact').selectBy('Name', 'Email'));
```

上述查询等价于以下 SOQL：

```sql
SELECT Name, toLabel(Industry),
    Owner.Name, FORMAT(CreatedDate)
    Parent.Name, FORMAT(convertCurrency(Parent.AnnualRevenue))
    (SELECT Name, Email FROM Contacts)
FROM Account
```

### 3.3 Where 语句

#### 设置根过滤器

`whereBy(Filter filter)` 可接收比较表达式或逻辑表达式。

```java
Query accountQuery = Query.of('Account')
    .selectBy('Name')
    .whereBy(gt('AnnualRevenue', 2000)); // #1. 比较过滤器

Query accountQuery = Query.of('Account')
    .selectBy('Name')
    .whereBy(andx()                      // #2. 逻辑过滤器
        .add(gt('AnnualRevenue', 2000))
        .add(lt('AnnualRevenue', 6000))
    );
```

#### 获取根过滤器

用 `whereBy()` 获取根过滤器，可后续追加分支过滤器。

```java
// 类型 #1: 默认 AND 逻辑过滤器
Query accountQuery = Query.of('Account').selectBy('Name')
    .whereBy(gt('AnnualRevenue', 2000));
accountQuery.whereBy().add(lt('AnnualRevenue', 6000));

// 类型 #2: 复用先有逻辑过滤器
Query accountQuery = Query.of('Account').selectBy('Name')
    .whereBy(andx().add(gt('AnnualRevenue', 2000)));
accountQuery.whereBy().add(lt('AnnualRevenue', 6000));

// 类型 #3: 默认 AND 逻辑过滤器
Query accountQuery = Query.of('Account').selectBy('Name');
accountQuery.whereBy().add(gt('AnnualRevenue', 2000));
accountQuery.whereBy().add(lt('AnnualRevenue', 6000));
```

以上三种类型都等价于以下 SOQL：：

```sql
SELECT Name FROM Account Where AnnualRevenue > 2000 AND AnnualRevenue < 6000
```

### 3.4 Order By 语句

|       | API                     | 描述           |
| ----- | ----------------------- | -------------- |
| **1** | `orderBy(Object...)`    | 最多 10 个字段 |
| **2** | `orderBy(List<Object>)` | 字段列表       |

参数可为字符串或函数。

```java
Query accountQuery = Query.of('Account')
    .selectBy('Name', toLabel('Industry'))
    .orderBy(
        'BillingCountry DESC NULLS LAST',
        distance('ShippingAddress', Location.newInstance(37.775000, -122.41800), 'km')
    )
    .orderBy(new List<Object>{ 'Owner.Profile.Name' });
```

也可用 `orderField()` 创建参数，上述查询等价于：

```java
Query accountQuery = Query.of('Account')
    .selectBy('Name', toLabel('Industry'))
    .orderBy(
        orderField('BillingCountry').descending().nullsLast(),
        orderField(distance('ShippingAddress', Location.newInstance(37.775000, -122.41800), 'km'))
    )
    .orderBy(new List<Object>{ orderField('Owner.Profile.Name') });
```

上述查询等价于以下 SOQL：

```sql
SELECT Name, toLabel(Industry)
FROM Account
ORDER BY BillingCountry DESC NULLS LAST,
    DISTANCE(ShippingAddress, GEOLOCATION(37.775001, -122.41801), 'km'),
    Owner.Profile.Name
```

### 3.5 Group By 语句

|       | API                     | 描述           |
| ----- | ----------------------- | -------------- |
| **1** | `groupBy(String ...)`   | 最多 10 个字段 |
| **2** | `groupBy(List<String>)` | 字段列表       |

```java
Query accountQuery = Query.of('Account')
    .selectBy(avg('AnnualRevenue'))
    .selectBy(sum('AnnualRevenue', 'RevenueSUM')) // 可选别名
    .groupBy('BillingCountry', calendarYear('CreatedDate'))
    .groupBy(new List<String>{ calendarMonth('CreatedDate') });
```

上述查询等价于以下 SOQL：

```sql
SELECT AVG(AnnualRevenue), SUM(AnnualRevenue) RevenueSUM
FROM Account
GROUP BY BillingCountry, CALENDAR_YEAR(CreatedDate), CALENDAR_MONTH(CreatedDate)
```

#### Having 子句

聚合结果可用 `havingBy()` 和 `orderBy()` 过滤和排序。`havingBy(Filter filter)` 用法同 `whereBy()`。

```java
Query accountQuery = Query.of('Account')
    .selectBy(avg('AnnualRevenue'), sum('AnnualRevenue'))
    .groupBy('BillingCountry', 'BillingState')
    .rollup()
    .havingBy(gt(sum('AnnualRevenue'), 2000))
    .orderBy(avg('AnnualRevenue'), sum('AnnualRevenue'));
```

上述查询等价于以下 SOQL：

```sql
SELECT AVG(AnnualRevenue), SUM(AnnualRevenue)
FROM Account
GROUP BY ROLLUP(BillingCountry, BillingState)
HAVING SUM(AnnualRevenue) > 2000
ORDER BY AVG(AnnualRevenue), SUM(AnnualRevenue)
```

#### Rollup 汇总

可选的 `rollup()` 或 `cube()` 方法可生成小计或总计。

```java
Query accountQuery = Query.of('Account')
    .selectBy(AVG('AnnualRevenue'), SUM('AnnualRevenue'))
    .groupBy('BillingCountry', 'BillingState')
    .rollup();
```

### 3.6 其他关键字

| API                 | 生成格式          |
| ------------------- | ----------------- |
| `limitx(Integer n)` | `LIMIT n`         |
| `offset(Integer n)` | `OFFSET n`        |
| `forView()`         | `FOR VIEW`        |
| `forReference()`    | `FOR REFERENCE`   |
| `forUpdate()`       | `FOR UPDATE`      |
| `updateTracking()`  | `UPDATE TRACKING` |
| `updateViewstat()`  | `UPDATE VIEWSTAT` |

## 4. 过滤器

### 4.1 比较过滤器

| SOQL 操作符  | Apex Query 操作符                 | 生成格式                        |
| ------------ | --------------------------------- | ------------------------------- |
| **=**        | `eq(param, value)`                | `param = value`                 |
| **!=**       | `ne(param, value)`                | `param != value`                |
| **<**        | `lt(param, value)`                | `param < value`                 |
| **<=**       | `lte(param, value)`               | `param <= value`                |
| **>**        | `gt(param, value)`                | `param > value`                 |
| **>=**       | `gte(param, value)`               | `param >= value`                |
| **BETWEEN**  | `between(param, min, max)`        | `param >= min AND param <= max` |
| **LIKE**     | `likex(param, String value)`      | `param LIKE value`              |
| **NOT LIKE** | `nlike(param, String value)`      | `(NOT param LIKE value)`        |
| **IN**       | `inx(param, List<Object> values)` | `param IN :values`              |
| **NOT IN**   | `nin(param, List<Object> values)` | `param NOT IN :values`          |
| **INCLUDES** | `includes(param, List<String>)`   | `param INCLUDES (:v1, :v2)`     |
| **EXCLUDES** | `excludes(param, List<String>)`   | `param EXCLUDES (:v1, :v2)`     |

第一个参数可为：

1. 字段名，如 `AnnualRevenue`，`'Owner.Profile.Name'`。
2. 函数，如：
   - `toLabel()`
   - 日期函数 `calendarMonth('CreatedDate')`
   - 距离函数 `distance('ShippingAddress', Location.newInstance(37.775001, -122.41801), 'km')`
   - 聚合函数 `sum('AnnualRevenue')`（仅用于 having）

#### 与 sObject 列表比较

`inx()` 和 `nin()` 也可用于 Id 字段与 sObject 列表比较。

```java
List<Account> accounts = ... ; // 其他地方查询的账户
List<Contact> contacts = List<Contact> Query.of('Contact')
    .selectBy('Name', toLabel('Account.Industry'))
    .whereBy(inx('AccountId', accounts))
    .run();
```

上述查询等价于以下 SOQL：

```sql
SELECT Name, toLabel(Account.Industry)
FROM Contact
WHERE AccountId IN :accounts
```

### 4.2 逻辑过滤器

| AND                                   | 生成格式          |
| ------------------------------------- | ----------------- |
| `andx().add(f1).add(f2)...`           | `(f1 AND f2 ...)` |
| `andx().addAll(List<Filter> filters)` | `(f1 AND f2 ...)` |
| **OR**                                |                   |
| `orx().add(f1).add(f2)...`            | `(f1 OR f2 ...)`  |
| `orx().addAll(List<Filter> filters)`  | `(f1 OR f2 ...)`  |
| **NOT**                               |                   |
| `notx(Filter filter)`                 | `NOT(filter)`     |

示例：

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
    .add(shanghaiRevenueLessThan);
```

上述查询等价于以下 SOQL：

```sql
(AnnualRevenue > 1000 AND BillingState = 'Beijing')
OR (AnnualRevenue < 1000 AND BillingState = 'Shanghai')
```

## 5. 函数

### 5.1 聚合函数

| 静态方法                      | 生成格式                      |
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

### 5.2 日期/时间函数

以下函数用于日期、时间和日期时间字段。

```java
Query.of('Opportunity')
    .selectBy(calendarYear('CreatedDate'), sum('Amount'))
    .whereBy(gt(calendarYear('CreatedDate'), 2000))
    .groupBy(calendarYear('CreatedDate'));
```

上述查询等价于以下 SOQL：

```sql
SELECT CALENDAR_YEAR(CreatedDate), SUM(Amount)
FROM Opportunity
WHERE CALENDAR_YEAR(CreatedDate) > 2000
GROUP BY CALENDAR_YEAR(CreatedDate)
```

| 静态方法                 | 描述                                 |
| ------------------------ | ------------------------------------ |
| `convertTimezone(field)` | 转换为用户时区，仅能用于日期函数内部 |
| `calendarMonth(field)`   | 返回日期字段的月份                   |
| `calendarQuarter(field)` | 返回日期字段的季度                   |
| `calendarYear(field)`    | 返回日期字段的年份                   |
| `dayInMonth(field)`      | 返回日期字段的天                     |
| `dayInWeek(field)`       | 返回日期字段的星期几                 |
| `dayInYear(field)`       | 返回日期字段的年内天数               |
| `dayOnly(field)`         | 返回日期时间字段的日期部分           |
| `fiscalMonth(field)`     | 返回日期字段的财务月份               |
| `fiscalQuarter(field)`   | 返回日期字段的财务季度               |
| `fiscalYear(field)`      | 返回日期字段的财务年份               |
| `hourInDay(field)`       | 返回日期时间字段的小时               |
| `weekInMonth(field)`     | 返回日期字段的月内周数               |
| `weekInYear(field)`      | 返回日期字段的年内周数               |

### 5.3 其他函数

示例：

```java
Query.Filter filter = lt(distance('ShippingAddreess',
    Location.newInstance(37.775000, -122.41800)), 20, 'km');
```

| 静态方法                                     | 生成格式                                                        |
| -------------------------------------------- | --------------------------------------------------------------- |
| `toLabel(field)`                             | `toLabel(field)`                                                |
| `format(field)`                              | `FORMAT(field)`                                                 |
| `convertCurrency(field)`                     | `convertCurrency(field)`，可嵌套于 format()                     |
| `distance(field, Location geo, string unit)` | `DISTANCE(ShippingAddress, GEOLOCATION(37.775,-122.418), 'km')` |

## 6. 字面量

### 6.1 日期字面量

以下为 Salesforce 支持的所有日期字面量（[官方文档](https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_dateformats.htm)）：

```java
Query.Filter filter = andx()
    .add(eq('LastModifiedDate', YESTERDAY()))
    .add(gt('CreatedDate', LAST_N_DAYS(5)))
);
```

> `YESTERDAY()`, `TODAY()`, `TOMORROW()`, `LAST_WEEK()`, `THIS_WEEK()`, `NEXT_WEEK()`, `LAST_MONTH()`, `THIS_MONTH()`, `NEXT_MONTH()`, `LAST_90_DAYS()`, `NEXT_90_DAYS()`, `THIS_QUARTER()`, `LAST_QUARTER()`, `NEXT_QUARTER()`, `THIS_YEAR()`, `LAST_YEAR()`, `NEXT_YEAR()`, `THIS_FISCAL_QUARTER()`, `LAST_FISCAL_QUARTER()`, `NEXT_FISCAL_QUARTER()`, `THIS_FISCAL_YEAR()`, `LAST_FISCAL_YEAR()`, `NEXT_FISCAL_YEAR()`
>
> `LAST_N_DAYS(Integer n)`, `NEXT_N_DAYS(Integer n)`, `N_DAYS_AGO(Integer n)`, `NEXT_N_WEEKS(Integer n)`, `LAST_N_WEEKS(Integer n)`, `N_WEEKS_AGO(Integer n)`, `NEXT_N_MONTHS(Integer n)`, `LAST_N_MONTHS(Integer n)`, `N_MONTHS_AGO(Integer n)`, `NEXT_N_QUARTERS(Integer n)`, `LAST_N_QUARTERS(Integer n)`, `N_QUARTERS_AGO(Integer n)`, `NEXT_N_YEARS(Integer n)`, `LAST_N_YEARS(Integer n)`, `N_YEARS_AGO(Integer n)`, `NEXT_N_FISCAL_QUARTERS(Integer n)`, `N_FISCAL_QUARTERS_AGO(Integer n)`, `NEXT_N_FISCAL_YEARS(Integer n)`, `LAST_N_FISCAL_YEARS(Integer n)`, `N_FISCAL_YEARS_AGO(Integer n)`

### 6.2 货币字面量

Salesforce 支持的货币 ISO 代码见[官方文档](https://help.salesforce.com/s/articleView?language=zh_CN&id=sf.admin_supported_currencies.htm)。

```java
Query.Filter filter = orx()
    .add(eq('AnnualRevenual', CURRENCY('USD', 2000)))
    .add(eq('AnnualRevenual', CURRENCY('CNY', 2000)))
    .add(eq('AnnualRevenual', CURRENCY('TRY', 2000)))
);
```

## 7. 许可证

Apache 2.0
