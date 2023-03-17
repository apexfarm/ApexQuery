/**
 * Copyright 2023 Jeff Jin
 * https://github.com/apexfarm/ApexQuery
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

public abstract class Query implements Querable {
    private SObjectType objectType { get; set; }
    private SelectorImpl rootSelector { get; set; }
    private Filter rootFilter { get; set; }
    private List<OrderByField> orderByFields { get; set; }

    private Map<String, Aggregation> aggregationsByAlias { get; set; }
    private List<Aggregation> aggregations { get; set; }
    private List<SObjectField> groupByFields { get; set; }
    private Boolean rollup { get; set; }
    private Boolean cube { get; set; }

    private Integer offset { get; set; }
    private Integer limitx { get; set; }
    private Boolean forView { get; set; }
    private Boolean forReference { get; set; }
    private Boolean forUpdate { get; set; }

    {
        this.rootSelector = new SelectorImpl();
        this.orderByFields = new List<OrderByField>();
        this.aggregationsByAlias = new Map<String, Aggregation>();
        this.aggregations = new List<Aggregation>();
        this.groupByFields = new List<SObjectField>();
        this.rollup = false;
        this.cube = false;
    }

    public Boolean equals(Object obj) {
        if (this === obj) {
            return true;
        }

        Query that = (Query) obj;

        if (this.aggregations.isEmpty() && this.groupByFields.isEmpty()) {
            return this.objectType == that.objectType &&
                this.rootSelector == that.rootSelector &&
                this.rootFilter == that.rootFilter &&
                this.orderByFields == that.orderByFields &&
                this.limitx == that.limitx &&
                this.offset == that.offset &&
                this.forView == that.forView &&
                this.forReference == that.forReference &&
                this.forUpdate == that.forUpdate;
        } else {
            return this.objectType == that.objectType &&
                this.groupByFields == that.groupByFields &&
                this.aggregations == that.aggregations &&
                this.orderByFields == that.orderByFields &&
                this.rollup == that.rollup &&
                this.cube == that.cube &&
                this.limitx == that.limitx;
        }
    }

    public static Query of(SObjectType objectType) {
        return new QueryBuilder(objectType);
    }

    private virtual IOrderManager getOrderManager() {
        return null;
    }

    private virtual IGroupManager getGroupManager() {
        return null;
    }

    protected virtual String build(Map<String, Object> tmpVars) {
        return null;
    }

    public Integer getCount() {
        return getCount(AccessLevel.SYSTEM_MODE);
    }

    public Integer getCount(AccessLevel accessLevel) {
        Map<String, Object> tmpVars = new Map<String, Object>();
        return Database.countQueryWithBinds(this.build(tmpVars), tmpVars, accessLevel);
    }

    public Object run() {
        return this.run(AccessLevel.SYSTEM_MODE);
    }

    public Object run(AccessLevel accessLevel) {
        Map<String, Object> tmpVars = new Map<String, Object>();
        return Database.queryWithBinds(this.build(tmpVars), tmpVars, accessLevel);
    }

    public Database.QueryLocator getLocator() {
        return this.getLocator(AccessLevel.SYSTEM_MODE);
    }

    public Database.QueryLocator getLocator(AccessLevel accessLevel) {
        Map<String, Object> tmpVars = new Map<String, Object>();
        return Database.getQueryLocatorWithBinds(this.build(tmpVars), tmpVars, accessLevel);
    }

    // =============
    // #region Query
    private class QueryBuilder extends Query {
        private OrderManager orderManager { get; set; }
        private GroupManager groupManager { get; set; }

        private QueryBuilder(SObjectType objectType) {
            this.objectType = objectType;
            this.orderManager = new OrderManager(this);
            this.groupManager = new GroupManager(this);
        }

        private override IOrderManager getOrderManager() {
            return this.orderManager;
        }

        private override IGroupManager getGroupManager() {
            return this.groupManager;
        }

        private void buildSelect(List<String> fragments, Map<String, Object> tmpVars) {
            Boolean isFirst = true;
            for (SObjectField field : this.rootSelector.fields) {
                if (isFirst) {
                    fragments.add('SELECT ');
                } else {
                    fragments.add(', ');
                }
                isFirst = false;
                fragments.add(String.valueOf(field));
            }

            for (String relationName : this.rootSelector.queries.keySet()) {
                fragments.add(', ');
                fragments.add('(');
                this.rootSelector.queries.get(relationName).buildSoql(relationName, fragments, tmpVars);
                fragments.add(')');
            }
        }

        private void buildOrderBy(List<String> fragments) {
            Boolean isFirst = true;
            for (OrderByField clause : orderByFields) {
                if (isFirst) {
                    fragments.add(' ORDER BY ');
                } else {
                    fragments.add(', ');
                }
                isFirst = false;

                fragments.add(clause.fieldName);

                if (!clause.ascending) {
                    fragments.add(' DESC');
                }

                if (!clause.nullFirst) {
                    fragments.add(' NULLS LAST');
                }
            }
        }

        private void buildOrderByForGroup(List<String> fragments) {
            Boolean isFirst = true;
            for (OrderByField clause : this.orderByFields) {
                if (isFirst) {
                    fragments.add(' ORDER BY ');
                } else {
                    fragments.add(', ');
                }
                isFirst = false;

                if (this.aggregationsByAlias.containsKey(clause.fieldName)) {
                    Aggregation operation = this.aggregationsByAlias.get(clause.fieldName);
                    fragments.add(operation.operation);
                    fragments.add('(');
                    fragments.add(String.valueOf(operation.field));
                    fragments.add(')');
                } else {
                    fragments.add(clause.fieldName);
                }

                if (!clause.ascending) {
                    fragments.add(' DESC');
                }

                if (!clause.nullFirst) {
                    fragments.add(' NULLS LAST');
                }
            }
        }

        public void buildGroupBySelect(List<String> fragments) {
            fragments.add('SELECT ');
            Boolean isFirst = true;
            for (SObjectField field : this.groupByFields) {
                if (!isFirst) {
                    fragments.add(', ');
                }
                isFirst = false;
                fragments.add(String.valueOf(field));
            }

            for (Aggregation operation : this.aggregations) {
                if (!isFirst) {
                    fragments.add(', ');
                }
                isFirst = false;
                operation.build(fragments);
            }
        }

        public void buildGroupBy(List<String> fragments) {
            Boolean isFirst = true;
            for (SObjectField field : this.groupByFields) {
                if (isFirst) {
                    fragments.add(' GROUP BY ');
                    if (this.rollup) {
                        fragments.add('ROLLUP(');
                    } else if (this.cube) {
                        fragments.add('CUBE(');
                    }
                } else {
                    fragments.add(', ');
                }
                isFirst = false;
                fragments.add(String.valueOf(field));
            }
            if (this.rollup || this.cube) {
                fragments.add(')');
            }
        }

        private void buildSoql(String fromObjectName, List<String> fragments, Map<String, Object> tmpVars) {
            if (this.aggregations.size() > 0) {
                this.buildGroupBySelect(fragments);
            } else {
                this.buildSelect(fragments, tmpVars);
            }
            fragments.add(' FROM ');
            fragments.add(fromObjectName);

            // Build Filters
            if (this.rootFilter != null) {
                fragments.add(' WHERE ');
                rootFilter.build(fragments, tmpVars);
            }

            this.buildGroupBy(fragments);

            if (this.aggregations.size() > 0) {
                buildOrderByForGroup(fragments);
            } else {
                buildOrderBy(fragments);
            }

            if (this.limitx != null) {
                fragments.add(' LIMIT ');
                fragments.add(String.valueOf(this.limitx));
            }

            if (this.offset != null) {
                fragments.add(' OFFSET ');
                fragments.add(String.valueOf(this.offset));
            }

            if (this.forView == true) {
                fragments.add(' FOR VIEW');
            } else if (this.forReference == true) {
                fragments.add(' FOR REFERENCE');
            } else if (this.forUpdate == true) {
                fragments.add(' FOR UPDATE');
            }
        }

        private void buildSoql(List<String> fragments, Map<String, Object> tmpVars) {
            this.buildSoql(this.objectType.getDescribe().getName(), fragments, tmpVars);
        }

        protected override String build(Map<String, Object> tmpVars) {
            List<String> fragments = new List<String>();
            buildSoql(fragments, tmpVars);
            String query = String.join(fragments, '');
            System.debug(query);
            return query;
        }
    }
    // #endregion
    // =============

    // ============
    // #region MISC
    public Query offset(Integer n) {
        this.offset = n;
        return this;
    }

    public Query limitx(Integer n) {
        this.limitx = n;
        return this;
    }

    public Query forView() {
        this.forView = true;
        return this;
    }

    public Query forReference() {
        this.forReference = true;
        return this;
    }

    public Query forUpdate() {
        this.forUpdate = true;
        return this;
    }

    // #endregion
    // ============

    // ==============
    // #region Select

    public interface Selector {
        Selector add(SObjectField field);
        Selector add(SObjectField field1, SObjectField field2);
        Selector add(SObjectField field1, SObjectField field2, SObjectField field3);
        Selector add(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        Selector add(
            SObjectField field1,
            SObjectField field2,
            SObjectField field3,
            SObjectField field4,
            SObjectField field5
        );
        Selector add(List<SObjectField> fields);
        Selector add(String relationName, Query query);
    }

    private class SelectorImpl implements Selector {
        private List<SObjectField> fields { get; set; }
        private Map<String, QueryBuilder> queries { get; set; }

        private SelectorImpl() {
            this.fields = new List<SObjectField>();
            this.queries = new Map<String, QueryBuilder>();
        }

        public Boolean equals(Object obj) {
            if (this === obj) {
                return true;
            }

            SelectorImpl that = (SelectorImpl) obj;
            return this.fields == that.fields && this.queries == that.queries;
        }

        public Selector add(SObjectField field) {
            this.fields.add(field);
            return this;
        }

        public Selector add(SObjectField field1, SObjectField field2) {
            this.fields.add(field1);
            this.fields.add(field2);
            return this;
        }

        public Selector add(SObjectField field1, SObjectField field2, SObjectField field3) {
            this.fields.add(field1);
            this.fields.add(field2);
            this.fields.add(field3);
            return this;
        }

        public Selector add(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            this.add(new List<SObjectField>{ field1, field2, field3, field4 });
            return this;
        }

        public Selector add(
            SObjectField field1,
            SObjectField field2,
            SObjectField field3,
            SObjectField field4,
            SObjectField field5
        ) {
            this.add(new List<SObjectField>{ field1, field2, field3, field4, field5 });
            return this;
        }

        public Selector add(List<SObjectField> fields) {
            this.fields.addAll(fields);
            return this;
        }

        public Selector add(String relationName, Query query) {
            this.queries.put(relationName, (QueryBuilder) query);
            return this;
        }

        private Selector addAll(Selector selector) {
            this.fields.addAll(((SelectorImpl) selector).fields);
            this.queries.putAll(((SelectorImpl) selector).queries);
            return this;
        }
    }

    public static Selector selector() {
        return new SelectorImpl();
    }

    public Query selectAll() {
        return this;
    }

    public Query selectBy(Selector selector) {
        this.rootSelector.addAll(selector);
        return this;
    }

    public Query selectBy(SObjectField field) {
        return selectBy(new List<SObjectField>{ field });
    }

    public Query selectBy(SObjectField field1, SObjectField field2) {
        return selectBy(new List<SObjectField>{ field1, field2 });
    }

    public Query selectBy(SObjectField field1, SObjectField field2, SObjectField field3) {
        return selectBy(new List<SObjectField>{ field1, field2, field3 });
    }

    public Query selectBy(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
        return selectBy(new List<SObjectField>{ field1, field2, field3, field4 });
    }

    public Query selectBy(
        SObjectField field1,
        SObjectField field2,
        SObjectField field3,
        SObjectField field4,
        SObjectField field5
    ) {
        return selectBy(new List<SObjectField>{ field1, field2, field3, field4, field5 });
    }
    public Query selectBy(List<SObjectField> fields) {
        this.rootSelector.fields.addAll(fields);
        return this;
    }

    public Query selectBy(String relationName, Query query) {
        this.rootSelector.queries.put(relationName, (QueryBuilder) query);
        return this;
    }

    // #endregion
    // ==============

    // ================
    // #region Order By

    private virtual class OrderByField {
        private String fieldName { get; set; }
        private Boolean ascending { get; set; }
        private Boolean nullFirst { get; set; }

        private OrderByField(String fieldName) {
            this.fieldName = fieldName;
            this.ascending = true;
            this.nullFirst = true;
        }

        public Boolean equals(Object obj) {
            if (this === obj) {
                return true;
            }

            OrderByField that = (OrderByField) obj;
            return this.fieldName == that.fieldName &&
                this.ascending == that.ascending &&
                this.nullFirst == that.nullFirst;
        }
    }

    private interface IOrderManager {
        void setFieldNames(List<String> fieldNames);
        void setAscending(Boolean ascending);
        void setNullFirst(Boolean nullFirst);
    }

    private class OrderManager implements IOrderManager {
        private Query query { get; set; }
        private Integer batchSize { get; set; }
        private List<OrderByField> clauses {
            get {
                return this.query.orderByFields;
            }
        }

        private OrderManager(Query query) {
            this.query = query;
            this.batchSize = 0;
        }

        public void setFieldNames(List<String> fieldNames) {
            this.batchSize = fieldNames.size();
            for (String fieldName : fieldNames) {
                this.clauses.add(new OrderByField(fieldName));
            }
        }

        public void setAscending(Boolean ascending) {
            if (this.clauses.size() >= this.batchSize) {
                for (Integer i = this.batchSize; i > 0; i--) {
                    this.clauses[this.clauses.size() - i].ascending = ascending;
                }
            }
        }
        public void setNullFirst(Boolean nullFirst) {
            if (this.clauses.size() >= this.batchSize) {
                for (Integer i = this.batchSize; i > 0; i--) {
                    this.clauses[this.clauses.size() - i].nullFirst = nullFirst;
                }
            }
        }
    }

    public Query orderBy(String name) {
        this.orderBy(new List<String>{ name });
        return this;
    }
    public Query orderBy(String name1, String name2) {
        this.orderBy(new List<String>{ name1, name2 });
        return this;
    }
    public Query orderBy(String name1, String name2, String name3) {
        this.orderBy(new List<String>{ name1, name2, name3 });
        return this;
    }
    public Query orderBy(String name1, String name2, String name3, String name4) {
        this.orderBy(new List<String>{ name1, name2, name3, name4 });
        return this;
    }
    public Query orderBy(String name1, String name2, String name3, String name4, String name5) {
        this.orderBy(new List<String>{ name1, name2, name3, name4, name5 });
        return this;
    }
    public Query orderBy(List<String> names) {
        this.getOrderManager().setFieldNames(names);
        return this;
    }

    public Query ascending() {
        // default to true
        return this;
    }

    public Query descending() {
        this.getOrderManager().setAscending(false);
        return this;
    }

    public Query nullsFirst() {
        // default to true
        return this;
    }

    public Query nullsLast() {
        this.getOrderManager().setNullFirst(false);
        return this;
    }
    // #endregion
    // ================

    // ================
    // #region Group By

    private interface IGroupManager {
        void add(Aggregation operation);
    }

    private class GroupManager implements IGroupManager {
        private Query query { get; set; }
        private Integer aliasIndex { get; set; }

        private GroupManager(Query query) {
            this.query = query;
            this.aliasIndex = 0;
        }

        public void add(Aggregation operation) {
            if (String.isBlank(operation.alias)) {
                operation.alias = 'expr' + this.aliasIndex;
                this.aliasIndex++;
            }
            this.query.aggregations.add(operation);
            this.query.aggregationsByAlias.put(operation.alias, operation);
        }
    }

    private abstract class Aggregation {
        private String operation { get; set; }
        private SOBjectField field { get; set; }
        private String alias { get; set; }
        private Integer tag { get; set; }

        private void build(List<String> fragments) {
            fragments.add(this.operation);
            fragments.add('(');
            if (this.field != null) {
                fragments.add(String.valueOf(this.field));
            }
            fragments.add(')');
            if (String.isNotBlank(this.alias) && !this.alias.startsWithIgnoreCase('expr')) {
                fragments.add(' ');
                fragments.add(this.alias);
            }
        }

        public Boolean equals(Object obj) {
            if (this === obj) {
                return true;
            }

            Aggregation that = (Aggregation) obj;

            return this.tag == that.tag && this.field == that.field;
        }
    }

    private class Grouping extends Aggregation {
        private Grouping(SObjectField field) {
            this.operation = 'GROUPING';
            this.field = field;
            this.tag = GROUPING_TAG;
        }

        private Grouping(SObjectField field, String alias) {
            this.operation = 'GROUPING';
            this.field = field;
            this.alias = alias;
            this.tag = GROUPING_TAG;
        }
    }

    private class Count extends Aggregation {
        private Count() {
            this.operation = 'COUNT';
            this.tag = COUNT_TAG;
        }

        private Count(SObjectField field) {
            this.operation = 'COUNT';
            this.field = field;
            this.tag = COUNT_TAG;
        }

        private Count(SObjectField field, String alias) {
            this.operation = 'COUNT';
            this.field = field;
            this.alias = alias;
            this.tag = COUNT_TAG;
        }
    }

    private class SUM extends Aggregation {
        private SUM(SObjectField field) {
            this.operation = 'SUM';
            this.field = field;
            this.tag = SUM_TAG;
        }

        private SUM(SObjectField field, String alias) {
            this.operation = 'SUM';
            this.field = field;
            this.alias = alias;
            this.tag = SUM_TAG;
        }
    }

    private class AVG extends Aggregation {
        private AVG(SObjectField field) {
            this.operation = 'AVG';
            this.field = field;
            this.tag = AVG_TAG;
        }

        private AVG(SObjectField field, String alias) {
            this.operation = 'AVG';
            this.field = field;
            this.alias = alias;
            this.tag = AVG_TAG;
        }
    }

    private class MAX extends Aggregation {
        private MAX(SObjectField field) {
            this.operation = 'MAX';
            this.field = field;
            this.tag = MAX_TAG;
        }

        private MAX(SObjectField field, String alias) {
            this.operation = 'MAX';
            this.field = field;
            this.alias = alias;
            this.tag = MAX_TAG;
        }
    }

    private class MIN extends Aggregation {
        private MIN(SObjectField field) {
            this.operation = 'MIN';
            this.field = field;
            this.tag = MIN_TAG;
        }

        private MIN(SObjectField field, String alias) {
            this.operation = 'MIN';
            this.field = field;
            this.alias = alias;
            this.tag = MIN_TAG;
        }
    }

    public Query grouping(SObjectField field) {
        this.getGroupManager().add(new Grouping(field));
        return this;
    }

    public Query grouping(SObjectField field, String alias) {
        this.getGroupManager().add(new Grouping(field, alias));
        return this;
    }

    public Query count() {
        this.getGroupManager().add(new Count());
        return this;
    }

    public Query count(SObjectField field) {
        this.getGroupManager().add(new Count(field));
        return this;
    }

    public Query count(SObjectField field, String alias) {
        this.getGroupManager().add(new Count(field, alias));
        return this;
    }

    public Query sum(SObjectField field) {
        this.getGroupManager().add(new SUM(field));
        return this;
    }

    public Query sum(SObjectField field, String alias) {
        this.getGroupManager().add(new SUM(field, alias));
        return this;
    }

    public Query avg(SObjectField field) {
        this.getGroupManager().add(new AVG(field));
        return this;
    }

    public Query avg(SObjectField field, String alias) {
        this.getGroupManager().add(new AVG(field, alias));
        return this;
    }

    public Query max(SObjectField field) {
        this.getGroupManager().add(new MAX(field));
        return this;
    }

    public Query max(SObjectField field, String alias) {
        this.getGroupManager().add(new MAX(field, alias));
        return this;
    }

    public Query min(SObjectField field) {
        this.getGroupManager().add(new MIN(field));
        return this;
    }

    public Query min(SObjectField field, String alias) {
        this.getGroupManager().add(new MIN(field, alias));
        return this;
    }

    public Query groupBy(SObjectField field) {
        return groupBy(new List<SObjectField>{ field });
    }

    public Query groupBy(SObjectField field1, SObjectField field2) {
        return groupBy(new List<SObjectField>{ field1, field2 });
    }

    public Query groupBy(SObjectField field1, SObjectField field2, SObjectField field3) {
        return groupBy(new List<SObjectField>{ field1, field2, field3 });
    }

    public Query groupBy(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
        return groupBy(new List<SObjectField>{ field1, field2, field3, field4 });
    }

    public Query groupBy(
        SObjectField field1,
        SObjectField field2,
        SObjectField field3,
        SObjectField field4,
        SObjectField field5
    ) {
        return groupBy(new List<SObjectField>{ field1, field2, field3, field4, field5 });
    }

    public Query groupBy(List<SObjectField> fields) {
        this.groupByFields.addAll(fields);
        return this;
    }

    public Query rollup() {
        this.rollup = true;
        return this;
    }

    public Query cube() {
        this.cube = true;
        return this;
    }
    // #endregion
    // ================

    // ==============
    // #region Filter
    public interface Filter {
        void build(List<String> fragments, Map<String, Object> tmpVars);
    }

    public interface CompositeFilter extends Filter {
        CompositeFilter add(Filter filter);
    }

    private abstract class LogicalExpression implements CompositeFilter {
        private List<Filter> filters { get; set; }
        private String operator { get; set; }
        private Integer tag { get; set; }

        private LogicalExpression(String operator) {
            this.filters = new List<Filter>();
            this.operator = operator;
        }

        public CompositeFilter add(Filter filter) {
            this.filters.add(filter);
            return this;
        }

        public CompositeFilter add(List<Filter> filters) {
            this.filters.addAll(filters);
            return this;
        }

        public void build(List<String> fragments, Map<String, Object> tmpVars) {
            if (this.filters.size() == 0) {
                return;
            }

            fragments.add('(');
            Integer index = 0;
            for (Filter filter : this.filters) {
                if (index > 0) {
                    fragments.add(this.operator);
                }
                filter.build(fragments, tmpVars);
                index++;
            }
            fragments.add(')');
        }

        public Boolean equals(Object obj) {
            if (this === obj) {
                return true;
            }

            LogicalExpression that = (LogicalExpression) obj;
            return this.tag == that.tag && this.filters == that.filters;
        }
    }

    private class AndLogicalExpression extends LogicalExpression {
        private AndLogicalExpression() {
            super(' AND ');
            this.tag = AND_TAG;
        }
    }

    private class OrLogicalExpression extends LogicalExpression {
        private OrLogicalExpression() {
            super(' OR ');
            this.tag = OR_TAG;
        }
    }

    private abstract class ComparisonExpression implements Filter {
        private SObjectField field { get; set; }
        private String operator { get; set; }
        private Object value { get; set; }
        private Distance distance { get; set; } // used by DistanceComparison
        private Integer tag { get; set; } // used to distinguish each implementation.

        private ComparisonExpression(SObjectField field, String operator, Object value) {
            this.field = field;
            this.operator = operator;
            this.value = value;
        }

        public virtual void build(List<String> fragments, Map<String, Object> tmpVars) {
            fragments.add(String.valueOf(this.field));
            fragments.add(this.operator);
            if (
                this.value instanceof List<Object> ||
                this.value instanceof Datetime ||
                this.value instanceof Date ||
                this.value instanceof Time
            ) {
                String var = 'tmpVar' + tmpVars.size() + 1;
                tmpVars.put(var, this.value);
                fragments.add(':');
                fragments.add(var);
            } else if (this.value instanceof String) {
                fragments.add('\'');
                fragments.add(String.escapeSingleQuotes(String.valueOf(this.value)));
                fragments.add('\'');
            } else if (this.value instanceof Id) {
                fragments.add('\'');
                fragments.add(String.valueOf(this.value));
                fragments.add('\'');
            } else {
                fragments.add(String.valueOf(this.value));
            }
        }

        public Boolean equals(Object obj) {
            if (this === obj) {
                return true;
            }

            ComparisonExpression that = (ComparisonExpression) obj;

            return (this.field == that.field &&
            this.tag == that.tag &&
            this.value == that.value &&
            this.distance == that.distance);
        }
    }

    public Query filterBy(Filter filter) {
        this.rootFilter = filter;
        return this;
    }

    public static CompositeFilter orx() {
        return new OrLogicalExpression();
    }

    public static CompositeFilter andx() {
        return new AndLogicalExpression();
    }

    public static CompositeFilter orx(Filter filter1, Filter filter2) {
        return orx(new List<Filter>{ filter1, filter2 });
    }

    public static CompositeFilter orx(Filter filter1, Filter filter2, Filter filter3) {
        return orx(new List<Filter>{ filter1, filter2, filter3 });
    }

    public static CompositeFilter orx(Filter filter1, Filter filter2, Filter filter3, Filter filter4) {
        return orx(new List<Filter>{ filter1, filter2, filter3, filter4 });
    }

    public static CompositeFilter orx(Filter filter1, Filter filter2, Filter filter3, Filter filter4, Filter filter5) {
        return orx(new List<Filter>{ filter1, filter2, filter3, filter4, filter5 });
    }

    public static CompositeFilter orx(
        Filter filter1,
        Filter filter2,
        Filter filter3,
        Filter filter4,
        Filter filter5,
        Filter filter6
    ) {
        return orx(new List<Filter>{ filter1, filter2, filter3, filter4, filter5, filter6 });
    }

    public static CompositeFilter orx(
        Filter filter1,
        Filter filter2,
        Filter filter3,
        Filter filter4,
        Filter filter5,
        Filter filter6,
        Filter filter7
    ) {
        return orx(new List<Filter>{ filter1, filter2, filter3, filter4, filter5, filter6, filter7 });
    }

    public static CompositeFilter orx(List<Filter> filters) {
        return new OrLogicalExpression().add(filters);
    }

    public static CompositeFilter andx(Filter filter1, Filter filter2) {
        return andx(new List<Filter>{ filter1, filter2 });
    }

    public static CompositeFilter andx(Filter filter1, Filter filter2, Filter filter3) {
        return andx(new List<Filter>{ filter1, filter2, filter3 });
    }

    public static CompositeFilter andx(Filter filter1, Filter filter2, Filter filter3, Filter filter4) {
        return andx(new List<Filter>{ filter1, filter2, filter3, filter4 });
    }

    public static CompositeFilter andx(Filter filter1, Filter filter2, Filter filter3, Filter filter4, Filter filter5) {
        return andx(new List<Filter>{ filter1, filter2, filter3, filter4, filter5 });
    }

    public static CompositeFilter andx(
        Filter filter1,
        Filter filter2,
        Filter filter3,
        Filter filter4,
        Filter filter5,
        Filter filter6
    ) {
        return andx(new List<Filter>{ filter1, filter2, filter3, filter4, filter5, filter6 });
    }

    public static CompositeFilter andx(
        Filter filter1,
        Filter filter2,
        Filter filter3,
        Filter filter4,
        Filter filter5,
        Filter filter6,
        Filter filter7
    ) {
        return andx(new List<Filter>{ filter1, filter2, filter3, filter4, filter5, filter6, filter7 });
    }

    public static CompositeFilter andx(List<Filter> filters) {
        return new AndLogicalExpression().add(filters);
    }

    // #endregion
    // ==================

    // =============
    // #region =, !=
    private class EQ extends ComparisonExpression {
        private EQ(SObjectField field, Object value) {
            super(field, ' = ', value);
            this.tag = EQ_TAG;
        }
    }

    private class NE extends ComparisonExpression {
        private NE(SObjectField field, Object value) {
            super(field, ' != ', value);
            this.tag = NE_TAG;
        }
    }

    public static Filter eq(SObjectField field, Object value) {
        return new EQ(field, value);
    }

    public static Filter ne(SObjectField field, Object value) {
        return new NE(field, value);
    }
    // #endregion
    // =============

    // =========
    // #region >
    private class GT extends ComparisonExpression {
        private GT(SObjectField field, Object value) {
            super(field, ' > ', value);
            this.tag = GT_TAG;
        }
    }

    public static Filter gt(SObjectField field, Decimal value) {
        return new GT(field, value);
    }

    public static Filter gt(SObjectField field, DateLiteral value) {
        return new GT(field, value);
    }

    public static Filter gt(SObjectField field, Date value) {
        return new GT(field, value);
    }

    public static Filter gt(SObjectField field, Datetime value) {
        return new GT(field, value);
    }

    public static Filter gt(SObjectField field, Time value) {
        return new GT(field, value);
    }

    public static Filter gt(SObjectField field, Id value) {
        return new GT(field, value);
    }

    public static Filter gt(SObjectField field, String value) {
        return new GT(field, value);
    }

    // #endregion
    // ==========

    // ==========
    // #region >=
    private class GTE extends ComparisonExpression {
        private GTE(SObjectField field, Object value) {
            super(field, ' >= ', value);
            this.tag = GTE_TAG;
        }
    }

    public static Filter gte(SObjectField field, Decimal value) {
        return new GTE(field, value);
    }

    public static Filter gte(SObjectField field, DateLiteral value) {
        return new GTE(field, value);
    }

    public static Filter gte(SObjectField field, Date value) {
        return new GTE(field, value);
    }

    public static Filter gte(SObjectField field, Datetime value) {
        return new GTE(field, value);
    }

    public static Filter gte(SObjectField field, Time value) {
        return new GTE(field, value);
    }

    public static Filter gte(SObjectField field, Id value) {
        return new GTE(field, value);
    }

    public static Filter gte(SObjectField field, String value) {
        return new GTE(field, value);
    }
    // #endregion
    // ===========

    // ==========
    // #region <
    private class LT extends ComparisonExpression {
        private LT(SObjectField field, Object value) {
            super(field, ' < ', value);
            this.tag = LT_TAG;
        }
    }

    public static Filter lt(SObjectField field, Decimal value) {
        return new LT(field, value);
    }

    public static Filter lt(SObjectField field, DateLiteral value) {
        return new LT(field, value);
    }

    public static Filter lt(SObjectField field, Date value) {
        return new LT(field, value);
    }

    public static Filter lt(SObjectField field, Datetime value) {
        return new LT(field, value);
    }

    public static Filter lt(SObjectField field, Time value) {
        return new LT(field, value);
    }

    public static Filter lt(SObjectField field, Id value) {
        return new LT(field, value);
    }

    public static Filter lt(SObjectField field, String value) {
        return new LT(field, value);
    }
    // #endregion
    // ==========

    // ==========
    // #region <=
    private class LTE extends ComparisonExpression {
        private LTE(SObjectField field, Object value) {
            super(field, ' <= ', value);
            this.tag = LTE_TAG;
        }
    }

    public static Filter lte(SObjectField field, Decimal value) {
        return new LTE(field, value);
    }

    public static Filter lte(SObjectField field, DateLiteral value) {
        return new LTE(field, value);
    }

    public static Filter lte(SObjectField field, Date value) {
        return new LTE(field, value);
    }

    public static Filter lte(SObjectField field, Datetime value) {
        return new LTE(field, value);
    }

    public static Filter lte(SObjectField field, Time value) {
        return new LTE(field, value);
    }

    public static Filter lte(SObjectField field, Id value) {
        return new LTE(field, value);
    }

    public static Filter lte(SObjectField field, String value) {
        return new LTE(field, value);
    }

    // #endregion
    // ==========

    // ===============
    // #region between
    // prettier-ignore
    public static Filter between(SObjectField field, Decimal fromValue, Decimal toValue) {
        return andx(gte(field, fromValue), lte(field, toValue));
    }
    // prettier-ignore
    public static Filter between(SObjectField field, DateLiteral fromValue, DateLiteral toValue) {
        return andx(gte(field, fromValue), lte(field, toValue));
    }
    // prettier-ignore
    public static Filter between(SObjectField field, Date fromValue, Date toValue) {
        return andx(gte(field, fromValue), lte(field, toValue));
    }
    // prettier-ignore
    public static Filter between(SObjectField field, Datetime fromValue, Datetime toValue) {
        return andx(gte(field, fromValue), lte(field, toValue));
    }
    // prettier-ignore
    public static Filter between(SObjectField field, Time fromValue, Time toValue) {
        return andx(gte(field, fromValue), lte(field, toValue));
    }
    // prettier-ignore
    public static Filter between(SObjectField field, Id fromValue, Id toValue) {
        return andx(gte(field, fromValue), lte(field, toValue));
    }
    // prettier-ignore
    public static Filter between(SObjectField field, String fromValue, String toValue) {
        return andx(gte(field, fromValue), lte(field, toValue));
    }
    // #endregion
    // ===============

    // ============
    // #region like
    private class LikeX extends ComparisonExpression {
        private LikeX(SObjectField field, String value) {
            super(field, ' LIKE ', value);
            this.tag = LIKEX_TAG;
        }
    }

    private class NLike extends ComparisonExpression {
        private NLike(SObjectField field, String value) {
            super(field, ' LIKE ', value);
            this.tag = NLIKE_TAG;
        }

        public override void build(List<String> fragments, Map<String, Object> tmpVars) {
            fragments.add('(NOT ');
            super.build(fragments, tmpVars);
            fragments.add(')');
        }
    }

    public static Filter likex(SObjectField field, String value) {
        return new LikeX(field, value);
    }

    public static Filter nlike(SObjectField field, String value) {
        return new NLike(field, value);
    }
    // #endregion
    // ============

    // ====================================
    // #region inx, nin, includes, excludes
    private class Includes extends ComparisonExpression {
        private Includes(SObjectField field, List<Object> values) {
            super(field, 'INCLUDES', values);
            this.tag = INCLUDES_TAG;
        }
    }

    private class Excludes extends ComparisonExpression {
        private Excludes(SObjectField field, List<Object> values) {
            super(field, 'EXCLUDES', values);
            this.tag = EXCLUDES_TAG;
        }
    }

    private class INX extends ComparisonExpression {
        private INX(SObjectField field, List<Object> values) {
            super(field, ' IN ', values);
            this.tag = INX_TAG;
        }
    }

    private class NIN extends ComparisonExpression {
        private NIN(SObjectField field, List<Object> values) {
            super(field, 'NOT IN', values);
            this.tag = NIN_TAG;
        }
    }

    private virtual class INX_Query extends ComparisonExpression {
        private INX_Query(SObjectField field, Boolean isNot, Query query) {
            super(field, isNot ? 'NOT IN' : 'IN', query);
            this.tag = INX_Query_TAG;
        }

        public override void build(List<String> fragments, Map<String, Object> tmpVars) {
            if (this.value instanceof QueryBuilder) {
                fragments.add(String.valueOf(this.field));
                fragments.add(' ');
                fragments.add(this.operator);
                fragments.add(' ');
                fragments.add('(');
                ((QueryBuilder) this.value).buildSoql(fragments, tmpVars);
                fragments.add(')');
            }
        }
    }

    public static Filter includes(SObjectField field, List<Object> values) {
        return new Includes(field, values);
    }

    public static Filter excludes(SObjectField field, List<Object> values) {
        return new Excludes(field, values);
    }

    public static Filter inx(SObjectField field, List<Object> values) {
        return new INX(field, values);
    }

    public static Filter inx(SObjectField field, Query query) {
        return new INX_Query(field, false, query);
    }

    public static Filter nin(SObjectField field, List<Object> values) {
        return new NIN(field, values);
    }

    public static Filter nin(SObjectField field, Query query) {
        return new INX_Query(field, true, query);
    }

    // #endregion
    // ====================================

    // ================
    // #region distance

    public class Distance {
        private SObjectField field { get; set; }
        private Location geo { get; set; }
        private String unit { get; set; }

        private Distance(SObjectField field, Location geo, String unit) {
            this.field = field;
            this.geo = geo;
            this.unit = unit;
        }

        private String build() {
            return 'DISTANCE(' +
                String.valueOf(this.field) +
                ', GEOLOCATION(' +
                this.geo.latitude +
                ',' +
                this.geo.longitude +
                '), \'' +
                this.unit +
                '\')';
        }

        public Boolean equals(Object obj) {
            if (this === obj) {
                return true;
            }

            Distance that = (Distance) obj;

            return this.field == that.field &&
                this.geo.latitude == that.geo.latitude &&
                this.geo.longitude == that.geo.longitude &&
                this.unit == that.unit;
        }
    }

    private static final String DISTANCE_UNIT_KM = 'km';
    private static final String DISTANCE_UNIT_MI = 'mi';

    public static Distance DISTANCE_IN_KILOMETER(SObjectField field, Location geo) {
        return new Distance(field, geo, DISTANCE_UNIT_KM);
    }

    public static Distance DISTANCE_IN_MILE(SObjectField field, Location geo) {
        return new Distance(field, geo, DISTANCE_UNIT_MI);
    }

    private class DistanceComparison extends ComparisonExpression {
        private DistanceComparison(Distance distance, String operator, Decimal value) {
            super(distance.field, operator, value);
            this.distance = distance;
            this.tag = DISTANCE_TAG;
        }

        public override void build(List<String> fragments, Map<String, Object> tmpVars) {
            fragments.add(this.distance.build());
            fragments.add(this.operator);
            fragments.add(String.valueOf(this.value));
        }
    }

    public static Filter gt(Distance distance, Decimal value) {
        return new DistanceComparison(distance, ' > ', value);
    }

    public static Filter gte(Distance distance, Decimal value) {
        return new DistanceComparison(distance, ' >= ', value);
    }

    public static Filter lt(Distance distance, Decimal value) {
        return new DistanceComparison(distance, ' < ', value);
    }

    public static Filter lte(Distance distance, Decimal value) {
        return new DistanceComparison(distance, ' <= ', value);
    }

    public static Filter between(Distance distance, Decimal fromValue, Decimal toValue) {
        return andx(gte(distance, fromValue), lte(distance, toValue));
    }

    public Query orderBy(Distance distance) {
        return this.orderBy(distance.build());
    }

    public Query orderBy(Distance distance1, Distance distance2) {
        return this.orderBy(distance1.build(), distance2.build());
    }

    public Query orderBy(Distance distance1, Distance distance2, Distance distance3) {
        return this.orderBy(distance1.build(), distance2.build(), distance3.build());
    }

    public Query orderBy(Distance distance1, Distance distance2, Distance distance3, Distance distance4) {
        return this.orderBy(distance1.build(), distance2.build(), distance3.build(), distance4.build());
    }

    public Query orderBy(
        Distance distance1,
        Distance distance2,
        Distance distance3,
        Distance distance4,
        Distance distance5
    ) {
        return this.orderBy(
            distance1.build(),
            distance2.build(),
            distance3.build(),
            distance4.build(),
            distance5.build()
        );
    }

    public Query orderBy(List<Distance> distances) {
        List<String> distStrings = new List<String>();

        for (Distance distance : distances) {
            distStrings.add(distance.build());
        }

        return this.orderBy(distStrings);
    }

    // #endregion
    // ================

    // =====================
    // #region Date Literals

    public class DateLiteral {
        public String value { get; set; }

        private DateLiteral(String value) {
            this.value = value;
        }

        public override String toString() {
            return this.value;
        }

        public Boolean equals(Object obj) {
            if (this === obj) {
                return true;
            }

            DateLiteral that = (DateLiteral) obj;
            return this.value == that.value;
        }
    }

    private class DateLiteralDictionary {
        private final DateLiteral YESTERDAY = new DateLiteral('YESTERDAY');
        private final DateLiteral TODAY = new DateLiteral('TODAY');
        private final DateLiteral TOMORROW = new DateLiteral('TOMORROW');
        private final DateLiteral LAST_WEEK = new DateLiteral('LAST_WEEK');
        private final DateLiteral THIS_WEEK = new DateLiteral('THIS_WEEK');
        private final DateLiteral NEXT_WEEK = new DateLiteral('NEXT_WEEK');
        private final DateLiteral LAST_MONTH = new DateLiteral('LAST_MONTH');
        private final DateLiteral THIS_MONTH = new DateLiteral('THIS_MONTH');
        private final DateLiteral NEXT_MONTH = new DateLiteral('NEXT_MONTH');
        private final DateLiteral LAST_90_DAYS = new DateLiteral('LAST_90_DAYS');
        private final DateLiteral NEXT_90_DAYS = new DateLiteral('NEXT_90_DAYS');
        private final DateLiteral THIS_QUARTER = new DateLiteral('THIS_QUARTER');
        private final DateLiteral LAST_QUARTER = new DateLiteral('LAST_QUARTER');
        private final DateLiteral NEXT_QUARTER = new DateLiteral('NEXT_QUARTER');
        private final DateLiteral THIS_YEAR = new DateLiteral('THIS_YEAR');
        private final DateLiteral LAST_YEAR = new DateLiteral('LAST_YEAR');
        private final DateLiteral NEXT_YEAR = new DateLiteral('NEXT_YEAR');
        private final DateLiteral THIS_FISCAL_QUARTER = new DateLiteral('THIS_FISCAL_QUARTER');
        private final DateLiteral LAST_FISCAL_QUARTER = new DateLiteral('LAST_FISCAL_QUARTER');
        private final DateLiteral NEXT_FISCAL_QUARTER = new DateLiteral('NEXT_FISCAL_QUARTER');
        private final DateLiteral THIS_FISCAL_YEAR = new DateLiteral('THIS_FISCAL_YEAR');
        private final DateLiteral LAST_FISCAL_YEAR = new DateLiteral('LAST_FISCAL_YEAR');
        private final DateLiteral NEXT_FISCAL_YEAR = new DateLiteral('NEXT_FISCAL_YEAR');
    }

    private static DateLiteralDictionary DTL {
        get {
            if (DTL == null) {
                DTL = new DateLiteralDictionary();
            }
            return DTL;
        }
        private set;
    }

    public static DateLiteral YESTERDAY() {
        return DTL.YESTERDAY;
    }

    public static DateLiteral TODAY() {
        return DTL.TODAY;
    }

    public static DateLiteral TOMORROW() {
        return DTL.TOMORROW;
    }

    public static DateLiteral LAST_WEEK() {
        return DTL.LAST_WEEK;
    }

    public static DateLiteral THIS_WEEK() {
        return DTL.THIS_WEEK;
    }

    public static DateLiteral NEXT_WEEK() {
        return DTL.NEXT_WEEK;
    }

    public static DateLiteral LAST_MONTH() {
        return DTL.LAST_MONTH;
    }

    public static DateLiteral THIS_MONTH() {
        return DTL.THIS_MONTH;
    }

    public static DateLiteral NEXT_MONTH() {
        return DTL.NEXT_MONTH;
    }

    public static DateLiteral LAST_90_DAYS() {
        return DTL.LAST_90_DAYS;
    }

    public static DateLiteral NEXT_90_DAYS() {
        return DTL.NEXT_90_DAYS;
    }

    public static DateLiteral THIS_QUARTER() {
        return DTL.THIS_QUARTER;
    }

    public static DateLiteral LAST_QUARTER() {
        return DTL.LAST_QUARTER;
    }

    public static DateLiteral NEXT_QUARTER() {
        return DTL.NEXT_QUARTER;
    }

    public static DateLiteral THIS_YEAR() {
        return DTL.THIS_YEAR;
    }

    public static DateLiteral LAST_YEAR() {
        return DTL.LAST_YEAR;
    }

    public static DateLiteral NEXT_YEAR() {
        return DTL.NEXT_YEAR;
    }

    public static DateLiteral THIS_FISCAL_QUARTER() {
        return DTL.THIS_FISCAL_QUARTER;
    }

    public static DateLiteral LAST_FISCAL_QUARTER() {
        return DTL.LAST_FISCAL_QUARTER;
    }

    public static DateLiteral NEXT_FISCAL_QUARTER() {
        return DTL.NEXT_FISCAL_QUARTER;
    }

    public static DateLiteral THIS_FISCAL_YEAR() {
        return DTL.THIS_FISCAL_YEAR;
    }

    public static DateLiteral LAST_FISCAL_YEAR() {
        return DTL.LAST_FISCAL_YEAR;
    }

    public static DateLiteral NEXT_FISCAL_YEAR() {
        return DTL.NEXT_FISCAL_YEAR;
    }

    public static DateLiteral LAST_N_DAYS(Integer n) {
        return new DateLiteral('LAST_N_DAYS:' + n);
    }

    public static DateLiteral NEXT_N_DAYS(Integer n) {
        return new DateLiteral('NEXT_N_DAYS:' + n);
    }

    public static DateLiteral N_DAYS_AGO(Integer n) {
        return new DateLiteral('N_DAYS_AGO:' + n);
    }

    public static DateLiteral NEXT_N_WEEKS(Integer n) {
        return new DateLiteral('NEXT_N_WEEKS:' + n);
    }

    public static DateLiteral LAST_N_WEEKS(Integer n) {
        return new DateLiteral('LAST_N_WEEKS:' + n);
    }

    public static DateLiteral N_WEEKS_AGO(Integer n) {
        return new DateLiteral('N_WEEKS_AGO:' + n);
    }

    public static DateLiteral NEXT_N_MONTHS(Integer n) {
        return new DateLiteral('NEXT_N_MONTHS:' + n);
    }

    public static DateLiteral LAST_N_MONTHS(Integer n) {
        return new DateLiteral('LAST_N_MONTHS:' + n);
    }

    public static DateLiteral N_MONTHS_AGO(Integer n) {
        return new DateLiteral('N_MONTHS_AGO:' + n);
    }

    public static DateLiteral NEXT_N_QUARTERS(Integer n) {
        return new DateLiteral('NEXT_N_QUARTERS:' + n);
    }

    public static DateLiteral LAST_N_QUARTERS(Integer n) {
        return new DateLiteral('LAST_N_QUARTERS:' + n);
    }

    public static DateLiteral N_QUARTERS_AGO(Integer n) {
        return new DateLiteral('N_QUARTERS_AGO:' + n);
    }

    public static DateLiteral NEXT_N_YEARS(Integer n) {
        return new DateLiteral('NEXT_N_YEARS:' + n);
    }

    public static DateLiteral LAST_N_YEARS(Integer n) {
        return new DateLiteral('LAST_N_YEARS:' + n);
    }

    public static DateLiteral N_YEARS_AGO(Integer n) {
        return new DateLiteral('N_YEARS_AGO:' + n);
    }

    public static DateLiteral NEXT_N_FISCAL_QUARTERS(Integer n) {
        return new DateLiteral('NEXT_N_FISCAL_QUARTERS:' + n);
    }

    public static DateLiteral N_FISCAL_QUARTERS_AGO(Integer n) {
        return new DateLiteral('N_FISCAL_QUARTERS_AGO:' + n);
    }

    public static DateLiteral NEXT_N_FISCAL_YEARS(Integer n) {
        return new DateLiteral('NEXT_N_FISCAL_YEARS:' + n);
    }

    public static DateLiteral LAST_N_FISCAL_YEARS(Integer n) {
        return new DateLiteral('LAST_N_FISCAL_YEARS:' + n);
    }

    public static DateLiteral N_FISCAL_YEARS_AGO(Integer n) {
        return new DateLiteral('N_FISCAL_YEARS_AGO:' + n);
    }

    // #endregion
    // =====================

    private static final Integer EQ_TAG = 1;
    private static final Integer NE_TAG = 2;
    private static final Integer GT_TAG = 3;
    private static final Integer GTE_TAG = 4;
    private static final Integer LT_TAG = 5;
    private static final Integer LTE_TAG = 6;
    private static final Integer LIKEX_TAG = 7;
    private static final Integer NLIKE_TAG = 8;
    private static final Integer INCLUDES_TAG = 9;
    private static final Integer EXCLUDES_TAG = 10;
    private static final Integer INX_TAG = 11;
    private static final Integer NIN_TAG = 12;
    private static final Integer INX_QUERY_TAG = 13;
    private static final Integer DISTANCE_TAG = 14;
    private static final Integer AND_TAG = 15;
    private static final Integer OR_TAG = 16;
    private static final Integer GROUPING_TAG = 17;
    private static final Integer COUNT_TAG = 18;
    private static final Integer SUM_TAG = 19;
    private static final Integer AVG_TAG = 20;
    private static final Integer MAX_TAG = 21;
    private static final Integer MIN_TAG = 22;

    // prettier-ignore
    public interface Querable {
        // Select
        Query selectAll();
        Query selectBy(Selector selector);
        Query selectBy(SObjectField field);
        Query selectBy(SObjectField field1, SObjectField field2);
        Query selectBy(SObjectField field1, SObjectField field2, SObjectField field3);
        Query selectBy(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        Query selectBy(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);
        Query selectBy(List<SObjectField> fields);
        Query selectBy(String relationName, Query query);

        // Group By
        Query grouping(SObjectField field);
        Query grouping(SObjectField field, String alias);
        Query count();
        Query count(SObjectField field);
        Query count(SObjectField field, String alias);
        Query sum(SObjectField field);
        Query sum(SObjectField field, String alias);
        Query avg(SObjectField field);
        Query avg(SObjectField field, String alias);
        Query max(SObjectField field);
        Query max(SObjectField field, String alias);
        Query min(SObjectField field);
        Query min(SObjectField field, String alias);

        Query groupBy(SObjectField field);
        Query groupBy(SObjectField field1, SObjectField field2);
        Query groupBy(SObjectField field1, SObjectField field2, SObjectField field3);
        Query groupBy(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        Query groupBy(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);
        Query groupBy(List<SObjectField> fields);
        Query rollup();
        Query cube();

        // Order By
        Query orderBy(String name);
        Query orderBy(String name1, String name2);
        Query orderBy(String name1, String name2, String name3);
        Query orderBy(String name1, String name2, String name3, String name4);
        Query orderBy(String name1, String name2, String name3, String name4, String name5);
        Query orderBy(List<String> names);
        Query orderBy(Distance distance);
        Query orderBy(Distance distance1, Distance distance2);
        Query orderBy(Distance distance1, Distance distance2, Distance distance3);
        Query orderBy(Distance distance1, Distance distance2, Distance distance3, Distance distance4);
        Query orderBy(Distance distance1, Distance distance2, Distance distance3, Distance distance4, Distance distance5);
        Query orderBy(List<Distance> distances);
        Query ascending();
        Query descending();
        Query nullsFirst();
        Query nullsLast();

        // Misc
        Query offset(Integer n);
        Query limitx(Integer n);
        Query forView();
        Query forReference();
        Query forUpdate();

        Query filterBy(Filter filter);
        Object run();
        Object run(AccessLevel accessLevel);
        Integer getCount();
        Integer getCount(AccessLevel accessLevel);
        Database.QueryLocator getLocator();
        Database.QueryLocator getLocator(AccessLevel accessLevel);
    }
}
