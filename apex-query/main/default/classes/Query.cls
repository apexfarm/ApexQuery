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
    public interface Querable extends Groupable {
        Integer getCount();
        Integer getCount(AccessLevel accessLevel);
        Integer getCount(Map<String, Object> bindingVars);
        Integer getCount(Map<String, Object> bindingVars, AccessLevel accessLevel);
        List<SObject> run();
        List<SObject> run(AccessLevel accessLevel);
        List<SObject> run(Map<String, Object> bindingVars);
        List<SObject> run(Map<String, Object> bindingVars, AccessLevel accessLevel);
        Database.QueryLocator getLocator();
        Database.QueryLocator getLocator(AccessLevel accessLevel);
        Database.QueryLocator getLocator(Map<String, Object> bindingVars);
        Database.QueryLocator getLocator(Map<String, Object> bindingVars, AccessLevel accessLevel);

        Query whereBy(Filter whereClause);
        Query havingBy(Filter havingClause);
        LogicalFilter whereBy();
        LogicalFilter havingBy();

        Query offset(Integer n);
        Query limitx(Integer n);

        Query forView();
        Query forReference();
        Query updateTracking();
        Query updateViewstat();
        Query forUpdate();
    }

    public interface Filter {
        void buildSOQL_Filter(List<String> fragments, TmpVars tmpVars);
    }

    public interface LogicalFilter extends Filter {
        LogicalFilter add(Filter filter);
        LogicalFilter addAll(List<Filter> filters);
        Boolean isEmpty();
    }

    public virtual class Literal {
        public String literal { get; set; }

        private Literal(String literal) {
            this.literal = literal;
        }
    }

    private class GroupBy {
        private List<String> fieldOrFuncs = new List<String>();
        private Boolean rollup { get; set; }
        private Boolean cube { get; set; }

        private Boolean isEmpty() {
            return this.fieldOrFuncs.isEmpty();
        }
    }

    private class TmpVars {
        Map<String, Object> bindingVars = new Map<String, Object>();
        Integer tmpVarCount = 0;

        private String put(Object var) {
            tmpVarCount++;
            String tmpVar = 'tmpVar' + tmpVarCount;
            this.bindingVars.put(tmpVar, var);
            return ':' + tmpVar;
        }
    }

    private String soql { get; set; }
    private TmpVars tmpVars { get; set; }

    public String objectName { get; private set; }
    private List<Object> selectFields = new List<Object>();
    public Map<String, Query> selectParent { get; private set; }
    public Map<String, Query> selectChild { get; private set; }

    private Filter whereClause;
    private Filter havingClause;
    private GroupBy groupByClause = new GroupBy();
    private List<Object> orderClause = new List<Object>();

    private Integer offset { get; set; }
    private Integer limitx { get; set; }

    private Boolean forView { get; set; }
    private Boolean forReference { get; set; }
    private Boolean updateTracking { get; set; }
    private Boolean updateViewstat { get; set; }
    private Boolean forUpdate { get; set; }

    protected Query() {
        this.selectParent = new Map<String, Query>();
        this.selectChild = new Map<String, Query>();
    }

    private Query(String objectName) {
        this();
        this.objectName = objectName;
    }

    public static Query of(String objectName) {
        return new Query(objectName);
    }

    public Query whereBy(Filter whereClause) {
        if (!(whereClause instanceof LogicalFilter)) {
            whereClause = andx().add(whereClause);
        }
        this.whereClause = whereClause;
        return this;
    }

    public Query havingBy(Filter havingClause) {
        if (!(havingClause instanceof LogicalFilter)) {
            havingClause = andx().add(havingClause);
        }
        this.havingClause = havingClause;
        return this;
    }

    public LogicalFilter whereBy() {
        if (this.whereClause == null) {
            this.whereClause = andx();
        }
        return (LogicalFilter) this.whereClause;
    }

    public LogicalFilter havingBy() {
        if (this.havingClause == null) {
            this.havingClause = andx();
        }
        return (LogicalFilter) this.havingClause;
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

    public Integer getCount() {
        return getCount(AccessLevel.SYSTEM_MODE);
    }

    public Integer getCount(AccessLevel accessLevel) {
        return this.getCount(null, accessLevel);
    }

    public Integer getCount(Map<String, Object> bindingVars) {
        return this.getCount(bindingVars, AccessLevel.SYSTEM_MODE);
    }

    public Integer getCount(Map<String, Object> bindingVars, AccessLevel accessLevel) {
        buildSOQL();
        if (bindingVars == null) {
            bindingVars = new Map<String, Object>();
        }
        bindingVars.putAll(this.tmpVars.bindingVars);

        if (Test.isRunningTest()) {
            return 0;
        }
        return Database.countQueryWithBinds(this.soql, bindingVars, accessLevel);
    }

    public List<SObject> run() {
        return this.run(AccessLevel.SYSTEM_MODE);
    }

    public List<SObject> run(AccessLevel accessLevel) {
        return this.run(null, accessLevel);
    }

    public List<SObject> run(Map<String, Object> bindingVars) {
        return this.run(bindingVars, AccessLevel.SYSTEM_MODE);
    }

    public List<SObject> run(Map<String, Object> bindingVars, AccessLevel accessLevel) {
        buildSOQL();
        if (bindingVars == null) {
            bindingVars = new Map<String, Object>();
        }
        bindingVars.putAll(this.tmpVars.bindingVars);

        if (Test.isRunningTest()) {
            return new List<SObject>();
        }
        return Database.queryWithBinds(this.soql, bindingVars, accessLevel);
    }

    public Database.QueryLocator getLocator() {
        return this.getLocator(AccessLevel.SYSTEM_MODE);
    }

    public Database.QueryLocator getLocator(AccessLevel accessLevel) {
        return this.getLocator(null, accessLevel);
    }

    public Database.QueryLocator getLocator(Map<String, Object> bindingVars) {
        return this.getLocator(bindingVars, AccessLevel.SYSTEM_MODE);
    }

    public Database.QueryLocator getLocator(Map<String, Object> bindingVars, AccessLevel accessLevel) {
        buildSOQL();
        if (bindingVars == null) {
            bindingVars = new Map<String, Object>();
        }
        bindingVars.putAll(this.tmpVars.bindingVars);

        if (Test.isRunningTest()) {
            return null;
        }
        return Database.getQueryLocatorWithBinds(this.soql, tmpVars.bindingVars, accessLevel);
    }

    // ====================
    // #region SOQL Builder

    public String buildSOQL() {
        if (this.soql == null) {
            this.tmpVars = new TmpVars();
            List<String> fragments = new List<String>();
            this.buildSOQL(fragments, this.tmpVars, this.objectName, 0);
            this.soql = String.join(fragments, '');
        }
        return this.soql;
    }

    private void buildSOQL(List<String> fragments, TmpVars tmpVars, String fromName, Integer level) {
        fragments.add('SELECT ');
        this.buildSOQL_SelectFields(fragments, null);

        if (!this.selectParent.isEmpty()) {
            for (String relationshipName : this.selectParent.keySet()) {
                Query parentQuery = this.selectParent.get(relationshipName);
                parentQuery.buildSOQL_SelectParent(fragments, relationshipName, level);
            }
        }

        if (level < 6 && !this.selectChild.isEmpty()) {
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

        if (
            this.whereClause != null &&
            (!(this.whereClause instanceof LogicalFilter) || !((LogicalFilter) this.whereClause).isEmpty())
        ) {
            fragments.add(' WHERE ');
            this.whereClause.buildSOQL_Filter(fragments, tmpVars);
        }

        if (!this.groupByClause.isEmpty()) {
            fragments.add(' GROUP BY ');
            this.buildSOQL_GroupBy(fragments);
        }

        if (
            this.havingClause != null &&
            (!(this.havingClause instanceof LogicalFilter) || !((LogicalFilter) this.havingClause).isEmpty())
        ) {
            fragments.add(' HAVING ');
            this.havingClause.buildSOQL_Filter(fragments, tmpVars);
        }

        if (!this.orderClause.isEmpty()) {
            fragments.add(' ORDER BY ');
            Boolean isNotFirst = false;
            for (Object field : this.orderClause) {
                if (isNotFirst) {
                    fragments.add(', ');
                } else {
                    isNotFirst = true;
                }

                if (field instanceof OrderField) {
                    OrderField fieldObj = (OrderField) field;
                    fragments.add(fieldObj.fieldOrFunc);
                    if (fieldObj.ascending == false) {
                        fragments.add(' DESC');
                    }
                    if (fieldObj.nullsFist == false) {
                        fragments.add(' NULLS LAST');
                    }
                } else {
                    fragments.add(String.valueOf(field));
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

    private void buildSOQL_GroupBy(List<String> fragments) {
        Boolean isNotFirst = false;
        for (String field : this.groupByClause.fieldOrFuncs) {
            if (isNotFirst) {
                fragments.add(', ');
            } else {
                if (this.groupByClause.rollup == true) {
                    fragments.add('ROLLUP(');
                } else if (this.groupByClause.cube == true) {
                    fragments.add('CUBE(');
                }
                isNotFirst = true;
            }
            fragments.add(field);
        }
        if (this.groupByClause.rollup == true || this.groupByClause.cube == true) {
            fragments.add(')');
        }
    }

    private void buildSOQL_SelectFields(List<String> fragments, String parentRelationshipName) {
        if (this.selectFields.isEmpty()) {
            if (parentRelationshipName != null) {
                fragments.add(', ');
                fragments.add(parentRelationshipName);
                fragments.add('.');
            }
            fragments.add('Id');
        } else {
            Boolean isNotFirst = parentRelationshipName != null;
            for (Object field : this.selectFields) {
                if (isNotFirst) {
                    fragments.add(', ');
                } else {
                    isNotFirst = true;
                }
                if (field instanceof FunctionImpl) {
                    FunctionImpl function = (FunctionImpl) field;
                    function.buildSOQL_Function(fragments, parentRelationshipName);
                } else {
                    if (parentRelationshipName != null) {
                        fragments.add(parentRelationshipName);
                        fragments.add('.');
                    }
                    fragments.add((String) field);
                }
            }
        }
    }

    private void buildSOQL_SelectParent(List<String> fragments, String parentRelationshipName, Integer level) {
        this.buildSOQL_SelectFields(fragments, parentRelationshipName);

        if (level < 6 && !this.selectParent.isEmpty()) {
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
    // #region Logic Filter
    private virtual class LogicalFilterImpl implements LogicalFilter {
        private List<Filter> filters { get; set; }
        private String operator { get; set; }

        private LogicalFilterImpl(String operator, List<Filter> filters) {
            this.operator = operator;
            this.filters = filters;
        }

        public LogicalFilter add(Filter filter) {
            this.filters.add(filter);
            return this;
        }

        public LogicalFilter addAll(List<Filter> filters) {
            this.filters.addAll(filters);
            return this;
        }

        public Boolean isEmpty() {
            return this.filters.isEmpty();
        }

        public virtual void buildSOQL_Filter(List<String> fragments, TmpVars tmpVars) {
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
                filter.buildSOQL_Filter(fragments, tmpVars);
            }
            fragments.add(')');
        }
    }

    private class NotLogicalFilter extends LogicalFilterImpl {
        private NotLogicalFilter(Filter filter) {
            super('NOT', new List<Filter>{ filter });
        }

        public override void buildSOQL_Filter(List<String> fragments, TmpVars tmpVars) {
            Filter filter = this.filters[0];
            fragments.add(this.operator);
            if (filter instanceof LogicalFilter) {
                filter.buildSOQL_Filter(fragments, tmpVars);
            } else {
                fragments.add('(');
                filter.buildSOQL_Filter(fragments, tmpVars);
                fragments.add(')');
            }
        }
    }

    public static Filter notx(Filter filter) {
        return new NotLogicalFilter(filter);
    }

    public static LogicalFilter orx() {
        return new LogicalFilterImpl(' OR ', new List<Filter>());
    }

    public static LogicalFilter andx() {
        return new LogicalFilterImpl(' AND ', new List<Filter>());
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

        public virtual void buildSOQL_Filter(List<String> fragments, TmpVars tmpVars) {
            fragments.add(this.fieldOrFunc);
            fragments.add(this.operator);
            if (value == null) {
                fragments.add('NULL');
            } else if (value instanceof Literal) {
                fragments.add(((Literal) this.value).literal);
            } else {
                fragments.add(tmpVars.put(this.value));
            }
        }
    }

    private class MultiComparisonFilter extends ComparisonFilter {
        private MultiComparisonFilter(String field, String operator, List<String> values) {
            super(field, operator, values);
        }

        public override void buildSOQL_Filter(List<String> fragments, TmpVars tmpVars) {
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

                fragments.add(tmpVars.put(this.value));
            }
            fragments.add(')');
        }
    }

    private class NotLikeFilter extends ComparisonFilter {
        private NotLikeFilter(String fieldOrFunc, Object value) {
            super(fieldOrFunc, ' LIKE ', value);
        }

        public override void buildSOQL_Filter(List<String> fragments, TmpVars tmpVars) {
            fragments.add('(NOT ');
            super.buildSOQL_Filter(fragments, tmpVars);
            fragments.add(')');
        }
    }

    private class InQueryFilter extends ComparisonFilter {
        private InQueryFilter(String field, String operator, Query query) {
            super(field, operator, query);
        }

        public override void buildSOQL_Filter(List<String> fragments, TmpVars tmpVars) {
            fragments.add(String.valueOf(this.fieldOrFunc));
            fragments.add(this.operator);
            fragments.add('(');
            Query subquery = ((Query) this.value);
            subquery.buildSOQL(fragments, tmpVars, subquery.objectName, 0);
            fragments.add(')');
        }
    }

    public static Filter inx(String IdField, Query query) {
        return new InQueryFilter(IdField, ' IN ', query);
    }

    public static Filter nin(String IdField, Query query) {
        return new InQueryFilter(IdField, ' NOT IN ', query);
    }

    public static Filter eq(String fieldOrFunc, Object value) {
        return new ComparisonFilter(fieldOrFunc, ' = ', value);
    }

    public static Filter ne(String fieldOrFunc, Object value) {
        return new ComparisonFilter(fieldOrFunc, ' != ', value);
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

    public static Filter between(String fieldOrFunc, Object minValue, Object maxValue) {
        return andx().add(gte(fieldOrFunc, minValue)).add(lte(fieldOrFunc, maxValue));
    }

    public static Filter likex(String field, String value) {
        return new ComparisonFilter(field, ' LIKE ', value);
    }

    public static Filter nlike(String field, String value) {
        return new NotLikeFilter(field, value);
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

    // #endregion
    // =========================

    // =============================
    // #region Comparison Filter Ext

    // Special Cases for ToLabelFunction
    public static Filter eq(ToLabelFunction func, String value) {
        String funcStr = func.buildSOQL_Function();
        return new ComparisonFilter(funcStr, ' = ', value);
    }

    public static Filter ne(ToLabelFunction func, String value) {
        String funcStr = func.buildSOQL_Function();
        return new ComparisonFilter(funcStr, ' != ', value);
    }

    public static Filter gt(ToLabelFunction func, String value) {
        String funcStr = func.buildSOQL_Function();
        return new ComparisonFilter(funcStr, ' > ', value);
    }

    public static Filter gte(ToLabelFunction func, String value) {
        String funcStr = func.buildSOQL_Function();
        return new ComparisonFilter(funcStr, ' >= ', value);
    }

    public static Filter lt(ToLabelFunction func, String value) {
        String funcStr = func.buildSOQL_Function();
        return new ComparisonFilter(funcStr, ' < ', value);
    }

    public static Filter lte(ToLabelFunction func, String value) {
        String funcStr = func.buildSOQL_Function();
        return new ComparisonFilter(funcStr, ' <= ', value);
    }

    public static Filter between(ToLabelFunction func, String minValue, String maxValue) {
        String funcStr = func.buildSOQL_Function();
        return andx().add(gte(funcStr, minValue)).add(lte(funcStr, maxValue));
    }

    public static Filter likex(ToLabelFunction func, String value) {
        String funcStr = func.buildSOQL_Function();
        return new ComparisonFilter(funcStr, ' LIKE ', value);
    }

    public static Filter nlike(ToLabelFunction func, String value) {
        String funcStr = func.buildSOQL_Function();
        return new NotLikeFilter(funcStr, value);
    }

    public static Filter inx(ToLabelFunction func, List<String> values) {
        String funcStr = func.buildSOQL_Function();
        return new ComparisonFilter(funcStr, ' IN ', values);
    }

    public static Filter nin(ToLabelFunction func, List<String> values) {
        String funcStr = func.buildSOQL_Function();
        return new ComparisonFilter(funcStr, ' NOT IN ', values);
    }

    public static Filter includes(ToLabelFunction func, List<String> values) {
        String funcStr = func.buildSOQL_Function();
        return new MultiComparisonFilter(funcStr, ' INCLUDES ', values);
    }

    public static Filter excludes(ToLabelFunction func, List<String> values) {
        String funcStr = func.buildSOQL_Function();
        return new MultiComparisonFilter(funcStr, ' EXCLUDES ', values);
    }

    // Special Cases for VarLiteral
    public static Filter likex(String field, VarLiteral value) {
        return new ComparisonFilter(field, ' LIKE ', value);
    }

    public static Filter nlike(String field, VarLiteral value) {
        return new NotLikeFilter(field, value);
    }

    public static Filter inx(String fieldOrFunc, VarLiteral values) {
        return new ComparisonFilter(fieldOrFunc, ' IN ', values);
    }

    public static Filter nin(String fieldOrFunc, VarLiteral values) {
        return new ComparisonFilter(fieldOrFunc, ' NOT IN ', values);
    }

    public static Filter likex(ToLabelFunction func, VarLiteral value) {
        String funcStr = func.buildSOQL_Function();
        return new ComparisonFilter(funcStr, ' LIKE ', value);
    }

    public static Filter nlike(ToLabelFunction func, VarLiteral value) {
        String funcStr = func.buildSOQL_Function();
        return new NotLikeFilter(funcStr, value);
    }

    public static Filter inx(ToLabelFunction func, VarLiteral values) {
        String funcStr = func.buildSOQL_Function();
        return new ComparisonFilter(funcStr, ' IN ', values);
    }

    public static Filter nin(ToLabelFunction func, VarLiteral values) {
        String funcStr = func.buildSOQL_Function();
        return new ComparisonFilter(funcStr, ' NOT IN ', values);
    }

    // #endregion
    // =============================

    // =====================
    // #region Select Clause
    public interface Selectable {
        Query selectBy(Object field);
        Query selectBy(Object field1, Object field2);
        Query selectBy(Object field1, Object field2, Object field3);
        Query selectBy(Object field1, Object field2, Object field3, Object field4);
        Query selectBy(Object field1, Object field2, Object field3, Object field4, Object field5);
        Query selectBy(Object field1, Object field2, Object field3, Object field4, Object field5, Object field6);
        Query selectBy(
            Object field1,
            Object field2,
            Object field3,
            Object field4,
            Object field5,
            Object field6,
            Object field7
        );
        Query selectBy(
            Object field1,
            Object field2,
            Object field3,
            Object field4,
            Object field5,
            Object field6,
            Object field7,
            Object field8
        );
        Query selectBy(
            Object field1,
            Object field2,
            Object field3,
            Object field4,
            Object field5,
            Object field6,
            Object field7,
            Object field8,
            Object field9
        );
        Query selectBy(
            Object field1,
            Object field2,
            Object field3,
            Object field4,
            Object field5,
            Object field6,
            Object field7,
            Object field8,
            Object field9,
            Object field10
        );
        Query selectBy(List<Object> fields);

        Query selectParent(String relationshipName, Query query);
        Query selectChild(String relationshipName, Query query);
    }

    public Query selectBy(Object field) {
        this.selectFields.add(field);
        return this;
    }

    public Query selectBy(Object field1, Object field2) {
        this.selectFields.add(field1);
        this.selectFields.add(field2);
        return this;
    }

    public Query selectBy(Object field1, Object field2, Object field3) {
        this.selectFields.add(field1);
        this.selectFields.add(field2);
        this.selectFields.add(field3);
        return this;
    }

    public Query selectBy(Object field1, Object field2, Object field3, Object field4) {
        this.selectFields.addAll(new List<Object>{ field1, field2, field3, field4 });
        return this;
    }

    public Query selectBy(Object field1, Object field2, Object field3, Object field4, Object field5) {
        this.selectFields.addAll(new List<Object>{ field1, field2, field3, field4, field5 });
        return this;
    }

    public Query selectBy(Object field1, Object field2, Object field3, Object field4, Object field5, Object field6) {
        this.selectFields.addAll(new List<Object>{ field1, field2, field3, field4, field5, field6 });
        return this;
    }

    public Query selectBy(
        Object field1,
        Object field2,
        Object field3,
        Object field4,
        Object field5,
        Object field6,
        Object field7
    ) {
        this.selectFields.addAll(new List<Object>{ field1, field2, field3, field4, field5, field6, field7 });
        return this;
    }

    public Query selectBy(
        Object field1,
        Object field2,
        Object field3,
        Object field4,
        Object field5,
        Object field6,
        Object field7,
        Object field8
    ) {
        this.selectFields.addAll(new List<Object>{ field1, field2, field3, field4, field5, field6, field7, field8 });
        return this;
    }

    public Query selectBy(
        Object field1,
        Object field2,
        Object field3,
        Object field4,
        Object field5,
        Object field6,
        Object field7,
        Object field8,
        Object field9
    ) {
        this.selectFields.addAll(
            new List<Object>{ field1, field2, field3, field4, field5, field6, field7, field8, field9 }
        );
        return this;
    }

    public Query selectBy(
        Object field1,
        Object field2,
        Object field3,
        Object field4,
        Object field5,
        Object field6,
        Object field7,
        Object field8,
        Object field9,
        Object field10
    ) {
        this.selectFields.addAll(
            new List<Object>{ field1, field2, field3, field4, field5, field6, field7, field8, field9, field10 }
        );
        return this;
    }

    public Query selectBy(List<Object> fields) {
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
    // =====================

    // =======================
    // #region Order By Clause

    public interface Orderable extends Selectable {
        Query orderBy(Object field);
        Query orderBy(Object field1, Object field2);
        Query orderBy(Object field1, Object field2, Object field3);
        Query orderBy(Object field1, Object field2, Object field3, Object field4);
        Query orderBy(Object field1, Object field2, Object field3, Object field4, Object field5);
        Query orderBy(Object field1, Object field2, Object field3, Object field4, Object field5, Object field6);
        Query orderBy(
            Object field1,
            Object field2,
            Object field3,
            Object field4,
            Object field5,
            Object field6,
            Object field7
        );
        Query orderBy(
            Object field1,
            Object field2,
            Object field3,
            Object field4,
            Object field5,
            Object field6,
            Object field7,
            Object field8
        );
        Query orderBy(
            Object field1,
            Object field2,
            Object field3,
            Object field4,
            Object field5,
            Object field6,
            Object field7,
            Object field8,
            Object field9
        );
        Query orderBy(
            Object field1,
            Object field2,
            Object field3,
            Object field4,
            Object field5,
            Object field6,
            Object field7,
            Object field8,
            Object field9,
            Object field10
        );
        Query orderBy(List<Object> fields);
    }

    public class OrderField {
        private String fieldOrFunc { get; set; }
        private Boolean ascending { get; set; }
        private Boolean nullsFist { get; set; }

        public OrderField(String fieldOrFunc) {
            this.fieldOrFunc = fieldOrFunc;
            this.ascending = true;
            this.nullsFist = true;
        }

        public OrderField ascending() {
            this.ascending = true;
            return this;
        }

        public OrderField descending() {
            this.ascending = false;
            return this;
        }

        public OrderField nullsFirst() {
            this.nullsFist = true;
            return this;
        }

        public OrderField nullsLast() {
            this.nullsFist = false;
            return this;
        }
    }

    public static OrderField orderField(String fieldOrFunc) {
        return new OrderField(fieldOrFunc);
    }

    public Query orderBy(Object field) {
        this.orderClause.add(field);
        return this;
    }

    public Query orderBy(Object field1, Object field2) {
        this.orderClause.add(field1);
        this.orderClause.add(field2);
        return this;
    }

    public Query orderBy(Object field1, Object field2, Object field3) {
        this.orderClause.add(field1);
        this.orderClause.add(field2);
        this.orderClause.add(field3);
        return this;
    }

    public Query orderBy(Object field1, Object field2, Object field3, Object field4) {
        this.orderClause.addAll(new List<Object>{ field1, field2, field3, field4 });
        return this;
    }

    public Query orderBy(Object field1, Object field2, Object field3, Object field4, Object field5) {
        this.orderClause.addAll(new List<Object>{ field1, field2, field3, field4, field5 });
        return this;
    }

    public Query orderBy(Object field1, Object field2, Object field3, Object field4, Object field5, Object field6) {
        this.orderClause.addAll(new List<Object>{ field1, field2, field3, field4, field5, field6 });
        return this;
    }

    public Query orderBy(
        Object field1,
        Object field2,
        Object field3,
        Object field4,
        Object field5,
        Object field6,
        Object field7
    ) {
        this.orderClause.addAll(new List<Object>{ field1, field2, field3, field4, field5, field6, field7 });
        return this;
    }

    public Query orderBy(
        Object field1,
        Object field2,
        Object field3,
        Object field4,
        Object field5,
        Object field6,
        Object field7,
        Object field8
    ) {
        this.orderClause.addAll(new List<Object>{ field1, field2, field3, field4, field5, field6, field7, field8 });
        return this;
    }

    public Query orderBy(
        Object field1,
        Object field2,
        Object field3,
        Object field4,
        Object field5,
        Object field6,
        Object field7,
        Object field8,
        Object field9
    ) {
        this.orderClause.addAll(
            new List<Object>{ field1, field2, field3, field4, field5, field6, field7, field8, field9 }
        );
        return this;
    }

    public Query orderBy(
        Object field1,
        Object field2,
        Object field3,
        Object field4,
        Object field5,
        Object field6,
        Object field7,
        Object field8,
        Object field9,
        Object field10
    ) {
        this.orderClause.addAll(
            new List<Object>{ field1, field2, field3, field4, field5, field6, field7, field8, field9, field10 }
        );
        return this;
    }

    public Query orderBy(List<Object> fields) {
        this.orderClause.addAll(fields);
        return this;
    }

    // #endregion
    // =======================

    // =======================
    // #region Group By Clause
    public interface Groupable extends Orderable {
        Query rollup();
        Query cube();

        Query groupBy(String field);
        Query groupBy(String field1, String field2);
        Query groupBy(String field1, String field2, String field3);
        Query groupBy(String field1, String field2, String field3, String field4);
        Query groupBy(String field1, String field2, String field3, String field4, String field5);
        Query groupBy(String field1, String field2, String field3, String field4, String field5, String field6);
        Query groupBy(
            String field1,
            String field2,
            String field3,
            String field4,
            String field5,
            String field6,
            String field7
        );
        Query groupBy(
            String field1,
            String field2,
            String field3,
            String field4,
            String field5,
            String field6,
            String field7,
            String field8
        );
        Query groupBy(
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
        Query groupBy(
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
        Query groupBy(List<String> fields);
    }

    public Query rollup() {
        this.groupByClause.rollup = true;
        return this;
    }

    public Query cube() {
        this.groupByClause.cube = true;
        return this;
    }

    public Query groupBy(String field) {
        this.groupByClause.fieldOrFuncs.add(field);
        return this;
    }

    public Query groupBy(String field1, String field2) {
        this.groupByClause.fieldOrFuncs.add(field1);
        this.groupByClause.fieldOrFuncs.add(field2);
        return this;
    }

    public Query groupBy(String field1, String field2, String field3) {
        this.groupByClause.fieldOrFuncs.add(field1);
        this.groupByClause.fieldOrFuncs.add(field2);
        this.groupByClause.fieldOrFuncs.add(field3);
        return this;
    }

    public Query groupBy(String field1, String field2, String field3, String field4) {
        this.groupByClause.fieldOrFuncs.addAll(new List<String>{ field1, field2, field3, field4 });
        return this;
    }

    public Query groupBy(String field1, String field2, String field3, String field4, String field5) {
        this.groupByClause.fieldOrFuncs.addAll(new List<String>{ field1, field2, field3, field4, field5 });
        return this;
    }

    public Query groupBy(String field1, String field2, String field3, String field4, String field5, String field6) {
        this.groupByClause.fieldOrFuncs.addAll(new List<String>{ field1, field2, field3, field4, field5, field6 });
        return this;
    }

    public Query groupBy(
        String field1,
        String field2,
        String field3,
        String field4,
        String field5,
        String field6,
        String field7
    ) {
        this.groupByClause.fieldOrFuncs.addAll(
            new List<String>{ field1, field2, field3, field4, field5, field6, field7 }
        );
        return this;
    }

    public Query groupBy(
        String field1,
        String field2,
        String field3,
        String field4,
        String field5,
        String field6,
        String field7,
        String field8
    ) {
        this.groupByClause.fieldOrFuncs.addAll(
            new List<String>{ field1, field2, field3, field4, field5, field6, field7, field8 }
        );
        return this;
    }

    public Query groupBy(
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
        this.groupByClause.fieldOrFuncs.addAll(
            new List<String>{ field1, field2, field3, field4, field5, field6, field7, field8, field9 }
        );
        return this;
    }

    public Query groupBy(
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
        this.groupByClause.fieldOrFuncs.addAll(
            new List<String>{ field1, field2, field3, field4, field5, field6, field7, field8, field9, field10 }
        );
        return this;
    }

    public Query groupBy(List<String> fields) {
        this.groupByClause.fieldOrFuncs.addAll(fields);
        return this;
    }

    // #endregion
    // =======================

    // =======================
    // #region SELECT Function
    public interface Function {
        void buildSOQL_Function(List<String> fragments, String parentRelationshipName);
        String buildSOQL_Function();
    }

    public interface SelectFunction extends Function {
    }

    public interface FormatFunction extends SelectFunction {
    }

    public interface ToLabelFunction extends SelectFunction {
    }

    public interface CurrencyFunction extends SelectFunction {
    }

    public interface TimezoneFunction {
    }

    public virtual class FunctionImpl implements Function {
        private String function { get; set; }
        private Object fieldOrFunc { get; set; }
        private String alias { get; set; }

        private FunctionImpl(String function, Object fieldOrFunc, String alias) {
            this.function = function;
            this.fieldOrFunc = fieldOrFunc;
            this.alias = alias;
        }

        public void buildSOQL_Function(List<String> fragments, String parentRelationshipName) {
            fragments.add(this.function);
            fragments.add('(');
            if (this.fieldOrFunc instanceof Function) {
                ((Function) this.fieldOrFunc).buildSOQL_Function(fragments, parentRelationshipName);
            } else {
                if (parentRelationshipName != null) {
                    fragments.add(parentRelationshipName);
                    fragments.add('.');
                }
                fragments.add((String) this.fieldOrFunc);
            }
            fragments.add(')');
            if (this.alias != null) {
                fragments.add(' AS ');
                fragments.add(this.alias);
            }
        }

        public String buildSOQL_Function() {
            return this.function + '(' + this.fieldOrFunc + ')';
        }
    }

    public class FormatFunctionImpl extends FunctionImpl implements FormatFunction {
        private FormatFunctionImpl(String function, Object fieldOrFunc, String alias) {
            super(function, fieldOrFunc, alias);
        }
    }

    public class ToLabelFunctionImpl extends FunctionImpl implements ToLabelFunction {
        private ToLabelFunctionImpl(String function, String fieldOrFunc, String alias) {
            super(function, fieldOrFunc, alias);
        }
    }

    public class CurrencyFunctionImpl extends FunctionImpl implements CurrencyFunction {
        private CurrencyFunctionImpl(String function, String fieldOrFunc, String alias) {
            super(function, fieldOrFunc, alias);
        }
    }

    public static ToLabelFunction toLabel(String field) {
        return new ToLabelFunctionImpl('toLabel', field, null);
    }

    public static ToLabelFunction toLabel(String field, String alias) {
        return new ToLabelFunctionImpl('toLabel', field, alias);
    }

    public static FormatFunction format(String field) {
        return new FormatFunctionImpl('FORMAT', field, null);
    }

    public static FormatFunction format(String field, String alias) {
        return new FormatFunctionImpl('FORMAT', field, alias);
    }

    public static FormatFunction format(CurrencyFunction field) {
        return new FormatFunctionImpl('FORMAT', field, null);
    }

    public static FormatFunction format(CurrencyFunction field, String alias) {
        return new FormatFunctionImpl('FORMAT', field, alias);
    }

    public static CurrencyFunction convertCurrency(String field) {
        return new CurrencyFunctionImpl('convertCurrency', field, null);
    }

    public static CurrencyFunction convertCurrency(String field, String alias) {
        return new CurrencyFunctionImpl('convertCurrency', field, alias);
    }

    public static String distance(String field, Location geo, string unit) {
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
    // =======================

    // ============================
    // #region Group By Aggregation

    public static String count() {
        return 'COUNT()';
    }

    public static String count(String field) {
        return 'COUNT(' + field + ')';
    }

    public static String count(String field, String alias) {
        return 'COUNT(' + field + ') ' + alias;
    }

    public static String countDistinct(String field) {
        return 'COUNT_DISTINCT(' + field + ')';
    }

    public static String countDistinct(String field, String alias) {
        return 'COUNT_DISTINCT(' + field + ') ' + alias;
    }

    public static String sum(String field) {
        return 'SUM(' + field + ')';
    }

    public static String sum(String field, String alias) {
        return 'SUM(' + field + ') ' + alias;
    }

    public static String avg(String field) {
        return 'AVG(' + field + ')';
    }

    public static String avg(String field, String alias) {
        return 'AVG(' + field + ') ' + alias;
    }

    public static String max(String field) {
        return 'MAX(' + field + ')';
    }

    public static String max(String field, String alias) {
        return 'MAX(' + field + ') ' + alias;
    }

    public static String min(String field) {
        return 'MIN(' + field + ')';
    }

    public static String min(String field, String alias) {
        return 'MIN(' + field + ') ' + alias;
    }

    // #endregion
    // ============================

    // ===============================
    // #region Group By Dimension

    public static String grouping(String field) {
        return 'GROUPING(' + field + ')';
    }

    public static String grouping(String field, String alias) {
        return 'GROUPING(' + field + ') ' + alias;
    }

    public static String convertTimezone(String field) {
        return 'convertTimezone(' + field + ')';
    }

    public static String calendarMonth(String field) {
        return 'CALENDAR_MONTH(' + field + ')';
    }

    public static String calendarQuarter(String field) {
        return 'CALENDAR_QUARTER(' + field + ')';
    }

    public static String calendarYear(String field) {
        return 'CALENDAR_YEAR(' + field + ')';
    }

    public static String dayInMonth(String field) {
        return 'DAY_IN_MONTH(' + field + ')';
    }

    public static String dayInWeek(String field) {
        return 'DAY_IN_WEEK(' + field + ')';
    }

    public static String dayInYear(String field) {
        return 'DAY_IN_YEAR(' + field + ')';
    }

    public static String dayOnly(String field) {
        return 'DAY_ONLY(' + field + ')';
    }

    public static String fiscalMonth(String field) {
        return 'FISCAL_MONTH(' + field + ')';
    }

    public static String fiscalQuarter(String field) {
        return 'FISCAL_QUARTER(' + field + ')';
    }

    public static String fiscalYear(String field) {
        return 'FISCAL_YEAR(' + field + ')';
    }

    public static String hourInDay(String field) {
        return 'HOUR_IN_DAY(' + field + ')';
    }

    public static String weekInMonth(String field) {
        return 'WEEK_IN_MONTH(' + field + ')';
    }

    public static String weekInYear(String field) {
        return 'WEEK_IN_YEAR(' + field + ')';
    }

    // #endregion
    // ===============================

    // ====================
    // #region VAR Literal

    public class VarLiteral extends Literal {
        public VarLiteral(String literal) {
            super(literal);
        }
    }

    public static VarLiteral var(String name) {
        return new VarLiteral(':' + name);
    }

    // #endregion
    // ====================

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

    // #endregion
    // ========================
}
