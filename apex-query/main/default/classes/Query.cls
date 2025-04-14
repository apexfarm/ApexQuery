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
    private SObjectType objectType { get; private set; }
    private SelectByImpl rootSelectBy { get; set; }
    private TypeOfImpl rootTypeOf { get; set; }
    private OrderByImpl rootOrderBy { get; set; }
    private GroupByImpl rootGroupBy { get; set; }
    private Filter rootFilterBy { get; set; }
    private Filter rootHavingBy { get; set; }

    private Boolean rollup { get; set; }
    private Boolean cube { get; set; }

    private Integer offset { get; set; }
    private Integer limitx { get; set; }

    private Boolean forView { get; set; }
    private Boolean forReference { get; set; }
    private Boolean updateTracking { get; set; }
    private Boolean updateViewstat { get; set; }
    private Boolean forUpdate { get; set; }

    public Query() {
    }

    private Query(SObjectType objectType) {
        this.objectType = objectType;
        this.rootSelectBy = new SelectByImpl();
        this.rootOrderBy = new OrderByImpl();
        this.rootGroupBy = new GroupByImpl();
        this.rollup = false;
        this.cube = false;
    }

    public static Query of(SObjectType objectType) {
        return new Query(objectType);
    }

    public static SelectBy selectBy() {
        return new SelectByImpl();
    }

    public static TypeOf typeof(String field) {
        return new TypeOfImpl(field);
    }

    public static OrderBy orderBy() {
        return new OrderByImpl();
    }

    public static GroupBy groupBy() {
        return new GroupByImpl();
    }

    @TestVisible
    protected String build(Map<String, Object> tmpVars) {
        List<String> fragments = new List<String>();
        buildSoql(fragments, tmpVars);
        String query = String.join(fragments, '');
        System.debug('[Apex Query Soql] => ' + query);
        System.debug('[Apex Query Vars] => ' + tmpVars);
        return query;
    }

    private void buildSoql(List<String> fragments, Map<String, Object> tmpVars) {
        this.buildSoql(String.valueOf(this.objectType), fragments, tmpVars);
    }

    private void buildSoql(String sobjectName, List<String> fragments, Map<String, Object> tmpVars) {
        this.buildSelect(fragments, tmpVars);
        fragments.add(' FROM ');
        fragments.add(sobjectName);

        // Build Filters
        if (this.rootFilterBy != null) {
            fragments.add(' WHERE ');
            fragments.add(this.rootFilterBy.getExpression(tmpVars));
        }

        this.buildGroupBy(fragments);

        // Build Filters
        if (this.rootHavingBy != null) {
            fragments.add(' HAVING ');
            fragments.add(this.rootHavingBy.getExpression(tmpVars));
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

        for (Object selection : this.rootSelectBy.selections) {
            if (isFirst) {
                isFirst = false;
            } else {
                fragments.add(', ');
            }

            if (selection instanceof QuerySelection) {
                QuerySelection child = (QuerySelection) selection;
                fragments.add('(');
                ((Query) child.query).buildSoql(child.relation, fragments, tmpVars);
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
        Set<Integer> descendingIndexes = this.rootOrderBy.descendingIndexes;
        Set<Integer> nullsLastIndexes = this.rootOrderBy.nullsLastIndexes;
        for (Integer i = 0; i < this.rootOrderBy.fieldOrFuncs.size(); i++) {
            Object fieldOrFunc = this.rootOrderBy.fieldOrFuncs[i];
            if (isFirst) {
                fragments.add(' ORDER BY ');
            } else {
                fragments.add(', ');
            }
            isFirst = false;

            if (fieldOrFunc instanceof AggregateFunction) {
                AggregateFunction func = (AggregateFunction) fieldOrFunc;
                fragments.add(func.function);
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
        for (Object field : this.rootGroupBy.fieldOrFuncs) {
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
    }

    private class SelectByImpl implements SelectBy {
        private List<Object> selections { get; set; }

        private SelectByImpl() {
            this.selections = new List<Object>();
        }

        public SelectBy add(String field) {
            this.selections.add(field);
            return this;
        }

        public SelectBy add(String field1, String field2) {
            this.selections.add(field1);
            this.selections.add(field2);
            return this;
        }

        public SelectBy add(String field1, String field2, String field3) {
            this.selections.add(field1);
            this.selections.add(field2);
            this.selections.add(field3);
            return this;
        }

        public SelectBy add(String field1, String field2, String field3, String field4) {
            this.selections.add(field1);
            this.selections.add(field2);
            this.selections.add(field3);
            this.selections.add(field4);
            return this;
        }

        public SelectBy add(String field1, String field2, String field3, String field4, String field5) {
            this.selections.add(field1);
            this.selections.add(field2);
            this.selections.add(field3);
            this.selections.add(field4);
            this.selections.add(field5);
            return this;
        }

        public SelectBy add(SObjectField field) {
            this.selections.add(field);
            return this;
        }

        public SelectBy add(SObjectField field1, SObjectField field2) {
            this.selections.add(field1);
            this.selections.add(field2);
            return this;
        }

        public SelectBy add(SObjectField field1, SObjectField field2, SObjectField field3) {
            this.selections.add(field1);
            this.selections.add(field2);
            this.selections.add(field3);
            return this;
        }

        public SelectBy add(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            this.selections.add(field1);
            this.selections.add(field2);
            this.selections.add(field3);
            this.selections.add(field4);
            return this;
        }

        public SelectBy add(
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

        public SelectBy add(SelectFunction func) {
            this.selections.add(func);
            return this;
        }

        public SelectBy add(SelectFunction func1, SelectFunction func2) {
            this.selections.add(func1);
            this.selections.add(func2);
            return this;
        }

        public SelectBy add(SelectFunction func1, SelectFunction func2, SelectFunction func3) {
            this.selections.add(func1);
            this.selections.add(func2);
            this.selections.add(func3);
            return this;
        }

        public SelectBy add(SelectFunction func1, SelectFunction func2, SelectFunction func3, SelectFunction func4) {
            this.selections.add(func1);
            this.selections.add(func2);
            this.selections.add(func3);
            this.selections.add(func4);
            return this;
        }

        public SelectBy add(
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

        public SelectBy add(String relationName, Query query) {
            if (query != null) {
                this.selections.add(new QuerySelection(relationName, query));
            }
            return this;
        }

        public SelectBy add(List<Object> fieldOrFuncs) {
            this.selections.addAll(fieldOrFuncs);
            return this;
        }

        public SelectBy add(SelectBy other) {
            if (other != null) {
                this.selections.addAll(((SelectByImpl) other).selections);
            }
            return this;
        }
    }

    // #endregion
    // ==============

    //========================
    // #region SELECT - TYPEOF
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

    // #endregion
    //========================

    // ================
    // #region ORDER BY
    private class OrderByImpl implements OrderBy {
        private List<Object> fieldOrFuncs { get; set; }
        private Set<Integer> descendingIndexes { get; set; }
        private Set<Integer> nullsLastIndexes { get; set; }

        private Integer batchSize { get; set; }

        private OrderByImpl() {
            this.fieldOrFuncs = new List<Object>();
            this.descendingIndexes = new Set<Integer>();
            this.nullsLastIndexes = new Set<Integer>();
            this.batchSize = 0;
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

        public OrderBy ascending() {
            this.setAscending(true);
            return this;
        }

        public OrderBy descending() {
            this.setAscending(false);
            return this;
        }

        public OrderBy nullsFirst() {
            this.setNullFirst(true);
            return this;
        }

        public OrderBy nullsLast() {
            this.setNullFirst(false);
            return this;
        }

        // String
        public OrderBy add(String field) {
            this.batchSize = 1;
            this.fieldOrFuncs.add(field);
            return this;
        }

        public OrderBy add(String field1, String field2) {
            this.batchSize = 2;
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            return this;
        }

        public OrderBy add(String field1, String field2, String field3) {
            this.batchSize = 3;
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            return this;
        }

        public OrderBy add(String field1, String field2, String field3, String field4) {
            this.batchSize = 4;
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            this.fieldOrFuncs.add(field4);
            return this;
        }

        public OrderBy add(String field1, String field2, String field3, String field4, String field5) {
            this.batchSize = 5;
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            this.fieldOrFuncs.add(field4);
            this.fieldOrFuncs.add(field5);
            return this;
        }

        // SObjectField
        public OrderBy add(SObjectField field) {
            this.batchSize = 1;
            this.fieldOrFuncs.add(field);
            return this;
        }

        public OrderBy add(SObjectField field1, SObjectField field2) {
            this.batchSize = 2;
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            return this;
        }

        public OrderBy add(SObjectField field1, SObjectField field2, SObjectField field3) {
            this.batchSize = 3;
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            return this;
        }

        public OrderBy add(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            this.batchSize = 4;
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            this.fieldOrFuncs.add(field4);
            return this;
        }

        public OrderBy add(
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
        public OrderBy add(OrderFunction func) {
            this.batchSize = 1;
            this.fieldOrFuncs.add(func);
            return this;
        }

        public OrderBy add(OrderFunction func1, OrderFunction func2) {
            this.batchSize = 2;
            this.fieldOrFuncs.add(func1);
            this.fieldOrFuncs.add(func2);
            return this;
        }

        public OrderBy add(OrderFunction func1, OrderFunction func2, OrderFunction func3) {
            this.batchSize = 3;
            this.fieldOrFuncs.add(func1);
            this.fieldOrFuncs.add(func2);
            this.fieldOrFuncs.add(func3);
            return this;
        }

        public OrderBy add(OrderFunction func1, OrderFunction func2, OrderFunction func3, OrderFunction func4) {
            this.batchSize = 4;
            this.fieldOrFuncs.add(func1);
            this.fieldOrFuncs.add(func2);
            this.fieldOrFuncs.add(func3);
            this.fieldOrFuncs.add(func4);
            return this;
        }

        public OrderBy add(
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
        public OrderBy add(List<Object> fieldOrFuncs) {
            this.fieldOrFuncs.addAll(fieldOrFuncs);
            return this;
        }

        public OrderBy add(OrderBy other) {
            if (other != null) {
                this.batchSize = this.fieldOrFuncs.size();
                Set<Integer> descendingIndexes = new Set<Integer>();
                for (Integer index : ((OrderByImpl) other).descendingIndexes) {
                    descendingIndexes.add(this.batchSize + index);
                }
                Set<Integer> nullsLastIndexes = new Set<Integer>();
                for (Integer index : ((OrderByImpl) other).nullsLastIndexes) {
                    nullsLastIndexes.add(this.batchSize + index);
                }

                this.descendingIndexes.addAll(descendingIndexes);
                this.nullsLastIndexes.addAll(nullsLastIndexes);
                this.fieldOrFuncs.addAll(((OrderByImpl) other).fieldOrFuncs);
                this.batchSize = 0;
            }
            return this;
        }
    }

    // #endregion
    // ================

    // ================
    // #region GROUP BY
    private class GroupByImpl implements GroupBy {
        private List<Object> fieldOrFuncs { get; set; }

        private GroupByImpl() {
            this.fieldOrFuncs = new List<Object>();
        }

        // String
        public GroupBy add(String field) {
            this.fieldOrFuncs.add(field);
            return this;
        }

        public GroupBy add(String field1, String field2) {
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            return this;
        }

        public GroupBy add(String field1, String field2, String field3) {
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            return this;
        }

        public GroupBy add(String field1, String field2, String field3, String field4) {
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            this.fieldOrFuncs.add(field4);
            return this;
        }

        public GroupBy add(String field1, String field2, String field3, String field4, String field5) {
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            this.fieldOrFuncs.add(field4);
            this.fieldOrFuncs.add(field5);
            return this;
        }

        // SObjectField
        public GroupBy add(SObjectField field) {
            this.fieldOrFuncs.add(field);
            return this;
        }

        public GroupBy add(SObjectField field1, SObjectField field2) {
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            return this;
        }

        public GroupBy add(SObjectField field1, SObjectField field2, SObjectField field3) {
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            return this;
        }

        public GroupBy add(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            this.fieldOrFuncs.add(field1);
            this.fieldOrFuncs.add(field2);
            this.fieldOrFuncs.add(field3);
            this.fieldOrFuncs.add(field4);
            return this;
        }

        public GroupBy add(
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
        public GroupBy add(DateFunction func) {
            this.fieldOrFuncs.add(func);
            return this;
        }

        public GroupBy add(DateFunction func1, DateFunction func2) {
            this.fieldOrFuncs.add(func1);
            this.fieldOrFuncs.add(func2);
            return this;
        }

        public GroupBy add(DateFunction func1, DateFunction func2, DateFunction func3) {
            this.fieldOrFuncs.add(func1);
            this.fieldOrFuncs.add(func2);
            this.fieldOrFuncs.add(func3);
            return this;
        }

        public GroupBy add(DateFunction func1, DateFunction func2, DateFunction func3, DateFunction func4) {
            this.fieldOrFuncs.add(func1);
            this.fieldOrFuncs.add(func2);
            this.fieldOrFuncs.add(func3);
            this.fieldOrFuncs.add(func4);
            return this;
        }

        public GroupBy add(
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

        public GroupBy add(List<Object> fieldOrFuncs) {
            this.fieldOrFuncs.addAll(fieldOrFuncs);
            return this;
        }

        public GroupBy add(GroupBy other) {
            if (other != null) {
                this.fieldOrFuncs.addAll(((GroupByImpl) other).fieldOrFuncs);
            }
            return this;
        }
    }

    // #endregion
    // ================

    // ==========================
    // #region Literal | Function

    public virtual class Literal {
        public String literal { get; set; }
    }

    public class DateLiteral extends Literal {
        private DateLiteral(String literal) {
            this.literal = literal;
        }
    }

    public class CurrencyLiteral extends Literal {
        private CurrencyLiteral(String literal) {
            this.literal = literal;
        }
    }

    public interface SelectFunction {
    }

    public interface OrderFunction {
    }

    public virtual class Function {
        public String function { get; set; }
    }

    public class DateFunction extends Function implements SelectFunction {
        private DateFunction(string function) {
            this.function = function;
        }
    }

    public class TimezoneFunction extends Function {
        private TimezoneFunction(string function) {
            this.function = function;
        }
    }

    public static final String DISTANCE_UNIT_KM = 'km';
    public static final String DISTANCE_UNIT_MI = 'mi';
    public class DistanceFunction extends Function implements OrderFunction {
        private DistanceFunction(Object field, Location geo, String unit) {
            this.function =
                'DISTANCE(' +
                String.valueOf(field) +
                ', GEOLOCATION(' +
                geo.latitude +
                ', ' +
                geo.longitude +
                '), \'' +
                unit +
                '\')';
        }
    }

    public class ToLabelFunction extends Function implements SelectFunction {
        private ToLabelFunction(String function) {
            this.function = function;
        }
    }

    public class FormatFunction extends Function implements SelectFunction {
        private FormatFunction(String function) {
            this.function = function;
        }
    }

    public class CurrencyFunction extends Function implements SelectFunction {
        private CurrencyFunction(String function) {
            this.function = function;
        }
    }

    public class AggregateFunction extends Function implements SelectFunction, OrderFunction {
        private AggregateFunction(String function) {
            this.function = function;
        }
    }

    // #endregion
    // ==========================

    // ==============
    // #region Filter

    public interface Filter {
        String getExpression(Map<String, Object> tmpVars);
    }

    public interface CompositeFilter extends Filter {
        CompositeFilter add(Filter filter);
    }

    private abstract class ComparisonFilter implements Filter {
        private String expression { get; set; }
        private Object value { get; set; }

        private ComparisonFilter(Object fieldOrFunc, String operator, Object value) {
            this.expression = String.valueOf(fieldOrFunc) + operator;
            this.value = value;
        }

        public virtual String getExpression(Map<String, Object> tmpVars) {
            if (value == null) {
                return this.expression + ' NULL';
            } else if (value instanceof Literal) {
                return this.expression + ((Literal) value).literal;
            } else {
                String tmpVar = 'tmpVar' + (tmpVars.size() + 1);
                tmpVars.put(tmpVar, value);
                return this.expression + ':' + tmpVar;
            }
        }
    }

    private class EQ extends ComparisonFilter {
        private EQ(Object fieldOrFunc, Object value) {
            super(fieldOrFunc, ' = ', value);
        }
    }

    private class NE extends ComparisonFilter {
        private NE(Object fieldOrFunc, Object value) {
            super(fieldOrFunc, ' != ', value);
        }
    }
    private class GT extends ComparisonFilter {
        private GT(Object fieldOrFunc, Object value) {
            super(fieldOrFunc, ' > ', value);
        }
    }

    private class GTE extends ComparisonFilter {
        private GTE(Object fieldOrFunc, Object value) {
            super(fieldOrFunc, ' >= ', value);
        }
    }
    private class LT extends ComparisonFilter {
        private LT(Object fieldOrFunc, Object value) {
            super(fieldOrFunc, ' < ', value);
        }
    }
    private class LTE extends ComparisonFilter {
        private LTE(Object fieldOrFunc, Object value) {
            super(fieldOrFunc, ' <= ', value);
        }
    }
    private class LikeX extends ComparisonFilter {
        private LikeX(Object fieldOrFunc, String value) {
            super(fieldOrFunc, ' LIKE ', value);
        }
    }

    private class INX extends ComparisonFilter {
        private INX(Object fieldOrFunc, List<Object> values) {
            super(fieldOrFunc, ' IN ', values);
        }
    }

    private class NIN extends ComparisonFilter {
        private NIN(Object fieldOrFunc, List<Object> values) {
            super(fieldOrFunc, ' NOT IN ', values);
        }
    }

    private virtual class MultiComparisonFilter extends ComparisonFilter {
        private MultiComparisonFilter(Object field, String operator, List<String> values) {
            super(field, operator, values);
        }

        public override String getExpression(Map<String, Object> tmpVars) {
            List<String> fragments = new List<String>();
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
            return this.expression + String.join(fragments, '');
        }
    }

    private class Includes extends MultiComparisonFilter {
        private Includes(Object field, List<String> values) {
            super(field, ' INCLUDES ', values);
        }
    }

    private class Excludes extends MultiComparisonFilter {
        private Excludes(Object field, List<String> values) {
            super(field, ' EXCLUDES ', values);
        }
    }

    // TODO:
    // private virtual class INX_Query extends ComparisonFilter {
    //     private INX_Query(Object field, Boolean isNot, Query query) {
    //         super(field, isNot ? ' NOT IN ' : ' IN ', query);
    //     }

    //     public override void build(List<String> fragments, Map<String, Object> tmpVars) {
    //         if (this.value instanceof QueryImpl) {
    //             fragments.add(String.valueOf(this.fieldOrFunc));
    //             fragments.add(this.operator);
    //             fragments.add('(');
    //             ((QueryImpl) this.value).buildSoql(fragments, tmpVars);
    //             fragments.add(')');
    //         }
    //     }
    // }

    // public static Filter inx(String field, Query query) {
    //     return new INX_Query(field, false, query);
    // }

    //     public static Filter inx(SObjectField field, Query query) {
    //     return new INX_Query(field, false, query);
    // }
    //     public static Filter nin(String field, Query query) {
    //     return new INX_Query(field, true, query);
    // }

    //     public static Filter nin(SObjectField field, Query query) {
    //     return new INX_Query(field, true, query);
    // }

    private virtual class LogicalFilter implements CompositeFilter {
        private List<Filter> filters { get; set; }
        private String operator { get; set; }

        private LogicalFilter(String operator, List<Filter> filters) {
            this.operator = operator;
            this.filters = filters;
        }

        public virtual String getExpression(Map<String, Object> tmpVars) {
            if (this.filters.isEmpty()) {
                return '';
            }

            List<String> fragments = new List<String>();
            fragments.add('(');
            Integer index = 0;
            for (Filter filter : this.filters) {
                if (index > 0) {
                    fragments.add(this.operator);
                }
                fragments.add(filter.getExpression(tmpVars));
                index++;
            }
            fragments.add(')');
            return String.join(fragments, '');
        }

        public CompositeFilter add(Filter filter) {
            this.filters.add(filter);
            return this;
        }
    }

    private class NotLogicalFilter extends LogicalFilter {
        private NotLogicalFilter(Filter filter) {
            super('NOT', new List<Filter>{ filter });
        }

        public override String getExpression(Map<String, Object> tmpVars) {
            if (this.filters.size() == 0) {
                return '';
            }

            Filter filter = this.filters[0];
            if (filter instanceof CompositeFilter) {
                return 'NOT' + filter.getExpression(tmpVars);
            } else {
                return 'NOT(' + filter.getExpression(tmpVars) + ')';
            }
        }
    }

    // #endregion
    // ==============

    // ======================
    // #region NOT | OR | AND

    // Logical Statement: notx()

    public static Filter notx(Filter filter) {
        return new NotLogicalFilter(filter);
    }

    // Logical Statement: orx()

    public static CompositeFilter orx() {
        return new LogicalFilter(' OR ', new List<Filter>());
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
        return new LogicalFilter(' OR ', filters);
    }

    // Logical Statement: andx()

    public static CompositeFilter andx() {
        return new LogicalFilter(' AND ', new List<Filter>());
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
        return new LogicalFilter(' AND ', filters);
    }
    // #endregion
    // ======================

    // ===============
    // #region EQ | NE

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
        return new EQ(func.function, value);
    }
    public static Filter eq(AggregateFunction func, Id value) {
        return new EQ(func.function, value);
    }
    public static Filter eq(AggregateFunction func, Boolean value) {
        return new EQ(func.function, value);
    }
    public static Filter eq(AggregateFunction func, Decimal value) {
        return new EQ(func.function, value);
    }
    public static Filter eq(AggregateFunction func, Datetime value) {
        return new EQ(func.function, value);
    }
    public static Filter eq(AggregateFunction func, Date value) {
        return new EQ(func.function, value);
    }
    public static Filter eq(AggregateFunction func, Time value) {
        return new EQ(func.function, value);
    }
    public static Filter eq(AggregateFunction func, DateLiteral value) {
        return new EQ(func.function, value);
    }
    public static Filter eq(AggregateFunction func, CurrencyLiteral value) {
        return new EQ(func.function, value);
    }
    public static Filter eqNull(AggregateFunction func) {
        return new EQ(func.function, null);
    }

    // Comparison - EQ - Others
    public static Filter eq(DistanceFunction func, Decimal value) {
        return new EQ(func.function, value);
    }

    public static Filter eq(DateFunction func, Integer value) {
        return new EQ(func.function, value);
    }

    public static Filter eq(ToLabelFunction func, String value) {
        return new EQ(func.function, value);
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
        return new NE(func.function, value);
    }
    public static Filter ne(AggregateFunction func, Id value) {
        return new NE(func.function, value);
    }
    public static Filter ne(AggregateFunction func, Boolean value) {
        return new NE(func.function, value);
    }
    public static Filter ne(AggregateFunction func, Decimal value) {
        return new NE(func.function, value);
    }
    public static Filter ne(AggregateFunction func, Datetime value) {
        return new NE(func.function, value);
    }
    public static Filter ne(AggregateFunction func, Date value) {
        return new NE(func.function, value);
    }
    public static Filter ne(AggregateFunction func, Time value) {
        return new NE(func.function, value);
    }
    public static Filter ne(AggregateFunction func, DateLiteral value) {
        return new NE(func.function, value);
    }
    public static Filter ne(AggregateFunction func, CurrencyLiteral value) {
        return new NE(func.function, value);
    }
    public static Filter neNull(AggregateFunction func) {
        return new NE(func.function, null);
    }

    // Comparison - EQ - Others
    public static Filter ne(DistanceFunction func, Decimal value) {
        return new NE(func.function, value);
    }

    public static Filter ne(DateFunction func, Integer value) {
        return new NE(func.function, value);
    }

    public static Filter ne(ToLabelFunction func, String value) {
        return new NE(func.function, value);
    }

    // #endregion
    // ===============

    // ==========
    // #region GT
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
        return new GT(func.function, value);
    }
    public static Filter gt(AggregateFunction func, Id value) {
        return new GT(func.function, value);
    }
    public static Filter gt(AggregateFunction func, Decimal value) {
        return new GT(func.function, value);
    }
    public static Filter gt(AggregateFunction func, Datetime value) {
        return new GT(func.function, value);
    }
    public static Filter gt(AggregateFunction func, Date value) {
        return new GT(func.function, value);
    }
    public static Filter gt(AggregateFunction func, Time value) {
        return new GT(func.function, value);
    }
    public static Filter gt(AggregateFunction func, DateLiteral value) {
        return new GT(func.function, value);
    }
    public static Filter gt(AggregateFunction func, CurrencyLiteral value) {
        return new GT(func.function, value);
    }

    // Comparison - GT - Others
    public static Filter gt(DistanceFunction func, Decimal value) {
        return new GT(func.function, value);
    }

    public static Filter gt(DateFunction func, Integer value) {
        return new GT(func.function, value);
    }

    public static Filter gt(ToLabelFunction func, String value) {
        return new GT(func.function, value);
    }

    // #endregion
    // ==========

    // ===========
    // #region GTE

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
        return new GTE(func.function, value);
    }
    public static Filter gte(AggregateFunction func, Id value) {
        return new GTE(func.function, value);
    }
    public static Filter gte(AggregateFunction func, Decimal value) {
        return new GTE(func.function, value);
    }
    public static Filter gte(AggregateFunction func, Datetime value) {
        return new GTE(func.function, value);
    }
    public static Filter gte(AggregateFunction func, Date value) {
        return new GTE(func.function, value);
    }
    public static Filter gte(AggregateFunction func, Time value) {
        return new GTE(func.function, value);
    }
    public static Filter gte(AggregateFunction func, DateLiteral value) {
        return new GTE(func.function, value);
    }
    public static Filter gte(AggregateFunction func, CurrencyLiteral value) {
        return new GTE(func.function, value);
    }

    // Comparison - GTE - Others
    public static Filter gte(DistanceFunction func, Decimal value) {
        return new GTE(func.function, value);
    }

    public static Filter gte(DateFunction func, Integer value) {
        return new GTE(func.function, value);
    }

    public static Filter gte(ToLabelFunction func, String value) {
        return new GTE(func.function, value);
    }
    // #endregion
    // ===========

    // ==========
    // #region LT

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
        return new LT(func.function, value);
    }
    public static Filter lt(AggregateFunction func, Id value) {
        return new LT(func.function, value);
    }
    public static Filter lt(AggregateFunction func, Decimal value) {
        return new LT(func.function, value);
    }
    public static Filter lt(AggregateFunction func, Datetime value) {
        return new LT(func.function, value);
    }
    public static Filter lt(AggregateFunction func, Date value) {
        return new LT(func.function, value);
    }
    public static Filter lt(AggregateFunction func, Time value) {
        return new LT(func.function, value);
    }
    public static Filter lt(AggregateFunction func, DateLiteral value) {
        return new LT(func.function, value);
    }
    public static Filter lt(AggregateFunction func, CurrencyLiteral value) {
        return new LT(func.function, value);
    }

    // Comparison - LT - Others
    public static Filter lt(DistanceFunction func, Decimal value) {
        return new LT(func.function, value);
    }

    public static Filter lt(DateFunction func, Integer value) {
        return new LT(func.function, value);
    }

    public static Filter lt(ToLabelFunction func, String value) {
        return new LT(func.function, value);
    }
    // #endregion
    // ==========

    // ===========
    // #region LTE

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
        return new LTE(func.function, value);
    }
    public static Filter lte(AggregateFunction func, Id value) {
        return new LTE(func.function, value);
    }
    public static Filter lte(AggregateFunction func, Decimal value) {
        return new LTE(func.function, value);
    }
    public static Filter lte(AggregateFunction func, Datetime value) {
        return new LTE(func.function, value);
    }
    public static Filter lte(AggregateFunction func, Date value) {
        return new LTE(func.function, value);
    }
    public static Filter lte(AggregateFunction func, Time value) {
        return new LTE(func.function, value);
    }
    public static Filter lte(AggregateFunction func, DateLiteral value) {
        return new LTE(func.function, value);
    }
    public static Filter lte(AggregateFunction func, CurrencyLiteral value) {
        return new LTE(func.function, value);
    }

    // Comparison - LTE - Others
    public static Filter lte(DistanceFunction func, Decimal value) {
        return new LTE(func.function, value);
    }

    public static Filter lte(DateFunction func, Integer value) {
        return new LTE(func.function, value);
    }

    public static Filter lte(ToLabelFunction func, String value) {
        return new LTE(func.function, value);
    }
    // #endregion
    // ===========

    // ===============
    // #region BETWEEN
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
    // ===============

    // =======================
    // #region LIKE | NOT LIKE
    public static Filter likex(String field, String value) {
        return new LikeX(field, value);
    }
    public static Filter likex(SObjectField field, String value) {
        return new LikeX(field, value);
    }
    public static Filter likex(AggregateFunction func, String value) {
        return new LikeX(func.function, value);
    }
    public static Filter likex(ToLabelFunction func, String value) {
        return new LikeX(func.function, value);
    }

    public static Filter nlike(String field, String value) {
        return notx(new LikeX(field, value));
    }
    public static Filter nlike(SObjectField field, String value) {
        return notx(new LikeX(field, value));
    }
    public static Filter nlike(AggregateFunction func, String value) {
        return notx(new LikeX(func.function, value));
    }
    public static Filter nlike(ToLabelFunction func, String value) {
        return notx(new LikeX(func.function, value));
    }
    // #endregion
    // =======================

    // ===========================
    // #region INCLUDES | EXCLUDES

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

    // #endregion
    // ===========================

    // =================
    // #region INX | NIN

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

    // Comparison - INX - AggregateFunction
    public static Filter inx(AggregateFunction func, List<String> values) {
        return new INX(func.function, values);
    }
    public static Filter inx(AggregateFunction func, List<Id> values) {
        return new INX(func.function, values);
    }
    public static Filter inx(AggregateFunction func, List<SObject> values) {
        return new INX(func.function, values);
    }
    public static Filter inx(AggregateFunction func, List<Boolean> values) {
        return new INX(func.function, values);
    }
    public static Filter inx(AggregateFunction func, List<Decimal> values) {
        return new INX(func.function, values);
    }
    public static Filter inx(AggregateFunction func, List<Datetime> values) {
        return new INX(func.function, values);
    }
    public static Filter inx(AggregateFunction func, List<Date> values) {
        return new INX(func.function, values);
    }
    public static Filter inx(AggregateFunction func, List<Time> values) {
        return new INX(func.function, values);
    }
    public static Filter inx(AggregateFunction func, List<DateLiteral> values) {
        return new INX(func.function, values);
    }
    public static Filter inx(AggregateFunction func, List<CurrencyLiteral> values) {
        return new INX(func.function, values);
    }

    // Comparison - INX - Others
    public static Filter inx(DistanceFunction func, List<Decimal> values) {
        return new INX(func.function, values);
    }

    public static Filter inx(DateFunction func, List<Integer> values) {
        return new INX(func.function, values);
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

    // Comparison - NIN - AggregateFunction
    public static Filter nin(AggregateFunction func, List<String> values) {
        return new NIN(func.function, values);
    }
    public static Filter nin(AggregateFunction func, List<Id> values) {
        return new NIN(func.function, values);
    }
    public static Filter nin(AggregateFunction func, List<SObject> values) {
        return new NIN(func.function, values);
    }
    public static Filter nin(AggregateFunction func, List<Boolean> values) {
        return new NIN(func.function, values);
    }
    public static Filter nin(AggregateFunction func, List<Decimal> values) {
        return new NIN(func.function, values);
    }
    public static Filter nin(AggregateFunction func, List<Datetime> values) {
        return new NIN(func.function, values);
    }
    public static Filter nin(AggregateFunction func, List<Date> values) {
        return new NIN(func.function, values);
    }
    public static Filter nin(AggregateFunction func, List<Time> values) {
        return new NIN(func.function, values);
    }
    public static Filter nin(AggregateFunction func, List<DateLiteral> values) {
        return new NIN(func.function, values);
    }
    public static Filter nin(AggregateFunction func, List<CurrencyLiteral> values) {
        return new NIN(func.function, values);
    }

    // Comparison - NIN - Others
    public static Filter nin(DistanceFunction func, List<Decimal> values) {
        return new NIN(func.function, values);
    }

    public static Filter nin(DateFunction func, List<Integer> values) {
        return new NIN(func.function, values);
    }

    // #endregion
    // =================

    // ===================
    // #region Aggregation

    // SObjectField
    public static AggregateFunction GROUPING(String field) {
        return new AggregateFunction('GROUPING(' + field + ')');
    }

    public static AggregateFunction GROUPING(String field, String alias) {
        return new AggregateFunction('GROUPING(' + field + ') ' + alias);
    }

    public static AggregateFunction COUNT(String field) {
        return new AggregateFunction('COUNT(' + field + ')');
    }

    public static AggregateFunction COUNT(String field, String alias) {
        return new AggregateFunction('COUNT(' + field + ') ' + alias);
    }

    public static AggregateFunction COUNT_DISTINCT(String field) {
        return new AggregateFunction('COUNT_DISTINCT(' + field + ')');
    }

    public static AggregateFunction COUNT_DISTINCT(String field, String alias) {
        return new AggregateFunction('COUNT_DISTINCT(' + field + ') ' + alias);
    }

    public static AggregateFunction SUM(String field) {
        return new AggregateFunction('SUM(' + field + ')');
    }

    public static AggregateFunction SUM(String field, String alias) {
        return new AggregateFunction('SUM(' + field + ') ' + alias);
    }

    public static AggregateFunction AVG(String field) {
        return new AggregateFunction('AVG(' + field + ')');
    }

    public static AggregateFunction AVG(String field, String alias) {
        return new AggregateFunction('AVG(' + field + ') ' + alias);
    }

    public static AggregateFunction MAX(String field) {
        return new AggregateFunction('MAX(' + field + ')');
    }

    public static AggregateFunction MAX(String field, String alias) {
        return new AggregateFunction('MAX(' + field + ') ' + alias);
    }

    public static AggregateFunction MIN(String field) {
        return new AggregateFunction('MIN(' + field + ')');
    }

    public static AggregateFunction MIN(String field, String alias) {
        return new AggregateFunction('MIN(' + field + ') ' + alias);
    }

    // SObjectField
    public static AggregateFunction GROUPING(SObjectField field) {
        return new AggregateFunction('GROUPING(' + field + ')');
    }

    public static AggregateFunction GROUPING(SObjectField field, String alias) {
        return new AggregateFunction('GROUPING(' + field + ') ' + alias);
    }

    public static AggregateFunction COUNT(SObjectField field) {
        return new AggregateFunction('COUNT(' + field + ')');
    }

    public static AggregateFunction COUNT(SObjectField field, String alias) {
        return new AggregateFunction('COUNT(' + field + ') ' + alias);
    }

    public static AggregateFunction COUNT_DISTINCT(SObjectField field) {
        return new AggregateFunction('COUNT_DISTINCT(' + field + ')');
    }

    public static AggregateFunction COUNT_DISTINCT(SObjectField field, String alias) {
        return new AggregateFunction('COUNT_DISTINCT(' + field + ') ' + alias);
    }

    public static AggregateFunction SUM(SObjectField field) {
        return new AggregateFunction('SUM(' + field + ')');
    }

    public static AggregateFunction SUM(SObjectField field, String alias) {
        return new AggregateFunction('SUM(' + field + ') ' + alias);
    }

    public static AggregateFunction AVG(SObjectField field) {
        return new AggregateFunction('AVG(' + field + ')');
    }

    public static AggregateFunction AVG(SObjectField field, String alias) {
        return new AggregateFunction('AVG(' + field + ') ' + alias);
    }

    public static AggregateFunction MAX(SObjectField field) {
        return new AggregateFunction('MAX(' + field + ')');
    }

    public static AggregateFunction MAX(SObjectField field, String alias) {
        return new AggregateFunction('MAX(' + field + ') ' + alias);
    }

    public static AggregateFunction MIN(SObjectField field) {
        return new AggregateFunction('MIN(' + field + ')');
    }

    public static AggregateFunction MIN(SObjectField field, String alias) {
        return new AggregateFunction('MIN(' + field + ') ' + alias);
    }

    // Others
    public static SelectFunction COUNT() {
        return new AggregateFunction('COUNT()');
    }

    // #endregion
    // ===================

    // ========================
    // #region ToLabel | Format
    public static ToLabelFunction TO_LABEL(String field) {
        return new ToLabelFunction('TOLABEL(' + field + ')');
    }

    public static ToLabelFunction TO_LABEL(SObjectField field) {
        return new ToLabelFunction('TOLABEL(' + field + ')');
    }

    public static FormatFunction FORMAT(String field) {
        return new FormatFunction('FORMAT(' + field + ')');
    }

    public static FormatFunction FORMAT(SObjectField field) {
        return new FormatFunction('FORMAT(' + field + ')');
    }

    public static FormatFunction FORMAT(CurrencyFunction func) {
        return new FormatFunction('FORMAT(' + func.function + ')');
    }

    public static CurrencyFunction CONVERT_CURRENCY(String field) {
        return new CurrencyFunction('CONVERTCURRENCY(' + field + ')');
    }

    public static CurrencyFunction CONVERT_CURRENCY(SObjectField field) {
        return new CurrencyFunction('CONVERTCURRENCY(' + field + ')');
    }
    // #endregion
    // ========================

    // =========================
    // #region Distance Function

    public static DistanceFunction DISTANCE(String field, Location geo, string unit) {
        return new DistanceFunction(field, geo, unit);
    }
    public static DistanceFunction DISTANCE(SObjectField field, Location geo, string unit) {
        return new DistanceFunction(field, geo, unit);
    }

    // #endregion
    // =========================

    // =======================
    // #region Date Function

    public static TimezoneFunction CONVERT_TIMEZONE(String field) {
        return new TimezoneFunction('CONVERTTIMEZONE(' + field + ')');
    }

    public static TimezoneFunction CONVERT_TIMEZONE(SObjectField field) {
        return new TimezoneFunction('CONVERTTIMEZONE(' + field + ')');
    }

    // DateFunction - String
    public static DateFunction CALENDAR_MONTH(String field) {
        return new DateFunction('CALENDAR_MONTH(' + field + ')');
    }

    public static DateFunction CALENDAR_QUARTER(String field) {
        return new DateFunction('CALENDAR_QUARTER(' + field + ')');
    }

    public static DateFunction CALENDAR_YEAR(String field) {
        return new DateFunction('CALENDAR_YEAR(' + field + ')');
    }

    public static DateFunction DAY_IN_MONTH(String field) {
        return new DateFunction('DAY_IN_MONTH(' + field + ')');
    }

    public static DateFunction DAY_IN_WEEK(String field) {
        return new DateFunction('DAY_IN_WEEK(' + field + ')');
    }

    public static DateFunction DAY_IN_YEAR(String field) {
        return new DateFunction('DAY_IN_YEAR(' + field + ')');
    }

    public static DateFunction DAY_ONLY(String field) {
        return new DateFunction('DAY_ONLY(' + field + ')');
    }

    public static DateFunction FISCAL_MONTH(String field) {
        return new DateFunction('FISCAL_MONTH(' + field + ')');
    }

    public static DateFunction FISCAL_QUARTER(String field) {
        return new DateFunction('FISCAL_QUARTER(' + field + ')');
    }

    public static DateFunction FISCAL_YEAR(String field) {
        return new DateFunction('FISCAL_YEAR(' + field + ')');
    }

    public static DateFunction HOUR_IN_DAY(String field) {
        return new DateFunction('HOUR_IN_DAY(' + field + ')');
    }

    public static DateFunction WEEK_IN_MONTH(String field) {
        return new DateFunction('WEEK_IN_MONTH(' + field + ')');
    }

    public static DateFunction WEEK_IN_YEAR(String field) {
        return new DateFunction('WEEK_IN_YEAR(' + field + ')');
    }

    // DateFunction - SObjectField
    public static DateFunction CALENDAR_MONTH(SObjectField field) {
        return new DateFunction('CALENDAR_MONTH(' + field + ')');
    }

    public static DateFunction CALENDAR_QUARTER(SObjectField field) {
        return new DateFunction('CALENDAR_QUARTER(' + field + ')');
    }

    public static DateFunction CALENDAR_YEAR(SObjectField field) {
        return new DateFunction('CALENDAR_YEAR(' + field + ')');
    }

    public static DateFunction DAY_IN_MONTH(SObjectField field) {
        return new DateFunction('DAY_IN_MONTH(' + field + ')');
    }

    public static DateFunction DAY_IN_WEEK(SObjectField field) {
        return new DateFunction('DAY_IN_WEEK(' + field + ')');
    }

    public static DateFunction DAY_IN_YEAR(SObjectField field) {
        return new DateFunction('DAY_IN_YEAR(' + field + ')');
    }

    public static DateFunction DAY_ONLY(SObjectField field) {
        return new DateFunction('DAY_ONLY(' + field + ')');
    }

    public static DateFunction FISCAL_MONTH(SObjectField field) {
        return new DateFunction('FISCAL_MONTH(' + field + ')');
    }

    public static DateFunction FISCAL_QUARTER(SObjectField field) {
        return new DateFunction('FISCAL_QUARTER(' + field + ')');
    }

    public static DateFunction FISCAL_YEAR(SObjectField field) {
        return new DateFunction('FISCAL_YEAR(' + field + ')');
    }

    public static DateFunction HOUR_IN_DAY(SObjectField field) {
        return new DateFunction('HOUR_IN_DAY(' + field + ')');
    }

    public static DateFunction WEEK_IN_MONTH(SObjectField field) {
        return new DateFunction('WEEK_IN_MONTH(' + field + ')');
    }

    public static DateFunction WEEK_IN_YEAR(SObjectField field) {
        return new DateFunction('WEEK_IN_YEAR(' + field + ')');
    }

    // DateFunction - TimezoneFunction
    public static DateFunction CALENDAR_MONTH(TimezoneFunction func) {
        return new DateFunction('CALENDAR_MONTH(' + func + ')');
    }

    public static DateFunction CALENDAR_QUARTER(TimezoneFunction func) {
        return new DateFunction('CALENDAR_QUARTER(' + func + ')');
    }

    public static DateFunction CALENDAR_YEAR(TimezoneFunction func) {
        return new DateFunction('CALENDAR_YEAR(' + func + ')');
    }

    public static DateFunction DAY_IN_MONTH(TimezoneFunction func) {
        return new DateFunction('DAY_IN_MONTH(' + func + ')');
    }

    public static DateFunction DAY_IN_WEEK(TimezoneFunction func) {
        return new DateFunction('DAY_IN_WEEK(' + func + ')');
    }

    public static DateFunction DAY_IN_YEAR(TimezoneFunction func) {
        return new DateFunction('DAY_IN_YEAR(' + func + ')');
    }

    public static DateFunction DAY_ONLY(TimezoneFunction func) {
        return new DateFunction('DAY_ONLY(' + func + ')');
    }

    public static DateFunction FISCAL_MONTH(TimezoneFunction func) {
        return new DateFunction('FISCAL_MONTH(' + func + ')');
    }

    public static DateFunction FISCAL_QUARTER(TimezoneFunction func) {
        return new DateFunction('FISCAL_QUARTER(' + func + ')');
    }

    public static DateFunction FISCAL_YEAR(TimezoneFunction func) {
        return new DateFunction('FISCAL_YEAR(' + func + ')');
    }

    public static DateFunction HOUR_IN_DAY(TimezoneFunction func) {
        return new DateFunction('HOUR_IN_DAY(' + func + ')');
    }

    public static DateFunction WEEK_IN_MONTH(TimezoneFunction func) {
        return new DateFunction('WEEK_IN_MONTH(' + func + ')');
    }

    public static DateFunction WEEK_IN_YEAR(TimezoneFunction func) {
        return new DateFunction('WEEK_IN_YEAR(' + func + ')');
    }

    // #endregion
    // =======================

    // ========================
    // #region Currency Literal
    public static CurrencyLiteral CURRENCY(String code, Decimal value) {
        return new CurrencyLiteral(code + value);
    }

    public static CurrencyLiteral AED(Decimal value) {
        return new CurrencyLiteral('AED' + value);
    }

    public static CurrencyLiteral AFN(Decimal value) {
        return new CurrencyLiteral('AFN' + value);
    }

    public static CurrencyLiteral ALL(Decimal value) {
        return new CurrencyLiteral('ALL' + value);
    }

    public static CurrencyLiteral AMD(Decimal value) {
        return new CurrencyLiteral('AMD' + value);
    }

    public static CurrencyLiteral ANG(Decimal value) {
        return new CurrencyLiteral('ANG' + value);
    }

    public static CurrencyLiteral AOA(Decimal value) {
        return new CurrencyLiteral('AOA' + value);
    }

    public static CurrencyLiteral ARS(Decimal value) {
        return new CurrencyLiteral('ARS' + value);
    }

    public static CurrencyLiteral AUD(Decimal value) {
        return new CurrencyLiteral('AUD' + value);
    }

    public static CurrencyLiteral AWG(Decimal value) {
        return new CurrencyLiteral('AWG' + value);
    }

    public static CurrencyLiteral AZN(Decimal value) {
        return new CurrencyLiteral('AZN' + value);
    }

    public static CurrencyLiteral BAM(Decimal value) {
        return new CurrencyLiteral('BAM' + value);
    }

    public static CurrencyLiteral BBD(Decimal value) {
        return new CurrencyLiteral('BBD' + value);
    }

    public static CurrencyLiteral BDT(Decimal value) {
        return new CurrencyLiteral('BDT' + value);
    }

    public static CurrencyLiteral BGN(Decimal value) {
        return new CurrencyLiteral('BGN' + value);
    }

    public static CurrencyLiteral BHD(Decimal value) {
        return new CurrencyLiteral('BHD' + value);
    }

    public static CurrencyLiteral BIF(Decimal value) {
        return new CurrencyLiteral('BIF' + value);
    }

    public static CurrencyLiteral BMD(Decimal value) {
        return new CurrencyLiteral('BMD' + value);
    }

    public static CurrencyLiteral BND(Decimal value) {
        return new CurrencyLiteral('BND' + value);
    }

    public static CurrencyLiteral BOB(Decimal value) {
        return new CurrencyLiteral('BOB' + value);
    }

    public static CurrencyLiteral BRL(Decimal value) {
        return new CurrencyLiteral('BRL' + value);
    }

    public static CurrencyLiteral BSD(Decimal value) {
        return new CurrencyLiteral('BSD' + value);
    }

    public static CurrencyLiteral BTN(Decimal value) {
        return new CurrencyLiteral('BTN' + value);
    }

    public static CurrencyLiteral BWP(Decimal value) {
        return new CurrencyLiteral('BWP' + value);
    }

    public static CurrencyLiteral BYN(Decimal value) {
        return new CurrencyLiteral('BYN' + value);
    }

    public static CurrencyLiteral BZD(Decimal value) {
        return new CurrencyLiteral('BZD' + value);
    }

    public static CurrencyLiteral CAD(Decimal value) {
        return new CurrencyLiteral('CAD' + value);
    }

    public static CurrencyLiteral CDF(Decimal value) {
        return new CurrencyLiteral('CDF' + value);
    }

    public static CurrencyLiteral CHF(Decimal value) {
        return new CurrencyLiteral('CHF' + value);
    }

    public static CurrencyLiteral CLP(Decimal value) {
        return new CurrencyLiteral('CLP' + value);
    }

    public static CurrencyLiteral CNY(Decimal value) {
        return new CurrencyLiteral('CNY' + value);
    }

    public static CurrencyLiteral COP(Decimal value) {
        return new CurrencyLiteral('COP' + value);
    }

    public static CurrencyLiteral CRC(Decimal value) {
        return new CurrencyLiteral('CRC' + value);
    }

    public static CurrencyLiteral CSD(Decimal value) {
        return new CurrencyLiteral('CSD' + value);
    }

    public static CurrencyLiteral CUP(Decimal value) {
        return new CurrencyLiteral('CUP' + value);
    }

    public static CurrencyLiteral CVE(Decimal value) {
        return new CurrencyLiteral('CVE' + value);
    }

    public static CurrencyLiteral CZK(Decimal value) {
        return new CurrencyLiteral('CZK' + value);
    }

    public static CurrencyLiteral DJF(Decimal value) {
        return new CurrencyLiteral('DJF' + value);
    }

    public static CurrencyLiteral DKK(Decimal value) {
        return new CurrencyLiteral('DKK' + value);
    }

    public static CurrencyLiteral DOP(Decimal value) {
        return new CurrencyLiteral('DOP' + value);
    }

    public static CurrencyLiteral DZD(Decimal value) {
        return new CurrencyLiteral('DZD' + value);
    }

    public static CurrencyLiteral EGP(Decimal value) {
        return new CurrencyLiteral('EGP' + value);
    }

    public static CurrencyLiteral ERN(Decimal value) {
        return new CurrencyLiteral('ERN' + value);
    }

    public static CurrencyLiteral ETB(Decimal value) {
        return new CurrencyLiteral('ETB' + value);
    }

    public static CurrencyLiteral EUR(Decimal value) {
        return new CurrencyLiteral('EUR' + value);
    }

    public static CurrencyLiteral FJD(Decimal value) {
        return new CurrencyLiteral('FJD' + value);
    }

    public static CurrencyLiteral FKP(Decimal value) {
        return new CurrencyLiteral('FKP' + value);
    }

    public static CurrencyLiteral GBP(Decimal value) {
        return new CurrencyLiteral('GBP' + value);
    }

    public static CurrencyLiteral GEL(Decimal value) {
        return new CurrencyLiteral('GEL' + value);
    }

    public static CurrencyLiteral GHS(Decimal value) {
        return new CurrencyLiteral('GHS' + value);
    }

    public static CurrencyLiteral GIP(Decimal value) {
        return new CurrencyLiteral('GIP' + value);
    }

    public static CurrencyLiteral GMD(Decimal value) {
        return new CurrencyLiteral('GMD' + value);
    }

    public static CurrencyLiteral GNF(Decimal value) {
        return new CurrencyLiteral('GNF' + value);
    }

    public static CurrencyLiteral GTQ(Decimal value) {
        return new CurrencyLiteral('GTQ' + value);
    }

    public static CurrencyLiteral GYD(Decimal value) {
        return new CurrencyLiteral('GYD' + value);
    }

    public static CurrencyLiteral HKD(Decimal value) {
        return new CurrencyLiteral('HKD' + value);
    }

    public static CurrencyLiteral HNL(Decimal value) {
        return new CurrencyLiteral('HNL' + value);
    }

    public static CurrencyLiteral HRK(Decimal value) {
        return new CurrencyLiteral('HRK' + value);
    }

    public static CurrencyLiteral HTG(Decimal value) {
        return new CurrencyLiteral('HTG' + value);
    }

    public static CurrencyLiteral HUF(Decimal value) {
        return new CurrencyLiteral('HUF' + value);
    }

    public static CurrencyLiteral IDR(Decimal value) {
        return new CurrencyLiteral('IDR' + value);
    }

    public static CurrencyLiteral ILS(Decimal value) {
        return new CurrencyLiteral('ILS' + value);
    }

    public static CurrencyLiteral INR(Decimal value) {
        return new CurrencyLiteral('INR' + value);
    }

    public static CurrencyLiteral IQD(Decimal value) {
        return new CurrencyLiteral('IQD' + value);
    }

    public static CurrencyLiteral IRR(Decimal value) {
        return new CurrencyLiteral('IRR' + value);
    }

    public static CurrencyLiteral ISK(Decimal value) {
        return new CurrencyLiteral('ISK' + value);
    }

    public static CurrencyLiteral JMD(Decimal value) {
        return new CurrencyLiteral('JMD' + value);
    }

    public static CurrencyLiteral JOD(Decimal value) {
        return new CurrencyLiteral('JOD' + value);
    }

    public static CurrencyLiteral JPY(Decimal value) {
        return new CurrencyLiteral('JPY' + value);
    }

    public static CurrencyLiteral KES(Decimal value) {
        return new CurrencyLiteral('KES' + value);
    }

    public static CurrencyLiteral KGS(Decimal value) {
        return new CurrencyLiteral('KGS' + value);
    }

    public static CurrencyLiteral KHR(Decimal value) {
        return new CurrencyLiteral('KHR' + value);
    }

    public static CurrencyLiteral KMF(Decimal value) {
        return new CurrencyLiteral('KMF' + value);
    }

    public static CurrencyLiteral KPW(Decimal value) {
        return new CurrencyLiteral('KPW' + value);
    }

    public static CurrencyLiteral KRW(Decimal value) {
        return new CurrencyLiteral('KRW' + value);
    }

    public static CurrencyLiteral KWD(Decimal value) {
        return new CurrencyLiteral('KWD' + value);
    }

    public static CurrencyLiteral KYD(Decimal value) {
        return new CurrencyLiteral('KYD' + value);
    }

    public static CurrencyLiteral KZT(Decimal value) {
        return new CurrencyLiteral('KZT' + value);
    }

    public static CurrencyLiteral LAK(Decimal value) {
        return new CurrencyLiteral('LAK' + value);
    }

    public static CurrencyLiteral LBP(Decimal value) {
        return new CurrencyLiteral('LBP' + value);
    }

    public static CurrencyLiteral LKR(Decimal value) {
        return new CurrencyLiteral('LKR' + value);
    }

    public static CurrencyLiteral LRD(Decimal value) {
        return new CurrencyLiteral('LRD' + value);
    }

    public static CurrencyLiteral LYD(Decimal value) {
        return new CurrencyLiteral('LYD' + value);
    }

    public static CurrencyLiteral MAD(Decimal value) {
        return new CurrencyLiteral('MAD' + value);
    }

    public static CurrencyLiteral MDL(Decimal value) {
        return new CurrencyLiteral('MDL' + value);
    }

    public static CurrencyLiteral MGA(Decimal value) {
        return new CurrencyLiteral('MGA' + value);
    }

    public static CurrencyLiteral MKD(Decimal value) {
        return new CurrencyLiteral('MKD' + value);
    }

    public static CurrencyLiteral MMK(Decimal value) {
        return new CurrencyLiteral('MMK' + value);
    }

    public static CurrencyLiteral MOP(Decimal value) {
        return new CurrencyLiteral('MOP' + value);
    }

    public static CurrencyLiteral MRU(Decimal value) {
        return new CurrencyLiteral('MRU' + value);
    }

    public static CurrencyLiteral MUR(Decimal value) {
        return new CurrencyLiteral('MUR' + value);
    }

    public static CurrencyLiteral MWK(Decimal value) {
        return new CurrencyLiteral('MWK' + value);
    }

    public static CurrencyLiteral MXN(Decimal value) {
        return new CurrencyLiteral('MXN' + value);
    }

    public static CurrencyLiteral MYR(Decimal value) {
        return new CurrencyLiteral('MYR' + value);
    }

    public static CurrencyLiteral MZN(Decimal value) {
        return new CurrencyLiteral('MZN' + value);
    }

    public static CurrencyLiteral NAD(Decimal value) {
        return new CurrencyLiteral('NAD' + value);
    }

    public static CurrencyLiteral NGN(Decimal value) {
        return new CurrencyLiteral('NGN' + value);
    }

    public static CurrencyLiteral NIO(Decimal value) {
        return new CurrencyLiteral('NIO' + value);
    }

    public static CurrencyLiteral NOK(Decimal value) {
        return new CurrencyLiteral('NOK' + value);
    }

    public static CurrencyLiteral NPR(Decimal value) {
        return new CurrencyLiteral('NPR' + value);
    }

    public static CurrencyLiteral NZD(Decimal value) {
        return new CurrencyLiteral('NZD' + value);
    }

    public static CurrencyLiteral OMR(Decimal value) {
        return new CurrencyLiteral('OMR' + value);
    }

    public static CurrencyLiteral PAB(Decimal value) {
        return new CurrencyLiteral('PAB' + value);
    }

    public static CurrencyLiteral PEN(Decimal value) {
        return new CurrencyLiteral('PEN' + value);
    }

    public static CurrencyLiteral PGK(Decimal value) {
        return new CurrencyLiteral('PGK' + value);
    }

    public static CurrencyLiteral PHP(Decimal value) {
        return new CurrencyLiteral('PHP' + value);
    }

    public static CurrencyLiteral PKR(Decimal value) {
        return new CurrencyLiteral('PKR' + value);
    }

    public static CurrencyLiteral PLN(Decimal value) {
        return new CurrencyLiteral('PLN' + value);
    }

    public static CurrencyLiteral PYG(Decimal value) {
        return new CurrencyLiteral('PYG' + value);
    }

    public static CurrencyLiteral QAR(Decimal value) {
        return new CurrencyLiteral('QAR' + value);
    }

    public static CurrencyLiteral RON(Decimal value) {
        return new CurrencyLiteral('RON' + value);
    }

    public static CurrencyLiteral RSD(Decimal value) {
        return new CurrencyLiteral('RSD' + value);
    }

    public static CurrencyLiteral RUB(Decimal value) {
        return new CurrencyLiteral('RUB' + value);
    }

    public static CurrencyLiteral RWF(Decimal value) {
        return new CurrencyLiteral('RWF' + value);
    }

    public static CurrencyLiteral SAR(Decimal value) {
        return new CurrencyLiteral('SAR' + value);
    }

    public static CurrencyLiteral SBD(Decimal value) {
        return new CurrencyLiteral('SBD' + value);
    }

    public static CurrencyLiteral SCR(Decimal value) {
        return new CurrencyLiteral('SCR' + value);
    }

    public static CurrencyLiteral SDG(Decimal value) {
        return new CurrencyLiteral('SDG' + value);
    }

    public static CurrencyLiteral SEK(Decimal value) {
        return new CurrencyLiteral('SEK' + value);
    }

    public static CurrencyLiteral SGD(Decimal value) {
        return new CurrencyLiteral('SGD' + value);
    }

    public static CurrencyLiteral SHP(Decimal value) {
        return new CurrencyLiteral('SHP' + value);
    }

    public static CurrencyLiteral SLE(Decimal value) {
        return new CurrencyLiteral('SLE' + value);
    }

    public static CurrencyLiteral SLL(Decimal value) {
        return new CurrencyLiteral('SLL' + value);
    }

    public static CurrencyLiteral SOS(Decimal value) {
        return new CurrencyLiteral('SOS' + value);
    }

    public static CurrencyLiteral SRD(Decimal value) {
        return new CurrencyLiteral('SRD' + value);
    }

    public static CurrencyLiteral STN(Decimal value) {
        return new CurrencyLiteral('STN' + value);
    }

    public static CurrencyLiteral SYP(Decimal value) {
        return new CurrencyLiteral('SYP' + value);
    }

    public static CurrencyLiteral SZL(Decimal value) {
        return new CurrencyLiteral('SZL' + value);
    }

    public static CurrencyLiteral THB(Decimal value) {
        return new CurrencyLiteral('THB' + value);
    }

    public static CurrencyLiteral TJS(Decimal value) {
        return new CurrencyLiteral('TJS' + value);
    }

    public static CurrencyLiteral TND(Decimal value) {
        return new CurrencyLiteral('TND' + value);
    }

    public static CurrencyLiteral TOP(Decimal value) {
        return new CurrencyLiteral('TOP' + value);
    }

    // !TRY is a keywork
    // public static CurrencyLiteral TRY(Decimal value) {
    //     return new CurrencyLiteral('TRY' + value);
    // }

    public static CurrencyLiteral TTD(Decimal value) {
        return new CurrencyLiteral('TTD' + value);
    }

    public static CurrencyLiteral TWD(Decimal value) {
        return new CurrencyLiteral('TWD' + value);
    }

    public static CurrencyLiteral TZS(Decimal value) {
        return new CurrencyLiteral('TZS' + value);
    }

    public static CurrencyLiteral UAH(Decimal value) {
        return new CurrencyLiteral('UAH' + value);
    }

    public static CurrencyLiteral UGX(Decimal value) {
        return new CurrencyLiteral('UGX' + value);
    }

    public static CurrencyLiteral USD(Decimal value) {
        return new CurrencyLiteral('USD' + value);
    }

    public static CurrencyLiteral UYU(Decimal value) {
        return new CurrencyLiteral('UYU' + value);
    }

    public static CurrencyLiteral UZS(Decimal value) {
        return new CurrencyLiteral('UZS' + value);
    }

    public static CurrencyLiteral VES(Decimal value) {
        return new CurrencyLiteral('VES' + value);
    }

    public static CurrencyLiteral VND(Decimal value) {
        return new CurrencyLiteral('VND' + value);
    }

    public static CurrencyLiteral VUV(Decimal value) {
        return new CurrencyLiteral('VUV' + value);
    }

    public static CurrencyLiteral WST(Decimal value) {
        return new CurrencyLiteral('WST' + value);
    }

    public static CurrencyLiteral XAF(Decimal value) {
        return new CurrencyLiteral('XAF' + value);
    }

    public static CurrencyLiteral XCD(Decimal value) {
        return new CurrencyLiteral('XCD' + value);
    }

    public static CurrencyLiteral XOF(Decimal value) {
        return new CurrencyLiteral('XOF' + value);
    }

    public static CurrencyLiteral XPF(Decimal value) {
        return new CurrencyLiteral('XPF' + value);
    }

    public static CurrencyLiteral YER(Decimal value) {
        return new CurrencyLiteral('YER' + value);
    }

    public static CurrencyLiteral ZAR(Decimal value) {
        return new CurrencyLiteral('ZAR' + value);
    }

    // #endregion
    // ========================

    // ====================
    // #region Date Literal
    public static DateLiteral YESTERDAY() {
        return new DateLiteral('YESTERDAY');
    }

    public static DateLiteral TODAY() {
        return new DateLiteral('TODAY');
    }

    public static DateLiteral TOMORROW() {
        return new DateLiteral('TOMORROW');
    }

    public static DateLiteral LAST_WEEK() {
        return new DateLiteral('LAST_WEEK');
    }

    public static DateLiteral THIS_WEEK() {
        return new DateLiteral('THIS_WEEK');
    }

    public static DateLiteral NEXT_WEEK() {
        return new DateLiteral('NEXT_WEEK');
    }

    public static DateLiteral LAST_MONTH() {
        return new DateLiteral('LAST_MONTH');
    }

    public static DateLiteral THIS_MONTH() {
        return new DateLiteral('THIS_MONTH');
    }

    public static DateLiteral NEXT_MONTH() {
        return new DateLiteral('NEXT_MONTH');
    }

    public static DateLiteral LAST_90_DAYS() {
        return new DateLiteral('LAST_90_DAYS');
    }

    public static DateLiteral NEXT_90_DAYS() {
        return new DateLiteral('NEXT_90_DAYS');
    }

    public static DateLiteral THIS_QUARTER() {
        return new DateLiteral('THIS_QUARTER');
    }

    public static DateLiteral LAST_QUARTER() {
        return new DateLiteral('LAST_QUARTER');
    }

    public static DateLiteral NEXT_QUARTER() {
        return new DateLiteral('NEXT_QUARTER');
    }

    public static DateLiteral THIS_YEAR() {
        return new DateLiteral('THIS_YEAR');
    }

    public static DateLiteral LAST_YEAR() {
        return new DateLiteral('LAST_YEAR');
    }

    public static DateLiteral NEXT_YEAR() {
        return new DateLiteral('NEXT_YEAR');
    }

    public static DateLiteral THIS_FISCAL_QUARTER() {
        return new DateLiteral('THIS_FISCAL_QUARTER');
    }

    public static DateLiteral LAST_FISCAL_QUARTER() {
        return new DateLiteral('LAST_FISCAL_QUARTER');
    }

    public static DateLiteral NEXT_FISCAL_QUARTER() {
        return new DateLiteral('NEXT_FISCAL_QUARTER');
    }

    public static DateLiteral THIS_FISCAL_YEAR() {
        return new DateLiteral('THIS_FISCAL_YEAR');
    }

    public static DateLiteral LAST_FISCAL_YEAR() {
        return new DateLiteral('LAST_FISCAL_YEAR');
    }

    public static DateLiteral NEXT_FISCAL_YEAR() {
        return new DateLiteral('NEXT_FISCAL_YEAR');
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
    // ====================

    // ==================
    // #region Interfaces
    // prettier-ignore
    public interface SelectBy {
        SelectBy add(String field);
        SelectBy add(String field1, String field2);
        SelectBy add(String field1, String field2, String field3);
        SelectBy add(String field1, String field2, String field3, String field4);
        SelectBy add(String field1, String field2, String field3, String field4, String field5);

        SelectBy add(SObjectField field);
        SelectBy add(SObjectField field1, SObjectField field2);
        SelectBy add(SObjectField field1, SObjectField field2, SObjectField field3);
        SelectBy add(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        SelectBy add(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);

        SelectBy add(SelectFunction func);
        SelectBy add(SelectFunction func1, SelectFunction func2);
        SelectBy add(SelectFunction func1, SelectFunction func2, SelectFunction func3);
        SelectBy add(SelectFunction func1, SelectFunction func2, SelectFunction func3, SelectFunction func4);
        SelectBy add(SelectFunction func1, SelectFunction func2, SelectFunction func3, SelectFunction func4, SelectFunction func5);
        SelectBy add(String relationName, Query query);
        SelectBy add(List<Object> fieldOrFuncs);
        SelectBy add(SelectBy other);
    }
    // prettier-ignore
    public interface TypeOf {
        TypeOf when(SObjectType sobjectType);

        TypeOf then(SObjectField field);
        TypeOf then(SObjectField field1, SObjectField field2);
        TypeOf then(SObjectField field1, SObjectField field2, SObjectField field3);
        TypeOf then(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        TypeOf then(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);
        TypeOf elsex(SObjectField field);
        TypeOf elsex(SObjectField field1, SObjectField field2);
        TypeOf elsex(SObjectField field1, SObjectField field2, SObjectField field3);
        TypeOf elsex(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        TypeOf elsex(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);

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
    // prettier-ignore
    public interface OrderBy {
        OrderBy ascending();
        OrderBy descending();
        OrderBy nullsFirst();
        OrderBy nullsLast();

        OrderBy add(String field);
        OrderBy add(String field1, String field2);
        OrderBy add(String field1, String field2, String field3);
        OrderBy add(String field1, String field2, String field3, String field4);
        OrderBy add(String field1, String field2, String field3, String field4, String field5);

        OrderBy add(SObjectField field);
        OrderBy add(SObjectField field1, SObjectField field2);
        OrderBy add(SObjectField field1, SObjectField field2, SObjectField field3);
        OrderBy add(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        OrderBy add(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);

        OrderBy add(OrderFunction func);
        OrderBy add(OrderFunction func1, OrderFunction func2);
        OrderBy add(OrderFunction func1, OrderFunction func2, OrderFunction func3);
        OrderBy add(OrderFunction func1, OrderFunction func2, OrderFunction func3, OrderFunction func4);
        OrderBy add(OrderFunction func1, OrderFunction func2, OrderFunction func3, OrderFunction func4, OrderFunction func5);

        OrderBy add(List<Object> fieldOrFuncs);
        OrderBy add(OrderBy other);
    }
    // prettier-ignore
    public interface GroupBy {
        GroupBy add(String field);
        GroupBy add(String field1, String field2);
        GroupBy add(String field1, String field2, String field3);
        GroupBy add(String field1, String field2, String field3, String field4);
        GroupBy add(String field1, String field2, String field3, String field4, String field5);

        GroupBy add(SObjectField field);
        GroupBy add(SObjectField field1, SObjectField field2);
        GroupBy add(SObjectField field1, SObjectField field2, SObjectField field3);
        GroupBy add(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        GroupBy add(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);

        GroupBy add(DateFunction func);
        GroupBy add(DateFunction func1, DateFunction func2);
        GroupBy add(DateFunction func1, DateFunction func2, DateFunction func3);
        GroupBy add(DateFunction func1, DateFunction func2, DateFunction func3, DateFunction func4);
        GroupBy add(DateFunction func1, DateFunction func2, DateFunction func3, DateFunction func4, DateFunction func5);

        GroupBy add(List<Object> fieldOrFuncs);
        GroupBy add(GroupBy other);
    }
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
        Query selectBy(SelectBy selectBy);
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
        Query orderBy(OrderBy orderBy);

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
        Query groupBy(GroupBy rootGroupBy);

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
    // #endregion
    // ==================

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

    // #endregion
    // ============

    // ==============
    // #region FILTER
    public Query filterBy(Filter filter) {
        this.rootFilterBy = filter;
        return this;
    }

    public Query havingBy(Filter filter) {
        this.rootHavingBy = filter;
        return this;
    }
    // #endregion
    // ============

    // ==============
    // #region SELECT
    public Query selectBy(SelectBy selectBy) {
        this.rootSelectBy.add(selectBy);
        return this;
    }

    public Query selectBy(List<Object> fieldOrFuncs) {
        this.rootSelectBy.selections.addAll(fieldOrFuncs);
        return this;
    }

    // Field
    public Query selectBy(SObjectField field) {
        this.rootSelectBy.selections.add(field);
        return this;
    }

    public Query selectBy(SObjectField field1, SObjectField field2) {
        this.rootSelectBy.selections.add(field1);
        this.rootSelectBy.selections.add(field2);
        return this;
    }

    public Query selectBy(SObjectField field1, SObjectField field2, SObjectField field3) {
        this.rootSelectBy.selections.add(field1);
        this.rootSelectBy.selections.add(field2);
        this.rootSelectBy.selections.add(field3);
        return this;
    }

    public Query selectBy(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
        this.rootSelectBy.selections.add(field1);
        this.rootSelectBy.selections.add(field2);
        this.rootSelectBy.selections.add(field3);
        this.rootSelectBy.selections.add(field4);
        return this;
    }

    public Query selectBy(
        SObjectField field1,
        SObjectField field2,
        SObjectField field3,
        SObjectField field4,
        SObjectField field5
    ) {
        this.rootSelectBy.selections.add(field1);
        this.rootSelectBy.selections.add(field2);
        this.rootSelectBy.selections.add(field3);
        this.rootSelectBy.selections.add(field4);
        this.rootSelectBy.selections.add(field5);
        return this;
    }

    // String
    public Query selectBy(String field) {
        this.rootSelectBy.selections.add(field);
        return this;
    }

    public Query selectBy(String field1, String field2) {
        this.rootSelectBy.selections.add(field1);
        this.rootSelectBy.selections.add(field2);
        return this;
    }

    public Query selectBy(String field1, String field2, String field3) {
        this.rootSelectBy.selections.add(field1);
        this.rootSelectBy.selections.add(field2);
        this.rootSelectBy.selections.add(field3);
        return this;
    }

    public Query selectBy(String field1, String field2, String field3, String field4) {
        this.rootSelectBy.selections.add(field1);
        this.rootSelectBy.selections.add(field2);
        this.rootSelectBy.selections.add(field3);
        this.rootSelectBy.selections.add(field4);
        return this;
    }

    public Query selectBy(String field1, String field2, String field3, String field4, String field5) {
        this.rootSelectBy.selections.add(field1);
        this.rootSelectBy.selections.add(field2);
        this.rootSelectBy.selections.add(field3);
        this.rootSelectBy.selections.add(field4);
        this.rootSelectBy.selections.add(field5);
        return this;
    }

    // Function
    public Query selectBy(SelectFunction func) {
        this.rootSelectBy.selections.add(func);
        return this;
    }

    public Query selectBy(SelectFunction func1, SelectFunction func2) {
        this.rootSelectBy.selections.add(func1);
        this.rootSelectBy.selections.add(func2);
        return this;
    }

    public Query selectBy(SelectFunction func1, SelectFunction func2, SelectFunction func3) {
        this.rootSelectBy.selections.add(func1);
        this.rootSelectBy.selections.add(func2);
        this.rootSelectBy.selections.add(func3);
        return this;
    }

    public Query selectBy(SelectFunction func1, SelectFunction func2, SelectFunction func3, SelectFunction func4) {
        this.rootSelectBy.selections.add(func1);
        this.rootSelectBy.selections.add(func2);
        this.rootSelectBy.selections.add(func3);
        this.rootSelectBy.selections.add(func4);
        return this;
    }

    public Query selectBy(
        SelectFunction func1,
        SelectFunction func2,
        SelectFunction func3,
        SelectFunction func4,
        SelectFunction func5
    ) {
        this.rootSelectBy.selections.add(func1);
        this.rootSelectBy.selections.add(func2);
        this.rootSelectBy.selections.add(func3);
        this.rootSelectBy.selections.add(func4);
        this.rootSelectBy.selections.add(func5);
        return this;
    }

    public Query selectBy(String relationName, Query query) {
        this.rootSelectBy.add(relationName, query);
        return this;
    }

    public Query selectBy(TypeOf typeof) {
        this.rootTypeOf = (TypeOfImpl) typeof;
        return this;
    }
    // #endregion
    // ==============

    // ================
    // #region ORDER BY
    public Query orderBy(OrderBy orderBy) {
        this.rootOrderBy.add(orderBy);
        return this;
    }

    public Query orderBy(List<Object> fieldOrFuncs) {
        this.rootOrderBy.add(fieldOrFuncs);
        return this;
    }

    // String
    public Query orderBy(String field) {
        this.rootOrderBy.add(field);
        return this;
    }
    public Query orderBy(String field1, String field2) {
        this.rootOrderBy.add(field1, field2);
        return this;
    }
    public Query orderBy(String field1, String field2, String field3) {
        this.rootOrderBy.add(field1, field2, field3);
        return this;
    }
    public Query orderBy(String field1, String field2, String field3, String field4) {
        this.rootOrderBy.add(field1, field2, field3, field4);
        return this;
    }
    public Query orderBy(String field1, String field2, String field3, String field4, String field5) {
        this.rootOrderBy.add(field1, field2, field3, field4, field5);
        return this;
    }

    // SObjectField
    public Query orderBy(SObjectField field) {
        this.rootOrderBy.add(field);
        return this;
    }
    public Query orderBy(SObjectField field1, SObjectField field2) {
        this.rootOrderBy.add(field1, field2);
        return this;
    }
    public Query orderBy(SObjectField field1, SObjectField field2, SObjectField field3) {
        this.rootOrderBy.add(field1, field2, field3);
        return this;
    }
    public Query orderBy(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
        this.rootOrderBy.add(field1, field2, field3, field4);
        return this;
    }
    public Query orderBy(
        SObjectField field1,
        SObjectField field2,
        SObjectField field3,
        SObjectField field4,
        SObjectField field5
    ) {
        this.rootOrderBy.add(field1, field2, field3, field4, field5);
        return this;
    }

    // Function
    public Query orderBy(OrderFunction func) {
        this.rootOrderBy.add(func);
        return this;
    }

    public Query orderBy(OrderFunction func1, OrderFunction func2) {
        this.rootOrderBy.add(func1, func2);
        return this;
    }

    public Query orderBy(OrderFunction func1, OrderFunction func2, OrderFunction func3) {
        this.rootOrderBy.add(func1, func2, func3);
        return this;
    }

    public Query orderBy(OrderFunction func1, OrderFunction func2, OrderFunction func3, OrderFunction func4) {
        this.rootOrderBy.add(func1, func2, func3, func4);
        return this;
    }

    public Query orderBy(
        OrderFunction func1,
        OrderFunction func2,
        OrderFunction func3,
        OrderFunction func4,
        OrderFunction func5
    ) {
        this.rootOrderBy.add(func1, func2, func3, func4, func5);
        return this;
    }

    // Others
    public Query ascending() {
        this.rootOrderBy.setAscending(true);
        return this;
    }

    public Query descending() {
        this.rootOrderBy.setAscending(false);
        return this;
    }

    public Query nullsFirst() {
        this.rootOrderBy.setNullFirst(true);
        return this;
    }

    public Query nullsLast() {
        this.rootOrderBy.setNullFirst(false);
        return this;
    }
    // #endregion
    // ================

    // ================
    // #region GROUP BY
    public Query groupBy(GroupBy groupBy) {
        this.rootGroupBy.add(groupBy);
        return this;
    }

    public Query groupBy(List<Object> fieldOrFuncs) {
        this.rootGroupBy.fieldOrFuncs.addAll(fieldOrFuncs);
        return this;
    }

    // String
    public Query groupBy(String field) {
        this.rootGroupBy.fieldOrFuncs.add(field);
        return this;
    }

    public Query groupBy(String field1, String field2) {
        this.rootGroupBy.fieldOrFuncs.add(field1);
        this.rootGroupBy.fieldOrFuncs.add(field2);
        return this;
    }

    public Query groupBy(String field1, String field2, String field3) {
        this.rootGroupBy.fieldOrFuncs.add(field1);
        this.rootGroupBy.fieldOrFuncs.add(field2);
        this.rootGroupBy.fieldOrFuncs.add(field3);
        return this;
    }

    public Query groupBy(String field1, String field2, String field3, String field4) {
        this.rootGroupBy.fieldOrFuncs.add(field1);
        this.rootGroupBy.fieldOrFuncs.add(field2);
        this.rootGroupBy.fieldOrFuncs.add(field3);
        this.rootGroupBy.fieldOrFuncs.add(field4);
        return this;
    }

    public Query groupBy(String field1, String field2, String field3, String field4, String field5) {
        this.rootGroupBy.fieldOrFuncs.add(field1);
        this.rootGroupBy.fieldOrFuncs.add(field2);
        this.rootGroupBy.fieldOrFuncs.add(field3);
        this.rootGroupBy.fieldOrFuncs.add(field4);
        this.rootGroupBy.fieldOrFuncs.add(field5);
        return this;
    }

    // SObjectField
    public Query groupBy(SObjectField field) {
        this.rootGroupBy.fieldOrFuncs.add(field);
        return this;
    }

    public Query groupBy(SObjectField field1, SObjectField field2) {
        this.rootGroupBy.fieldOrFuncs.add(field1);
        this.rootGroupBy.fieldOrFuncs.add(field2);
        return this;
    }

    public Query groupBy(SObjectField field1, SObjectField field2, SObjectField field3) {
        this.rootGroupBy.fieldOrFuncs.add(field1);
        this.rootGroupBy.fieldOrFuncs.add(field2);
        this.rootGroupBy.fieldOrFuncs.add(field3);
        return this;
    }

    public Query groupBy(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
        this.rootGroupBy.fieldOrFuncs.add(field1);
        this.rootGroupBy.fieldOrFuncs.add(field2);
        this.rootGroupBy.fieldOrFuncs.add(field3);
        this.rootGroupBy.fieldOrFuncs.add(field4);
        return this;
    }

    public Query groupBy(
        SObjectField field1,
        SObjectField field2,
        SObjectField field3,
        SObjectField field4,
        SObjectField field5
    ) {
        this.rootGroupBy.fieldOrFuncs.add(field1);
        this.rootGroupBy.fieldOrFuncs.add(field2);
        this.rootGroupBy.fieldOrFuncs.add(field3);
        this.rootGroupBy.fieldOrFuncs.add(field4);
        this.rootGroupBy.fieldOrFuncs.add(field5);
        return this;
    }

    // Function
    public Query groupBy(DateFunction func) {
        this.rootGroupBy.fieldOrFuncs.add(func);
        return this;
    }

    public Query groupBy(DateFunction func1, DateFunction func2) {
        this.rootGroupBy.fieldOrFuncs.add(func1);
        this.rootGroupBy.fieldOrFuncs.add(func2);
        return this;
    }

    public Query groupBy(DateFunction func1, DateFunction func2, DateFunction func3) {
        this.rootGroupBy.fieldOrFuncs.add(func1);
        this.rootGroupBy.fieldOrFuncs.add(func2);
        this.rootGroupBy.fieldOrFuncs.add(func3);
        return this;
    }

    public Query groupBy(DateFunction func1, DateFunction func2, DateFunction func3, DateFunction func4) {
        this.rootGroupBy.fieldOrFuncs.add(func1);
        this.rootGroupBy.fieldOrFuncs.add(func2);
        this.rootGroupBy.fieldOrFuncs.add(func3);
        this.rootGroupBy.fieldOrFuncs.add(func4);
        return this;
    }

    public Query groupBy(
        DateFunction func1,
        DateFunction func2,
        DateFunction func3,
        DateFunction func4,
        DateFunction func5
    ) {
        this.rootGroupBy.fieldOrFuncs.add(func1);
        this.rootGroupBy.fieldOrFuncs.add(func2);
        this.rootGroupBy.fieldOrFuncs.add(func3);
        this.rootGroupBy.fieldOrFuncs.add(func4);
        this.rootGroupBy.fieldOrFuncs.add(func5);
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

    // ================
    // #region Commands
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
    // #endregion
    // ================
}
