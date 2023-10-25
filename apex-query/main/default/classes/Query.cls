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
    public SObjectType objectType { get; private set; }

    public static Query of(SObjectType objectType) {
        return new QueryImpl(objectType);
    }

    public Integer getCount() {
        return getCount(AccessLevel.SYSTEM_MODE);
    }

    public Integer getCount(AccessLevel accessLevel) {
        Map<String, Object> tmpVars = new Map<String, Object>();
        return Database.countQueryWithBinds(this.build(tmpVars), tmpVars, accessLevel);
    }

    public List<SObject> run() {
        return this.run(AccessLevel.SYSTEM_MODE);
    }

    public List<SObject> run(AccessLevel accessLevel) {
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

    @TestVisible
    protected virtual String build(Map<String, Object> tmpVars) {
        return null;
    }

    @TestVisible
    private String build() {
        Map<String, Object> tmpVars = new Map<String, Object>();
        return this.build(tmpVars);
    }

    // =============
    // #region Query
    private class QueryImpl extends Query implements Querable {
        private SelectorImpl rootSelector { get; set; }
        private TypeOfImpl rootTypeOf { get; set; }
        private Filter rootFilter { get; set; }
        private Filter rootHaving { get; set; }
        private OrdererImpl rootOrderer { get; set; }

        private GrouperImpl rootGrouper { get; set; }

        private Boolean rollup { get; set; }
        private Boolean cube { get; set; }

        private Integer offset { get; set; }
        private Integer limitx { get; set; }

        private Boolean forView { get; set; }
        private Boolean forReference { get; set; }
        private Boolean updateTracking { get; set; }
        private Boolean updateViewstat { get; set; }
        private Boolean forUpdate { get; set; }

        {
            this.rootSelector = new SelectorImpl();
            this.rootOrderer = new OrdererImpl();
            this.rootGrouper = new GrouperImpl();
            this.rollup = false;
            this.cube = false;
        }

        public Boolean equals(Object obj) {
            if (obj == null) {
                return false;
            }

            if (this === obj) {
                return true;
            }

            QueryImpl that = (QueryImpl) obj;

            return this.objectType == that.objectType &&
                this.rootSelector == that.rootSelector &&
                this.rootFilter == that.rootFilter &&
                this.rootOrderer == that.rootOrderer &&
                this.limitx == that.limitx &&
                this.offset == that.offset &&
                this.forView == that.forView &&
                this.forReference == that.forReference &&
                this.updateTracking == that.updateTracking &&
                this.updateViewstat == that.updateViewstat &&
                this.forUpdate == that.forUpdate &&
                this.rollup == that.rollup &&
                this.cube == that.cube &&
                this.rootGrouper == that.rootGrouper &&
                this.rootTypeOf == that.rootTypeOf;
        }

        public Integer hashCode() {
            Integer hashCode = this.objectType == null ? 23 : System.hashCode(this.objectType);
            hashCode = (hashCode * 397) ^ (this.rootSelector == null ? 23 : this.rootSelector.hashCode());
            hashCode = (hashCode * 397) ^ (this.rootFilter == null ? 23 : this.rootFilter.hashCode());
            hashCode = (hashCode * 397) ^ (this.rootOrderer == null ? 23 : this.rootOrderer.hashCode());
            hashCode = (hashCode * 397) ^ (this.rootGrouper == null ? 23 : this.rootGrouper.hashCode());
            hashCode = (hashCode * 397) ^ (this.rootTypeOf == null ? 23 : this.rootTypeOf.hashCode());

            hashCode = (hashCode * 397) ^ (this.limitx == null ? 23 : System.hashCode(this.limitx));
            hashCode = (hashCode * 397) ^ (this.offset == null ? 23 : System.hashCode(this.offset));
            hashCode = (hashCode * 397) ^ (this.forView == null ? 23 : System.hashCode(this.forView));
            hashCode = (hashCode * 397) ^ (this.forReference == null ? 23 : System.hashCode(this.forReference));
            hashCode = (hashCode * 397) ^ (this.updateTracking == null ? 23 : System.hashCode(this.updateTracking));
            hashCode = (hashCode * 397) ^ (this.updateViewstat == null ? 23 : System.hashCode(this.updateViewstat));
            hashCode = (hashCode * 397) ^ (this.forUpdate == null ? 23 : System.hashCode(this.forUpdate));
            hashCode = (hashCode * 397) ^ (this.rollup == null ? 23 : System.hashCode(this.rollup));
            hashCode = (hashCode * 397) ^ (this.cube == null ? 23 : System.hashCode(this.cube));
            return hashCode;
        }

        private QueryImpl(SObjectType objectType) {
            this.objectType = objectType;
        }

        protected override String build(Map<String, Object> tmpVars) {
            List<String> fragments = new List<String>();
            buildSoql(fragments, tmpVars);
            String query = String.join(fragments, '');
            System.debug(query);
            System.debug(tmpVars);
            return query;
        }

        private void buildSoql(List<String> fragments, Map<String, Object> tmpVars) {
            this.buildSoql(this.objectType.getDescribe().getName(), fragments, tmpVars);
        }

        private void buildSoql(String fromObjectName, List<String> fragments, Map<String, Object> tmpVars) {
            this.buildSelect(fragments, tmpVars);
            fragments.add(' FROM ');
            fragments.add(fromObjectName);

            // Build Filters
            if (this.rootFilter != null) {
                fragments.add(' WHERE ');
                this.rootFilter.build(fragments, tmpVars);
            }

            this.buildGroupBy(fragments);

            // Build Filters
            if (this.rootHaving != null) {
                fragments.add(' HAVING ');
                this.rootHaving.build(fragments, tmpVars);
            }

            this.buildOrderBy(fragments);

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
            }
            if (this.forReference == true) {
                fragments.add(' FOR REFERENCE');
            }
            if (this.updateTracking == true) {
                fragments.add(' UPDATE TRACKING');
            }
            if (this.updateViewstat == true) {
                fragments.add(' UPDATE VIEWSTAT');
            }
            if (this.forUpdate == true) {
                fragments.add(' FOR UPDATE');
            }
        }

        private void buildSelect(List<String> fragments, Map<String, Object> tmpVars) {
            fragments.add('SELECT ');
            Boolean isFirst = true;

            for (Object selection : this.rootSelector.selections) {
                if (isFirst) {
                    isFirst = false;
                } else {
                    fragments.add(', ');
                }

                if (selection instanceof QuerySelection) {
                    QuerySelection child = (QuerySelection) selection;
                    fragments.add('(');
                    ((QueryImpl) child.query).buildSoql(child.relation, fragments, tmpVars);
                    fragments.add(')');
                } else {
                    fragments.add(String.valueOf(selection));
                }
            }

            // build typeof statement
            if (this.rootTypeOf != null && !this.rootTypeOf.sobjectTypes.isEmpty()) {
                if (isFirst) {
                    isFirst = false;
                } else {
                    fragments.add(', ');
                }

                fragments.add('TYPEOF ');
                fragments.add(String.valueOf(this.rootTypeOf.field));
                for (SObjectType sobjectType : this.rootTypeOf.sobjectTypes) {
                    fragments.add(' WHEN ');
                    fragments.add(String.valueOf(sobjectType));
                    if (!this.rootTypeOf.fieldsByType.get(sobjectType).isEmpty()) {
                        fragments.add(' THEN ');
                        Boolean isFirstThen = true;
                        for (Object field : this.rootTypeOf.fieldsByType.get(sobjectType)) {
                            if (isFirstThen) {
                                isFirstThen = false;
                            } else {
                                fragments.add(', ');
                            }
                            fragments.add(String.valueOf(field));
                        }
                    }
                }

                if (this.rootTypeOf.fieldsByType.get(null).size() > 0) {
                    fragments.add(' ELSE ');
                    Boolean isFirstElse = true;
                    for (Object field : this.rootTypeOf.fieldsByType.get(null)) {
                        if (isFirstElse) {
                            isFirstElse = false;
                        } else {
                            fragments.add(', ');
                        }
                        fragments.add(String.valueOf(field));
                    }
                }
                fragments.add(' END');
            }

            if (isFirst) {
                fragments.add('Id');
                isFirst = false;
            }
        }

        private void buildOrderBy(List<String> fragments) {
            Boolean isFirst = true;
            Set<Integer> descendingIndexes = this.rootOrderer.descendingIndexes;
            Set<Integer> nullsLastIndexes = this.rootOrderer.nullsLastIndexes;
            for (Integer i = 0; i < this.rootOrderer.fieldOrFuncs.size(); i++) {
                Object fieldOrFunc = this.rootOrderer.fieldOrFuncs[i];
                if (isFirst) {
                    fragments.add(' ORDER BY ');
                } else {
                    fragments.add(', ');
                }
                isFirst = false;

                if (fieldOrFunc instanceof AggregateFunction) {
                    AggregateFunction func = (AggregateFunction) fieldOrFunc;
                    fragments.add(func.name);
                    fragments.add('(');
                    fragments.add(String.valueOf(func.fieldOrFunc));
                    fragments.add(')');
                } else {
                    fragments.add(String.valueOf(fieldOrFunc));
                }

                if (descendingIndexes.contains(i)) {
                    fragments.add(' DESC');
                }

                if (nullsLastIndexes.contains(i)) {
                    fragments.add(' NULLS LAST');
                }
            }
        }

        public void buildGroupBy(List<String> fragments) {
            Boolean isFirst = true;
            for (Object field : this.rootGrouper.fieldOrFuncs) {
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

        // ============
        // #region MISC
        public override Query offset(Integer n) {
            this.offset = n;
            return this;
        }

        public override Query limitx(Integer n) {
            this.limitx = n;
            return this;
        }

        public override Query forView() {
            this.forView = true;
            return this;
        }

        public override Query forReference() {
            this.forReference = true;
            return this;
        }

        public override Query updateTracking() {
            this.updateTracking = true;
            return this;
        }

        public override Query updateViewstat() {
            this.updateViewstat = true;
            return this;
        }

        public override Query forUpdate() {
            this.forUpdate = true;
            return this;
        }

        // #endregion
        // ============

        // ==============
        // #region FILTER
        public override Query filterBy(Filter filter) {
            this.rootFilter = filter;
            return this;
        }

        public override Query havingBy(Filter filter) {
            this.rootHaving = filter;
            return this;
        }
        // #endregion
        // ============

        // ==============
        // #region SELECT
        public override Query selectBy(Selector selector) {
            this.rootSelector.add(selector);
            return this;
        }

        public override Query selectBy(List<Object> fieldOrFuncs) {
            this.rootSelector.selections.addAll(fieldOrFuncs);
            return this;
        }

        // Field
        public override Query selectBy(SObjectField field) {
            this.rootSelector.selections.add(field);
            return this;
        }

        public override Query selectBy(SObjectField field1, SObjectField field2) {
            this.rootSelector.selections.add(field1);
            this.rootSelector.selections.add(field2);
            return this;
        }

        public override Query selectBy(SObjectField field1, SObjectField field2, SObjectField field3) {
            this.rootSelector.selections.add(field1);
            this.rootSelector.selections.add(field2);
            this.rootSelector.selections.add(field3);
            return this;
        }

        public override Query selectBy(
            SObjectField field1,
            SObjectField field2,
            SObjectField field3,
            SObjectField field4
        ) {
            this.rootSelector.selections.add(field1);
            this.rootSelector.selections.add(field2);
            this.rootSelector.selections.add(field3);
            this.rootSelector.selections.add(field4);
            return this;
        }

        public override Query selectBy(
            SObjectField field1,
            SObjectField field2,
            SObjectField field3,
            SObjectField field4,
            SObjectField field5
        ) {
            this.rootSelector.selections.add(field1);
            this.rootSelector.selections.add(field2);
            this.rootSelector.selections.add(field3);
            this.rootSelector.selections.add(field4);
            this.rootSelector.selections.add(field5);
            return this;
        }

        // String
        public override Query selectBy(String field) {
            this.rootSelector.selections.add(field);
            return this;
        }

        public override Query selectBy(String field1, String field2) {
            this.rootSelector.selections.add(field1);
            this.rootSelector.selections.add(field2);
            return this;
        }

        public override Query selectBy(String field1, String field2, String field3) {
            this.rootSelector.selections.add(field1);
            this.rootSelector.selections.add(field2);
            this.rootSelector.selections.add(field3);
            return this;
        }

        public override Query selectBy(String field1, String field2, String field3, String field4) {
            this.rootSelector.selections.add(field1);
            this.rootSelector.selections.add(field2);
            this.rootSelector.selections.add(field3);
            this.rootSelector.selections.add(field4);
            return this;
        }

        public override Query selectBy(String field1, String field2, String field3, String field4, String field5) {
            this.rootSelector.selections.add(field1);
            this.rootSelector.selections.add(field2);
            this.rootSelector.selections.add(field3);
            this.rootSelector.selections.add(field4);
            this.rootSelector.selections.add(field5);
            return this;
        }

        // Function
        public override Query selectBy(SelectFunction func) {
            this.rootSelector.selections.add(func);
            return this;
        }

        public override Query selectBy(SelectFunction func1, SelectFunction func2) {
            this.rootSelector.selections.add(func1);
            this.rootSelector.selections.add(func2);
            return this;
        }

        public override Query selectBy(SelectFunction func1, SelectFunction func2, SelectFunction func3) {
            this.rootSelector.selections.add(func1);
            this.rootSelector.selections.add(func2);
            this.rootSelector.selections.add(func3);
            return this;
        }

        public override Query selectBy(
            SelectFunction func1,
            SelectFunction func2,
            SelectFunction func3,
            SelectFunction func4
        ) {
            this.rootSelector.selections.add(func1);
            this.rootSelector.selections.add(func2);
            this.rootSelector.selections.add(func3);
            this.rootSelector.selections.add(func4);
            return this;
        }

        public override Query selectBy(
            SelectFunction func1,
            SelectFunction func2,
            SelectFunction func3,
            SelectFunction func4,
            SelectFunction func5
        ) {
            this.rootSelector.selections.add(func1);
            this.rootSelector.selections.add(func2);
            this.rootSelector.selections.add(func3);
            this.rootSelector.selections.add(func4);
            this.rootSelector.selections.add(func5);
            return this;
        }

        public override Query selectBy(String relationName, Query query) {
            this.rootSelector.add(relationName, query);
            return this;
        }

        public override Query selectBy(TypeOf typeof) {
            this.rootTypeOf = (TypeOfImpl) typeof;
            return this;
        }
        // #endregion
        // ==============

        // ================
        // #region ORDER BY
        public override Query orderBy(Orderer orderer) {
            this.rootOrderer.add(orderer);
            return this;
        }

        public override Query orderBy(List<Object> fieldOrFuncs) {
            this.rootOrderer.add(fieldOrFuncs);
            return this;
        }

        // String
        public override Query orderBy(String field) {
            this.rootOrderer.add(field);
            return this;
        }
        public override Query orderBy(String field1, String field2) {
            this.rootOrderer.add(field1, field2);
            return this;
        }
        public override Query orderBy(String field1, String field2, String field3) {
            this.rootOrderer.add(field1, field2, field3);
            return this;
        }
        public override Query orderBy(String field1, String field2, String field3, String field4) {
            this.rootOrderer.add(field1, field2, field3, field4);
            return this;
        }
        public override Query orderBy(String field1, String field2, String field3, String field4, String field5) {
            this.rootOrderer.add(field1, field2, field3, field4, field5);
            return this;
        }

        // SObjectField
        public override Query orderBy(SObjectField field) {
            this.rootOrderer.add(field);
            return this;
        }
        public override Query orderBy(SObjectField field1, SObjectField field2) {
            this.rootOrderer.add(field1, field2);
            return this;
        }
        public override Query orderBy(SObjectField field1, SObjectField field2, SObjectField field3) {
            this.rootOrderer.add(field1, field2, field3);
            return this;
        }
        public override Query orderBy(
            SObjectField field1,
            SObjectField field2,
            SObjectField field3,
            SObjectField field4
        ) {
            this.rootOrderer.add(field1, field2, field3, field4);
            return this;
        }
        public override Query orderBy(
            SObjectField field1,
            SObjectField field2,
            SObjectField field3,
            SObjectField field4,
            SObjectField field5
        ) {
            this.rootOrderer.add(field1, field2, field3, field4, field5);
            return this;
        }

        // Function
        public override Query orderBy(OrderFunction func) {
            this.rootOrderer.add(func);
            return this;
        }

        public override Query orderBy(OrderFunction func1, OrderFunction func2) {
            this.rootOrderer.add(func1, func2);
            return this;
        }

        public override Query orderBy(OrderFunction func1, OrderFunction func2, OrderFunction func3) {
            this.rootOrderer.add(func1, func2, func3);
            return this;
        }

        public override Query orderBy(
            OrderFunction func1,
            OrderFunction func2,
            OrderFunction func3,
            OrderFunction func4
        ) {
            this.rootOrderer.add(func1, func2, func3, func4);
            return this;
        }

        public override Query orderBy(
            OrderFunction func1,
            OrderFunction func2,
            OrderFunction func3,
            OrderFunction func4,
            OrderFunction func5
        ) {
            this.rootOrderer.add(func1, func2, func3, func4, func5);
            return this;
        }

        // Others
        public override Query ascending() {
            this.rootOrderer.setAscending(true);
            return this;
        }

        public override Query descending() {
            this.rootOrderer.setAscending(false);
            return this;
        }

        public override Query nullsFirst() {
            this.rootOrderer.setNullFirst(true);
            return this;
        }

        public override Query nullsLast() {
            this.rootOrderer.setNullFirst(false);
            return this;
        }
        // #endregion
        // ================

        // ================
        // #region GROUP BY
        public override Query groupBy(Grouper grouper) {
            this.rootGrouper.add(grouper);
            return this;
        }

        public override Query groupBy(List<Object> fieldOrFuncs) {
            this.rootGrouper.fieldOrFuncs.addAll(fieldOrFuncs);
            return this;
        }

        // String
        public override Query groupBy(String field) {
            this.rootGrouper.fieldOrFuncs.add(field);
            return this;
        }

        public override Query groupBy(String field1, String field2) {
            this.rootGrouper.fieldOrFuncs.add(field1);
            this.rootGrouper.fieldOrFuncs.add(field2);
            return this;
        }

        public override Query groupBy(String field1, String field2, String field3) {
            this.rootGrouper.fieldOrFuncs.add(field1);
            this.rootGrouper.fieldOrFuncs.add(field2);
            this.rootGrouper.fieldOrFuncs.add(field3);
            return this;
        }

        public override Query groupBy(String field1, String field2, String field3, String field4) {
            this.rootGrouper.fieldOrFuncs.add(field1);
            this.rootGrouper.fieldOrFuncs.add(field2);
            this.rootGrouper.fieldOrFuncs.add(field3);
            this.rootGrouper.fieldOrFuncs.add(field4);
            return this;
        }

        public override Query groupBy(String field1, String field2, String field3, String field4, String field5) {
            this.rootGrouper.fieldOrFuncs.add(field1);
            this.rootGrouper.fieldOrFuncs.add(field2);
            this.rootGrouper.fieldOrFuncs.add(field3);
            this.rootGrouper.fieldOrFuncs.add(field4);
            this.rootGrouper.fieldOrFuncs.add(field5);
            return this;
        }

        // SObjectField
        public override Query groupBy(SObjectField field) {
            this.rootGrouper.fieldOrFuncs.add(field);
            return this;
        }

        public override Query groupBy(SObjectField field1, SObjectField field2) {
            this.rootGrouper.fieldOrFuncs.add(field1);
            this.rootGrouper.fieldOrFuncs.add(field2);
            return this;
        }

        public override Query groupBy(SObjectField field1, SObjectField field2, SObjectField field3) {
            this.rootGrouper.fieldOrFuncs.add(field1);
            this.rootGrouper.fieldOrFuncs.add(field2);
            this.rootGrouper.fieldOrFuncs.add(field3);
            return this;
        }

        public override Query groupBy(
            SObjectField field1,
            SObjectField field2,
            SObjectField field3,
            SObjectField field4
        ) {
            this.rootGrouper.fieldOrFuncs.add(field1);
            this.rootGrouper.fieldOrFuncs.add(field2);
            this.rootGrouper.fieldOrFuncs.add(field3);
            this.rootGrouper.fieldOrFuncs.add(field4);
            return this;
        }

        public override Query groupBy(
            SObjectField field1,
            SObjectField field2,
            SObjectField field3,
            SObjectField field4,
            SObjectField field5
        ) {
            this.rootGrouper.fieldOrFuncs.add(field1);
            this.rootGrouper.fieldOrFuncs.add(field2);
            this.rootGrouper.fieldOrFuncs.add(field3);
            this.rootGrouper.fieldOrFuncs.add(field4);
            this.rootGrouper.fieldOrFuncs.add(field5);
            return this;
        }

        // Function
        public override Query groupBy(DateFunction func) {
            this.rootGrouper.fieldOrFuncs.add(func);
            return this;
        }

        public override Query groupBy(DateFunction func1, DateFunction func2) {
            this.rootGrouper.fieldOrFuncs.add(func1);
            this.rootGrouper.fieldOrFuncs.add(func2);
            return this;
        }

        public override Query groupBy(DateFunction func1, DateFunction func2, DateFunction func3) {
            this.rootGrouper.fieldOrFuncs.add(func1);
            this.rootGrouper.fieldOrFuncs.add(func2);
            this.rootGrouper.fieldOrFuncs.add(func3);
            return this;
        }

        public override Query groupBy(DateFunction func1, DateFunction func2, DateFunction func3, DateFunction func4) {
            this.rootGrouper.fieldOrFuncs.add(func1);
            this.rootGrouper.fieldOrFuncs.add(func2);
            this.rootGrouper.fieldOrFuncs.add(func3);
            this.rootGrouper.fieldOrFuncs.add(func4);
            return this;
        }

        public override Query groupBy(
            DateFunction func1,
            DateFunction func2,
            DateFunction func3,
            DateFunction func4,
            DateFunction func5
        ) {
            this.rootGrouper.fieldOrFuncs.add(func1);
            this.rootGrouper.fieldOrFuncs.add(func2);
            this.rootGrouper.fieldOrFuncs.add(func3);
            this.rootGrouper.fieldOrFuncs.add(func4);
            this.rootGrouper.fieldOrFuncs.add(func5);
            return this;
        }

        public override Query rollup() {
            this.rollup = true;
            return this;
        }

        public override Query cube() {
            this.cube = true;
            return this;
        }
        // #endregion
        // ================
    }
    // #endregion
    // =============

    // ==============
    // #region SELECT

    @TestVisible
    private class QuerySelection {
        private String relation { get; set; }
        private Query query { get; set; }

        @TestVisible
        private QuerySelection(String relation, Query query) {
            this.relation = relation;
            this.query = query;
        }

        public Boolean equals(Object obj) {
            if (obj == null) {
                return false;
            }

            if (this === obj) {
                return true;
            }

            QuerySelection that = (QuerySelection) obj;

            return this.relation == that.relation && this.query == that.query;
        }

        public Integer hashCode() {
            Integer hashCode = this.relation == null ? 23 : this.relation.hashCode();
            hashCode = (hashCode * 397) ^ (this.query == null ? 23 : this.query.hashCode());
            return hashCode;
        }
    }

    public interface Selector {
        Selector add(String field);
        Selector add(String field1, String field2);
        Selector add(String field1, String field2, String field3);
        Selector add(String field1, String field2, String field3, String field4);
        Selector add(String field1, String field2, String field3, String field4, String field5);

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

        Selector add(SelectFunction func);
        Selector add(SelectFunction func1, SelectFunction func2);
        Selector add(SelectFunction func1, SelectFunction func2, SelectFunction func3);
        Selector add(SelectFunction func1, SelectFunction func2, SelectFunction func3, SelectFunction func4);
        Selector add(
            SelectFunction func1,
            SelectFunction func2,
            SelectFunction func3,
            SelectFunction func4,
            SelectFunction func5
        );
        Selector add(String relationName, Query query);
        Selector add(List<Object> fieldOrFuncs);
        Selector add(Selector other);
    }

    private class SelectorImpl implements Selector {
        private List<Object> selections { get; set; }

        private SelectorImpl() {
            this.selections = new List<Object>();
        }

        public Boolean equals(Object obj) {
            if (obj == null) {
                return false;
            }

            if (this === obj) {
                return true;
            }

            SelectorImpl that = (SelectorImpl) obj;
            return this.selections == that.selections;
        }

        public Integer hashCode() {
            return this.selections == null ? 23 : this.selections.hashCode();
        }

        public Selector add(String field) {
            this.selections.add(field);
            return this;
        }

        public Selector add(String field1, String field2) {
            this.selections.add(field1);
            this.selections.add(field2);
            return this;
        }

        public Selector add(String field1, String field2, String field3) {
            this.selections.add(field1);
            this.selections.add(field2);
            this.selections.add(field3);
            return this;
        }

        public Selector add(String field1, String field2, String field3, String field4) {
            this.selections.add(field1);
            this.selections.add(field2);
            this.selections.add(field3);
            this.selections.add(field4);
            return this;
        }

        public Selector add(String field1, String field2, String field3, String field4, String field5) {
            this.selections.add(field1);
            this.selections.add(field2);
            this.selections.add(field3);
            this.selections.add(field4);
            this.selections.add(field5);
            return this;
        }

        public Selector add(SObjectField field) {
            this.selections.add(field);
            return this;
        }

        public Selector add(SObjectField field1, SObjectField field2) {
            this.selections.add(field1);
            this.selections.add(field2);
            return this;
        }

        public Selector add(SObjectField field1, SObjectField field2, SObjectField field3) {
            this.selections.add(field1);
            this.selections.add(field2);
            this.selections.add(field3);
            return this;
        }

        public Selector add(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            this.selections.add(field1);
            this.selections.add(field2);
            this.selections.add(field3);
            this.selections.add(field4);
            return this;
        }

        public Selector add(
            SObjectField field1,
            SObjectField field2,
            SObjectField field3,
            SObjectField field4,
            SObjectField field5
        ) {
            this.selections.add(field1);
            this.selections.add(field2);
            this.selections.add(field3);
            this.selections.add(field4);
            this.selections.add(field5);
            return this;
        }

        public Selector add(SelectFunction func) {
            this.selections.add(func);
            return this;
        }

        public Selector add(SelectFunction func1, SelectFunction func2) {
            this.selections.add(func1);
            this.selections.add(func2);
            return this;
        }

        public Selector add(SelectFunction func1, SelectFunction func2, SelectFunction func3) {
            this.selections.add(func1);
            this.selections.add(func2);
            this.selections.add(func3);
            return this;
        }

        public Selector add(SelectFunction func1, SelectFunction func2, SelectFunction func3, SelectFunction func4) {
            this.selections.add(func1);
            this.selections.add(func2);
            this.selections.add(func3);
            this.selections.add(func4);
            return this;
        }

        public Selector add(
            SelectFunction func1,
            SelectFunction func2,
            SelectFunction func3,
            SelectFunction func4,
            SelectFunction func5
        ) {
            this.selections.add(func1);
            this.selections.add(func2);
            this.selections.add(func3);
            this.selections.add(func4);
            this.selections.add(func5);
            return this;
        }

        public Selector add(String relationName, Query query) {
            if (query != null) {
                this.selections.add(new QuerySelection(relationName, query));
            }
            return this;
        }

        public Selector add(List<Object> fieldOrFuncs) {
            this.selections.addAll(fieldOrFuncs);
            return this;
        }

        public Selector add(Selector other) {
            if (other != null) {
                this.selections.addAll(((SelectorImpl) other).selections);
            }
            return this;
        }
    }

    public static Selector selector() {
        return new SelectorImpl();
    }
    // #endregion
    // ==============

    //========================
    // #region SELECT - TYPEOF

    public interface TypeOf {
        TypeOf when(SObjectType sobjectType);

        TypeOf then(SObjectField field);
        TypeOf then(SObjectField field1, SObjectField field2);
        TypeOf then(SObjectField field1, SObjectField field2, SObjectField field3);
        TypeOf then(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        TypeOf then(
            SObjectField field1,
            SObjectField field2,
            SObjectField field3,
            SObjectField field4,
            SObjectField field5
        );
        TypeOf elsex(SObjectField field);
        TypeOf elsex(SObjectField field1, SObjectField field2);
        TypeOf elsex(SObjectField field1, SObjectField field2, SObjectField field3);
        TypeOf elsex(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        TypeOf elsex(
            SObjectField field1,
            SObjectField field2,
            SObjectField field3,
            SObjectField field4,
            SObjectField field5
        );

        TypeOf then(String field);
        TypeOf then(String field1, String field2);
        TypeOf then(String field1, String field2, String field3);
        TypeOf then(String field1, String field2, String field3, String field4);
        TypeOf then(String field1, String field2, String field3, String field4, String field5);
        TypeOf elsex(String field);
        TypeOf elsex(String field1, String field2);
        TypeOf elsex(String field1, String field2, String field3);
        TypeOf elsex(String field1, String field2, String field3, String field4);
        TypeOf elsex(String field1, String field2, String field3, String field4, String field5);
    }

    private class TypeOfImpl implements TypeOf {
        private string field { get; set; }
        private List<SObjectType> sobjectTypes { get; set; }
        private Map<SObjectType, List<Object>> fieldsByType { get; set; }
        private SObjectType currentType { get; set; }

        private TypeOfImpl(string field) {
            this.field = field;
            this.sobjectTypes = new List<SObjectType>();
            this.fieldsByType = new Map<SObjectType, List<Object>>{ null => new List<Object>() };
        }

        public Boolean equals(Object obj) {
            if (obj == null) {
                return false;
            }

            if (this === obj) {
                return true;
            }

            TypeOfImpl that = (TypeOfImpl) obj;
            return this.field == that.field && this.fieldsByType == that.fieldsByType;
        }

        public Integer hashCode() {
            Integer hashCode = this.field == null ? 23 : this.field.hashCode();
            hashCode = (hashCode * 397) ^ (this.fieldsByType == null ? 23 : this.fieldsByType.hashCode());
            return hashCode;
        }

        public TypeOf when(SObjectType sobjectType) {
            if (sobjectType != null) {
                this.currentType = sobjectType;
                if (!this.fieldsByType.containsKey(sobjectType)) {
                    this.fieldsByType.put(sobjectType, new List<Object>());
                    this.sobjectTypes.add(sobjectType);
                }
            }
            return this;
        }

        public TypeOf then(SObjectField field) {
            if (this.currentType != null) {
                this.fieldsByType.get(this.currentType).add(field);
            }
            return this;
        }
        public TypeOf then(SObjectField field1, SObjectField field2) {
            if (this.currentType != null) {
                this.fieldsByType.get(this.currentType).add(field1);
                this.fieldsByType.get(this.currentType).add(field2);
            }
            return this;
        }
        public TypeOf then(SObjectField field1, SObjectField field2, SObjectField field3) {
            if (this.currentType != null) {
                this.fieldsByType.get(this.currentType).add(field1);
                this.fieldsByType.get(this.currentType).add(field2);
                this.fieldsByType.get(this.currentType).add(field3);
            }
            return this;
        }
        public TypeOf then(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            if (this.currentType != null) {
                this.fieldsByType.get(this.currentType).add(field1);
                this.fieldsByType.get(this.currentType).add(field2);
                this.fieldsByType.get(this.currentType).add(field3);
                this.fieldsByType.get(this.currentType).add(field4);
            }
            return this;
        }
        public TypeOf then(
            SObjectField field1,
            SObjectField field2,
            SObjectField field3,
            SObjectField field4,
            SObjectField field5
        ) {
            if (this.currentType != null) {
                this.fieldsByType.get(this.currentType).add(field1);
                this.fieldsByType.get(this.currentType).add(field2);
                this.fieldsByType.get(this.currentType).add(field3);
                this.fieldsByType.get(this.currentType).add(field4);
                this.fieldsByType.get(this.currentType).add(field5);
            }
            return this;
        }

        public TypeOf elsex(SObjectField field) {
            this.fieldsByType.get(null).add(field);

            return this;
        }
        public TypeOf elsex(SObjectField field1, SObjectField field2) {
            this.fieldsByType.get(null).add(field1);
            this.fieldsByType.get(null).add(field2);

            return this;
        }
        public TypeOf elsex(SObjectField field1, SObjectField field2, SObjectField field3) {
            this.fieldsByType.get(null).add(field1);
            this.fieldsByType.get(null).add(field2);
            this.fieldsByType.get(null).add(field3);

            return this;
        }
        public TypeOf elsex(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            this.fieldsByType.get(null).add(field1);
            this.fieldsByType.get(null).add(field2);
            this.fieldsByType.get(null).add(field3);
            this.fieldsByType.get(null).add(field4);

            return this;
        }
        public TypeOf elsex(
            SObjectField field1,
            SObjectField field2,
            SObjectField field3,
            SObjectField field4,
            SObjectField field5
        ) {
            this.fieldsByType.get(null).add(field1);
            this.fieldsByType.get(null).add(field2);
            this.fieldsByType.get(null).add(field3);
            this.fieldsByType.get(null).add(field4);
            this.fieldsByType.get(null).add(field5);

            return this;
        }

        // Strings
        public TypeOf then(String field) {
            if (currentType != null) {
                this.fieldsByType.get(this.currentType).add(field);
            }
            return this;
        }
        public TypeOf then(String field1, String field2) {
            if (currentType != null) {
                this.fieldsByType.get(this.currentType).add(field1);
                this.fieldsByType.get(this.currentType).add(field2);
            }
            return this;
        }
        public TypeOf then(String field1, String field2, String field3) {
            if (currentType != null) {
                this.fieldsByType.get(this.currentType).add(field1);
                this.fieldsByType.get(this.currentType).add(field2);
                this.fieldsByType.get(this.currentType).add(field3);
            }
            return this;
        }
        public TypeOf then(String field1, String field2, String field3, String field4) {
            if (currentType != null) {
                this.fieldsByType.get(this.currentType).add(field1);
                this.fieldsByType.get(this.currentType).add(field2);
                this.fieldsByType.get(this.currentType).add(field3);
                this.fieldsByType.get(this.currentType).add(field4);
            }
            return this;
        }
        public TypeOf then(String field1, String field2, String field3, String field4, String field5) {
            if (currentType != null) {
                this.fieldsByType.get(this.currentType).add(field1);
                this.fieldsByType.get(this.currentType).add(field2);
                this.fieldsByType.get(this.currentType).add(field3);
                this.fieldsByType.get(this.currentType).add(field4);
                this.fieldsByType.get(this.currentType).add(field5);
            }
            return this;
        }

        public TypeOf elsex(String field) {
            this.fieldsByType.get(null).add(field);

            return this;
        }
        public TypeOf elsex(String field1, String field2) {
            this.fieldsByType.get(null).add(field1);
            this.fieldsByType.get(null).add(field2);

            return this;
        }
        public TypeOf elsex(String field1, String field2, String field3) {
            this.fieldsByType.get(null).add(field1);
            this.fieldsByType.get(null).add(field2);
            this.fieldsByType.get(null).add(field3);

            return this;
        }
        public TypeOf elsex(String field1, String field2, String field3, String field4) {
            this.fieldsByType.get(null).add(field1);
            this.fieldsByType.get(null).add(field2);
            this.fieldsByType.get(null).add(field3);
            this.fieldsByType.get(null).add(field4);

            return this;
        }
        public TypeOf elsex(String field1, String field2, String field3, String field4, String field5) {
            this.fieldsByType.get(null).add(field1);
            this.fieldsByType.get(null).add(field2);
            this.fieldsByType.get(null).add(field3);
            this.fieldsByType.get(null).add(field4);
            this.fieldsByType.get(null).add(field5);

            return this;
        }
    }

    public static TypeOf typeof(String field) {
        return new TypeOfImpl(field);
    }

    // #endregion
    //========================

    // ================
    // #region ORDER BY

    public interface Orderer {
        Orderer ascending();
        Orderer descending();
        Orderer nullsFirst();
        Orderer nullsLast();

        Orderer add(String field);
        Orderer add(String field1, String field2);
        Orderer add(String field1, String field2, String field3);
        Orderer add(String field1, String field2, String field3, String field4);
        Orderer add(String field1, String field2, String field3, String field4, String field5);

        Orderer add(SObjectField field);
        Orderer add(SObjectField field1, SObjectField field2);
        Orderer add(SObjectField field1, SObjectField field2, SObjectField field3);
        Orderer add(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        Orderer add(
            SObjectField field1,
            SObjectField field2,
            SObjectField field3,
            SObjectField field4,
            SObjectField field5
        );

        Orderer add(OrderFunction func);
        Orderer add(OrderFunction func1, OrderFunction func2);
        Orderer add(OrderFunction func1, OrderFunction func2, OrderFunction func3);
        Orderer add(OrderFunction func1, OrderFunction func2, OrderFunction func3, OrderFunction func4);
        Orderer add(
            OrderFunction func1,
            OrderFunction func2,
            OrderFunction func3,
            OrderFunction func4,
            OrderFunction func5
        );

        Orderer add(List<Object> fieldOrFuncs);
        Orderer add(Orderer other);
    }

    private class OrdererImpl implements Orderer {
        private List<Object> fieldOrFuncs { get; set; }
        private Set<Integer> descendingIndexes { get; set; }
        private Set<Integer> nullsLastIndexes { get; set; }

        private Integer batchSize { get; set; }

        private OrdererImpl() {
            this.fieldOrFuncs = new List<Object>();
            this.descendingIndexes = new Set<Integer>();
            this.nullsLastIndexes = new Set<Integer>();
            this.batchSize = 0;
        }

        public Boolean equals(Object obj) {
            if (obj == null) {
                return false;
            }

            if (this === obj) {
                return true;
            }

            OrdererImpl that = (OrdererImpl) obj;

            return this.fieldOrFuncs == that.fieldOrFuncs &&
                this.descendingIndexes == that.descendingIndexes &&
                this.nullsLastIndexes == that.nullsLastIndexes;
        }

        public Integer hashCode() {
            Integer hashCode = this.fieldOrFuncs == null ? 23 : this.fieldOrFuncs.hashCode();
            hashCode = (hashCode * 397) ^ (this.descendingIndexes == null ? 23 : this.descendingIndexes.hashCode());
            hashCode = (hashCode * 397) ^ (this.nullsLastIndexes == null ? 23 : this.nullsLastIndexes.hashCode());
            return hashCode;
        }

        private void setAscending(Boolean ascending) {
            Integer size = this.fieldOrFuncs.size();
            if (size >= this.batchSize) {
                for (Integer i = this.batchSize; i > 0; i--) {
                    if (!ascending) {
                        this.descendingIndexes.add(size - i);
                    } else {
                        this.descendingIndexes.remove(size - i);
                    }
                }
            }
        }

        private void setNullFirst(Boolean nullFirst) {
            Integer size = this.fieldOrFuncs.size();
            if (size >= this.batchSize) {
                for (Integer i = this.batchSize; i > 0; i--) {
                    if (!nullFirst) {
                        this.nullsLastIndexes.add(size - i);
                    } else {
                        this.nullsLastIndexes.remove(size - i);
                    }
                }
            }
        }

        public Orderer ascending() {
            this.setAscending(true);
            return this;
        }

        public Orderer descending() {
            this.setAscending(false);
            return this;
        }

        public Orderer nullsFirst() {
            this.setNullFirst(true);
            return this;
        }

        public Orderer nullsLast() {
            this.setNullFirst(false);
            return this;
        }

        // String
        public Orderer add(String field) {
            this.batchSize = 1;
            this.fieldOrFuncs.add(field);
            return this;
        }

        public Orderer add(String field1, String field2) {
            this.batchSize = 2;
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            return this;
        }

        public Orderer add(String field1, String field2, String field3) {
            this.batchSize = 3;
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            return this;
        }

        public Orderer add(String field1, String field2, String field3, String field4) {
            this.batchSize = 4;
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            this.fieldOrFuncs.add(field4);
            return this;
        }

        public Orderer add(String field1, String field2, String field3, String field4, String field5) {
            this.batchSize = 5;
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            this.fieldOrFuncs.add(field4);
            this.fieldOrFuncs.add(field5);
            return this;
        }

        // SObjectField
        public Orderer add(SObjectField field) {
            this.batchSize = 1;
            this.fieldOrFuncs.add(field);
            return this;
        }

        public Orderer add(SObjectField field1, SObjectField field2) {
            this.batchSize = 2;
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            return this;
        }

        public Orderer add(SObjectField field1, SObjectField field2, SObjectField field3) {
            this.batchSize = 3;
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            return this;
        }

        public Orderer add(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            this.batchSize = 4;
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            this.fieldOrFuncs.add(field4);
            return this;
        }

        public Orderer add(
            SObjectField field1,
            SObjectField field2,
            SObjectField field3,
            SObjectField field4,
            SObjectField field5
        ) {
            this.batchSize = 5;
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            this.fieldOrFuncs.add(field4);
            this.fieldOrFuncs.add(field5);
            return this;
        }

        // Functions
        public Orderer add(OrderFunction func) {
            this.batchSize = 1;
            this.fieldOrFuncs.add(func);
            return this;
        }

        public Orderer add(OrderFunction func1, OrderFunction func2) {
            this.batchSize = 2;
            this.fieldOrFuncs.add(func1);
            this.fieldOrFuncs.add(func2);
            return this;
        }

        public Orderer add(OrderFunction func1, OrderFunction func2, OrderFunction func3) {
            this.batchSize = 3;
            this.fieldOrFuncs.add(func1);
            this.fieldOrFuncs.add(func2);
            this.fieldOrFuncs.add(func3);
            return this;
        }

        public Orderer add(OrderFunction func1, OrderFunction func2, OrderFunction func3, OrderFunction func4) {
            this.batchSize = 4;
            this.fieldOrFuncs.add(func1);
            this.fieldOrFuncs.add(func2);
            this.fieldOrFuncs.add(func3);
            this.fieldOrFuncs.add(func4);
            return this;
        }

        public Orderer add(
            OrderFunction func1,
            OrderFunction func2,
            OrderFunction func3,
            OrderFunction func4,
            OrderFunction func5
        ) {
            this.batchSize = 5;
            this.fieldOrFuncs.add(func1);
            this.fieldOrFuncs.add(func2);
            this.fieldOrFuncs.add(func3);
            this.fieldOrFuncs.add(func4);
            this.fieldOrFuncs.add(func5);
            return this;
        }

        // Others
        public Orderer add(List<Object> fieldOrFuncs) {
            this.fieldOrFuncs.addAll(fieldOrFuncs);
            return this;
        }

        public Orderer add(Orderer other) {
            if (other != null) {
                this.batchSize = this.fieldOrFuncs.size();
                Set<Integer> descendingIndexes = new Set<Integer>();
                for (Integer index : ((OrdererImpl) other).descendingIndexes) {
                    descendingIndexes.add(this.batchSize + index);
                }
                Set<Integer> nullsLastIndexes = new Set<Integer>();
                for (Integer index : ((OrdererImpl) other).nullsLastIndexes) {
                    nullsLastIndexes.add(this.batchSize + index);
                }

                this.descendingIndexes.addAll(descendingIndexes);
                this.nullsLastIndexes.addAll(nullsLastIndexes);
                this.fieldOrFuncs.addAll(((OrdererImpl) other).fieldOrFuncs);
                this.batchSize = 0;
            }
            return this;
        }
    }

    public static Orderer orderer() {
        return new OrdererImpl();
    }
    // #endregion
    // ================

    // ================
    // #region GROUP BY
    public interface Grouper {
        Grouper add(String field);
        Grouper add(String field1, String field2);
        Grouper add(String field1, String field2, String field3);
        Grouper add(String field1, String field2, String field3, String field4);
        Grouper add(String field1, String field2, String field3, String field4, String field5);

        Grouper add(SObjectField field);
        Grouper add(SObjectField field1, SObjectField field2);
        Grouper add(SObjectField field1, SObjectField field2, SObjectField field3);
        Grouper add(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        Grouper add(
            SObjectField field1,
            SObjectField field2,
            SObjectField field3,
            SObjectField field4,
            SObjectField field5
        );

        Grouper add(DateFunction func);
        Grouper add(DateFunction func1, DateFunction func2);
        Grouper add(DateFunction func1, DateFunction func2, DateFunction func3);
        Grouper add(DateFunction func1, DateFunction func2, DateFunction func3, DateFunction func4);
        Grouper add(DateFunction func1, DateFunction func2, DateFunction func3, DateFunction func4, DateFunction func5);

        Grouper add(List<Object> fieldOrFuncs);
        Grouper add(Grouper other);
    }

    private class GrouperImpl implements Grouper {
        private List<Object> fieldOrFuncs { get; set; }

        private GrouperImpl() {
            this.fieldOrFuncs = new List<Object>();
        }

        public Boolean equals(Object obj) {
            if (obj == null) {
                return false;
            }

            if (this === obj) {
                return true;
            }

            GrouperImpl that = (GrouperImpl) obj;
            return this.fieldOrFuncs == that.fieldOrFuncs;
        }

        public Integer hashCode() {
            return this.fieldOrFuncs.hashCode();
        }

        // String
        public Grouper add(String field) {
            this.fieldOrFuncs.add(field);
            return this;
        }

        public Grouper add(String field1, String field2) {
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            return this;
        }

        public Grouper add(String field1, String field2, String field3) {
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            return this;
        }

        public Grouper add(String field1, String field2, String field3, String field4) {
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            this.fieldOrFuncs.add(field4);
            return this;
        }

        public Grouper add(String field1, String field2, String field3, String field4, String field5) {
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            this.fieldOrFuncs.add(field4);
            this.fieldOrFuncs.add(field5);
            return this;
        }

        // SObjectField
        public Grouper add(SObjectField field) {
            this.fieldOrFuncs.add(field);
            return this;
        }

        public Grouper add(SObjectField field1, SObjectField field2) {
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            return this;
        }

        public Grouper add(SObjectField field1, SObjectField field2, SObjectField field3) {
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            return this;
        }

        public Grouper add(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            this.fieldOrFuncs.add(field4);
            return this;
        }

        public Grouper add(
            SObjectField field1,
            SObjectField field2,
            SObjectField field3,
            SObjectField field4,
            SObjectField field5
        ) {
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            this.fieldOrFuncs.add(field4);
            this.fieldOrFuncs.add(field5);
            return this;
        }

        // Function
        public Grouper add(DateFunction func) {
            this.fieldOrFuncs.add(func);
            return this;
        }

        public Grouper add(DateFunction func1, DateFunction func2) {
            this.fieldOrFuncs.add(func1);
            this.fieldOrFuncs.add(func2);
            return this;
        }

        public Grouper add(DateFunction func1, DateFunction func2, DateFunction func3) {
            this.fieldOrFuncs.add(func1);
            this.fieldOrFuncs.add(func2);
            this.fieldOrFuncs.add(func3);
            return this;
        }

        public Grouper add(DateFunction func1, DateFunction func2, DateFunction func3, DateFunction func4) {
            this.fieldOrFuncs.add(func1);
            this.fieldOrFuncs.add(func2);
            this.fieldOrFuncs.add(func3);
            this.fieldOrFuncs.add(func4);
            return this;
        }

        public Grouper add(
            DateFunction func1,
            DateFunction func2,
            DateFunction func3,
            DateFunction func4,
            DateFunction func5
        ) {
            this.fieldOrFuncs.add(func1);
            this.fieldOrFuncs.add(func2);
            this.fieldOrFuncs.add(func3);
            this.fieldOrFuncs.add(func4);
            this.fieldOrFuncs.add(func5);
            return this;
        }

        public Grouper add(List<Object> fieldOrFuncs) {
            this.fieldOrFuncs.addAll(fieldOrFuncs);
            return this;
        }

        public Grouper add(Grouper other) {
            if (other != null) {
                this.fieldOrFuncs.addAll(((GrouperImpl) other).fieldOrFuncs);
            }
            return this;
        }
    }

    public static Grouper grouper() {
        return new GrouperImpl();
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

    private virtual class LogicalExpression implements CompositeFilter {
        private List<Filter> filters { get; set; }
        private String operator { get; set; }
        private Integer tag { get; set; }

        private LogicalExpression(String operator, Integer tag) {
            this.operator = operator;
            this.tag = tag;
            this.filters = new List<Filter>();
        }

        private LogicalExpression(String operator, Integer tag, List<Filter> filters) {
            this.operator = operator;
            this.tag = tag;
            this.filters = filters;
        }

        public CompositeFilter add(Filter filter) {
            this.filters.add(filter);
            return this;
        }

        public virtual void build(List<String> fragments, Map<String, Object> tmpVars) {
            if (this.filters.isEmpty()) {
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
            if (obj == null) {
                return false;
            }

            if (this === obj) {
                return true;
            }

            LogicalExpression that = (LogicalExpression) obj;
            return this.tag == that.tag && this.filters == that.filters;
        }

        public Integer hashCode() {
            Integer hashCode = this.filters == null ? 23 : this.filters.hashCode();
            hashCode = (hashCode * 397) ^ (this.tag);
            return hashCode;
        }
    }

    private abstract class ComparisonExpression implements Filter {
        private Object fieldOrFunc { get; set; }
        private String operator { get; set; }
        private Object value { get; set; }
        private Integer tag { get; set; } // used to distinguish each implementation.

        private ComparisonExpression(Object fieldOrFunc, String operator, Object value) {
            this.fieldOrFunc = fieldOrFunc;
            this.operator = operator;
            this.value = value;
        }

        public virtual void build(List<String> fragments, Map<String, Object> tmpVars) {
            fragments.add(String.valueOf(this.fieldOrFunc));
            fragments.add(this.operator);

            if (this.value == null) {
                fragments.add('NULL');
            } else if (
                this.value instanceof List<Object> ||
                this.value instanceof Datetime ||
                this.value instanceof Date ||
                this.value instanceof Time
            ) {
                String var = 'tmpVar' + (tmpVars.size() + 1);
                tmpVars.put(var, this.value);
                fragments.add(':');
                fragments.add(var);
            } else if (this.value instanceof Id) {
                fragments.add('\'');
                fragments.add(String.valueOf(this.value));
                fragments.add('\'');
            } else if (this.value instanceof String) {
                fragments.add('\'');
                fragments.add(String.escapeSingleQuotes(String.valueOf(this.value)));
                fragments.add('\'');
            } else {
                // i.e. Numbers and Literals
                fragments.add(String.valueOf(this.value));
            }
        }

        public Boolean equals(Object obj) {
            if (obj == null) {
                return false;
            }

            if (this === obj) {
                return true;
            }

            ComparisonExpression that = (ComparisonExpression) obj;

            return (this.tag == that.tag && this.fieldOrFunc == that.fieldOrFunc && this.value == that.value);
        }

        public Integer hashCode() {
            Integer hashCode = this.fieldOrFunc == null ? 23 : this.fieldOrFunc.hashCode();
            hashCode = (hashCode * 397) ^ (this.value == null ? 23 : this.value.hashCode());
            hashCode = (hashCode * 397) ^ (this.tag);
            return hashCode;
        }
    }

    // #endregion
    // ==============

    // ==========================
    // #region Operator - Logical

    private class NotLogicalExpression extends LogicalExpression {
        private NotLogicalExpression(Filter filter) {
            super('NOT', FILTER_NOT_TAG, new List<Filter>{ filter });
        }

        public override void build(List<String> fragments, Map<String, Object> tmpVars) {
            if (this.filters.size() == 0) {
                return;
            }

            Filter filter = this.filters[0];

            fragments.add(this.operator);
            if (filter instanceof CompositeFilter) {
                this.filters[0].build(fragments, tmpVars);
            } else {
                fragments.add('(');
                this.filters[0].build(fragments, tmpVars);
                fragments.add(')');
            }
        }
    }
    // Logical Statement: notx()

    public static Filter notx(Filter filter) {
        return new NotLogicalExpression(filter);
    }

    // Logical Statement: orx()

    public static CompositeFilter orx() {
        return new LogicalExpression(' OR ', FILTER_OR_TAG);
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

    public static CompositeFilter orx(
        Filter filter1,
        Filter filter2,
        Filter filter3,
        Filter filter4,
        Filter filter5,
        Filter filter6,
        Filter filter7,
        Filter filter8
    ) {
        return orx(new List<Filter>{ filter1, filter2, filter3, filter4, filter5, filter6, filter7, filter8 });
    }

    public static CompositeFilter orx(
        Filter filter1,
        Filter filter2,
        Filter filter3,
        Filter filter4,
        Filter filter5,
        Filter filter6,
        Filter filter7,
        Filter filter8,
        Filter filter9
    ) {
        return orx(new List<Filter>{ filter1, filter2, filter3, filter4, filter5, filter6, filter7, filter8, filter9 });
    }

    public static CompositeFilter orx(
        Filter filter1,
        Filter filter2,
        Filter filter3,
        Filter filter4,
        Filter filter5,
        Filter filter6,
        Filter filter7,
        Filter filter8,
        Filter filter9,
        Filter filter10
    ) {
        return orx(
            new List<Filter>{
                filter1,
                filter2,
                filter3,
                filter4,
                filter5,
                filter6,
                filter7,
                filter8,
                filter9,
                filter10
            }
        );
    }

    public static CompositeFilter orx(List<Filter> filters) {
        return new LogicalExpression(' OR ', FILTER_OR_TAG, filters);
    }

    // Logical Statement: andx()

    public static CompositeFilter andx() {
        return new LogicalExpression(' AND ', FILTER_AND_TAG);
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

    public static CompositeFilter andx(
        Filter filter1,
        Filter filter2,
        Filter filter3,
        Filter filter4,
        Filter filter5,
        Filter filter6,
        Filter filter7,
        Filter filter8
    ) {
        return andx(new List<Filter>{ filter1, filter2, filter3, filter4, filter5, filter6, filter7, filter8 });
    }

    public static CompositeFilter andx(
        Filter filter1,
        Filter filter2,
        Filter filter3,
        Filter filter4,
        Filter filter5,
        Filter filter6,
        Filter filter7,
        Filter filter8,
        Filter filter9
    ) {
        return andx(
            new List<Filter>{ filter1, filter2, filter3, filter4, filter5, filter6, filter7, filter8, filter9 }
        );
    }

    public static CompositeFilter andx(
        Filter filter1,
        Filter filter2,
        Filter filter3,
        Filter filter4,
        Filter filter5,
        Filter filter6,
        Filter filter7,
        Filter filter8,
        Filter filter9,
        Filter filter10
    ) {
        return andx(
            new List<Filter>{
                filter1,
                filter2,
                filter3,
                filter4,
                filter5,
                filter6,
                filter7,
                filter8,
                filter9,
                filter10
            }
        );
    }

    public static CompositeFilter andx(List<Filter> filters) {
        return new LogicalExpression(' AND ', FILTER_AND_TAG, filters);
    }
    // #endregion
    // ==========================

    // ========================
    // #region Operator - =, !=
    private class EQ extends ComparisonExpression {
        private EQ(Object fieldOrFunc, Object value) {
            super(fieldOrFunc, ' = ', value);
            this.tag = FILTER_EQ_TAG;
        }
    }

    private class NE extends ComparisonExpression {
        private NE(Object fieldOrFunc, Object value) {
            super(fieldOrFunc, ' != ', value);
            this.tag = FILTER_NE_TAG;
        }
    }

    // Comparison - EQ
    // Comparison - EQ - String

    public static Filter eq(String field, String value) {
        return new EQ(field, value);
    }
    public static Filter eq(String field, Id value) {
        return new EQ(field, value);
    }
    public static Filter eq(String field, Boolean value) {
        return new EQ(field, value);
    }
    public static Filter eq(String field, Decimal value) {
        return new EQ(field, value);
    }
    public static Filter eq(String field, Datetime value) {
        return new EQ(field, value);
    }
    public static Filter eq(String field, Date value) {
        return new EQ(field, value);
    }
    public static Filter eq(String field, Time value) {
        return new EQ(field, value);
    }
    public static Filter eq(String field, DateLiteral value) {
        return new EQ(field, value);
    }
    public static Filter eq(String field, CurrencyLiteral value) {
        return new EQ(field, value);
    }
    public static Filter eqNull(String field) {
        return new EQ(field, null);
    }

    // Comparison - EQ - SObjectField
    public static Filter eq(SObjectField field, String value) {
        return new EQ(field, value);
    }
    public static Filter eq(SObjectField field, Id value) {
        return new EQ(field, value);
    }
    public static Filter eq(SObjectField field, Boolean value) {
        return new EQ(field, value);
    }
    public static Filter eq(SObjectField field, Decimal value) {
        return new EQ(field, value);
    }
    public static Filter eq(SObjectField field, Datetime value) {
        return new EQ(field, value);
    }
    public static Filter eq(SObjectField field, Date value) {
        return new EQ(field, value);
    }
    public static Filter eq(SObjectField field, Time value) {
        return new EQ(field, value);
    }
    public static Filter eq(SObjectField field, DateLiteral value) {
        return new EQ(field, value);
    }
    public static Filter eq(SObjectField field, CurrencyLiteral value) {
        return new EQ(field, value);
    }
    public static Filter eqNull(SObjectField field) {
        return new EQ(field, null);
    }

    // Comparison - EQ - AggregateFunction
    public static Filter eq(AggregateFunction func, String value) {
        return new EQ(func, value);
    }
    public static Filter eq(AggregateFunction func, Id value) {
        return new EQ(func, value);
    }
    public static Filter eq(AggregateFunction func, Boolean value) {
        return new EQ(func, value);
    }
    public static Filter eq(AggregateFunction func, Decimal value) {
        return new EQ(func, value);
    }
    public static Filter eq(AggregateFunction func, Datetime value) {
        return new EQ(func, value);
    }
    public static Filter eq(AggregateFunction func, Date value) {
        return new EQ(func, value);
    }
    public static Filter eq(AggregateFunction func, Time value) {
        return new EQ(func, value);
    }
    public static Filter eq(AggregateFunction func, DateLiteral value) {
        return new EQ(func, value);
    }
    public static Filter eq(AggregateFunction func, CurrencyLiteral value) {
        return new EQ(func, value);
    }
    public static Filter eqNull(AggregateFunction func) {
        return new EQ(func, null);
    }

    // Comparison - EQ - Others
    public static Filter eq(DistanceFunction field, Decimal value) {
        return new EQ(field, value);
    }

    public static Filter eq(DateFunction func, Integer value) {
        return new EQ(func, value);
    }

    public static Filter eq(ToLabelFunction func, String value) {
        return new EQ(func, value);
    }

    // Comparison - NE
    // Comparison - NE - String

    public static Filter ne(String field, String value) {
        return new NE(field, value);
    }
    public static Filter ne(String field, Id value) {
        return new NE(field, value);
    }
    public static Filter ne(String field, Boolean value) {
        return new NE(field, value);
    }
    public static Filter ne(String field, Decimal value) {
        return new NE(field, value);
    }
    public static Filter ne(String field, Datetime value) {
        return new NE(field, value);
    }
    public static Filter ne(String field, Date value) {
        return new NE(field, value);
    }
    public static Filter ne(String field, Time value) {
        return new NE(field, value);
    }
    public static Filter ne(String field, DateLiteral value) {
        return new NE(field, value);
    }
    public static Filter ne(String field, CurrencyLiteral value) {
        return new NE(field, value);
    }
    public static Filter neNull(String field) {
        return new NE(field, null);
    }

    // Comparison - EQ - SObjectField
    public static Filter ne(SObjectField field, String value) {
        return new NE(field, value);
    }
    public static Filter ne(SObjectField field, Id value) {
        return new NE(field, value);
    }
    public static Filter ne(SObjectField field, Boolean value) {
        return new NE(field, value);
    }
    public static Filter ne(SObjectField field, Decimal value) {
        return new NE(field, value);
    }
    public static Filter ne(SObjectField field, Datetime value) {
        return new NE(field, value);
    }
    public static Filter ne(SObjectField field, Date value) {
        return new NE(field, value);
    }
    public static Filter ne(SObjectField field, Time value) {
        return new NE(field, value);
    }
    public static Filter ne(SObjectField field, DateLiteral value) {
        return new NE(field, value);
    }
    public static Filter ne(SObjectField field, CurrencyLiteral value) {
        return new NE(field, value);
    }
    public static Filter neNull(SObjectField field) {
        return new NE(field, null);
    }

    // Comparison - EQ - AggregateFunction
    public static Filter ne(AggregateFunction func, String value) {
        return new NE(func, value);
    }
    public static Filter ne(AggregateFunction func, Id value) {
        return new NE(func, value);
    }
    public static Filter ne(AggregateFunction func, Boolean value) {
        return new NE(func, value);
    }
    public static Filter ne(AggregateFunction func, Decimal value) {
        return new NE(func, value);
    }
    public static Filter ne(AggregateFunction func, Datetime value) {
        return new NE(func, value);
    }
    public static Filter ne(AggregateFunction func, Date value) {
        return new NE(func, value);
    }
    public static Filter ne(AggregateFunction func, Time value) {
        return new NE(func, value);
    }
    public static Filter ne(AggregateFunction func, DateLiteral value) {
        return new NE(func, value);
    }
    public static Filter ne(AggregateFunction func, CurrencyLiteral value) {
        return new NE(func, value);
    }
    public static Filter neNull(AggregateFunction func) {
        return new NE(func, null);
    }

    // Comparison - EQ - Others
    public static Filter ne(DistanceFunction field, Decimal value) {
        return new NE(field, value);
    }

    public static Filter ne(DateFunction func, Integer value) {
        return new NE(func, value);
    }

    public static Filter ne(ToLabelFunction func, String value) {
        return new NE(func, value);
    }

    // #endregion
    // ========================

    // ====================
    // #region Operator - >
    private class GT extends ComparisonExpression {
        private GT(Object fieldOrFunc, Object value) {
            super(fieldOrFunc, ' > ', value);
            this.tag = FILTER_GT_TAG;
        }
    }

    // Comparison - GT - String
    public static Filter gt(String field, String value) {
        return new GT(field, value);
    }
    public static Filter gt(String field, Id value) {
        return new GT(field, value);
    }
    public static Filter gt(String field, Decimal value) {
        return new GT(field, value);
    }
    public static Filter gt(String field, Datetime value) {
        return new GT(field, value);
    }
    public static Filter gt(String field, Date value) {
        return new GT(field, value);
    }
    public static Filter gt(String field, Time value) {
        return new GT(field, value);
    }
    public static Filter gt(String field, DateLiteral value) {
        return new GT(field, value);
    }
    public static Filter gt(String field, CurrencyLiteral value) {
        return new GT(field, value);
    }

    // Comparison - GT - SObjectField
    public static Filter gt(SObjectField field, String value) {
        return new GT(field, value);
    }
    public static Filter gt(SObjectField field, Id value) {
        return new GT(field, value);
    }
    public static Filter gt(SObjectField field, Decimal value) {
        return new GT(field, value);
    }
    public static Filter gt(SObjectField field, Datetime value) {
        return new GT(field, value);
    }
    public static Filter gt(SObjectField field, Date value) {
        return new GT(field, value);
    }
    public static Filter gt(SObjectField field, Time value) {
        return new GT(field, value);
    }
    public static Filter gt(SObjectField field, DateLiteral value) {
        return new GT(field, value);
    }
    public static Filter gt(SObjectField field, CurrencyLiteral value) {
        return new GT(field, value);
    }

    // Comparison - GT - AggregateFunction
    public static Filter gt(AggregateFunction func, String value) {
        return new GT(func, value);
    }
    public static Filter gt(AggregateFunction func, Id value) {
        return new GT(func, value);
    }
    public static Filter gt(AggregateFunction func, Decimal value) {
        return new GT(func, value);
    }
    public static Filter gt(AggregateFunction func, Datetime value) {
        return new GT(func, value);
    }
    public static Filter gt(AggregateFunction func, Date value) {
        return new GT(func, value);
    }
    public static Filter gt(AggregateFunction func, Time value) {
        return new GT(func, value);
    }
    public static Filter gt(AggregateFunction func, DateLiteral value) {
        return new GT(func, value);
    }
    public static Filter gt(AggregateFunction func, CurrencyLiteral value) {
        return new GT(func, value);
    }

    // Comparison - GT - Others
    public static Filter gt(DistanceFunction func, Decimal value) {
        return new GT(func, value);
    }

    public static Filter gt(DateFunction func, Integer value) {
        return new GT(func, value);
    }

    public static Filter gt(ToLabelFunction func, String value) {
        return new GT(func, value);
    }

    // #endregion
    // ====================

    // =====================
    // #region Operator - >=
    private class GTE extends ComparisonExpression {
        private GTE(Object fieldOrFunc, Object value) {
            super(fieldOrFunc, ' >= ', value);
            this.tag = FILTER_GTE_TAG;
        }
    }

    // Comparison - GTE - String
    public static Filter gte(String field, String value) {
        return new GTE(field, value);
    }
    public static Filter gte(String field, Id value) {
        return new GTE(field, value);
    }
    public static Filter gte(String field, Decimal value) {
        return new GTE(field, value);
    }
    public static Filter gte(String field, Datetime value) {
        return new GTE(field, value);
    }
    public static Filter gte(String field, Date value) {
        return new GTE(field, value);
    }
    public static Filter gte(String field, Time value) {
        return new GTE(field, value);
    }
    public static Filter gte(String field, DateLiteral value) {
        return new GTE(field, value);
    }
    public static Filter gte(String field, CurrencyLiteral value) {
        return new GTE(field, value);
    }

    // Comparison - GTE - SObjectField
    public static Filter gte(SObjectField field, String value) {
        return new GTE(field, value);
    }
    public static Filter gte(SObjectField field, Id value) {
        return new GTE(field, value);
    }
    public static Filter gte(SObjectField field, Decimal value) {
        return new GTE(field, value);
    }
    public static Filter gte(SObjectField field, Datetime value) {
        return new GTE(field, value);
    }
    public static Filter gte(SObjectField field, Date value) {
        return new GTE(field, value);
    }
    public static Filter gte(SObjectField field, Time value) {
        return new GTE(field, value);
    }
    public static Filter gte(SObjectField field, DateLiteral value) {
        return new GTE(field, value);
    }
    public static Filter gte(SObjectField field, CurrencyLiteral value) {
        return new GTE(field, value);
    }

    // Comparison - GTE - AggregateFunction
    public static Filter gte(AggregateFunction func, String value) {
        return new GTE(func, value);
    }
    public static Filter gte(AggregateFunction func, Id value) {
        return new GTE(func, value);
    }
    public static Filter gte(AggregateFunction func, Decimal value) {
        return new GTE(func, value);
    }
    public static Filter gte(AggregateFunction func, Datetime value) {
        return new GTE(func, value);
    }
    public static Filter gte(AggregateFunction func, Date value) {
        return new GTE(func, value);
    }
    public static Filter gte(AggregateFunction func, Time value) {
        return new GTE(func, value);
    }
    public static Filter gte(AggregateFunction func, DateLiteral value) {
        return new GTE(func, value);
    }
    public static Filter gte(AggregateFunction func, CurrencyLiteral value) {
        return new GTE(func, value);
    }

    // Comparison - GTE - Others
    public static Filter gte(DistanceFunction func, Decimal value) {
        return new GTE(func, value);
    }

    public static Filter gte(DateFunction func, Integer value) {
        return new GTE(func, value);
    }

    public static Filter gte(ToLabelFunction func, String value) {
        return new GTE(func, value);
    }
    // #endregion
    // =====================

    // ====================
    // #region Operator - <
    private class LT extends ComparisonExpression {
        private LT(Object fieldOrFunc, Object value) {
            super(fieldOrFunc, ' < ', value);
            this.tag = FILTER_LT_TAG;
        }
    }

    // Comparison - LT - String
    public static Filter lt(String field, String value) {
        return new LT(field, value);
    }
    public static Filter lt(String field, Id value) {
        return new LT(field, value);
    }
    public static Filter lt(String field, Decimal value) {
        return new LT(field, value);
    }
    public static Filter lt(String field, Datetime value) {
        return new LT(field, value);
    }
    public static Filter lt(String field, Date value) {
        return new LT(field, value);
    }
    public static Filter lt(String field, Time value) {
        return new LT(field, value);
    }
    public static Filter lt(String field, DateLiteral value) {
        return new LT(field, value);
    }
    public static Filter lt(String field, CurrencyLiteral value) {
        return new LT(field, value);
    }

    // Comparison - LT - SObjectField
    public static Filter lt(SObjectField field, String value) {
        return new LT(field, value);
    }
    public static Filter lt(SObjectField field, Id value) {
        return new LT(field, value);
    }
    public static Filter lt(SObjectField field, Decimal value) {
        return new LT(field, value);
    }
    public static Filter lt(SObjectField field, Datetime value) {
        return new LT(field, value);
    }
    public static Filter lt(SObjectField field, Date value) {
        return new LT(field, value);
    }
    public static Filter lt(SObjectField field, Time value) {
        return new LT(field, value);
    }
    public static Filter lt(SObjectField field, DateLiteral value) {
        return new LT(field, value);
    }
    public static Filter lt(SObjectField field, CurrencyLiteral value) {
        return new LT(field, value);
    }

    // Comparison - LT - AggregateFunction
    public static Filter lt(AggregateFunction func, String value) {
        return new LT(func, value);
    }
    public static Filter lt(AggregateFunction func, Id value) {
        return new LT(func, value);
    }
    public static Filter lt(AggregateFunction func, Decimal value) {
        return new LT(func, value);
    }
    public static Filter lt(AggregateFunction func, Datetime value) {
        return new LT(func, value);
    }
    public static Filter lt(AggregateFunction func, Date value) {
        return new LT(func, value);
    }
    public static Filter lt(AggregateFunction func, Time value) {
        return new LT(func, value);
    }
    public static Filter lt(AggregateFunction func, DateLiteral value) {
        return new LT(func, value);
    }
    public static Filter lt(AggregateFunction func, CurrencyLiteral value) {
        return new LT(func, value);
    }

    // Comparison - LT - Others
    public static Filter lt(DistanceFunction func, Decimal value) {
        return new LT(func, value);
    }

    public static Filter lt(DateFunction func, Integer value) {
        return new LT(func, value);
    }

    public static Filter lt(ToLabelFunction func, String value) {
        return new LT(func, value);
    }
    // #endregion
    // ====================

    // =====================
    // #region Operator - <=
    private class LTE extends ComparisonExpression {
        private LTE(Object fieldOrFunc, Object value) {
            super(fieldOrFunc, ' <= ', value);
            this.tag = FILTER_LTE_TAG;
        }
    }

    // Comparison - LTE - String
    public static Filter lte(String field, String value) {
        return new LTE(field, value);
    }
    public static Filter lte(String field, Id value) {
        return new LTE(field, value);
    }
    public static Filter lte(String field, Decimal value) {
        return new LTE(field, value);
    }
    public static Filter lte(String field, Datetime value) {
        return new LTE(field, value);
    }
    public static Filter lte(String field, Date value) {
        return new LTE(field, value);
    }
    public static Filter lte(String field, Time value) {
        return new LTE(field, value);
    }
    public static Filter lte(String field, DateLiteral value) {
        return new LTE(field, value);
    }
    public static Filter lte(String field, CurrencyLiteral value) {
        return new LTE(field, value);
    }

    // Comparison - LTE - SObjectField
    public static Filter lte(SObjectField field, String value) {
        return new LTE(field, value);
    }
    public static Filter lte(SObjectField field, Id value) {
        return new LTE(field, value);
    }
    public static Filter lte(SObjectField field, Decimal value) {
        return new LTE(field, value);
    }
    public static Filter lte(SObjectField field, Datetime value) {
        return new LTE(field, value);
    }
    public static Filter lte(SObjectField field, Date value) {
        return new LTE(field, value);
    }
    public static Filter lte(SObjectField field, Time value) {
        return new LTE(field, value);
    }
    public static Filter lte(SObjectField field, DateLiteral value) {
        return new LTE(field, value);
    }
    public static Filter lte(SObjectField field, CurrencyLiteral value) {
        return new LTE(field, value);
    }

    // Comparison - LTE - AggregateFunction
    public static Filter lte(AggregateFunction func, String value) {
        return new LTE(func, value);
    }
    public static Filter lte(AggregateFunction func, Id value) {
        return new LTE(func, value);
    }
    public static Filter lte(AggregateFunction func, Decimal value) {
        return new LTE(func, value);
    }
    public static Filter lte(AggregateFunction func, Datetime value) {
        return new LTE(func, value);
    }
    public static Filter lte(AggregateFunction func, Date value) {
        return new LTE(func, value);
    }
    public static Filter lte(AggregateFunction func, Time value) {
        return new LTE(func, value);
    }
    public static Filter lte(AggregateFunction func, DateLiteral value) {
        return new LTE(func, value);
    }
    public static Filter lte(AggregateFunction func, CurrencyLiteral value) {
        return new LTE(func, value);
    }

    // Comparison - LTE - Others
    public static Filter lte(DistanceFunction func, Decimal value) {
        return new LTE(func, value);
    }

    public static Filter lte(DateFunction func, Integer value) {
        return new LTE(func, value);
    }

    public static Filter lte(ToLabelFunction func, String value) {
        return new LTE(func, value);
    }
    // #endregion
    // =====================

    // ==========================
    // #region Operator - between
    // Comparison - Between - String
    public static Filter between(String field, String minValue, String maxValue) {
        return andx(gte(field, minValue), lte(field, maxValue));
    }
    public static Filter between(String field, Id minValue, Id maxValue) {
        return andx(gte(field, minValue), lte(field, maxValue));
    }
    public static Filter between(String field, Decimal minValue, Decimal maxValue) {
        return andx(gte(field, minValue), lte(field, maxValue));
    }
    public static Filter between(String field, Datetime minValue, Datetime maxValue) {
        return andx(gte(field, minValue), lte(field, maxValue));
    }
    public static Filter between(String field, Date minValue, Date maxValue) {
        return andx(gte(field, minValue), lte(field, maxValue));
    }
    public static Filter between(String field, Time minValue, Time maxValue) {
        return andx(gte(field, minValue), lte(field, maxValue));
    }
    public static Filter between(String field, DateLiteral minValue, DateLiteral maxValue) {
        return andx(gte(field, minValue), lte(field, maxValue));
    }
    public static Filter between(String field, CurrencyLiteral minValue, CurrencyLiteral maxValue) {
        return andx(gte(field, minValue), lte(field, maxValue));
    }

    // Comparison - Between - SObjectField
    public static Filter between(SObjectField field, String minValue, String maxValue) {
        return andx(gte(field, minValue), lte(field, maxValue));
    }
    public static Filter between(SObjectField field, Id minValue, Id maxValue) {
        return andx(gte(field, minValue), lte(field, maxValue));
    }
    public static Filter between(SObjectField field, Decimal minValue, Decimal maxValue) {
        return andx(gte(field, minValue), lte(field, maxValue));
    }
    public static Filter between(SObjectField field, Datetime minValue, Datetime maxValue) {
        return andx(gte(field, minValue), lte(field, maxValue));
    }
    public static Filter between(SObjectField field, Date minValue, Date maxValue) {
        return andx(gte(field, minValue), lte(field, maxValue));
    }
    public static Filter between(SObjectField field, Time minValue, Time maxValue) {
        return andx(gte(field, minValue), lte(field, maxValue));
    }
    public static Filter between(SObjectField field, DateLiteral minValue, DateLiteral maxValue) {
        return andx(gte(field, minValue), lte(field, maxValue));
    }
    public static Filter between(SObjectField field, CurrencyLiteral minValue, CurrencyLiteral maxValue) {
        return andx(gte(field, minValue), lte(field, maxValue));
    }

    // Comparison - Between - AggregateFunction
    public static Filter between(AggregateFunction func, String minValue, String maxValue) {
        return andx(gte(func, minValue), lte(func, maxValue));
    }
    public static Filter between(AggregateFunction func, Id minValue, Id maxValue) {
        return andx(gte(func, minValue), lte(func, maxValue));
    }
    public static Filter between(AggregateFunction func, Decimal minValue, Decimal maxValue) {
        return andx(gte(func, minValue), lte(func, maxValue));
    }
    public static Filter between(AggregateFunction func, Datetime minValue, Datetime maxValue) {
        return andx(gte(func, minValue), lte(func, maxValue));
    }
    public static Filter between(AggregateFunction func, Date minValue, Date maxValue) {
        return andx(gte(func, minValue), lte(func, maxValue));
    }
    public static Filter between(AggregateFunction func, Time minValue, Time maxValue) {
        return andx(gte(func, minValue), lte(func, maxValue));
    }
    public static Filter between(AggregateFunction func, DateLiteral minValue, DateLiteral maxValue) {
        return andx(gte(func, minValue), lte(func, maxValue));
    }
    public static Filter between(AggregateFunction func, CurrencyLiteral minValue, CurrencyLiteral maxValue) {
        return andx(gte(func, minValue), lte(func, maxValue));
    }

    // Comparison - Between - Others
    public static Filter between(DistanceFunction func, Decimal minValue, Decimal maxValue) {
        return andx(gte(func, minValue), lte(func, maxValue));
    }

    public static Filter between(DateFunction func, Integer minValue, Integer maxValue) {
        return andx(gte(func, minValue), lte(func, maxValue));
    }

    public static Filter between(ToLabelFunction func, String minValue, String maxValue) {
        return andx(gte(func, minValue), lte(func, maxValue));
    }
    // #endregion
    // ==========================

    // =======================
    // #region Operator - like
    private class LikeX extends ComparisonExpression {
        private LikeX(Object fieldOrFunc, String value) {
            super(fieldOrFunc, ' LIKE ', value);
            this.tag = FILTER_LIKEX_TAG;
        }
    }

    private class NLike extends ComparisonExpression {
        private NLike(Object fieldOrFunc, String value) {
            super(fieldOrFunc, ' LIKE ', value);
            this.tag = FILTER_NLIKE_TAG;
        }

        public override void build(List<String> fragments, Map<String, Object> tmpVars) {
            fragments.add('(NOT ');
            super.build(fragments, tmpVars);
            fragments.add(')');
        }
    }

    public static Filter likex(String field, String value) {
        return new LikeX(field, value);
    }
    public static Filter likex(SObjectField field, String value) {
        return new LikeX(field, value);
    }
    public static Filter likex(AggregateFunction func, String value) {
        return new LikeX(func, value);
    }
    public static Filter likex(ToLabelFunction func, String value) {
        return new LikeX(func, value);
    }

    public static Filter nlike(String field, String value) {
        return new NLike(field, value);
    }
    public static Filter nlike(SObjectField field, String value) {
        return new NLike(field, value);
    }
    public static Filter nlike(AggregateFunction func, String value) {
        return new NLike(func, value);
    }
    public static Filter nlike(ToLabelFunction func, String value) {
        return new NLike(func, value);
    }
    // #endregion
    // =======================

    // ===============================================
    // #region Operator - includes, excludes, inx, nin
    private virtual class MultiComparisonExpression extends ComparisonExpression {
        private MultiComparisonExpression(Object field, String operator, Object value) {
            super(field, operator, value);
        }

        public override void build(List<String> fragments, Map<String, Object> tmpVars) {
            fragments.add(String.valueOf(this.fieldOrFunc));
            fragments.add(this.operator);
            fragments.add('(');
            Boolean isFirst = true;
            for (string value : (List<String>) this.value) {
                if (isFirst) {
                    isFirst = false;
                } else {
                    fragments.add(', ');
                }

                String var = 'tmpVar' + (tmpVars.size() + 1);
                tmpVars.put(var, value);
                fragments.add(':');
                fragments.add(var);
            }
            fragments.add(')');
        }
    }

    private class Includes extends MultiComparisonExpression {
        private Includes(Object field, List<String> values) {
            super(field, ' INCLUDES ', values);
            this.tag = FILTER_INCLUDES_TAG;
        }
    }

    private class Excludes extends MultiComparisonExpression {
        private Excludes(Object field, List<String> values) {
            super(field, ' EXCLUDES ', values);
            this.tag = FILTER_EXCLUDES_TAG;
        }
    }

    public static Filter includes(String field, List<String> values) {
        return new Includes(field, values);
    }

    public static Filter includes(SObjectField field, List<String> values) {
        return new Includes(field, values);
    }

    public static Filter excludes(String field, List<String> values) {
        return new Excludes(field, values);
    }

    public static Filter excludes(SObjectField field, List<String> values) {
        return new Excludes(field, values);
    }

    private class INX extends ComparisonExpression {
        private INX(Object fieldOrFunc, List<Object> values) {
            super(fieldOrFunc, ' IN ', values);
            this.tag = FILTER_INX_TAG;
        }
    }

    private class NIN extends ComparisonExpression {
        private NIN(Object fieldOrFunc, List<Object> values) {
            super(fieldOrFunc, ' NOT IN ', values);
            this.tag = FILTER_NIN_TAG;
        }
    }

    private virtual class INX_Query extends ComparisonExpression {
        private INX_Query(Object field, Boolean isNot, Query query) {
            super(field, isNot ? ' NOT IN ' : ' IN ', query);
            this.tag = FILTER_INX_Query_TAG;
        }

        public override void build(List<String> fragments, Map<String, Object> tmpVars) {
            if (this.value instanceof QueryImpl) {
                fragments.add(String.valueOf(this.fieldOrFunc));
                fragments.add(this.operator);
                fragments.add('(');
                ((QueryImpl) this.value).buildSoql(fragments, tmpVars);
                fragments.add(')');
            }
        }
    }

    // Comparison - INX
    // Comparison - INX - String
    public static Filter inx(String field, List<String> values) {
        return new INX(field, values);
    }
    public static Filter inx(String field, List<Id> values) {
        return new INX(field, values);
    }
    public static Filter inx(String field, List<SObject> values) {
        return new INX(field, values);
    }
    public static Filter inx(String field, List<Boolean> values) {
        return new INX(field, values);
    }
    public static Filter inx(String field, List<Decimal> values) {
        return new INX(field, values);
    }
    public static Filter inx(String field, List<Datetime> values) {
        return new INX(field, values);
    }
    public static Filter inx(String field, List<Date> values) {
        return new INX(field, values);
    }
    public static Filter inx(String field, List<Time> values) {
        return new INX(field, values);
    }
    public static Filter inx(String field, List<DateLiteral> values) {
        return new INX(field, values);
    }
    public static Filter inx(String field, List<CurrencyLiteral> values) {
        return new INX(field, values);
    }
    public static Filter inx(String field, Query query) {
        return new INX_Query(field, false, query);
    }

    // Comparison - INX - SObjectField
    public static Filter inx(SObjectField field, List<String> values) {
        return new INX(field, values);
    }
    public static Filter inx(SObjectField field, List<Id> values) {
        return new INX(field, values);
    }
    public static Filter inx(SObjectField field, List<SObject> values) {
        return new INX(field, values);
    }
    public static Filter inx(SObjectField field, List<Boolean> values) {
        return new INX(field, values);
    }
    public static Filter inx(SObjectField field, List<Decimal> values) {
        return new INX(field, values);
    }
    public static Filter inx(SObjectField field, List<Datetime> values) {
        return new INX(field, values);
    }
    public static Filter inx(SObjectField field, List<Date> values) {
        return new INX(field, values);
    }
    public static Filter inx(SObjectField field, List<Time> values) {
        return new INX(field, values);
    }
    public static Filter inx(SObjectField field, List<DateLiteral> values) {
        return new INX(field, values);
    }
    public static Filter inx(SObjectField field, List<CurrencyLiteral> values) {
        return new INX(field, values);
    }
    public static Filter inx(SObjectField field, Query query) {
        return new INX_Query(field, false, query);
    }

    // Comparison - INX - AggregateFunction
    public static Filter inx(AggregateFunction field, List<String> values) {
        return new INX(field, values);
    }
    public static Filter inx(AggregateFunction field, List<Id> values) {
        return new INX(field, values);
    }
    public static Filter inx(AggregateFunction field, List<SObject> values) {
        return new INX(field, values);
    }
    public static Filter inx(AggregateFunction field, List<Boolean> values) {
        return new INX(field, values);
    }
    public static Filter inx(AggregateFunction field, List<Decimal> values) {
        return new INX(field, values);
    }
    public static Filter inx(AggregateFunction field, List<Datetime> values) {
        return new INX(field, values);
    }
    public static Filter inx(AggregateFunction field, List<Date> values) {
        return new INX(field, values);
    }
    public static Filter inx(AggregateFunction field, List<Time> values) {
        return new INX(field, values);
    }
    public static Filter inx(AggregateFunction field, List<DateLiteral> values) {
        return new INX(field, values);
    }
    public static Filter inx(AggregateFunction field, List<CurrencyLiteral> values) {
        return new INX(field, values);
    }

    // Comparison - INX - Others
    public static Filter inx(DistanceFunction func, List<Decimal> values) {
        return new INX(func, values);
    }

    public static Filter inx(DateFunction func, List<Integer> values) {
        return new INX(func, values);
    }

    // Comparison - NIN
    // Comparison - NIN - String
    public static Filter nin(String field, List<String> values) {
        return new NIN(field, values);
    }
    public static Filter nin(String field, List<Id> values) {
        return new NIN(field, values);
    }
    public static Filter nin(String field, List<SObject> values) {
        return new NIN(field, values);
    }
    public static Filter nin(String field, List<Boolean> values) {
        return new NIN(field, values);
    }
    public static Filter nin(String field, List<Decimal> values) {
        return new NIN(field, values);
    }
    public static Filter nin(String field, List<Datetime> values) {
        return new NIN(field, values);
    }
    public static Filter nin(String field, List<Date> values) {
        return new NIN(field, values);
    }
    public static Filter nin(String field, List<Time> values) {
        return new NIN(field, values);
    }
    public static Filter nin(String field, List<DateLiteral> values) {
        return new NIN(field, values);
    }
    public static Filter nin(String field, List<CurrencyLiteral> values) {
        return new NIN(field, values);
    }
    public static Filter nin(String field, Query query) {
        return new INX_Query(field, true, query);
    }

    // Comparison - NIN - SObjectField
    public static Filter nin(SObjectField field, List<String> values) {
        return new NIN(field, values);
    }
    public static Filter nin(SObjectField field, List<Id> values) {
        return new NIN(field, values);
    }
    public static Filter nin(SObjectField field, List<SObject> values) {
        return new NIN(field, values);
    }
    public static Filter nin(SObjectField field, List<Boolean> values) {
        return new NIN(field, values);
    }
    public static Filter nin(SObjectField field, List<Decimal> values) {
        return new NIN(field, values);
    }
    public static Filter nin(SObjectField field, List<Datetime> values) {
        return new NIN(field, values);
    }
    public static Filter nin(SObjectField field, List<Date> values) {
        return new NIN(field, values);
    }
    public static Filter nin(SObjectField field, List<Time> values) {
        return new NIN(field, values);
    }
    public static Filter nin(SObjectField field, List<DateLiteral> values) {
        return new NIN(field, values);
    }
    public static Filter nin(SObjectField field, List<CurrencyLiteral> values) {
        return new NIN(field, values);
    }
    public static Filter nin(SObjectField field, Query query) {
        return new INX_Query(field, true, query);
    }

    // Comparison - NIN - AggregateFunction
    public static Filter nin(AggregateFunction func, List<String> values) {
        return new NIN(func, values);
    }
    public static Filter nin(AggregateFunction func, List<Id> values) {
        return new NIN(func, values);
    }
    public static Filter nin(AggregateFunction func, List<SObject> values) {
        return new NIN(func, values);
    }
    public static Filter nin(AggregateFunction func, List<Boolean> values) {
        return new NIN(func, values);
    }
    public static Filter nin(AggregateFunction func, List<Decimal> values) {
        return new NIN(func, values);
    }
    public static Filter nin(AggregateFunction func, List<Datetime> values) {
        return new NIN(func, values);
    }
    public static Filter nin(AggregateFunction func, List<Date> values) {
        return new NIN(func, values);
    }
    public static Filter nin(AggregateFunction func, List<Time> values) {
        return new NIN(func, values);
    }
    public static Filter nin(AggregateFunction func, List<DateLiteral> values) {
        return new NIN(func, values);
    }
    public static Filter nin(AggregateFunction func, List<CurrencyLiteral> values) {
        return new NIN(func, values);
    }

    // Comparison - NIN - Others
    public static Filter nin(DistanceFunction func, List<Decimal> values) {
        return new NIN(func, values);
    }

    public static Filter nin(DateFunction func, List<Integer> values) {
        return new NIN(func, values);
    }

    // #endregion
    // ===============================================

    // ================
    // #region Function

    public interface Function {
    }

    public interface SelectFunction extends Function {
    }

    public interface OrderFunction extends Function {
    }

    public virtual class GenericFunction implements Function {
        private Object fieldOrFunc { get; set; }
        private String name { get; set; }
        private Integer tag { get; set; }
        private String alias { get; set; }

        private GenericFunction(Object fieldOrFunc, String name, Integer tag) {
            this.fieldOrFunc = fieldOrFunc;
            this.name = name;
            this.tag = tag;
        }

        private GenericFunction(Object fieldOrFunc, String name, Integer tag, String alias) {
            this.fieldOrFunc = fieldOrFunc;
            this.name = name;
            this.tag = tag;
            this.alias = alias;
        }

        public override String toString() {
            if (this.alias == null && this.fieldOrFunc == null) {
                return this.name + '()';
            } else if (this.alias == null) {
                return this.name + '(' + this.fieldOrFunc + ')';
            } else {
                return String.format('{0}({1}) {2}', new List<Object>{ this.name, this.fieldOrFunc, this.alias });
            }
        }

        public Boolean equals(Object obj) {
            if (obj == null) {
                return false;
            }

            if (this === obj) {
                return true;
            }

            GenericFunction that = (GenericFunction) obj;
            return this.tag == that.tag && this.fieldOrFunc == that.fieldOrFunc;
        }

        public Integer hashCode() {
            Integer hashCode = this.fieldOrFunc == null ? 23 : this.fieldOrFunc.hashCode();
            hashCode = (hashCode * 397) ^ (this.tag);
            return hashCode;
        }
    }

    // #endregion
    // ================

    // ============================
    // #region Function - Aggregate
    public class AggregateFunction extends GenericFunction implements SelectFunction, OrderFunction {
        private AggregateFunction(Object field, String name, Integer tag, String alias) {
            super(field, name, tag, alias);
        }
    }

    // SObjectField
    public static AggregateFunction GROUPING(String field) {
        return new AggregateFunction(field, 'GROUPING', FUNC_GROUPING_TAG, null);
    }

    public static AggregateFunction GROUPING(String field, String alias) {
        return new AggregateFunction(field, 'GROUPING', FUNC_GROUPING_TAG, alias);
    }

    public static AggregateFunction COUNT(String field) {
        return new AggregateFunction(field, 'COUNT', FUNC_COUNT_TAG, null);
    }

    public static AggregateFunction COUNT(String field, String alias) {
        return new AggregateFunction(field, 'COUNT', FUNC_COUNT_TAG, alias);
    }

    public static AggregateFunction COUNT_DISTINCT(String field) {
        return new AggregateFunction(field, 'COUNT_DISTINCT', FUNC_COUNT_DISTINCT_TAG, null);
    }

    public static AggregateFunction COUNT_DISTINCT(String field, String alias) {
        return new AggregateFunction(field, 'COUNT_DISTINCT', FUNC_COUNT_DISTINCT_TAG, alias);
    }

    public static AggregateFunction SUM(String field) {
        return new AggregateFunction(field, 'SUM', FUNC_SUM_TAG, null);
    }

    public static AggregateFunction SUM(String field, String alias) {
        return new AggregateFunction(field, 'SUM', FUNC_SUM_TAG, alias);
    }

    public static AggregateFunction AVG(String field) {
        return new AggregateFunction(field, 'AVG', FUNC_AVG_TAG, null);
    }

    public static AggregateFunction AVG(String field, String alias) {
        return new AggregateFunction(field, 'AVG', FUNC_AVG_TAG, alias);
    }

    public static AggregateFunction MAX(String field) {
        return new AggregateFunction(field, 'MAX', FUNC_MAX_TAG, null);
    }

    public static AggregateFunction MAX(String field, String alias) {
        return new AggregateFunction(field, 'MAX', FUNC_MAX_TAG, alias);
    }

    public static AggregateFunction MIN(String field) {
        return new AggregateFunction(field, 'MIN', FUNC_MIN_TAG, null);
    }

    public static AggregateFunction MIN(String field, String alias) {
        return new AggregateFunction(field, 'MIN', FUNC_MIN_TAG, alias);
    }

    // SObjectField
    public static AggregateFunction GROUPING(SObjectField field) {
        return new AggregateFunction(field, 'GROUPING', FUNC_GROUPING_TAG, null);
    }

    public static AggregateFunction GROUPING(SObjectField field, String alias) {
        return new AggregateFunction(field, 'GROUPING', FUNC_GROUPING_TAG, alias);
    }

    public static AggregateFunction COUNT(SObjectField field) {
        return new AggregateFunction(field, 'COUNT', FUNC_COUNT_TAG, null);
    }

    public static AggregateFunction COUNT(SObjectField field, String alias) {
        return new AggregateFunction(field, 'COUNT', FUNC_COUNT_TAG, alias);
    }

    public static AggregateFunction COUNT_DISTINCT(SObjectField field) {
        return new AggregateFunction(field, 'COUNT_DISTINCT', FUNC_COUNT_DISTINCT_TAG, null);
    }

    public static AggregateFunction COUNT_DISTINCT(SObjectField field, String alias) {
        return new AggregateFunction(field, 'COUNT_DISTINCT', FUNC_COUNT_DISTINCT_TAG, alias);
    }

    public static AggregateFunction SUM(SObjectField field) {
        return new AggregateFunction(field, 'SUM', FUNC_SUM_TAG, null);
    }

    public static AggregateFunction SUM(SObjectField field, String alias) {
        return new AggregateFunction(field, 'SUM', FUNC_SUM_TAG, alias);
    }

    public static AggregateFunction AVG(SObjectField field) {
        return new AggregateFunction(field, 'AVG', FUNC_AVG_TAG, null);
    }

    public static AggregateFunction AVG(SObjectField field, String alias) {
        return new AggregateFunction(field, 'AVG', FUNC_AVG_TAG, alias);
    }

    public static AggregateFunction MAX(SObjectField field) {
        return new AggregateFunction(field, 'MAX', FUNC_MAX_TAG, null);
    }

    public static AggregateFunction MAX(SObjectField field, String alias) {
        return new AggregateFunction(field, 'MAX', FUNC_MAX_TAG, alias);
    }

    public static AggregateFunction MIN(SObjectField field) {
        return new AggregateFunction(field, 'MIN', FUNC_MIN_TAG, null);
    }

    public static AggregateFunction MIN(SObjectField field, String alias) {
        return new AggregateFunction(field, 'MIN', FUNC_MIN_TAG, alias);
    }

    // Others
    public static SelectFunction COUNT() {
        return new AggregateFunction(null, 'COUNT', FUNC_COUNT_TAG, null);
    }

    // #endregion
    // ============================

    // =================================
    // #region Function - ToLabel/Format

    public class ToLabelFunction extends GenericFunction implements SelectFunction {
        private ToLabelFunction(Object field) {
            super(field, 'TOLABEL', FUNC_LABEL_TAG);
        }
    }

    public class FormatFunction extends GenericFunction implements SelectFunction {
        private FormatFunction(Object fieldOrFunc) {
            super(fieldOrFunc, 'FORMAT', FUNC_FORMAT_TAG);
        }
    }

    public class CurrencyFunction extends GenericFunction implements SelectFunction {
        private CurrencyFunction(Object field) {
            super(field, 'CONVERTCURRENCY', FUNC_CURRENCY_TAG);
        }
    }

    public static ToLabelFunction TO_LABEL(String field) {
        return new ToLabelFunction(field);
    }

    public static ToLabelFunction TO_LABEL(SObjectField field) {
        return new ToLabelFunction(field);
    }

    public static FormatFunction FORMAT(String field) {
        return new FormatFunction(field);
    }

    public static FormatFunction FORMAT(SObjectField field) {
        return new FormatFunction(field);
    }

    public static FormatFunction FORMAT(CurrencyFunction func) {
        return new FormatFunction(func);
    }

    public static CurrencyFunction CONVERT_CURRENCY(String field) {
        return new CurrencyFunction(field);
    }

    public static CurrencyFunction CONVERT_CURRENCY(SObjectField field) {
        return new CurrencyFunction(field);
    }
    // #endregion
    // =================================

    // ===========================
    // #region Function - Distance

    public class DistanceFunction implements Function, OrderFunction {
        private Object field { get; set; }
        private Location geo { get; set; }
        private String unit { get; set; }

        private DistanceFunction(Object field, Location geo, String unit) {
            this.field = field;
            this.geo = geo;
            this.unit = unit;
        }

        public override String toString() {
            return 'DISTANCE(' +
                String.valueOf(this.field) +
                ', GEOLOCATION(' +
                this.geo.latitude +
                ', ' +
                this.geo.longitude +
                '), \'' +
                this.unit +
                '\')';
        }

        public Boolean equals(Object obj) {
            if (obj == null) {
                return false;
            }

            if (this === obj) {
                return true;
            }

            DistanceFunction that = (DistanceFunction) obj;

            return this.field == that.field &&
                this.geo.latitude == that.geo.latitude &&
                this.geo.longitude == that.geo.longitude;
        }

        public Integer hashCode() {
            Integer hashCode = this.field == null ? 23 : this.field.hashCode();
            if (this.geo == null) {
                hashCode = (hashCode * 397) ^ (23);
                hashCode = (hashCode * 397) ^ (23);
            } else {
                hashCode = (hashCode * 397) ^ (this.geo.latitude == null ? 23 : System.hashCode(this.geo.latitude));
                hashCode = (hashCode * 397) ^ (this.geo.longitude == null ? 23 : System.hashCode(this.geo.longitude));
            }
            return hashCode;
        }
    }

    private static final String DISTANCE_UNIT_KM = 'km';
    private static final String DISTANCE_UNIT_MI = 'mi';

    public static DistanceFunction DISTANCE_IN_KM(String field, Location geo) {
        return new DistanceFunction(field, geo, DISTANCE_UNIT_KM);
    }
    public static DistanceFunction DISTANCE_IN_KM(SObjectField field, Location geo) {
        return new DistanceFunction(field, geo, DISTANCE_UNIT_KM);
    }

    public static DistanceFunction DISTANCE_IN_MI(String field, Location geo) {
        return new DistanceFunction(field, geo, DISTANCE_UNIT_MI);
    }
    public static DistanceFunction DISTANCE_IN_MI(SObjectField field, Location geo) {
        return new DistanceFunction(field, geo, DISTANCE_UNIT_MI);
    }

    // #endregion
    // ===========================

    // =======================
    // #region Function - Date

    public class TimezoneFunction extends GenericFunction {
        private TimezoneFunction(Object field) {
            super(field, 'CONVERTTIMEZONE', FUNC_CURRENCY_TAG);
        }
    }

    public static TimezoneFunction CONVERT_TIMEZONE(String field) {
        return new TimezoneFunction(field);
    }

    public static TimezoneFunction CONVERT_TIMEZONE(SObjectField field) {
        return new TimezoneFunction(field);
    }

    public class DateFunction extends GenericFunction implements SelectFunction {
        private DateFunction(Object fieldOrFunc, String name, Integer tag) {
            super(fieldOrFunc, name, tag);
        }

        private DateFunction(Object fieldOrFunc, String name, Integer tag, String alias) {
            super(fieldOrFunc, name, tag, alias);
        }
    }

    // DateFunction - String
    public static DateFunction CALENDAR_MONTH(String field) {
        return new DateFunction(field, 'CALENDAR_MONTH', CALENDAR_MONTH_TAG);
    }

    public static DateFunction CALENDAR_QUARTER(String field) {
        return new DateFunction(field, 'CALENDAR_QUARTER', CALENDAR_QUARTER_TAG);
    }

    public static DateFunction CALENDAR_YEAR(String field) {
        return new DateFunction(field, 'CALENDAR_YEAR', CALENDAR_YEAR_TAG);
    }

    public static DateFunction DAY_IN_MONTH(String field) {
        return new DateFunction(field, 'DAY_IN_MONTH', DAY_IN_MONTH_TAG);
    }

    public static DateFunction DAY_IN_WEEK(String field) {
        return new DateFunction(field, 'DAY_IN_WEEK', DAY_IN_WEEK_TAG);
    }

    public static DateFunction DAY_IN_YEAR(String field) {
        return new DateFunction(field, 'DAY_IN_YEAR', DAY_IN_YEAR_TAG);
    }

    public static DateFunction DAY_ONLY(String field) {
        return new DateFunction(field, 'DAY_ONLY', DAY_ONLY_TAG);
    }

    public static DateFunction FISCAL_MONTH(String field) {
        return new DateFunction(field, 'FISCAL_MONTH', FISCAL_MONTH_TAG);
    }

    public static DateFunction FISCAL_QUARTER(String field) {
        return new DateFunction(field, 'FISCAL_QUARTER', FISCAL_QUARTER_TAG);
    }

    public static DateFunction FISCAL_YEAR(String field) {
        return new DateFunction(field, 'FISCAL_YEAR', FISCAL_YEAR_TAG);
    }

    public static DateFunction HOUR_IN_DAY(String field) {
        return new DateFunction(field, 'HOUR_IN_DAY', HOUR_IN_DAY_TAG);
    }

    public static DateFunction WEEK_IN_MONTH(String field) {
        return new DateFunction(field, 'WEEK_IN_MONTH', WEEK_IN_MONTH_TAG);
    }

    public static DateFunction WEEK_IN_YEAR(String field) {
        return new DateFunction(field, 'WEEK_IN_YEAR', WEEK_IN_YEAR_TAG);
    }

    // DateFunction - SObjectField
    public static DateFunction CALENDAR_MONTH(SObjectField field) {
        return new DateFunction(field, 'CALENDAR_MONTH', CALENDAR_MONTH_TAG);
    }

    public static DateFunction CALENDAR_QUARTER(SObjectField field) {
        return new DateFunction(field, 'CALENDAR_QUARTER', CALENDAR_QUARTER_TAG);
    }

    public static DateFunction CALENDAR_YEAR(SObjectField field) {
        return new DateFunction(field, 'CALENDAR_YEAR', CALENDAR_YEAR_TAG);
    }

    public static DateFunction DAY_IN_MONTH(SObjectField field) {
        return new DateFunction(field, 'DAY_IN_MONTH', DAY_IN_MONTH_TAG);
    }

    public static DateFunction DAY_IN_WEEK(SObjectField field) {
        return new DateFunction(field, 'DAY_IN_WEEK', DAY_IN_WEEK_TAG);
    }

    public static DateFunction DAY_IN_YEAR(SObjectField field) {
        return new DateFunction(field, 'DAY_IN_YEAR', DAY_IN_YEAR_TAG);
    }

    public static DateFunction DAY_ONLY(SObjectField field) {
        return new DateFunction(field, 'DAY_ONLY', DAY_ONLY_TAG);
    }

    public static DateFunction FISCAL_MONTH(SObjectField field) {
        return new DateFunction(field, 'FISCAL_MONTH', FISCAL_MONTH_TAG);
    }

    public static DateFunction FISCAL_QUARTER(SObjectField field) {
        return new DateFunction(field, 'FISCAL_QUARTER', FISCAL_QUARTER_TAG);
    }

    public static DateFunction FISCAL_YEAR(SObjectField field) {
        return new DateFunction(field, 'FISCAL_YEAR', FISCAL_YEAR_TAG);
    }

    public static DateFunction HOUR_IN_DAY(SObjectField field) {
        return new DateFunction(field, 'HOUR_IN_DAY', HOUR_IN_DAY_TAG);
    }

    public static DateFunction WEEK_IN_MONTH(SObjectField field) {
        return new DateFunction(field, 'WEEK_IN_MONTH', WEEK_IN_MONTH_TAG);
    }

    public static DateFunction WEEK_IN_YEAR(SObjectField field) {
        return new DateFunction(field, 'WEEK_IN_YEAR', WEEK_IN_YEAR_TAG);
    }

    // DateFunction - TimezoneFunction
    public static DateFunction CALENDAR_MONTH(TimezoneFunction func) {
        return new DateFunction(func, 'CALENDAR_MONTH', CALENDAR_MONTH_TAG);
    }

    public static DateFunction CALENDAR_QUARTER(TimezoneFunction func) {
        return new DateFunction(func, 'CALENDAR_QUARTER', CALENDAR_QUARTER_TAG);
    }

    public static DateFunction CALENDAR_YEAR(TimezoneFunction func) {
        return new DateFunction(func, 'CALENDAR_YEAR', CALENDAR_YEAR_TAG);
    }

    public static DateFunction DAY_IN_MONTH(TimezoneFunction func) {
        return new DateFunction(func, 'DAY_IN_MONTH', DAY_IN_MONTH_TAG);
    }

    public static DateFunction DAY_IN_WEEK(TimezoneFunction func) {
        return new DateFunction(func, 'DAY_IN_WEEK', DAY_IN_WEEK_TAG);
    }

    public static DateFunction DAY_IN_YEAR(TimezoneFunction func) {
        return new DateFunction(func, 'DAY_IN_YEAR', DAY_IN_YEAR_TAG);
    }

    public static DateFunction DAY_ONLY(TimezoneFunction func) {
        return new DateFunction(func, 'DAY_ONLY', DAY_ONLY_TAG);
    }

    public static DateFunction FISCAL_MONTH(TimezoneFunction func) {
        return new DateFunction(func, 'FISCAL_MONTH', FISCAL_MONTH_TAG);
    }

    public static DateFunction FISCAL_QUARTER(TimezoneFunction func) {
        return new DateFunction(func, 'FISCAL_QUARTER', FISCAL_QUARTER_TAG);
    }

    public static DateFunction FISCAL_YEAR(TimezoneFunction func) {
        return new DateFunction(func, 'FISCAL_YEAR', FISCAL_YEAR_TAG);
    }

    public static DateFunction HOUR_IN_DAY(TimezoneFunction func) {
        return new DateFunction(func, 'HOUR_IN_DAY', HOUR_IN_DAY_TAG);
    }

    public static DateFunction WEEK_IN_MONTH(TimezoneFunction func) {
        return new DateFunction(func, 'WEEK_IN_MONTH', WEEK_IN_MONTH_TAG);
    }

    public static DateFunction WEEK_IN_YEAR(TimezoneFunction func) {
        return new DateFunction(func, 'WEEK_IN_YEAR', WEEK_IN_YEAR_TAG);
    }

    // #endregion
    // =======================

    // ==========================
    // #region Literal - Currency
    public class CurrencyLiteral {
        // ISO Code Reference: https://help.salesforce.com/s/articleView?id=sf.admin_supported_currencies.htm
        private String code { get; set; }
        private Decimal value { get; set; }

        private CurrencyLiteral(String code, Decimal value) {
            this.code = code;
            this.value = value;
        }

        public override String toString() {
            return this.code + this.value;
        }

        public Boolean equals(Object obj) {
            if (obj == null) {
                return false;
            }

            if (this === obj) {
                return true;
            }

            CurrencyLiteral that = (CurrencyLiteral) obj;
            return this.value == that.value && this.code == that.code;
        }

        public Integer hashCode() {
            Integer hashCode = this.value == null ? 23 : System.hashCode(this.value);
            hashCode = (hashCode * 397) ^ (this.code == null ? 23 : this.code.hashCode());
            return hashCode;
        }
    }

    public static CurrencyLiteral CURRENCY(String code, Decimal value) {
        return new CurrencyLiteral(code, value);
    }

    public static CurrencyLiteral AED(Decimal value) {
        return new CurrencyLiteral('AED', value);
    }

    public static CurrencyLiteral AFN(Decimal value) {
        return new CurrencyLiteral('AFN', value);
    }

    public static CurrencyLiteral ALL(Decimal value) {
        return new CurrencyLiteral('ALL', value);
    }

    public static CurrencyLiteral AMD(Decimal value) {
        return new CurrencyLiteral('AMD', value);
    }

    public static CurrencyLiteral ANG(Decimal value) {
        return new CurrencyLiteral('ANG', value);
    }

    public static CurrencyLiteral AOA(Decimal value) {
        return new CurrencyLiteral('AOA', value);
    }

    public static CurrencyLiteral ARS(Decimal value) {
        return new CurrencyLiteral('ARS', value);
    }

    public static CurrencyLiteral AUD(Decimal value) {
        return new CurrencyLiteral('AUD', value);
    }

    public static CurrencyLiteral AWG(Decimal value) {
        return new CurrencyLiteral('AWG', value);
    }

    public static CurrencyLiteral AZN(Decimal value) {
        return new CurrencyLiteral('AZN', value);
    }

    public static CurrencyLiteral BAM(Decimal value) {
        return new CurrencyLiteral('BAM', value);
    }

    public static CurrencyLiteral BBD(Decimal value) {
        return new CurrencyLiteral('BBD', value);
    }

    public static CurrencyLiteral BDT(Decimal value) {
        return new CurrencyLiteral('BDT', value);
    }

    public static CurrencyLiteral BGN(Decimal value) {
        return new CurrencyLiteral('BGN', value);
    }

    public static CurrencyLiteral BHD(Decimal value) {
        return new CurrencyLiteral('BHD', value);
    }

    public static CurrencyLiteral BIF(Decimal value) {
        return new CurrencyLiteral('BIF', value);
    }

    public static CurrencyLiteral BMD(Decimal value) {
        return new CurrencyLiteral('BMD', value);
    }

    public static CurrencyLiteral BND(Decimal value) {
        return new CurrencyLiteral('BND', value);
    }

    public static CurrencyLiteral BOB(Decimal value) {
        return new CurrencyLiteral('BOB', value);
    }

    public static CurrencyLiteral BRL(Decimal value) {
        return new CurrencyLiteral('BRL', value);
    }

    public static CurrencyLiteral BSD(Decimal value) {
        return new CurrencyLiteral('BSD', value);
    }

    public static CurrencyLiteral BTN(Decimal value) {
        return new CurrencyLiteral('BTN', value);
    }

    public static CurrencyLiteral BWP(Decimal value) {
        return new CurrencyLiteral('BWP', value);
    }

    public static CurrencyLiteral BYN(Decimal value) {
        return new CurrencyLiteral('BYN', value);
    }

    public static CurrencyLiteral BZD(Decimal value) {
        return new CurrencyLiteral('BZD', value);
    }

    public static CurrencyLiteral CAD(Decimal value) {
        return new CurrencyLiteral('CAD', value);
    }

    public static CurrencyLiteral CDF(Decimal value) {
        return new CurrencyLiteral('CDF', value);
    }

    public static CurrencyLiteral CHF(Decimal value) {
        return new CurrencyLiteral('CHF', value);
    }

    public static CurrencyLiteral CLP(Decimal value) {
        return new CurrencyLiteral('CLP', value);
    }

    public static CurrencyLiteral CNY(Decimal value) {
        return new CurrencyLiteral('CNY', value);
    }

    public static CurrencyLiteral COP(Decimal value) {
        return new CurrencyLiteral('COP', value);
    }

    public static CurrencyLiteral CRC(Decimal value) {
        return new CurrencyLiteral('CRC', value);
    }

    public static CurrencyLiteral CSD(Decimal value) {
        return new CurrencyLiteral('CSD', value);
    }

    public static CurrencyLiteral CUP(Decimal value) {
        return new CurrencyLiteral('CUP', value);
    }

    public static CurrencyLiteral CVE(Decimal value) {
        return new CurrencyLiteral('CVE', value);
    }

    public static CurrencyLiteral CZK(Decimal value) {
        return new CurrencyLiteral('CZK', value);
    }

    public static CurrencyLiteral DJF(Decimal value) {
        return new CurrencyLiteral('DJF', value);
    }

    public static CurrencyLiteral DKK(Decimal value) {
        return new CurrencyLiteral('DKK', value);
    }

    public static CurrencyLiteral DOP(Decimal value) {
        return new CurrencyLiteral('DOP', value);
    }

    public static CurrencyLiteral DZD(Decimal value) {
        return new CurrencyLiteral('DZD', value);
    }

    public static CurrencyLiteral EGP(Decimal value) {
        return new CurrencyLiteral('EGP', value);
    }

    public static CurrencyLiteral ERN(Decimal value) {
        return new CurrencyLiteral('ERN', value);
    }

    public static CurrencyLiteral ETB(Decimal value) {
        return new CurrencyLiteral('ETB', value);
    }

    public static CurrencyLiteral EUR(Decimal value) {
        return new CurrencyLiteral('EUR', value);
    }

    public static CurrencyLiteral FJD(Decimal value) {
        return new CurrencyLiteral('FJD', value);
    }

    public static CurrencyLiteral FKP(Decimal value) {
        return new CurrencyLiteral('FKP', value);
    }

    public static CurrencyLiteral GBP(Decimal value) {
        return new CurrencyLiteral('GBP', value);
    }

    public static CurrencyLiteral GEL(Decimal value) {
        return new CurrencyLiteral('GEL', value);
    }

    public static CurrencyLiteral GHS(Decimal value) {
        return new CurrencyLiteral('GHS', value);
    }

    public static CurrencyLiteral GIP(Decimal value) {
        return new CurrencyLiteral('GIP', value);
    }

    public static CurrencyLiteral GMD(Decimal value) {
        return new CurrencyLiteral('GMD', value);
    }

    public static CurrencyLiteral GNF(Decimal value) {
        return new CurrencyLiteral('GNF', value);
    }

    public static CurrencyLiteral GTQ(Decimal value) {
        return new CurrencyLiteral('GTQ', value);
    }

    public static CurrencyLiteral GYD(Decimal value) {
        return new CurrencyLiteral('GYD', value);
    }

    public static CurrencyLiteral HKD(Decimal value) {
        return new CurrencyLiteral('HKD', value);
    }

    public static CurrencyLiteral HNL(Decimal value) {
        return new CurrencyLiteral('HNL', value);
    }

    public static CurrencyLiteral HRK(Decimal value) {
        return new CurrencyLiteral('HRK', value);
    }

    public static CurrencyLiteral HTG(Decimal value) {
        return new CurrencyLiteral('HTG', value);
    }

    public static CurrencyLiteral HUF(Decimal value) {
        return new CurrencyLiteral('HUF', value);
    }

    public static CurrencyLiteral IDR(Decimal value) {
        return new CurrencyLiteral('IDR', value);
    }

    public static CurrencyLiteral ILS(Decimal value) {
        return new CurrencyLiteral('ILS', value);
    }

    public static CurrencyLiteral INR(Decimal value) {
        return new CurrencyLiteral('INR', value);
    }

    public static CurrencyLiteral IQD(Decimal value) {
        return new CurrencyLiteral('IQD', value);
    }

    public static CurrencyLiteral IRR(Decimal value) {
        return new CurrencyLiteral('IRR', value);
    }

    public static CurrencyLiteral ISK(Decimal value) {
        return new CurrencyLiteral('ISK', value);
    }

    public static CurrencyLiteral JMD(Decimal value) {
        return new CurrencyLiteral('JMD', value);
    }

    public static CurrencyLiteral JOD(Decimal value) {
        return new CurrencyLiteral('JOD', value);
    }

    public static CurrencyLiteral JPY(Decimal value) {
        return new CurrencyLiteral('JPY', value);
    }

    public static CurrencyLiteral KES(Decimal value) {
        return new CurrencyLiteral('KES', value);
    }

    public static CurrencyLiteral KGS(Decimal value) {
        return new CurrencyLiteral('KGS', value);
    }

    public static CurrencyLiteral KHR(Decimal value) {
        return new CurrencyLiteral('KHR', value);
    }

    public static CurrencyLiteral KMF(Decimal value) {
        return new CurrencyLiteral('KMF', value);
    }

    public static CurrencyLiteral KPW(Decimal value) {
        return new CurrencyLiteral('KPW', value);
    }

    public static CurrencyLiteral KRW(Decimal value) {
        return new CurrencyLiteral('KRW', value);
    }

    public static CurrencyLiteral KWD(Decimal value) {
        return new CurrencyLiteral('KWD', value);
    }

    public static CurrencyLiteral KYD(Decimal value) {
        return new CurrencyLiteral('KYD', value);
    }

    public static CurrencyLiteral KZT(Decimal value) {
        return new CurrencyLiteral('KZT', value);
    }

    public static CurrencyLiteral LAK(Decimal value) {
        return new CurrencyLiteral('LAK', value);
    }

    public static CurrencyLiteral LBP(Decimal value) {
        return new CurrencyLiteral('LBP', value);
    }

    public static CurrencyLiteral LKR(Decimal value) {
        return new CurrencyLiteral('LKR', value);
    }

    public static CurrencyLiteral LRD(Decimal value) {
        return new CurrencyLiteral('LRD', value);
    }

    public static CurrencyLiteral LYD(Decimal value) {
        return new CurrencyLiteral('LYD', value);
    }

    public static CurrencyLiteral MAD(Decimal value) {
        return new CurrencyLiteral('MAD', value);
    }

    public static CurrencyLiteral MDL(Decimal value) {
        return new CurrencyLiteral('MDL', value);
    }

    public static CurrencyLiteral MGA(Decimal value) {
        return new CurrencyLiteral('MGA', value);
    }

    public static CurrencyLiteral MKD(Decimal value) {
        return new CurrencyLiteral('MKD', value);
    }

    public static CurrencyLiteral MMK(Decimal value) {
        return new CurrencyLiteral('MMK', value);
    }

    public static CurrencyLiteral MOP(Decimal value) {
        return new CurrencyLiteral('MOP', value);
    }

    public static CurrencyLiteral MRU(Decimal value) {
        return new CurrencyLiteral('MRU', value);
    }

    public static CurrencyLiteral MUR(Decimal value) {
        return new CurrencyLiteral('MUR', value);
    }

    public static CurrencyLiteral MWK(Decimal value) {
        return new CurrencyLiteral('MWK', value);
    }

    public static CurrencyLiteral MXN(Decimal value) {
        return new CurrencyLiteral('MXN', value);
    }

    public static CurrencyLiteral MYR(Decimal value) {
        return new CurrencyLiteral('MYR', value);
    }

    public static CurrencyLiteral MZN(Decimal value) {
        return new CurrencyLiteral('MZN', value);
    }

    public static CurrencyLiteral NAD(Decimal value) {
        return new CurrencyLiteral('NAD', value);
    }

    public static CurrencyLiteral NGN(Decimal value) {
        return new CurrencyLiteral('NGN', value);
    }

    public static CurrencyLiteral NIO(Decimal value) {
        return new CurrencyLiteral('NIO', value);
    }

    public static CurrencyLiteral NOK(Decimal value) {
        return new CurrencyLiteral('NOK', value);
    }

    public static CurrencyLiteral NPR(Decimal value) {
        return new CurrencyLiteral('NPR', value);
    }

    public static CurrencyLiteral NZD(Decimal value) {
        return new CurrencyLiteral('NZD', value);
    }

    public static CurrencyLiteral OMR(Decimal value) {
        return new CurrencyLiteral('OMR', value);
    }

    public static CurrencyLiteral PAB(Decimal value) {
        return new CurrencyLiteral('PAB', value);
    }

    public static CurrencyLiteral PEN(Decimal value) {
        return new CurrencyLiteral('PEN', value);
    }

    public static CurrencyLiteral PGK(Decimal value) {
        return new CurrencyLiteral('PGK', value);
    }

    public static CurrencyLiteral PHP(Decimal value) {
        return new CurrencyLiteral('PHP', value);
    }

    public static CurrencyLiteral PKR(Decimal value) {
        return new CurrencyLiteral('PKR', value);
    }

    public static CurrencyLiteral PLN(Decimal value) {
        return new CurrencyLiteral('PLN', value);
    }

    public static CurrencyLiteral PYG(Decimal value) {
        return new CurrencyLiteral('PYG', value);
    }

    public static CurrencyLiteral QAR(Decimal value) {
        return new CurrencyLiteral('QAR', value);
    }

    public static CurrencyLiteral RON(Decimal value) {
        return new CurrencyLiteral('RON', value);
    }

    public static CurrencyLiteral RSD(Decimal value) {
        return new CurrencyLiteral('RSD', value);
    }

    public static CurrencyLiteral RUB(Decimal value) {
        return new CurrencyLiteral('RUB', value);
    }

    public static CurrencyLiteral RWF(Decimal value) {
        return new CurrencyLiteral('RWF', value);
    }

    public static CurrencyLiteral SAR(Decimal value) {
        return new CurrencyLiteral('SAR', value);
    }

    public static CurrencyLiteral SBD(Decimal value) {
        return new CurrencyLiteral('SBD', value);
    }

    public static CurrencyLiteral SCR(Decimal value) {
        return new CurrencyLiteral('SCR', value);
    }

    public static CurrencyLiteral SDG(Decimal value) {
        return new CurrencyLiteral('SDG', value);
    }

    public static CurrencyLiteral SEK(Decimal value) {
        return new CurrencyLiteral('SEK', value);
    }

    public static CurrencyLiteral SGD(Decimal value) {
        return new CurrencyLiteral('SGD', value);
    }

    public static CurrencyLiteral SHP(Decimal value) {
        return new CurrencyLiteral('SHP', value);
    }

    public static CurrencyLiteral SLE(Decimal value) {
        return new CurrencyLiteral('SLE', value);
    }

    public static CurrencyLiteral SLL(Decimal value) {
        return new CurrencyLiteral('SLL', value);
    }

    public static CurrencyLiteral SOS(Decimal value) {
        return new CurrencyLiteral('SOS', value);
    }

    public static CurrencyLiteral SRD(Decimal value) {
        return new CurrencyLiteral('SRD', value);
    }

    public static CurrencyLiteral STN(Decimal value) {
        return new CurrencyLiteral('STN', value);
    }

    public static CurrencyLiteral SYP(Decimal value) {
        return new CurrencyLiteral('SYP', value);
    }

    public static CurrencyLiteral SZL(Decimal value) {
        return new CurrencyLiteral('SZL', value);
    }

    public static CurrencyLiteral THB(Decimal value) {
        return new CurrencyLiteral('THB', value);
    }

    public static CurrencyLiteral TJS(Decimal value) {
        return new CurrencyLiteral('TJS', value);
    }

    public static CurrencyLiteral TND(Decimal value) {
        return new CurrencyLiteral('TND', value);
    }

    public static CurrencyLiteral TOP(Decimal value) {
        return new CurrencyLiteral('TOP', value);
    }

    // !TRY is a keywork
    // public static CurrencyLiteral TRY(Decimal value) {
    //     return new CurrencyLiteral('TRY', value);
    // }

    public static CurrencyLiteral TTD(Decimal value) {
        return new CurrencyLiteral('TTD', value);
    }

    public static CurrencyLiteral TWD(Decimal value) {
        return new CurrencyLiteral('TWD', value);
    }

    public static CurrencyLiteral TZS(Decimal value) {
        return new CurrencyLiteral('TZS', value);
    }

    public static CurrencyLiteral UAH(Decimal value) {
        return new CurrencyLiteral('UAH', value);
    }

    public static CurrencyLiteral UGX(Decimal value) {
        return new CurrencyLiteral('UGX', value);
    }

    public static CurrencyLiteral USD(Decimal value) {
        return new CurrencyLiteral('USD', value);
    }

    public static CurrencyLiteral UYU(Decimal value) {
        return new CurrencyLiteral('UYU', value);
    }

    public static CurrencyLiteral UZS(Decimal value) {
        return new CurrencyLiteral('UZS', value);
    }

    public static CurrencyLiteral VES(Decimal value) {
        return new CurrencyLiteral('VES', value);
    }

    public static CurrencyLiteral VND(Decimal value) {
        return new CurrencyLiteral('VND', value);
    }

    public static CurrencyLiteral VUV(Decimal value) {
        return new CurrencyLiteral('VUV', value);
    }

    public static CurrencyLiteral WST(Decimal value) {
        return new CurrencyLiteral('WST', value);
    }

    public static CurrencyLiteral XAF(Decimal value) {
        return new CurrencyLiteral('XAF', value);
    }

    public static CurrencyLiteral XCD(Decimal value) {
        return new CurrencyLiteral('XCD', value);
    }

    public static CurrencyLiteral XOF(Decimal value) {
        return new CurrencyLiteral('XOF', value);
    }

    public static CurrencyLiteral XPF(Decimal value) {
        return new CurrencyLiteral('XPF', value);
    }

    public static CurrencyLiteral YER(Decimal value) {
        return new CurrencyLiteral('YER', value);
    }

    public static CurrencyLiteral ZAR(Decimal value) {
        return new CurrencyLiteral('ZAR', value);
    }

    // #endregion
    // ==========================

    // ======================
    // #region Literal - Date
    public class DateLiteral {
        public String name { get; set; }
        public Integer value { get; set; }

        private DateLiteral(String name) {
            this.name = name;
        }

        private DateLiteral(String name, Integer value) {
            this.name = name;
            this.value = value;
        }

        public override String toString() {
            if (this.value == null) {
                return this.name;
            } else {
                return this.name + this.value;
            }
        }

        public Boolean equals(Object obj) {
            if (obj == null) {
                return false;
            }

            if (this === obj) {
                return true;
            }

            DateLiteral that = (DateLiteral) obj;
            return this.value == that.value && this.name == that.name;
        }

        public Integer hashCode() {
            Integer hashCode = this.value == null ? 23 : this.value;
            hashCode = (hashCode * 397) ^ (this.name == null ? 23 : this.name.hashCode());
            return hashCode;
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
        return new DateLiteral('LAST_N_DAYS:', n);
    }

    public static DateLiteral NEXT_N_DAYS(Integer n) {
        return new DateLiteral('NEXT_N_DAYS:', n);
    }

    public static DateLiteral N_DAYS_AGO(Integer n) {
        return new DateLiteral('N_DAYS_AGO:', n);
    }

    public static DateLiteral NEXT_N_WEEKS(Integer n) {
        return new DateLiteral('NEXT_N_WEEKS:', n);
    }

    public static DateLiteral LAST_N_WEEKS(Integer n) {
        return new DateLiteral('LAST_N_WEEKS:', n);
    }

    public static DateLiteral N_WEEKS_AGO(Integer n) {
        return new DateLiteral('N_WEEKS_AGO:', n);
    }

    public static DateLiteral NEXT_N_MONTHS(Integer n) {
        return new DateLiteral('NEXT_N_MONTHS:', n);
    }

    public static DateLiteral LAST_N_MONTHS(Integer n) {
        return new DateLiteral('LAST_N_MONTHS:', n);
    }

    public static DateLiteral N_MONTHS_AGO(Integer n) {
        return new DateLiteral('N_MONTHS_AGO:', n);
    }

    public static DateLiteral NEXT_N_QUARTERS(Integer n) {
        return new DateLiteral('NEXT_N_QUARTERS:', n);
    }

    public static DateLiteral LAST_N_QUARTERS(Integer n) {
        return new DateLiteral('LAST_N_QUARTERS:', n);
    }

    public static DateLiteral N_QUARTERS_AGO(Integer n) {
        return new DateLiteral('N_QUARTERS_AGO:', n);
    }

    public static DateLiteral NEXT_N_YEARS(Integer n) {
        return new DateLiteral('NEXT_N_YEARS:', n);
    }

    public static DateLiteral LAST_N_YEARS(Integer n) {
        return new DateLiteral('LAST_N_YEARS:', n);
    }

    public static DateLiteral N_YEARS_AGO(Integer n) {
        return new DateLiteral('N_YEARS_AGO:', n);
    }

    public static DateLiteral NEXT_N_FISCAL_QUARTERS(Integer n) {
        return new DateLiteral('NEXT_N_FISCAL_QUARTERS:', n);
    }

    public static DateLiteral N_FISCAL_QUARTERS_AGO(Integer n) {
        return new DateLiteral('N_FISCAL_QUARTERS_AGO:', n);
    }

    public static DateLiteral NEXT_N_FISCAL_YEARS(Integer n) {
        return new DateLiteral('NEXT_N_FISCAL_YEARS:', n);
    }

    public static DateLiteral LAST_N_FISCAL_YEARS(Integer n) {
        return new DateLiteral('LAST_N_FISCAL_YEARS:', n);
    }

    public static DateLiteral N_FISCAL_YEARS_AGO(Integer n) {
        return new DateLiteral('N_FISCAL_YEARS_AGO:', n);
    }

    // #endregion
    // ======================

    // Filter Tags
    private static final Integer FILTER_EQ_TAG = 1;
    private static final Integer FILTER_NE_TAG = 2;
    private static final Integer FILTER_GT_TAG = 3;
    private static final Integer FILTER_GTE_TAG = 4;
    private static final Integer FILTER_LT_TAG = 5;
    private static final Integer FILTER_LTE_TAG = 6;
    private static final Integer FILTER_LIKEX_TAG = 7;
    private static final Integer FILTER_NLIKE_TAG = 8;
    private static final Integer FILTER_INCLUDES_TAG = 9;
    private static final Integer FILTER_EXCLUDES_TAG = 10;
    private static final Integer FILTER_INX_TAG = 11;
    private static final Integer FILTER_NIN_TAG = 12;
    private static final Integer FILTER_INX_QUERY_TAG = 13;
    private static final Integer FILTER_DISTANCE_TAG = 14;
    private static final Integer FILTER_AND_TAG = 15;
    private static final Integer FILTER_OR_TAG = 16;
    private static final Integer FILTER_NOT_TAG = 17;

    private static final Integer FUNC_GROUPING_TAG = 18;
    private static final Integer FUNC_COUNT_TAG = 19;
    private static final Integer FUNC_COUNT_DISTINCT_TAG = 20;
    private static final Integer FUNC_SUM_TAG = 21;
    private static final Integer FUNC_AVG_TAG = 22;
    private static final Integer FUNC_MAX_TAG = 23;
    private static final Integer FUNC_MIN_TAG = 24;

    private static final Integer CALENDAR_MONTH_TAG = 25;
    private static final Integer CALENDAR_QUARTER_TAG = 26;
    private static final Integer CALENDAR_YEAR_TAG = 27;
    private static final Integer DAY_IN_MONTH_TAG = 28;
    private static final Integer DAY_IN_WEEK_TAG = 29;
    private static final Integer DAY_IN_YEAR_TAG = 30;
    private static final Integer DAY_ONLY_TAG = 31;
    private static final Integer FISCAL_MONTH_TAG = 32;
    private static final Integer FISCAL_QUARTER_TAG = 33;
    private static final Integer FISCAL_YEAR_TAG = 34;
    private static final Integer HOUR_IN_DAY_TAG = 35;
    private static final Integer WEEK_IN_MONTH_TAG = 36;
    private static final Integer WEEK_IN_YEAR_TAG = 37;

    private static final Integer FUNC_FORMAT_TAG = 38;
    private static final Integer FUNC_LABEL_TAG = 39;
    private static final Integer FUNC_CURRENCY_TAG = 40;

    // prettier-ignore
    public interface Querable {
        List<SObject> run();
        List<SObject> run(AccessLevel accessLevel);
        Integer getCount();
        Integer getCount(AccessLevel accessLevel);
        Database.QueryLocator getLocator();
        Database.QueryLocator getLocator(AccessLevel accessLevel);

        // SELECT
        Query selectBy(String field);
        Query selectBy(String field1, String field2);
        Query selectBy(String field1, String field2, String field3);
        Query selectBy(String field1, String field2, String field3, String field4);
        Query selectBy(String field1, String field2, String field3, String field4, String field5);

        Query selectBy(SObjectField field);
        Query selectBy(SObjectField field1, SObjectField field2);
        Query selectBy(SObjectField field1, SObjectField field2, SObjectField field3);
        Query selectBy(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        Query selectBy(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);

        Query selectBy(SelectFunction func);
        Query selectBy(SelectFunction func1, SelectFunction func2);
        Query selectBy(SelectFunction func1, SelectFunction func2, SelectFunction func3);
        Query selectBy(SelectFunction func1, SelectFunction func2, SelectFunction func3, SelectFunction func4);
        Query selectBy(SelectFunction func1, SelectFunction func2, SelectFunction func3, SelectFunction func4, SelectFunction func5);

        Query selectBy(String relationName, Query query);
        Query selectBy(List<Object> fieldOrFuncs);
        Query selectBy(Selector selector);
        Query selectBy(TypeOf typeof);

        // WHERE
        Query filterBy(Filter filter);

        // ORDER BY
        Query orderBy(String field);
        Query orderBy(String field1, String field2);
        Query orderBy(String field1, String field2, String field3);
        Query orderBy(String field1, String field2, String field3, String field4);
        Query orderBy(String field1, String field2, String field3, String field4, String field5);

        Query orderBy(SObjectField field);
        Query orderBy(SObjectField field1, SObjectField field2);
        Query orderBy(SObjectField field1, SObjectField field2, SObjectField field3);
        Query orderBy(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        Query orderBy(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);

        Query orderBy(OrderFunction func);
        Query orderBy(OrderFunction func1, OrderFunction func2);
        Query orderBy(OrderFunction func1, OrderFunction func2, OrderFunction func3);
        Query orderBy(OrderFunction func1, OrderFunction func2, OrderFunction func3, OrderFunction func4);
        Query orderBy(OrderFunction func1, OrderFunction func2, OrderFunction func3, OrderFunction func4, OrderFunction func5);

        Query orderBy(List<Object> fieldOrFuncs);
        Query orderBy(Orderer orderer);

        Query ascending();
        Query descending();
        Query nullsFirst();
        Query nullsLast();

        // GROUP BY
        Query groupBy(String field);
        Query groupBy(String field1, String field2);
        Query groupBy(String field1, String field2, String field3);
        Query groupBy(String field1, String field2, String field3, String field4);
        Query groupBy(String field1, String field2, String field3, String field4, String field5);

        Query groupBy(SObjectField field);
        Query groupBy(SObjectField field1, SObjectField field2);
        Query groupBy(SObjectField field1, SObjectField field2, SObjectField field3);
        Query groupBy(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        Query groupBy(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);

        Query groupBy(DateFunction func);
        Query groupBy(DateFunction func1, DateFunction func2);
        Query groupBy(DateFunction func1, DateFunction func2, DateFunction func3);
        Query groupBy(DateFunction func1, DateFunction func2, DateFunction func3, DateFunction func4);
        Query groupBy(DateFunction func1, DateFunction func2, DateFunction func3, DateFunction func4, DateFunction func5);

        Query groupBy(List<Object> fieldOrFuncs);
        Query groupBy(Grouper rootGrouper);

        Query rollup();
        Query cube();

        // HAVING
        Query havingBy(Filter filter);

        // Misc
        Query offset(Integer n);
        Query limitx(Integer n);

        Query forView();
        Query forReference();
        Query updateTracking();
        Query updateViewstat();
        Query forUpdate();
    }
    // ===================
    // #region HIDE SYNTAX
    public virtual Query selectBy(String field) {
        return this;
    }
    public virtual Query selectBy(String field1, String field2) {
        return this;
    }
    public virtual Query selectBy(String field1, String field2, String field3) {
        return this;
    }
    public virtual Query selectBy(String field1, String field2, String field3, String field4) {
        return this;
    }
    public virtual Query selectBy(String field1, String field2, String field3, String field4, String field5) {
        return this;
    }
    public virtual Query selectBy(SObjectField field) {
        return this;
    }
    public virtual Query selectBy(SObjectField field1, SObjectField field2) {
        return this;
    }
    public virtual Query selectBy(SObjectField field1, SObjectField field2, SObjectField field3) {
        return this;
    }
    public virtual Query selectBy(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
        return this;
    }
    public virtual Query selectBy(
        SObjectField field1,
        SObjectField field2,
        SObjectField field3,
        SObjectField field4,
        SObjectField field5
    ) {
        return this;
    }
    public virtual Query selectBy(SelectFunction func) {
        return this;
    }
    public virtual Query selectBy(SelectFunction func1, SelectFunction func2) {
        return this;
    }
    public virtual Query selectBy(SelectFunction func1, SelectFunction func2, SelectFunction func3) {
        return this;
    }
    public virtual Query selectBy(
        SelectFunction func1,
        SelectFunction func2,
        SelectFunction func3,
        SelectFunction func4
    ) {
        return this;
    }
    public virtual Query selectBy(
        SelectFunction func1,
        SelectFunction func2,
        SelectFunction func3,
        SelectFunction func4,
        SelectFunction func5
    ) {
        return this;
    }
    public virtual Query selectBy(String relationName, Query query) {
        return this;
    }
    public virtual Query selectBy(List<Object> fieldOrFuncs) {
        return this;
    }
    public virtual Query selectBy(Selector selector) {
        return this;
    }
    public virtual Query selectBy(TypeOf typeof) {
        return this;
    }
    public virtual Query filterBy(Filter filter) {
        return this;
    }
    public virtual Query orderBy(String field) {
        return this;
    }
    public virtual Query orderBy(String field1, String field2) {
        return this;
    }
    public virtual Query orderBy(String field1, String field2, String field3) {
        return this;
    }
    public virtual Query orderBy(String field1, String field2, String field3, String field4) {
        return this;
    }
    public virtual Query orderBy(String field1, String field2, String field3, String field4, String field5) {
        return this;
    }
    public virtual Query orderBy(SObjectField field) {
        return this;
    }
    public virtual Query orderBy(SObjectField field1, SObjectField field2) {
        return this;
    }
    public virtual Query orderBy(SObjectField field1, SObjectField field2, SObjectField field3) {
        return this;
    }
    public virtual Query orderBy(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
        return this;
    }
    public virtual Query orderBy(
        SObjectField field1,
        SObjectField field2,
        SObjectField field3,
        SObjectField field4,
        SObjectField field5
    ) {
        return this;
    }
    public virtual Query orderBy(OrderFunction func) {
        return this;
    }
    public virtual Query orderBy(OrderFunction func1, OrderFunction func2) {
        return this;
    }
    public virtual Query orderBy(OrderFunction func1, OrderFunction func2, OrderFunction func3) {
        return this;
    }
    public virtual Query orderBy(OrderFunction func1, OrderFunction func2, OrderFunction func3, OrderFunction func4) {
        return this;
    }
    public virtual Query orderBy(
        OrderFunction func1,
        OrderFunction func2,
        OrderFunction func3,
        OrderFunction func4,
        OrderFunction func5
    ) {
        return this;
    }
    public virtual Query orderBy(List<Object> fieldOrFuncs) {
        return this;
    }
    public virtual Query orderBy(Orderer orderer) {
        return this;
    }
    public virtual Query ascending() {
        return this;
    }
    public virtual Query descending() {
        return this;
    }
    public virtual Query nullsFirst() {
        return this;
    }
    public virtual Query nullsLast() {
        return this;
    }
    public virtual Query groupBy(String field) {
        return this;
    }
    public virtual Query groupBy(String field1, String field2) {
        return this;
    }
    public virtual Query groupBy(String field1, String field2, String field3) {
        return this;
    }
    public virtual Query groupBy(String field1, String field2, String field3, String field4) {
        return this;
    }
    public virtual Query groupBy(String field1, String field2, String field3, String field4, String field5) {
        return this;
    }
    public virtual Query groupBy(SObjectField field) {
        return this;
    }
    public virtual Query groupBy(SObjectField field1, SObjectField field2) {
        return this;
    }
    public virtual Query groupBy(SObjectField field1, SObjectField field2, SObjectField field3) {
        return this;
    }
    public virtual Query groupBy(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
        return this;
    }
    public virtual Query groupBy(
        SObjectField field1,
        SObjectField field2,
        SObjectField field3,
        SObjectField field4,
        SObjectField field5
    ) {
        return this;
    }
    public virtual Query groupBy(DateFunction func) {
        return this;
    }
    public virtual Query groupBy(DateFunction func1, DateFunction func2) {
        return this;
    }
    public virtual Query groupBy(DateFunction func1, DateFunction func2, DateFunction func3) {
        return this;
    }
    public virtual Query groupBy(DateFunction func1, DateFunction func2, DateFunction func3, DateFunction func4) {
        return this;
    }
    public virtual Query groupBy(
        DateFunction func1,
        DateFunction func2,
        DateFunction func3,
        DateFunction func4,
        DateFunction func5
    ) {
        return this;
    }
    public virtual Query groupBy(List<Object> fieldOrFuncs) {
        return this;
    }
    public virtual Query groupBy(Grouper rootGrouper) {
        return this;
    }
    public virtual Query rollup() {
        return this;
    }
    public virtual Query cube() {
        return this;
    }
    public virtual Query havingBy(Filter filter) {
        return this;
    }
    public virtual Query offset(Integer n) {
        return this;
    }
    public virtual Query limitx(Integer n) {
        return this;
    }
    public virtual Query forView() {
        return this;
    }
    public virtual Query forReference() {
        return this;
    }
    public virtual Query updateTracking() {
        return this;
    }
    public virtual Query updateViewstat() {
        return this;
    }
    public virtual Query forUpdate() {
        return this;
    }
    // #endregion
    // ===================
}
