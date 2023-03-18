# Apex Query





- Queries are value objects, thus different query instances with same parameters are treated as equal.

- Highly composable, select, where and order by clauses can be create standalone and passed in the query when needed. And they are value objects as well.

- Support all keywords, operators and functions, except `TYPEOF` and `WITH`. If some feature is missing and wanted, please leave an issue, I will add it by time.

- String parameters are internal single quote escaped to prevent SOQL injection.

- Strong encapsulation such as methods and types to constraint the inputs and outputs. Some disallowed syntax is graded by strong types, but not for all.

- 

- Automatically skips fields don't have read permission?

- Managing comma is a bad thing

- Avoid too many small method calls which polluting Apex logs.

- Built in Currency ISO code

  

Use In Batch with Query Locator
