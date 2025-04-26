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
        void buildSOQL(List<String> fragments, TmpVars tmpVars);
    }

    public interface CompositeFilter extends Filter {
        CompositeFilter add(Filter filter);
    }

    public class Literal {
        public String literal { get; set; }

        private Literal(String literal) {
            this.literal = literal;
        }
    }

    public class GroupBy {
        private List<String> fieldOrFuncs = new List<String>();
        private Boolean rollup { get; set; }
        private Boolean cube { get; set; }

        private Boolean isEmpty() {
            return this.fieldOrFuncs.isEmpty();
        }
    }

    public class TmpVars {
        Map<String, Object> tmpVars = new Map<String, Object>();

        public String put(Object var) {
            String tmpVar = 'tmpVar' + (this.tmpVars.size() + 1);
            this.tmpVars.put(tmpVar, var);
            return tmpVar;
        }
    }

    private String objectName { get; set; }
    private List<String> selectFields = new List<String>();
    private Map<String, Query> selectParent = new Map<String, Query>();
    private Map<String, Query> selectChild = new Map<String, Query>();

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
        String soql = this.buildSOQL();
        return Database.query(soql);
    }

    // ====================
    // #region SOQL Builder

    public String buildSOQL() {
        List<String> fragments = new List<String>();
        TmpVars tmpVars = new TmpVars();
        this.buildSOQL(fragments, tmpVars, this.objectName, 0);
        return String.join(fragments, '');
    }

    public void buildSOQL(List<String> fragments, TmpVars tmpVars, String fromName, Integer level) {
        fragments.add('SELECT ');
        if (this.selectFields.isEmpty()) {
            fragments.add('Id');
        } else {
            Boolean isNotFirst = false;
            for (String field : this.selectFields) {
                if (isNotFirst) {
                    fragments.add(', ');
                } else {
                    isNotFirst = true;
                }
                fragments.add(field);
            }
        }

        if (!this.selectParent.isEmpty()) {
            for (String relationshipName : this.selectParent.keySet()) {
                Query parentQuery = this.selectParent.get(relationshipName);
                parentQuery.buildSOQL_SelectParent(fragments, relationshipName, level);
            }
        }

        if (level < 5 && !this.selectChild.isEmpty()) {
            for (String relationshipName : this.selectChild.keySet()) {
                Query childQuery = this.selectChild.get(relationshipName);
                fragments.add(', ');
                fragments.add('(');
                childQuery.buildSOQL(fragments, tmpVars, relationshipName, level + 1);
                fragments.add(')');
            }
        }

        fragments.add(' FROM ');
        fragments.add(fromName);

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

        if (!this.orderBys.isEmpty()) {
            fragments.add(' ORDER BY ');
            Boolean isNotFirst = false;
            for (OrderByField field : this.orderBys) {
                if (isNotFirst) {
                    fragments.add(', ');
                } else {
                    isNotFirst = true;
                }
                fragments.add(field.fieldOrFunc);
                if (field.ascending == false) {
                    fragments.add(' DESC');
                }
                if (field.nullsFist == false) {
                    fragments.add(' NULLS LAST');
                }
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
    }

    public void buildSOQL_SelectParent(List<String> fragments, String parentRelationshipName, Integer level) {
        if (this.selectFields.isEmpty()) {
            fragments.add(', ');
            fragments.add(parentRelationshipName);
            fragments.add('.');
            fragments.add('Id');
        } else {
            for (String field : this.selectFields) {
                fragments.add(', ');
                fragments.add(parentRelationshipName);
                fragments.add('.');
                fragments.add(field);
            }
        }

        if (level < 5 && !this.selectParent.isEmpty()) {
            for (String relationshipName : this.selectParent.keySet()) {
                Query parentQuery = this.selectParent.get(relationshipName);
                parentQuery.buildSOQL_SelectParent(
                    fragments,
                    parentRelationshipName + '.' + relationshipName,
                    level + 1
                );
            }
        }
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

        public virtual void buildSOQL(List<String> fragments, TmpVars tmpVars) {
            if (this.filters.isEmpty()) {
                return;
            }

            fragments.add('(');
            Boolean isNotFirst = false;
            for (Filter filter : this.filters) {
                if (isNotFirst) {
                    fragments.add(this.operator);
                } else {
                    isNotFirst = true;
                }
                filter.buildSOQL(fragments, tmpVars);
            }
            fragments.add(')');
        }
    }

    private class NotLogicalFilter extends LogicalFilter {
        private NotLogicalFilter(Filter filter) {
            super('NOT', new List<Filter>{ filter });
        }

        public override void buildSOQL(List<String> fragments, TmpVars tmpVars) {
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

        public virtual void buildSOQL(List<String> fragments, TmpVars tmpVars) {
            fragments.add(this.fieldOrFunc);
            fragments.add(this.operator);
            if (value == null) {
                fragments.add('NULL');
            } else if (value instanceof Literal) {
                fragments.add(((Literal) this.value).literal);
            } else {
                String tmpVar = tmpVars.put(this.value);
                fragments.add(':');
                fragments.add(tmpVar);
            }
        }
    }

    private class MultiComparisonFilter extends ComparisonFilter {
        private MultiComparisonFilter(String field, String operator, List<String> values) {
            super(field, operator, values);
        }

        public override void buildSOQL(List<String> fragments, TmpVars tmpVars) {
            fragments.add(this.fieldOrFunc);
            fragments.add(this.operator);
            fragments.add('(');
            Boolean isNotFirst = false;
            for (string value : (List<String>) this.value) {
                if (isNotFirst) {
                    fragments.add(', ');
                } else {
                    isNotFirst = true;
                }

                String tmpVar = tmpVars.put(this.value);
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
        Query selectChild(String relationshipName, Query query);
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
        this.selectParent.put(relationshipName.trim(), query);
        return this;
    }

    public Query selectChild(String relationshipName, Query query) {
        this.selectChild.put(relationshipName.trim(), query);
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

    public static OrderByField orderBy(String fieldOrFunc) {
        return new OrderByField(fieldOrFunc);
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
    public static Literal YESTERDAY() {
        return new Literal('YESTERDAY');
    }

    public static Literal TODAY() {
        return new Literal('TODAY');
    }

    public static Literal TOMORROW() {
        return new Literal('TOMORROW');
    }

    public static Literal LAST_WEEK() {
        return new Literal('LAST_WEEK');
    }

    public static Literal THIS_WEEK() {
        return new Literal('THIS_WEEK');
    }

    public static Literal NEXT_WEEK() {
        return new Literal('NEXT_WEEK');
    }

    public static Literal LAST_MONTH() {
        return new Literal('LAST_MONTH');
    }

    public static Literal THIS_MONTH() {
        return new Literal('THIS_MONTH');
    }

    public static Literal NEXT_MONTH() {
        return new Literal('NEXT_MONTH');
    }

    public static Literal LAST_90_DAYS() {
        return new Literal('LAST_90_DAYS');
    }

    public static Literal NEXT_90_DAYS() {
        return new Literal('NEXT_90_DAYS');
    }

    public static Literal THIS_QUARTER() {
        return new Literal('THIS_QUARTER');
    }

    public static Literal LAST_QUARTER() {
        return new Literal('LAST_QUARTER');
    }

    public static Literal NEXT_QUARTER() {
        return new Literal('NEXT_QUARTER');
    }

    public static Literal THIS_YEAR() {
        return new Literal('THIS_YEAR');
    }

    public static Literal LAST_YEAR() {
        return new Literal('LAST_YEAR');
    }

    public static Literal NEXT_YEAR() {
        return new Literal('NEXT_YEAR');
    }

    public static Literal THIS_FISCAL_QUARTER() {
        return new Literal('THIS_FISCAL_QUARTER');
    }

    public static Literal LAST_FISCAL_QUARTER() {
        return new Literal('LAST_FISCAL_QUARTER');
    }

    public static Literal NEXT_FISCAL_QUARTER() {
        return new Literal('NEXT_FISCAL_QUARTER');
    }

    public static Literal THIS_FISCAL_YEAR() {
        return new Literal('THIS_FISCAL_YEAR');
    }

    public static Literal LAST_FISCAL_YEAR() {
        return new Literal('LAST_FISCAL_YEAR');
    }

    public static Literal NEXT_FISCAL_YEAR() {
        return new Literal('NEXT_FISCAL_YEAR');
    }

    public static Literal LAST_N_DAYS(Integer n) {
        return new Literal('LAST_N_DAYS:' + n);
    }

    public static Literal NEXT_N_DAYS(Integer n) {
        return new Literal('NEXT_N_DAYS:' + n);
    }

    public static Literal N_DAYS_AGO(Integer n) {
        return new Literal('N_DAYS_AGO:' + n);
    }

    public static Literal NEXT_N_WEEKS(Integer n) {
        return new Literal('NEXT_N_WEEKS:' + n);
    }

    public static Literal LAST_N_WEEKS(Integer n) {
        return new Literal('LAST_N_WEEKS:' + n);
    }

    public static Literal N_WEEKS_AGO(Integer n) {
        return new Literal('N_WEEKS_AGO:' + n);
    }

    public static Literal NEXT_N_MONTHS(Integer n) {
        return new Literal('NEXT_N_MONTHS:' + n);
    }

    public static Literal LAST_N_MONTHS(Integer n) {
        return new Literal('LAST_N_MONTHS:' + n);
    }

    public static Literal N_MONTHS_AGO(Integer n) {
        return new Literal('N_MONTHS_AGO:' + n);
    }

    public static Literal NEXT_N_QUARTERS(Integer n) {
        return new Literal('NEXT_N_QUARTERS:' + n);
    }

    public static Literal LAST_N_QUARTERS(Integer n) {
        return new Literal('LAST_N_QUARTERS:' + n);
    }

    public static Literal N_QUARTERS_AGO(Integer n) {
        return new Literal('N_QUARTERS_AGO:' + n);
    }

    public static Literal NEXT_N_YEARS(Integer n) {
        return new Literal('NEXT_N_YEARS:' + n);
    }

    public static Literal LAST_N_YEARS(Integer n) {
        return new Literal('LAST_N_YEARS:' + n);
    }

    public static Literal N_YEARS_AGO(Integer n) {
        return new Literal('N_YEARS_AGO:' + n);
    }

    public static Literal NEXT_N_FISCAL_QUARTERS(Integer n) {
        return new Literal('NEXT_N_FISCAL_QUARTERS:' + n);
    }

    public static Literal N_FISCAL_QUARTERS_AGO(Integer n) {
        return new Literal('N_FISCAL_QUARTERS_AGO:' + n);
    }

    public static Literal NEXT_N_FISCAL_YEARS(Integer n) {
        return new Literal('NEXT_N_FISCAL_YEARS:' + n);
    }

    public static Literal LAST_N_FISCAL_YEARS(Integer n) {
        return new Literal('LAST_N_FISCAL_YEARS:' + n);
    }

    public static Literal N_FISCAL_YEARS_AGO(Integer n) {
        return new Literal('N_FISCAL_YEARS_AGO:' + n);
    }

    // #endregion
    // ====================

    // ========================
    // #region Currency Literal
    public static Literal CURRENCY(String code, Decimal value) {
        return new Literal(code + value);
    }

    public static Literal AED(Decimal value) {
        return new Literal('AED' + value);
    }

    public static Literal AFN(Decimal value) {
        return new Literal('AFN' + value);
    }

    public static Literal ALL(Decimal value) {
        return new Literal('ALL' + value);
    }

    public static Literal AMD(Decimal value) {
        return new Literal('AMD' + value);
    }

    public static Literal ANG(Decimal value) {
        return new Literal('ANG' + value);
    }

    public static Literal AOA(Decimal value) {
        return new Literal('AOA' + value);
    }

    public static Literal ARS(Decimal value) {
        return new Literal('ARS' + value);
    }

    public static Literal AUD(Decimal value) {
        return new Literal('AUD' + value);
    }

    public static Literal AWG(Decimal value) {
        return new Literal('AWG' + value);
    }

    public static Literal AZN(Decimal value) {
        return new Literal('AZN' + value);
    }

    public static Literal BAM(Decimal value) {
        return new Literal('BAM' + value);
    }

    public static Literal BBD(Decimal value) {
        return new Literal('BBD' + value);
    }

    public static Literal BDT(Decimal value) {
        return new Literal('BDT' + value);
    }

    public static Literal BGN(Decimal value) {
        return new Literal('BGN' + value);
    }

    public static Literal BHD(Decimal value) {
        return new Literal('BHD' + value);
    }

    public static Literal BIF(Decimal value) {
        return new Literal('BIF' + value);
    }

    public static Literal BMD(Decimal value) {
        return new Literal('BMD' + value);
    }

    public static Literal BND(Decimal value) {
        return new Literal('BND' + value);
    }

    public static Literal BOB(Decimal value) {
        return new Literal('BOB' + value);
    }

    public static Literal BRL(Decimal value) {
        return new Literal('BRL' + value);
    }

    public static Literal BSD(Decimal value) {
        return new Literal('BSD' + value);
    }

    public static Literal BTN(Decimal value) {
        return new Literal('BTN' + value);
    }

    public static Literal BWP(Decimal value) {
        return new Literal('BWP' + value);
    }

    public static Literal BYN(Decimal value) {
        return new Literal('BYN' + value);
    }

    public static Literal BZD(Decimal value) {
        return new Literal('BZD' + value);
    }

    public static Literal CAD(Decimal value) {
        return new Literal('CAD' + value);
    }

    public static Literal CDF(Decimal value) {
        return new Literal('CDF' + value);
    }

    public static Literal CHF(Decimal value) {
        return new Literal('CHF' + value);
    }

    public static Literal CLP(Decimal value) {
        return new Literal('CLP' + value);
    }

    public static Literal CNY(Decimal value) {
        return new Literal('CNY' + value);
    }

    public static Literal COP(Decimal value) {
        return new Literal('COP' + value);
    }

    public static Literal CRC(Decimal value) {
        return new Literal('CRC' + value);
    }

    public static Literal CSD(Decimal value) {
        return new Literal('CSD' + value);
    }

    public static Literal CUP(Decimal value) {
        return new Literal('CUP' + value);
    }

    public static Literal CVE(Decimal value) {
        return new Literal('CVE' + value);
    }

    public static Literal CZK(Decimal value) {
        return new Literal('CZK' + value);
    }

    public static Literal DJF(Decimal value) {
        return new Literal('DJF' + value);
    }

    public static Literal DKK(Decimal value) {
        return new Literal('DKK' + value);
    }

    public static Literal DOP(Decimal value) {
        return new Literal('DOP' + value);
    }

    public static Literal DZD(Decimal value) {
        return new Literal('DZD' + value);
    }

    public static Literal EGP(Decimal value) {
        return new Literal('EGP' + value);
    }

    public static Literal ERN(Decimal value) {
        return new Literal('ERN' + value);
    }

    public static Literal ETB(Decimal value) {
        return new Literal('ETB' + value);
    }

    public static Literal EUR(Decimal value) {
        return new Literal('EUR' + value);
    }

    public static Literal FJD(Decimal value) {
        return new Literal('FJD' + value);
    }

    public static Literal FKP(Decimal value) {
        return new Literal('FKP' + value);
    }

    public static Literal GBP(Decimal value) {
        return new Literal('GBP' + value);
    }

    public static Literal GEL(Decimal value) {
        return new Literal('GEL' + value);
    }

    public static Literal GHS(Decimal value) {
        return new Literal('GHS' + value);
    }

    public static Literal GIP(Decimal value) {
        return new Literal('GIP' + value);
    }

    public static Literal GMD(Decimal value) {
        return new Literal('GMD' + value);
    }

    public static Literal GNF(Decimal value) {
        return new Literal('GNF' + value);
    }

    public static Literal GTQ(Decimal value) {
        return new Literal('GTQ' + value);
    }

    public static Literal GYD(Decimal value) {
        return new Literal('GYD' + value);
    }

    public static Literal HKD(Decimal value) {
        return new Literal('HKD' + value);
    }

    public static Literal HNL(Decimal value) {
        return new Literal('HNL' + value);
    }

    public static Literal HRK(Decimal value) {
        return new Literal('HRK' + value);
    }

    public static Literal HTG(Decimal value) {
        return new Literal('HTG' + value);
    }

    public static Literal HUF(Decimal value) {
        return new Literal('HUF' + value);
    }

    public static Literal IDR(Decimal value) {
        return new Literal('IDR' + value);
    }

    public static Literal ILS(Decimal value) {
        return new Literal('ILS' + value);
    }

    public static Literal INR(Decimal value) {
        return new Literal('INR' + value);
    }

    public static Literal IQD(Decimal value) {
        return new Literal('IQD' + value);
    }

    public static Literal IRR(Decimal value) {
        return new Literal('IRR' + value);
    }

    public static Literal ISK(Decimal value) {
        return new Literal('ISK' + value);
    }

    public static Literal JMD(Decimal value) {
        return new Literal('JMD' + value);
    }

    public static Literal JOD(Decimal value) {
        return new Literal('JOD' + value);
    }

    public static Literal JPY(Decimal value) {
        return new Literal('JPY' + value);
    }

    public static Literal KES(Decimal value) {
        return new Literal('KES' + value);
    }

    public static Literal KGS(Decimal value) {
        return new Literal('KGS' + value);
    }

    public static Literal KHR(Decimal value) {
        return new Literal('KHR' + value);
    }

    public static Literal KMF(Decimal value) {
        return new Literal('KMF' + value);
    }

    public static Literal KPW(Decimal value) {
        return new Literal('KPW' + value);
    }

    public static Literal KRW(Decimal value) {
        return new Literal('KRW' + value);
    }

    public static Literal KWD(Decimal value) {
        return new Literal('KWD' + value);
    }

    public static Literal KYD(Decimal value) {
        return new Literal('KYD' + value);
    }

    public static Literal KZT(Decimal value) {
        return new Literal('KZT' + value);
    }

    public static Literal LAK(Decimal value) {
        return new Literal('LAK' + value);
    }

    public static Literal LBP(Decimal value) {
        return new Literal('LBP' + value);
    }

    public static Literal LKR(Decimal value) {
        return new Literal('LKR' + value);
    }

    public static Literal LRD(Decimal value) {
        return new Literal('LRD' + value);
    }

    public static Literal LYD(Decimal value) {
        return new Literal('LYD' + value);
    }

    public static Literal MAD(Decimal value) {
        return new Literal('MAD' + value);
    }

    public static Literal MDL(Decimal value) {
        return new Literal('MDL' + value);
    }

    public static Literal MGA(Decimal value) {
        return new Literal('MGA' + value);
    }

    public static Literal MKD(Decimal value) {
        return new Literal('MKD' + value);
    }

    public static Literal MMK(Decimal value) {
        return new Literal('MMK' + value);
    }

    public static Literal MOP(Decimal value) {
        return new Literal('MOP' + value);
    }

    public static Literal MRU(Decimal value) {
        return new Literal('MRU' + value);
    }

    public static Literal MUR(Decimal value) {
        return new Literal('MUR' + value);
    }

    public static Literal MWK(Decimal value) {
        return new Literal('MWK' + value);
    }

    public static Literal MXN(Decimal value) {
        return new Literal('MXN' + value);
    }

    public static Literal MYR(Decimal value) {
        return new Literal('MYR' + value);
    }

    public static Literal MZN(Decimal value) {
        return new Literal('MZN' + value);
    }

    public static Literal NAD(Decimal value) {
        return new Literal('NAD' + value);
    }

    public static Literal NGN(Decimal value) {
        return new Literal('NGN' + value);
    }

    public static Literal NIO(Decimal value) {
        return new Literal('NIO' + value);
    }

    public static Literal NOK(Decimal value) {
        return new Literal('NOK' + value);
    }

    public static Literal NPR(Decimal value) {
        return new Literal('NPR' + value);
    }

    public static Literal NZD(Decimal value) {
        return new Literal('NZD' + value);
    }

    public static Literal OMR(Decimal value) {
        return new Literal('OMR' + value);
    }

    public static Literal PAB(Decimal value) {
        return new Literal('PAB' + value);
    }

    public static Literal PEN(Decimal value) {
        return new Literal('PEN' + value);
    }

    public static Literal PGK(Decimal value) {
        return new Literal('PGK' + value);
    }

    public static Literal PHP(Decimal value) {
        return new Literal('PHP' + value);
    }

    public static Literal PKR(Decimal value) {
        return new Literal('PKR' + value);
    }

    public static Literal PLN(Decimal value) {
        return new Literal('PLN' + value);
    }

    public static Literal PYG(Decimal value) {
        return new Literal('PYG' + value);
    }

    public static Literal QAR(Decimal value) {
        return new Literal('QAR' + value);
    }

    public static Literal RON(Decimal value) {
        return new Literal('RON' + value);
    }

    public static Literal RSD(Decimal value) {
        return new Literal('RSD' + value);
    }

    public static Literal RUB(Decimal value) {
        return new Literal('RUB' + value);
    }

    public static Literal RWF(Decimal value) {
        return new Literal('RWF' + value);
    }

    public static Literal SAR(Decimal value) {
        return new Literal('SAR' + value);
    }

    public static Literal SBD(Decimal value) {
        return new Literal('SBD' + value);
    }

    public static Literal SCR(Decimal value) {
        return new Literal('SCR' + value);
    }

    public static Literal SDG(Decimal value) {
        return new Literal('SDG' + value);
    }

    public static Literal SEK(Decimal value) {
        return new Literal('SEK' + value);
    }

    public static Literal SGD(Decimal value) {
        return new Literal('SGD' + value);
    }

    public static Literal SHP(Decimal value) {
        return new Literal('SHP' + value);
    }

    public static Literal SLE(Decimal value) {
        return new Literal('SLE' + value);
    }

    public static Literal SLL(Decimal value) {
        return new Literal('SLL' + value);
    }

    public static Literal SOS(Decimal value) {
        return new Literal('SOS' + value);
    }

    public static Literal SRD(Decimal value) {
        return new Literal('SRD' + value);
    }

    public static Literal STN(Decimal value) {
        return new Literal('STN' + value);
    }

    public static Literal SYP(Decimal value) {
        return new Literal('SYP' + value);
    }

    public static Literal SZL(Decimal value) {
        return new Literal('SZL' + value);
    }

    public static Literal THB(Decimal value) {
        return new Literal('THB' + value);
    }

    public static Literal TJS(Decimal value) {
        return new Literal('TJS' + value);
    }

    public static Literal TND(Decimal value) {
        return new Literal('TND' + value);
    }

    public static Literal TOP(Decimal value) {
        return new Literal('TOP' + value);
    }

    // !TRY is a keywork
    // public static Literal TRY(Decimal value) {
    // new Literal(    return 'TRY' + value);
    // }

    public static Literal TTD(Decimal value) {
        return new Literal('TTD' + value);
    }

    public static Literal TWD(Decimal value) {
        return new Literal('TWD' + value);
    }

    public static Literal TZS(Decimal value) {
        return new Literal('TZS' + value);
    }

    public static Literal UAH(Decimal value) {
        return new Literal('UAH' + value);
    }

    public static Literal UGX(Decimal value) {
        return new Literal('UGX' + value);
    }

    public static Literal USD(Decimal value) {
        return new Literal('USD' + value);
    }

    public static Literal UYU(Decimal value) {
        return new Literal('UYU' + value);
    }

    public static Literal UZS(Decimal value) {
        return new Literal('UZS' + value);
    }

    public static Literal VES(Decimal value) {
        return new Literal('VES' + value);
    }

    public static Literal VND(Decimal value) {
        return new Literal('VND' + value);
    }

    public static Literal VUV(Decimal value) {
        return new Literal('VUV' + value);
    }

    public static Literal WST(Decimal value) {
        return new Literal('WST' + value);
    }

    public static Literal XAF(Decimal value) {
        return new Literal('XAF' + value);
    }

    public static Literal XCD(Decimal value) {
        return new Literal('XCD' + value);
    }

    public static Literal XOF(Decimal value) {
        return new Literal('XOF' + value);
    }

    public static Literal XPF(Decimal value) {
        return new Literal('XPF' + value);
    }

    public static Literal YER(Decimal value) {
        return new Literal('YER' + value);
    }

    public static Literal ZAR(Decimal value) {
        return new Literal('ZAR' + value);
    }

    // #endregion
    // ========================
}
