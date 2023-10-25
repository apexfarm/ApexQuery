List<SObject> records = Query.of(Account.SObjectType)
    .selectBy(Account.Name)
    .filterBy(Query.includes(Account.TestMultiPicklist__c, new List<String>{ 'AAA;DDD', 'CCC' }))
    .run();
System.debug(records.size());

List<SObject> records = Query.of(Account.SObjectType)
    .selectBy(Account.Name)
    .filterBy(Query.eq(Account.TestMultiPicklist__c, 'AAA;DDD'))
    .run();
System.debug(records.size());

List<SObject> records = Query.of(Account.SObjectType)
    .selectBy(Account.Name)
    .filterBy(Query.inx(Account.TestMultiPicklist__c,  new List<String>{ 'AAA;DDD', 'CCC' }))
    .run();
System.debug(records.size());
