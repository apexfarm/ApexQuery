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

public virtual class Query implements Querable {
    public interface Querable extends Orderable {
        List<SObject> run();
        // List<SObject> run(AccessLevel accessLevel);
        // Database.QueryLocator getLocator();
        // Database.QueryLocator getLocator(AccessLevel accessLevel);
        // Integer getCount();
        // Integer getCount(AccessLevel accessLevel);

        Query whereBy(Filter whereFilters);
        // Query groupBy(Filter groupBy);
        Query havingBy(Filter havingFilters);

        Query offset(Integer n);
        Query limitx(Integer n);

        Query forView();
        Query forReference();
        Query updateTracking();
        Query updateViewstat();
        Query forUpdate();
    }

    public interface Filter {
        void buildSOQL(List<String> fragments, Map<String, Object> tmpVars);
    }

    public interface CompositeFilter extends Filter {
        CompositeFilter add(Filter filter);
    }

    public class GroupBy {
        private List<String> fieldOrFuncs = new List<String>();
        private Boolean rollup { get; set; }
        private Boolean cube { get; set; }

        private Boolean isEmpty() {
            return this.fieldOrFuncs.isEmpty();
        }
    }

    private String objectName { get; set; }
    private List<String> selectFields = new List<String>();
    private Map<String, Query> selectParent = new Map<String, Query>();
    private Map<String, Query> selectChildren = new Map<String, Query>();

    private Filter whereFilters;
    private Filter havingFilters;
    private GroupBy groupBy = new GroupBy();
    private List<OrderByField> orderBys = new List<OrderByField>();

    private Integer offset { get; set; }
    private Integer limitx { get; set; }

    private Boolean forView { get; set; }
    private Boolean forReference { get; set; }
    private Boolean updateTracking { get; set; }
    private Boolean updateViewstat { get; set; }
    private Boolean forUpdate { get; set; }

    public static Query of(String objectName) {
        return new Query(objectName);
    }

    public Query() {
    }

    private Query(String objectName) {
        this.objectName = objectName;
    }

    public Query whereBy(Filter whereFilters) {
        this.whereFilters = whereFilters;
        return this;
    }

    public Query havingBy(Filter havingFilters) {
        this.havingFilters = havingFilters;
        return this;
    }

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

    public Query updateTracking() {
        this.updateTracking = true;
        return this;
    }

    public Query updateViewstat() {
        this.updateViewstat = true;
        return this;
    }

    public Query forUpdate() {
        this.forUpdate = true;
        return this;
    }

    public List<SObject> run() {
        String soql = buildSOQL();
        return Database.query(soql);
    }

    // ====================
    // #region SOQL Builder

    public String buildSOQL() {
        List<String> fragments = new List<String>();
        Map<String, Object> tmpVars = new Map<String, Object>();
        fragments.add('SELECT ');
        if (this.selectFields.size() > 0) {
            fragments.add(String.join(this.selectFields, ', '));
        } else {
            fragments.add('Id');
        }

        fragments.add(' FROM ');
        fragments.add(this.objectName);

        if (this.whereFilters != null) {
            fragments.add(' WHERE ');
            this.whereFilters.buildSOQL(fragments, tmpVars);
        }

        if (!this.groupBy.isEmpty()) {
            fragments.add(' GROUP BY ');
            if (this.havingFilters != null) {
                fragments.add(' HAVING ');
                this.havingFilters.buildSOQL(fragments, tmpVars);
            }
        }

        if (this.limitx != null) {
            fragments.add(' LIMIT ');
            fragments.add(String.valueOf(this.limitx));
        }

        if (this.offset != null) {
            fragments.add(' OFFSET ');
            fragments.add(String.valueOf(this.offset));
        }

        // * SOQL can only has one of the following
        if (this.forView == true) {
            fragments.add(' FOR VIEW');
        } else if (this.forReference == true) {
            fragments.add(' FOR REFERENCE');
        } else if (this.updateTracking == true) {
            fragments.add(' UPDATE TRACKING');
        } else if (this.updateViewstat == true) {
            fragments.add(' UPDATE VIEWSTAT');
        } else if (this.forUpdate == true) {
            fragments.add(' FOR UPDATE');
        }

        return String.join(fragments, '');
    }

    // #endregion
    // ====================

    // =====================
    // #region Logical Filter
    private virtual class LogicalFilter implements CompositeFilter {
        private List<Filter> filters { get; set; }
        private String operator { get; set; }

        private LogicalFilter(String operator, List<Filter> filters) {
            this.operator = operator;
            this.filters = filters;
        }

        public CompositeFilter add(Filter filter) {
            this.filters.add(filter);
            return this;
        }

        public virtual void buildSOQL(List<String> fragments, Map<String, Object> tmpVars) {
            if (this.filters.isEmpty()) {
                return;
            }

            fragments.add('(');
            Integer index = 0;
            for (Filter filter : this.filters) {
                if (index > 0) {
                    fragments.add(this.operator);
                }
                filter.buildSOQL(fragments, tmpVars);
                index++;
            }
            fragments.add(')');
        }
    }

    private class NotLogicalFilter extends LogicalFilter {
        private NotLogicalFilter(Filter filter) {
            super('NOT', new List<Filter>{ filter });
        }

        public override void buildSOQL(List<String> fragments, Map<String, Object> tmpVars) {
            if (this.filters.isEmpty()) {
                return;
            }

            Filter filter = this.filters[0];
            if (filter instanceof CompositeFilter) {
                fragments.add('NOT');
                filter.buildSOQL(fragments, tmpVars);
            } else {
                fragments.add('NOT(');
                filter.buildSOQL(fragments, tmpVars);
                fragments.add(')');
            }
        }
    }

    public static Filter notx(Filter filter) {
        return new NotLogicalFilter(filter);
    }

    public static CompositeFilter orx() {
        return new LogicalFilter(' OR ', new List<Filter>());
    }

    public static CompositeFilter orx(List<Filter> filters) {
        return new LogicalFilter(' OR ', filters);
    }

    public static CompositeFilter andx() {
        return new LogicalFilter(' AND ', new List<Filter>());
    }

    public static CompositeFilter andx(List<Filter> filters) {
        return new LogicalFilter(' AND ', filters);
    }

    // #endregion
    // =====================

    // =========================
    // #region Comparison Filter

    private virtual class ComparisonFilter implements Filter {
        private String fieldOrFunc { get; set; }
        private String operator { get; set; }
        private Object value { get; set; }

        private ComparisonFilter(String fieldOrFunc, String operator, Object value) {
            this.fieldOrFunc = fieldOrFunc;
            this.operator = operator;
            this.value = value;
        }

        public virtual void buildSOQL(List<String> fragments, Map<String, Object> tmpVars) {
            fragments.add(this.fieldOrFunc);
            fragments.add(this.operator);
            if (value == null) {
                fragments.add('NULL');
            } else {
                String tmpVar = 'tmpVar' + (tmpVars.size() + 1);
                tmpVars.put(tmpVar, value);
                fragments.add(':');
                fragments.add(tmpVar);
            }
        }
    }

    private class MultiComparisonFilter extends ComparisonFilter {
        private MultiComparisonFilter(String field, String operator, List<String> values) {
            super(field, operator, values);
        }

        public override void buildSOQL(List<String> fragments, Map<String, Object> tmpVars) {
            fragments.add(this.fieldOrFunc);
            fragments.add(this.operator);
            fragments.add('(');
            Boolean isFirst = true;
            for (string value : (List<String>) this.value) {
                if (isFirst) {
                    isFirst = false;
                } else {
                    fragments.add(', ');
                }

                String tmpVar = 'tmpVar' + (tmpVars.size() + 1);
                tmpVars.put(tmpVar, value);
                fragments.add(':');
                fragments.add(tmpVar);
            }
            fragments.add(')');
        }
    }

    public static Filter eq(String fieldOrFunc, Object value) {
        return new ComparisonFilter(fieldOrFunc, ' = ', value);
    }
    public static Filter eqNull(String fieldOrFunc) {
        return new ComparisonFilter(fieldOrFunc, ' = ', null);
    }

    public static Filter ne(String fieldOrFunc, Object value) {
        return new ComparisonFilter(fieldOrFunc, ' != ', value);
    }

    public static Filter neNull(String fieldOrFunc) {
        return new ComparisonFilter(fieldOrFunc, ' != ', null);
    }

    public static Filter gt(String fieldOrFunc, Object value) {
        return new ComparisonFilter(fieldOrFunc, ' > ', value);
    }

    public static Filter gte(String fieldOrFunc, Object value) {
        return new ComparisonFilter(fieldOrFunc, ' >= ', value);
    }

    public static Filter lt(String fieldOrFunc, Object value) {
        return new ComparisonFilter(fieldOrFunc, ' < ', value);
    }

    public static Filter lte(String fieldOrFunc, Object value) {
        return new ComparisonFilter(fieldOrFunc, ' <= ', value);
    }

    public static Filter likex(String field, String value) {
        return new ComparisonFilter(field, ' LIKE ', value);
    }

    public static Filter nlike(String field, String value) {
        return notx(likex(field, value));
    }

    public static Filter inx(String fieldOrFunc, List<Object> values) {
        return new ComparisonFilter(fieldOrFunc, ' IN ', values);
    }

    public static Filter nin(String fieldOrFunc, List<Object> values) {
        return new ComparisonFilter(fieldOrFunc, ' NOT IN ', values);
    }

    public static Filter includes(String field, List<String> values) {
        return new MultiComparisonFilter(field, ' INCLUDES ', values);
    }

    public static Filter excludes(String field, List<String> values) {
        return new MultiComparisonFilter(field, ' EXCLUDES ', values);
    }

    public static Filter between(String fieldOrFunc, Object minValue, Object maxValue) {
        return andx().add(gte(fieldOrFunc, minValue)).add(lte(fieldOrFunc, maxValue));
    }

    // #endregion
    // =========================

    // ==============
    // #region Select
    public interface Selectable {
        Query selectFields(String field);
        Query selectFields(String field1, String field2);
        Query selectFields(String field1, String field2, String field3);
        Query selectFields(String field1, String field2, String field3, String field4);
        Query selectFields(String field1, String field2, String field3, String field4, String field5);
        Query selectFields(String field1, String field2, String field3, String field4, String field5, String field6);
        Query selectFields(
            String field1,
            String field2,
            String field3,
            String field4,
            String field5,
            String field6,
            String field7
        );
        Query selectFields(
            String field1,
            String field2,
            String field3,
            String field4,
            String field5,
            String field6,
            String field7,
            String field8
        );
        Query selectFields(
            String field1,
            String field2,
            String field3,
            String field4,
            String field5,
            String field6,
            String field7,
            String field8,
            String field9
        );
        Query selectFields(
            String field1,
            String field2,
            String field3,
            String field4,
            String field5,
            String field6,
            String field7,
            String field8,
            String field9,
            String field10
        );
        Query selectFields(List<String> fields);

        Query selectParent(String relationshipName, Query query);
        Query selectChildren(String relationshipName, Query query);
    }

    public Query selectFields(String field) {
        this.selectFields.add(field);
        return this;
    }

    public Query selectFields(String field1, String field2) {
        this.selectFields.add(field1);
        this.selectFields.add(field2);
        return this;
    }

    public Query selectFields(String field1, String field2, String field3) {
        this.selectFields.add(field1);
        this.selectFields.add(field2);
        this.selectFields.add(field3);
        return this;
    }

    public Query selectFields(String field1, String field2, String field3, String field4) {
        this.selectFields.addAll(new List<String>{ field1, field2, field3, field4 });
        return this;
    }

    public Query selectFields(String field1, String field2, String field3, String field4, String field5) {
        this.selectFields.addAll(new List<String>{ field1, field2, field3, field4, field5 });
        return this;
    }

    public Query selectFields(
        String field1,
        String field2,
        String field3,
        String field4,
        String field5,
        String field6
    ) {
        this.selectFields.addAll(new List<String>{ field1, field2, field3, field4, field5, field6 });
        return this;
    }

    public Query selectFields(
        String field1,
        String field2,
        String field3,
        String field4,
        String field5,
        String field6,
        String field7
    ) {
        this.selectFields.addAll(new List<String>{ field1, field2, field3, field4, field5, field6, field7 });
        return this;
    }

    public Query selectFields(
        String field1,
        String field2,
        String field3,
        String field4,
        String field5,
        String field6,
        String field7,
        String field8
    ) {
        this.selectFields.addAll(new List<String>{ field1, field2, field3, field4, field5, field6, field7, field8 });
        return this;
    }

    public Query selectFields(
        String field1,
        String field2,
        String field3,
        String field4,
        String field5,
        String field6,
        String field7,
        String field8,
        String field9
    ) {
        this.selectFields.addAll(
            new List<String>{ field1, field2, field3, field4, field5, field6, field7, field8, field9 }
        );
        return this;
    }

    public Query selectFields(
        String field1,
        String field2,
        String field3,
        String field4,
        String field5,
        String field6,
        String field7,
        String field8,
        String field9,
        String field10
    ) {
        this.selectFields.addAll(
            new List<String>{ field1, field2, field3, field4, field5, field6, field7, field8, field9, field10 }
        );
        return this;
    }

    public Query selectFields(List<String> fields) {
        this.selectFields.addAll(fields);
        return this;
    }

    public Query selectParent(String relationshipName, Query query) {
        this.selectParent.put(relationshipName, query);
        return this;
    }

    public Query selectChildren(String relationshipName, Query query) {
        this.selectChildren.put(relationshipName, query);
        return this;
    }
    // #endregion
    // ==============

    // ================
    // #region Order By

    public interface Orderable extends Selectable {
        Query orderBy(OrderByField field);
        Query orderBy(OrderByField field1, OrderByField field2);
        Query orderBy(OrderByField field1, OrderByField field2, OrderByField field3);
        Query orderBy(OrderByField field1, OrderByField field2, OrderByField field3, OrderByField field4);
        Query orderBy(
            OrderByField field1,
            OrderByField field2,
            OrderByField field3,
            OrderByField field4,
            OrderByField field5
        );
        Query orderBy(
            OrderByField field1,
            OrderByField field2,
            OrderByField field3,
            OrderByField field4,
            OrderByField field5,
            OrderByField field6
        );
        Query orderBy(
            OrderByField field1,
            OrderByField field2,
            OrderByField field3,
            OrderByField field4,
            OrderByField field5,
            OrderByField field6,
            OrderByField field7
        );
        Query orderBy(
            OrderByField field1,
            OrderByField field2,
            OrderByField field3,
            OrderByField field4,
            OrderByField field5,
            OrderByField field6,
            OrderByField field7,
            OrderByField field8
        );
        Query orderBy(
            OrderByField field1,
            OrderByField field2,
            OrderByField field3,
            OrderByField field4,
            OrderByField field5,
            OrderByField field6,
            OrderByField field7,
            OrderByField field8,
            OrderByField field9
        );
        Query orderBy(
            OrderByField field1,
            OrderByField field2,
            OrderByField field3,
            OrderByField field4,
            OrderByField field5,
            OrderByField field6,
            OrderByField field7,
            OrderByField field8,
            OrderByField field9,
            OrderByField field10
        );
        Query orderBy(List<OrderByField> fields);
    }

    public class OrderByField {
        private String fieldOrFunc { get; set; }
        private Boolean ascending { get; set; }
        private Boolean nullsFist { get; set; }

        public OrderByField(String fieldOrFunc) {
            this.fieldOrFunc = fieldOrFunc;
            this.ascending = true;
            this.nullsFist = true;
        }

        public OrderByField ascending() {
            this.ascending = true;
            return this;
        }

        public OrderByField descending() {
            this.ascending = false;
            return this;
        }

        public OrderByField nullsFirst() {
            this.nullsFist = true;
            return this;
        }

        public OrderByField nullsLast() {
            this.nullsFist = false;
            return this;
        }
    }

    public Query orderBy(OrderByField field) {
        this.orderBys.add(field);
        return this;
    }

    public Query orderBy(OrderByField field1, OrderByField field2) {
        this.orderBys.add(field1);
        this.orderBys.add(field2);
        return this;
    }

    public Query orderBy(OrderByField field1, OrderByField field2, OrderByField field3) {
        this.orderBys.add(field1);
        this.orderBys.add(field2);
        this.orderBys.add(field3);
        return this;
    }

    public Query orderBy(OrderByField field1, OrderByField field2, OrderByField field3, OrderByField field4) {
        this.orderBys.addAll(new List<OrderByField>{ field1, field2, field3, field4 });
        return this;
    }

    public Query orderBy(
        OrderByField field1,
        OrderByField field2,
        OrderByField field3,
        OrderByField field4,
        OrderByField field5
    ) {
        this.orderBys.addAll(new List<OrderByField>{ field1, field2, field3, field4, field5 });
        return this;
    }

    public Query orderBy(
        OrderByField field1,
        OrderByField field2,
        OrderByField field3,
        OrderByField field4,
        OrderByField field5,
        OrderByField field6
    ) {
        this.orderBys.addAll(new List<OrderByField>{ field1, field2, field3, field4, field5, field6 });
        return this;
    }

    public Query orderBy(
        OrderByField field1,
        OrderByField field2,
        OrderByField field3,
        OrderByField field4,
        OrderByField field5,
        OrderByField field6,
        OrderByField field7
    ) {
        this.orderBys.addAll(new List<OrderByField>{ field1, field2, field3, field4, field5, field6, field7 });
        return this;
    }

    public Query orderBy(
        OrderByField field1,
        OrderByField field2,
        OrderByField field3,
        OrderByField field4,
        OrderByField field5,
        OrderByField field6,
        OrderByField field7,
        OrderByField field8
    ) {
        this.orderBys.addAll(new List<OrderByField>{ field1, field2, field3, field4, field5, field6, field7, field8 });
        return this;
    }

    public Query orderBy(
        OrderByField field1,
        OrderByField field2,
        OrderByField field3,
        OrderByField field4,
        OrderByField field5,
        OrderByField field6,
        OrderByField field7,
        OrderByField field8,
        OrderByField field9
    ) {
        this.orderBys.addAll(
            new List<OrderByField>{ field1, field2, field3, field4, field5, field6, field7, field8, field9 }
        );
        return this;
    }

    public Query orderBy(
        OrderByField field1,
        OrderByField field2,
        OrderByField field3,
        OrderByField field4,
        OrderByField field5,
        OrderByField field6,
        OrderByField field7,
        OrderByField field8,
        OrderByField field9,
        OrderByField field10
    ) {
        this.orderBys.addAll(
            new List<OrderByField>{ field1, field2, field3, field4, field5, field6, field7, field8, field9, field10 }
        );
        return this;
    }

    public Query orderBy(List<OrderByField> fields) {
        this.orderBys.addAll(fields);
        return this;
    }

    // #endregion
    // ================

    // ==========================
    // #region Group By Functions
    public static String GROUPING(String field) {
        return 'GROUPING(' + field + ')';
    }

    public static String GROUPING(String field, String alias) {
        return 'GROUPING(' + field + ') ' + alias;
    }

    public static String COUNT(String field) {
        return 'COUNT(' + field + ')';
    }

    public static String COUNT(String field, String alias) {
        return 'COUNT(' + field + ') ' + alias;
    }

    public static String COUNT_DISTINCT(String field) {
        return 'COUNT_DISTINCT(' + field + ')';
    }

    public static String COUNT_DISTINCT(String field, String alias) {
        return 'COUNT_DISTINCT(' + field + ') ' + alias;
    }

    public static String SUM(String field) {
        return 'SUM(' + field + ')';
    }

    public static String SUM(String field, String alias) {
        return 'SUM(' + field + ') ' + alias;
    }

    public static String AVG(String field) {
        return 'AVG(' + field + ')';
    }

    public static String AVG(String field, String alias) {
        return 'AVG(' + field + ') ' + alias;
    }

    public static String MAX(String field) {
        return 'MAX(' + field + ')';
    }

    public static String MAX(String field, String alias) {
        return 'MAX(' + field + ') ' + alias;
    }

    public static String MIN(String field) {
        return 'MIN(' + field + ')';
    }

    public static String MIN(String field, String alias) {
        return 'MIN(' + field + ') ' + alias;
    }
    // #endregion
    // ==========================

    // ========================
    // #region Utility Function
    public static String TO_LABEL(String field) {
        return 'TOLABEL(' + field + ')';
    }

    public static String FORMAT(String field) {
        return 'FORMAT(' + field + ')';
    }

    public static String CONVERT_CURRENCY(String field) {
        return 'CONVERTCURRENCY(' + field + ')';
    }

    public static String DISTANCE(String field, Location geo, string unit) {
        return 'DISTANCE(' +
            String.valueOf(field) +
            ', GEOLOCATION(' +
            geo.latitude +
            ', ' +
            geo.longitude +
            '), \'' +
            unit +
            '\')';
    }
    // #endregion
    // ========================

    // =======================
    // #region Date Function

    public static String CALENDAR_MONTH(String field) {
        return 'CALENDAR_MONTH(' + field + ')';
    }

    public static String CALENDAR_QUARTER(String field) {
        return 'CALENDAR_QUARTER(' + field + ')';
    }

    public static String CALENDAR_YEAR(String field) {
        return 'CALENDAR_YEAR(' + field + ')';
    }

    public static String DAY_IN_MONTH(String field) {
        return 'DAY_IN_MONTH(' + field + ')';
    }

    public static String DAY_IN_WEEK(String field) {
        return 'DAY_IN_WEEK(' + field + ')';
    }

    public static String DAY_IN_YEAR(String field) {
        return 'DAY_IN_YEAR(' + field + ')';
    }

    public static String DAY_ONLY(String field) {
        return 'DAY_ONLY(' + field + ')';
    }

    public static String FISCAL_MONTH(String field) {
        return 'FISCAL_MONTH(' + field + ')';
    }

    public static String FISCAL_QUARTER(String field) {
        return 'FISCAL_QUARTER(' + field + ')';
    }

    public static String FISCAL_YEAR(String field) {
        return 'FISCAL_YEAR(' + field + ')';
    }

    public static String HOUR_IN_DAY(String field) {
        return 'HOUR_IN_DAY(' + field + ')';
    }

    public static String WEEK_IN_MONTH(String field) {
        return 'WEEK_IN_MONTH(' + field + ')';
    }

    public static String WEEK_IN_YEAR(String field) {
        return 'WEEK_IN_YEAR(' + field + ')';
    }

    public static String CONVERT_TIMEZONE(String field) {
        return 'CONVERTTIMEZONE(' + field + ')';
    }

    // #endregion
    // =======================

    // ====================
    // #region Date Literal
    public static String YESTERDAY() {
        return 'YESTERDAY';
    }

    public static String TODAY() {
        return 'TODAY';
    }

    public static String TOMORROW() {
        return 'TOMORROW';
    }

    public static String LAST_WEEK() {
        return 'LAST_WEEK';
    }

    public static String THIS_WEEK() {
        return 'THIS_WEEK';
    }

    public static String NEXT_WEEK() {
        return 'NEXT_WEEK';
    }

    public static String LAST_MONTH() {
        return 'LAST_MONTH';
    }

    public static String THIS_MONTH() {
        return 'THIS_MONTH';
    }

    public static String NEXT_MONTH() {
        return 'NEXT_MONTH';
    }

    public static String LAST_90_DAYS() {
        return 'LAST_90_DAYS';
    }

    public static String NEXT_90_DAYS() {
        return 'NEXT_90_DAYS';
    }

    public static String THIS_QUARTER() {
        return 'THIS_QUARTER';
    }

    public static String LAST_QUARTER() {
        return 'LAST_QUARTER';
    }

    public static String NEXT_QUARTER() {
        return 'NEXT_QUARTER';
    }

    public static String THIS_YEAR() {
        return 'THIS_YEAR';
    }

    public static String LAST_YEAR() {
        return 'LAST_YEAR';
    }

    public static String NEXT_YEAR() {
        return 'NEXT_YEAR';
    }

    public static String THIS_FISCAL_QUARTER() {
        return 'THIS_FISCAL_QUARTER';
    }

    public static String LAST_FISCAL_QUARTER() {
        return 'LAST_FISCAL_QUARTER';
    }

    public static String NEXT_FISCAL_QUARTER() {
        return 'NEXT_FISCAL_QUARTER';
    }

    public static String THIS_FISCAL_YEAR() {
        return 'THIS_FISCAL_YEAR';
    }

    public static String LAST_FISCAL_YEAR() {
        return 'LAST_FISCAL_YEAR';
    }

    public static String NEXT_FISCAL_YEAR() {
        return 'NEXT_FISCAL_YEAR';
    }

    public static String LAST_N_DAYS(Integer n) {
        return 'LAST_N_DAYS:' + n;
    }

    public static String NEXT_N_DAYS(Integer n) {
        return 'NEXT_N_DAYS:' + n;
    }

    public static String N_DAYS_AGO(Integer n) {
        return 'N_DAYS_AGO:' + n;
    }

    public static String NEXT_N_WEEKS(Integer n) {
        return 'NEXT_N_WEEKS:' + n;
    }

    public static String LAST_N_WEEKS(Integer n) {
        return 'LAST_N_WEEKS:' + n;
    }

    public static String N_WEEKS_AGO(Integer n) {
        return 'N_WEEKS_AGO:' + n;
    }

    public static String NEXT_N_MONTHS(Integer n) {
        return 'NEXT_N_MONTHS:' + n;
    }

    public static String LAST_N_MONTHS(Integer n) {
        return 'LAST_N_MONTHS:' + n;
    }

    public static String N_MONTHS_AGO(Integer n) {
        return 'N_MONTHS_AGO:' + n;
    }

    public static String NEXT_N_QUARTERS(Integer n) {
        return 'NEXT_N_QUARTERS:' + n;
    }

    public static String LAST_N_QUARTERS(Integer n) {
        return 'LAST_N_QUARTERS:' + n;
    }

    public static String N_QUARTERS_AGO(Integer n) {
        return 'N_QUARTERS_AGO:' + n;
    }

    public static String NEXT_N_YEARS(Integer n) {
        return 'NEXT_N_YEARS:' + n;
    }

    public static String LAST_N_YEARS(Integer n) {
        return 'LAST_N_YEARS:' + n;
    }

    public static String N_YEARS_AGO(Integer n) {
        return 'N_YEARS_AGO:' + n;
    }

    public static String NEXT_N_FISCAL_QUARTERS(Integer n) {
        return 'NEXT_N_FISCAL_QUARTERS:' + n;
    }

    public static String N_FISCAL_QUARTERS_AGO(Integer n) {
        return 'N_FISCAL_QUARTERS_AGO:' + n;
    }

    public static String NEXT_N_FISCAL_YEARS(Integer n) {
        return 'NEXT_N_FISCAL_YEARS:' + n;
    }

    public static String LAST_N_FISCAL_YEARS(Integer n) {
        return 'LAST_N_FISCAL_YEARS:' + n;
    }

    public static String N_FISCAL_YEARS_AGO(Integer n) {
        return 'N_FISCAL_YEARS_AGO:' + n;
    }

    // #endregion
    // ====================

    // ========================
    // #region Currency Literal
    public static String CURRENCY(String code, Decimal value) {
        return code + value;
    }

    public static String AED(Decimal value) {
        return 'AED' + value;
    }

    public static String AFN(Decimal value) {
        return 'AFN' + value;
    }

    public static String ALL(Decimal value) {
        return 'ALL' + value;
    }

    public static String AMD(Decimal value) {
        return 'AMD' + value;
    }

    public static String ANG(Decimal value) {
        return 'ANG' + value;
    }

    public static String AOA(Decimal value) {
        return 'AOA' + value;
    }

    public static String ARS(Decimal value) {
        return 'ARS' + value;
    }

    public static String AUD(Decimal value) {
        return 'AUD' + value;
    }

    public static String AWG(Decimal value) {
        return 'AWG' + value;
    }

    public static String AZN(Decimal value) {
        return 'AZN' + value;
    }

    public static String BAM(Decimal value) {
        return 'BAM' + value;
    }

    public static String BBD(Decimal value) {
        return 'BBD' + value;
    }

    public static String BDT(Decimal value) {
        return 'BDT' + value;
    }

    public static String BGN(Decimal value) {
        return 'BGN' + value;
    }

    public static String BHD(Decimal value) {
        return 'BHD' + value;
    }

    public static String BIF(Decimal value) {
        return 'BIF' + value;
    }

    public static String BMD(Decimal value) {
        return 'BMD' + value;
    }

    public static String BND(Decimal value) {
        return 'BND' + value;
    }

    public static String BOB(Decimal value) {
        return 'BOB' + value;
    }

    public static String BRL(Decimal value) {
        return 'BRL' + value;
    }

    public static String BSD(Decimal value) {
        return 'BSD' + value;
    }

    public static String BTN(Decimal value) {
        return 'BTN' + value;
    }

    public static String BWP(Decimal value) {
        return 'BWP' + value;
    }

    public static String BYN(Decimal value) {
        return 'BYN' + value;
    }

    public static String BZD(Decimal value) {
        return 'BZD' + value;
    }

    public static String CAD(Decimal value) {
        return 'CAD' + value;
    }

    public static String CDF(Decimal value) {
        return 'CDF' + value;
    }

    public static String CHF(Decimal value) {
        return 'CHF' + value;
    }

    public static String CLP(Decimal value) {
        return 'CLP' + value;
    }

    public static String CNY(Decimal value) {
        return 'CNY' + value;
    }

    public static String COP(Decimal value) {
        return 'COP' + value;
    }

    public static String CRC(Decimal value) {
        return 'CRC' + value;
    }

    public static String CSD(Decimal value) {
        return 'CSD' + value;
    }

    public static String CUP(Decimal value) {
        return 'CUP' + value;
    }

    public static String CVE(Decimal value) {
        return 'CVE' + value;
    }

    public static String CZK(Decimal value) {
        return 'CZK' + value;
    }

    public static String DJF(Decimal value) {
        return 'DJF' + value;
    }

    public static String DKK(Decimal value) {
        return 'DKK' + value;
    }

    public static String DOP(Decimal value) {
        return 'DOP' + value;
    }

    public static String DZD(Decimal value) {
        return 'DZD' + value;
    }

    public static String EGP(Decimal value) {
        return 'EGP' + value;
    }

    public static String ERN(Decimal value) {
        return 'ERN' + value;
    }

    public static String ETB(Decimal value) {
        return 'ETB' + value;
    }

    public static String EUR(Decimal value) {
        return 'EUR' + value;
    }

    public static String FJD(Decimal value) {
        return 'FJD' + value;
    }

    public static String FKP(Decimal value) {
        return 'FKP' + value;
    }

    public static String GBP(Decimal value) {
        return 'GBP' + value;
    }

    public static String GEL(Decimal value) {
        return 'GEL' + value;
    }

    public static String GHS(Decimal value) {
        return 'GHS' + value;
    }

    public static String GIP(Decimal value) {
        return 'GIP' + value;
    }

    public static String GMD(Decimal value) {
        return 'GMD' + value;
    }

    public static String GNF(Decimal value) {
        return 'GNF' + value;
    }

    public static String GTQ(Decimal value) {
        return 'GTQ' + value;
    }

    public static String GYD(Decimal value) {
        return 'GYD' + value;
    }

    public static String HKD(Decimal value) {
        return 'HKD' + value;
    }

    public static String HNL(Decimal value) {
        return 'HNL' + value;
    }

    public static String HRK(Decimal value) {
        return 'HRK' + value;
    }

    public static String HTG(Decimal value) {
        return 'HTG' + value;
    }

    public static String HUF(Decimal value) {
        return 'HUF' + value;
    }

    public static String IDR(Decimal value) {
        return 'IDR' + value;
    }

    public static String ILS(Decimal value) {
        return 'ILS' + value;
    }

    public static String INR(Decimal value) {
        return 'INR' + value;
    }

    public static String IQD(Decimal value) {
        return 'IQD' + value;
    }

    public static String IRR(Decimal value) {
        return 'IRR' + value;
    }

    public static String ISK(Decimal value) {
        return 'ISK' + value;
    }

    public static String JMD(Decimal value) {
        return 'JMD' + value;
    }

    public static String JOD(Decimal value) {
        return 'JOD' + value;
    }

    public static String JPY(Decimal value) {
        return 'JPY' + value;
    }

    public static String KES(Decimal value) {
        return 'KES' + value;
    }

    public static String KGS(Decimal value) {
        return 'KGS' + value;
    }

    public static String KHR(Decimal value) {
        return 'KHR' + value;
    }

    public static String KMF(Decimal value) {
        return 'KMF' + value;
    }

    public static String KPW(Decimal value) {
        return 'KPW' + value;
    }

    public static String KRW(Decimal value) {
        return 'KRW' + value;
    }

    public static String KWD(Decimal value) {
        return 'KWD' + value;
    }

    public static String KYD(Decimal value) {
        return 'KYD' + value;
    }

    public static String KZT(Decimal value) {
        return 'KZT' + value;
    }

    public static String LAK(Decimal value) {
        return 'LAK' + value;
    }

    public static String LBP(Decimal value) {
        return 'LBP' + value;
    }

    public static String LKR(Decimal value) {
        return 'LKR' + value;
    }

    public static String LRD(Decimal value) {
        return 'LRD' + value;
    }

    public static String LYD(Decimal value) {
        return 'LYD' + value;
    }

    public static String MAD(Decimal value) {
        return 'MAD' + value;
    }

    public static String MDL(Decimal value) {
        return 'MDL' + value;
    }

    public static String MGA(Decimal value) {
        return 'MGA' + value;
    }

    public static String MKD(Decimal value) {
        return 'MKD' + value;
    }

    public static String MMK(Decimal value) {
        return 'MMK' + value;
    }

    public static String MOP(Decimal value) {
        return 'MOP' + value;
    }

    public static String MRU(Decimal value) {
        return 'MRU' + value;
    }

    public static String MUR(Decimal value) {
        return 'MUR' + value;
    }

    public static String MWK(Decimal value) {
        return 'MWK' + value;
    }

    public static String MXN(Decimal value) {
        return 'MXN' + value;
    }

    public static String MYR(Decimal value) {
        return 'MYR' + value;
    }

    public static String MZN(Decimal value) {
        return 'MZN' + value;
    }

    public static String NAD(Decimal value) {
        return 'NAD' + value;
    }

    public static String NGN(Decimal value) {
        return 'NGN' + value;
    }

    public static String NIO(Decimal value) {
        return 'NIO' + value;
    }

    public static String NOK(Decimal value) {
        return 'NOK' + value;
    }

    public static String NPR(Decimal value) {
        return 'NPR' + value;
    }

    public static String NZD(Decimal value) {
        return 'NZD' + value;
    }

    public static String OMR(Decimal value) {
        return 'OMR' + value;
    }

    public static String PAB(Decimal value) {
        return 'PAB' + value;
    }

    public static String PEN(Decimal value) {
        return 'PEN' + value;
    }

    public static String PGK(Decimal value) {
        return 'PGK' + value;
    }

    public static String PHP(Decimal value) {
        return 'PHP' + value;
    }

    public static String PKR(Decimal value) {
        return 'PKR' + value;
    }

    public static String PLN(Decimal value) {
        return 'PLN' + value;
    }

    public static String PYG(Decimal value) {
        return 'PYG' + value;
    }

    public static String QAR(Decimal value) {
        return 'QAR' + value;
    }

    public static String RON(Decimal value) {
        return 'RON' + value;
    }

    public static String RSD(Decimal value) {
        return 'RSD' + value;
    }

    public static String RUB(Decimal value) {
        return 'RUB' + value;
    }

    public static String RWF(Decimal value) {
        return 'RWF' + value;
    }

    public static String SAR(Decimal value) {
        return 'SAR' + value;
    }

    public static String SBD(Decimal value) {
        return 'SBD' + value;
    }

    public static String SCR(Decimal value) {
        return 'SCR' + value;
    }

    public static String SDG(Decimal value) {
        return 'SDG' + value;
    }

    public static String SEK(Decimal value) {
        return 'SEK' + value;
    }

    public static String SGD(Decimal value) {
        return 'SGD' + value;
    }

    public static String SHP(Decimal value) {
        return 'SHP' + value;
    }

    public static String SLE(Decimal value) {
        return 'SLE' + value;
    }

    public static String SLL(Decimal value) {
        return 'SLL' + value;
    }

    public static String SOS(Decimal value) {
        return 'SOS' + value;
    }

    public static String SRD(Decimal value) {
        return 'SRD' + value;
    }

    public static String STN(Decimal value) {
        return 'STN' + value;
    }

    public static String SYP(Decimal value) {
        return 'SYP' + value;
    }

    public static String SZL(Decimal value) {
        return 'SZL' + value;
    }

    public static String THB(Decimal value) {
        return 'THB' + value;
    }

    public static String TJS(Decimal value) {
        return 'TJS' + value;
    }

    public static String TND(Decimal value) {
        return 'TND' + value;
    }

    public static String TOP(Decimal value) {
        return 'TOP' + value;
    }

    // !TRY is a keywork
    // public static String TRY(Decimal value) {
    //     return 'TRY' + value;
    // }

    public static String TTD(Decimal value) {
        return 'TTD' + value;
    }

    public static String TWD(Decimal value) {
        return 'TWD' + value;
    }

    public static String TZS(Decimal value) {
        return 'TZS' + value;
    }

    public static String UAH(Decimal value) {
        return 'UAH' + value;
    }

    public static String UGX(Decimal value) {
        return 'UGX' + value;
    }

    public static String USD(Decimal value) {
        return 'USD' + value;
    }

    public static String UYU(Decimal value) {
        return 'UYU' + value;
    }

    public static String UZS(Decimal value) {
        return 'UZS' + value;
    }

    public static String VES(Decimal value) {
        return 'VES' + value;
    }

    public static String VND(Decimal value) {
        return 'VND' + value;
    }

    public static String VUV(Decimal value) {
        return 'VUV' + value;
    }

    public static String WST(Decimal value) {
        return 'WST' + value;
    }

    public static String XAF(Decimal value) {
        return 'XAF' + value;
    }

    public static String XCD(Decimal value) {
        return 'XCD' + value;
    }

    public static String XOF(Decimal value) {
        return 'XOF' + value;
    }

    public static String XPF(Decimal value) {
        return 'XPF' + value;
    }

    public static String YER(Decimal value) {
        return 'YER' + value;
    }

    public static String ZAR(Decimal value) {
        return 'ZAR' + value;
    }

    // #endregion
    // ========================
}
