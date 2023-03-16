public with sharing abstract class Query implements Querable {
    public static DateLiteral d = new DateLiteral();

    public Integer offset { get; set; }
    public Integer limitx { get; set; }
    public Boolean forView { get; set; }
    public Boolean forReference { get; set; }
    public Boolean forUpdate { get; set; }

    public static Query of(SObjectType objectType) {
        return new SoqlQuery(objectType);
    }

    private virtual SelectManager getSelectManager() {
        return null;
    }

    private virtual FilterManager getFilterManager() {
        return null;
    }

    private virtual IOrderManager getOrderManager() {
        return null;
    }

    private virtual IGroupManager getGroupManager() {
        return null;
    }

    public virtual Object run() {
        return null;
    }

    // =============
    // #region Query
    private class SoqlQuery extends Query {
        private SObjectType objectType { get; set; }

        private SOQLQuerySelectManager selectManager { get; set; }
        private SOQLQueryFilterManager filterManager { get; set; }
        private SOQLQueryOrderManager orderManager { get; set; }
        private SOQLQueryGroupManager groupManager { get; set; }

        private SoqlQuery(SObjectType objectType) {
            this.objectType = objectType;
            this.selectManager = new SOQLQuerySelectManager();
            this.filterManager = new SOQLQueryFilterManager();
            this.orderManager = new SOQLQueryOrderManager();
            this.groupManager = new SOQLQueryGroupManager();
        }

        private override SelectManager getSelectManager() {
            return this.selectManager;
        }

        private override FilterManager getFilterManager() {
            return this.filterManager;
        }

        private override IOrderManager getOrderManager() {
            return this.orderManager;
        }

        private override IGroupManager getGroupManager() {
            return this.groupManager;
        }

        private void buildSoql(String fromObjectName, List<String> fragments, List<List<Object>> tmpVars) {
            if (!this.groupManager.isEmpty()) {
                this.groupManager.buildSelect(fragments);
            } else {
                this.selectManager.build(fragments, tmpVars);
            }
            fragments.add(' FROM ');
            fragments.add(fromObjectName);

            this.filterManager.build(fragments, tmpVars);
            this.groupManager.build(fragments);

            if (!this.groupManager.isEmpty()) {
                this.orderManager.build(fragments, this.groupManager.operationByAliasName);
            } else {
                this.orderManager.build(fragments);
            }

            if (this.offset != null) {
                fragments.add(' OFFSET ');
                fragments.add(String.valueOf(this.offset));
            }

            if (this.offset != null) {
                fragments.add(' LIMIT ');
                fragments.add(String.valueOf(this.offset));
            }

            if (this.forView == true) {
                fragments.add(' FOR VIEW');
            }

            if (this.forReference == true) {
                fragments.add(' FOR REFERENCE');
            }

            if (this.forUpdate == true) {
                fragments.add(' FOR UPDATE');
            }
        }

        private void buildSoql(List<String> fragments, List<List<Object>> tmpVars) {
            this.buildSoql(this.objectType.getDescribe().getName(), fragments, tmpVars);
        }

        public override Object run() {
            List<String> fragments = new List<String>();
            List<List<Object>> tmpVars = new List<List<Object>>();
            buildSoql(fragments, tmpVars);
            String query = String.join(fragments, '');
            System.debug(query);

            List<Object> tmpVar1;
            List<Object> tmpVar2;
            List<Object> tmpVar3;
            List<Object> tmpVar4;
            List<Object> tmpVar5;
            List<Object> tmpVar6;
            List<Object> tmpVar7;
            List<Object> tmpVar8;
            List<Object> tmpVar9;
            List<Object> tmpVar10;
            List<Object> tmpVar11;
            List<Object> tmpVar12;
            List<Object> tmpVar13;
            List<Object> tmpVar14;
            List<Object> tmpVar15;
            List<Object> tmpVar16;
            List<Object> tmpVar17;
            List<Object> tmpVar18;
            List<Object> tmpVar19;
            List<Object> tmpVar20;
            List<Object> tmpVar21;
            List<Object> tmpVar22;
            List<Object> tmpVar23;
            List<Object> tmpVar24;
            List<Object> tmpVar25;
            List<Object> tmpVar26;
            List<Object> tmpVar27;
            List<Object> tmpVar28;
            List<Object> tmpVar29;
            List<Object> tmpVar30;

            for (Integer i = 0; i < tmpVars.size(); i++) {
                switch on i {
                    when 0 {
                        tmpVar1 = tmpVars[i];
                    }
                    when 1 {
                        tmpVar2 = tmpVars[i];
                    }
                    when 2 {
                        tmpVar3 = tmpVars[i];
                    }
                    when 3 {
                        tmpVar4 = tmpVars[i];
                    }
                    when 4 {
                        tmpVar5 = tmpVars[i];
                    }
                    when 5 {
                        tmpVar6 = tmpVars[i];
                    }
                    when 6 {
                        tmpVar7 = tmpVars[i];
                    }
                    when 7 {
                        tmpVar8 = tmpVars[i];
                    }
                    when 8 {
                        tmpVar9 = tmpVars[i];
                    }
                    when 9 {
                        tmpVar10 = tmpVars[i];
                    }
                    when 10 {
                        tmpVar11 = tmpVars[i];
                    }
                    when 11 {
                        tmpVar12 = tmpVars[i];
                    }
                    when 12 {
                        tmpVar13 = tmpVars[i];
                    }
                    when 13 {
                        tmpVar14 = tmpVars[i];
                    }
                    when 14 {
                        tmpVar15 = tmpVars[i];
                    }
                    when 15 {
                        tmpVar16 = tmpVars[i];
                    }
                    when 16 {
                        tmpVar17 = tmpVars[i];
                    }
                    when 17 {
                        tmpVar18 = tmpVars[i];
                    }
                    when 18 {
                        tmpVar19 = tmpVars[i];
                    }
                    when 19 {
                        tmpVar20 = tmpVars[i];
                    }
                    when 20 {
                        tmpVar21 = tmpVars[i];
                    }
                    when 21 {
                        tmpVar22 = tmpVars[i];
                    }
                    when 22 {
                        tmpVar23 = tmpVars[i];
                    }
                    when 23 {
                        tmpVar24 = tmpVars[i];
                    }
                    when 24 {
                        tmpVar25 = tmpVars[i];
                    }
                    when 25 {
                        tmpVar26 = tmpVars[i];
                    }
                    when 26 {
                        tmpVar27 = tmpVars[i];
                    }
                    when 27 {
                        tmpVar28 = tmpVars[i];
                    }
                    when 28 {
                        tmpVar29 = tmpVars[i];
                    }
                    when 29 {
                        tmpVar30 = tmpVars[i];
                    }
                    when else {
                    }
                }
            }
            return Database.query(query);
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
    private abstract class SelectManager {
        private List<String> fieldNames { get; set; }

        {
            fieldNames = new List<String>();
        }

        public void addAll(List<String> names) {
            this.fieldNames.addAll(names);
        }
    }

    private class SOQLQuerySelectManager extends SelectManager {
        private Map<String, SoqlQuery> subQueries { get; set; }

        {
            this.subQueries = new Map<String, SoqlQuery>();
        }

        private void add(String relationName, SoqlQuery query) {
            this.subQueries.put(relationName, query);
        }

        private void build(List<String> fragments, List<List<Object>> tmpVars) {
            Boolean isFirst = true;
            for (String fieldName : this.fieldNames) {
                if (isFirst) {
                    fragments.add('SELECT ');
                } else {
                    fragments.add(', ');
                }
                isFirst = false;
                fragments.add(fieldName);
            }

            for (String relationName : this.subQueries.keySet()) {
                fragments.add(', ');
                fragments.add('(');
                this.subQueries.get(relationName).buildSoql(relationName, fragments, tmpVars);
                fragments.add(')');
            }
        }
    }

    public Query selectAll() {
        return this;
    }

    public Query selectWith(String name) {
        return selectWith(new List<String>{ name });
    }

    public Query selectWith(String name1, String name2) {
        return selectWith(new List<String>{ name1, name2 });
    }

    public Query selectWith(String name1, String name2, String name3) {
        return selectWith(new List<String>{ name1, name2, name3 });
    }

    public Query selectWith(String name1, String name2, String name3, String name4) {
        return selectWith(new List<String>{ name1, name2, name3, name4 });
    }

    public Query selectWith(String name1, String name2, String name3, String name4, String name5) {
        return selectWith(new List<String>{ name1, name2, name3, name4, name5 });
    }
    public Query selectWith(List<String> names) {
        this.getSelectManager().addAll(names);
        return this;
    }

    public Query selectWith(String relationName, Query query) {
        if (this instanceof SoqlQuery && query instanceof SoqlQuery) {
            ((SoqlQuery) this).selectManager.add(relationName, (SoqlQuery) query);
        }
        return this;
    }

    // #endregion
    // ==============

    // ================
    // #region Order By

    private virtual class OrderByClause {
        private String fieldName { get; set; }
        private List<String> pathNames { get; set; }
        private Boolean ascending { get; set; }
        private Boolean nullFirst { get; set; }

        private OrderByClause(String fieldName) {
            this.fieldName = fieldName;
            this.ascending = true;
            this.nullFirst = true;
        }
    }

    private interface IOrderManager {
        void setFieldNames(List<String> names);
        void setAscending(Boolean ascending);
        void setNullFirst(Boolean nullFirst);
        Object sort(Object objectList);
    }

    private abstract class OrderManager implements IOrderManager {
        private List<OrderByClause> orderByClauses { get; set; }
        private Integer batchSize { get; set; }

        private OrderManager() {
            this.orderByClauses = new List<OrderByClause>();
            this.batchSize = 0;
        }

        public void setFieldNames(List<String> fieldNames) {
            this.batchSize = fieldNames.size();
            for (String fieldName : fieldNames) {
                this.orderByClauses.add(new OrderByClause(fieldName));
            }
        }

        public void setAscending(Boolean ascending) {
            if (this.orderByClauses.size() >= this.batchSize) {
                for (Integer i = this.batchSize; i > 0; i--) {
                    this.orderByClauses[this.orderByClauses.size() - i].ascending = ascending;
                }
            }
        }
        public void setNullFirst(Boolean nullFirst) {
            if (this.orderByClauses.size() >= this.batchSize) {
                for (Integer i = this.batchSize; i > 0; i--) {
                    this.orderByClauses[this.orderByClauses.size() - i].nullFirst = nullFirst;
                }
            }
        }
    }

    private class SOQLQueryOrderManager extends OrderManager {
        public Object sort(Object objects) {
            return objects;
        }

        private void build(List<String> fragments) {
            Boolean isFirst = true;
            for (OrderByClause clause : orderByClauses) {
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

        private void build(List<String> fragments, Map<String, AggregateOperation> operationByAliasName) {
            Boolean isFirst = true;
            for (OrderByClause clause : this.orderByClauses) {
                if (isFirst) {
                    fragments.add(' ORDER BY ');
                } else {
                    fragments.add(', ');
                }
                isFirst = false;

                if (operationByAliasName.containsKey(clause.fieldName)) {
                    AggregateOperation operation = operationByAliasName.get(clause.fieldName);
                    fragments.add(operation.operation);
                    fragments.add('(');
                    fragments.add(operation.fieldName);
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
        return this;
    }

    public Query descending() {
        this.getOrderManager().setAscending(false);
        return this;
    }

    public Query nullsFirst() {
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
        void add(AggregateOperation operation);
        void add(List<String> fieldNames);
        Boolean isEmpty();
        void setRollup(Boolean rollup);
        void setCube(Boolean cube);
    }

    private abstract class GroupManager implements IGroupManager {
        private List<AggregateOperation> operations { get; set; }
        private Map<String, AggregateOperation> operationByAliasName { get; set; }
        private Integer aliasIndex { get; set; }

        private List<String> fieldNames { get; set; }
        private Boolean rollup { get; set; }
        private Boolean cube { get; set; }

        {
            this.operations = new List<AggregateOperation>();
            this.operationByAliasName = new Map<String, AggregateOperation>();
            this.aliasIndex = 0;

            this.fieldNames = new List<String>();
            this.rollup = false;
            this.cube = false;
        }

        public Boolean isEmpty() {
            return this.operations.size() == 0 || this.fieldNames.size() == 0;
        }

        public void add(AggregateOperation operation) {
            if (String.isBlank(operation.aliasName)) {
                operation.aliasName = 'expr' + this.aliasIndex;
                this.aliasIndex++;
            }
            this.operations.add(operation);
            this.operationByAliasName.put(operation.aliasName, operation);
        }

        public void add(List<String> fieldNames) {
            this.fieldNames.addAll(fieldNames);
        }

        public void setRollup(Boolean rollup) {
            this.rollup = rollup;
        }

        public void setCube(Boolean cube) {
            this.cube = cube;
        }
    }

    private class SOQLQueryGroupManager extends GroupManager {
        public void buildSelect(List<String> fragments) {
            fragments.add('SELECT ');
            Boolean isFirst = true;
            for (String fieldName : this.fieldNames) {
                if (!isFirst) {
                    fragments.add(', ');
                }
                isFirst = false;
                fragments.add(fieldName);
            }

            for (AggregateOperation operation : this.operations) {
                if (!isFirst) {
                    fragments.add(', ');
                }
                isFirst = false;
                operation.build(fragments);
            }
        }

        public void build(List<String> fragments) {
            Boolean isFirst = true;
            for (String fieldName : this.fieldNames) {
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
                fragments.add(fieldName);
            }
            if (this.rollup || this.cube) {
                fragments.add(')');
            }
        }
    }

    private abstract class AggregateOperation {
        private String operation { get; set; }
        private String fieldName { get; set; }
        private String aliasName { get; set; }

        private void build(List<String> fragments) {
            fragments.add(this.operation);
            fragments.add('(');
            fragments.add(this.fieldName);
            fragments.add(')');
            if (String.isNotBlank(this.aliasName) && !this.aliasName.startsWithIgnoreCase('expr')) {
                fragments.add(' ');
                fragments.add(this.aliasName);
            }
        }

        private abstract Object compute(List<SObject> objectList);
    }

    private class Grouping extends AggregateOperation {
        private Grouping(String fieldName) {
            this.operation = 'GROUPING';
            this.fieldName = fieldName;
        }

        private Grouping(String fieldName, String aliasName) {
            this.operation = 'GROUPING';
            this.fieldName = fieldName;
            this.aliasName = aliasName;
        }

        private override Object compute(List<SObject> objectList) {
            for (SObject obj : objectList) {
            }

            return 0;
        }
    }

    private class SUM extends AggregateOperation {
        private SUM(String fieldName) {
            this.operation = 'SUM';
            this.fieldName = fieldName;
        }

        private SUM(String fieldName, String aliasName) {
            this.operation = 'SUM';
            this.fieldName = fieldName;
            this.aliasName = aliasName;
        }

        private override Object compute(List<SObject> objectList) {
            Decimal value = 0;
            for (SObject obj : objectList) {
                value += (Decimal) obj.get(this.fieldName);
            }

            return value;
        }
    }

    private class AVG extends AggregateOperation {
        private AVG(String fieldName) {
            this.operation = 'AVG';
            this.fieldName = fieldName;
        }

        private AVG(String fieldName, String aliasName) {
            this.operation = 'AVG';
            this.fieldName = fieldName;
            this.aliasName = aliasName;
        }

        private override Object compute(List<SObject> objectList) {
            Decimal value = 0;
            for (SObject obj : objectList) {
                value += (Decimal) obj.get(this.fieldName);
            }
            return value / objectList.size();
        }
    }

    private class MAX extends AggregateOperation {
        private MAX(String fieldName) {
            this.operation = 'MAX';
            this.fieldName = fieldName;
        }

        private MAX(String fieldName, String aliasName) {
            this.operation = 'MAX';
            this.fieldName = fieldName;
            this.aliasName = aliasName;
        }

        private override Object compute(List<SObject> objectList) {
            Object value;
            for (SObject obj : objectList) {
                Object newValue = obj.get(this.fieldName);
                if (value == null) {
                    value = newValue;
                }

                if (newValue != null) {
                    if (newValue instanceof String || newValue instanceof Id) {
                        value = String.valueOf(newValue) > String.valueOf(value) ? newValue : value;
                    } else {
                        value = Math.max((Decimal) value, (Decimal) newValue);
                    }
                }
            }
            return value;
        }
    }

    private class MIN extends AggregateOperation {
        private MIN(String fieldName) {
            this.operation = 'MIN';
            this.fieldName = fieldName;
        }

        private MIN(String fieldName, String aliasName) {
            this.operation = 'MIN';
            this.fieldName = fieldName;
            this.aliasName = aliasName;
        }

        private override Object compute(List<SObject> objectList) {
            Object value;
            for (SObject obj : objectList) {
                Object newValue = obj.get(this.fieldName);
                if (value == null) {
                    value = newValue;
                }

                if (newValue != null) {
                    if (newValue instanceof String || newValue instanceof Id) {
                        value = String.valueOf(newValue) < String.valueOf(value) ? newValue : value;
                    } else {
                        value = Math.min((Decimal) value, (Decimal) newValue);
                    }
                }
            }
            return value;
        }
    }

    public Query grouping(String name) {
        this.getGroupManager().add(new Grouping(name));
        return this;
    }

    public Query sum(String name) {
        this.getGroupManager().add(new SUM(name));
        return this;
    }

    public Query avg(String name) {
        this.getGroupManager().add(new AVG(name));
        return this;
    }

    public Query max(String name) {
        this.getGroupManager().add(new MAX(name));
        return this;
    }

    public Query min(String name) {
        this.getGroupManager().add(new MIN(name));
        return this;
    }

    public Query grouping(String name, String alias) {
        this.getGroupManager().add(new Grouping(name, alias));
        return this;
    }

    public Query sum(String name, String alias) {
        this.getGroupManager().add(new SUM(name, alias));
        return this;
    }

    public Query avg(String name, String alias) {
        this.getGroupManager().add(new AVG(name, alias));
        return this;
    }

    public Query max(String name, String alias) {
        this.getGroupManager().add(new MAX(name, alias));
        return this;
    }

    public Query min(String name, String alias) {
        this.getGroupManager().add(new MIN(name, alias));
        return this;
    }

    public Query groupBy(String name) {
        return groupBy(new List<String>{ name });
    }

    public Query groupBy(String name1, String name2) {
        return groupBy(new List<String>{ name1, name2 });
    }

    public Query groupBy(String name1, String name2, String name3) {
        return groupBy(new List<String>{ name1, name2, name3 });
    }

    public Query groupBy(String name1, String name2, String name3, String name4) {
        return groupBy(new List<String>{ name1, name2, name3, name4 });
    }

    public Query groupBy(String name1, String name2, String name3, String name4, String name5) {
        return groupBy(new List<String>{ name1, name2, name3, name4, name5 });
    }

    public Query groupBy(List<String> names) {
        this.getGroupManager().add(names);
        return this;
    }

    public Query rollup() {
        this.getGroupManager().setRollup(true);
        return this;
    }

    public Query cube() {
        this.getGroupManager().setCube(true);
        return this;
    }
    // #endregion
    // ================

    // ==============
    // #region Filter
    public interface Filterable {
    }

    public interface FilterableList extends Filterable {
        FilterableList add(Filterable filter);
    }

    private interface InnerFilterable {
        void build(List<String> fragments, List<List<Object>> tmpVars);
    }

    private abstract class FilterManager implements InnerFilterable {
        private InnerFilterable filter { get; set; }

        private void add(Filterable filter) {
            this.filter = (InnerFilterable) filter;
        }

        public virtual void build(List<String> fragments, List<List<Object>> tmpVars) {
        }
    }

    private class SOQLQueryFilterManager extends FilterManager {
        public override void build(List<String> fragments, List<List<Object>> tmpVars) {
            if (this.filter != null) {
                fragments.add(' WHERE ');
                filter.build(fragments, tmpVars);
            }
        }
    }

    private abstract class LogicalExpression implements FilterableList, InnerFilterable {
        private List<InnerFilterable> filters { get; set; }
        private String operator { get; set; }

        private LogicalExpression(String operator) {
            this.filters = new List<InnerFilterable>();
            this.operator = operator;
        }

        public FilterableList add(Filterable filter) {
            this.filters.add((InnerFilterable) filter);
            return this;
        }

        public void build(List<String> fragments, List<List<Object>> tmpVars) {
            if (this.filters.size() == 0) {
                return;
            }

            fragments.add('(');
            Integer index = 0;
            for (InnerFilterable filter : this.filters) {
                if (index > 0) {
                    fragments.add(this.operator);
                }
                filter.build(fragments, tmpVars);
                index++;
            }
            fragments.add(')');
        }
    }

    private class AndLogicalExpression extends LogicalExpression {
        private AndLogicalExpression() {
            super(' AND ');
        }
    }

    private class OrLogicalExpression extends LogicalExpression {
        private OrLogicalExpression() {
            super(' OR ');
        }
    }

    private abstract class ComparisonExpression implements Filterable, InnerFilterable {
        private String fieldName { get; set; }
        private List<String> pathNames { get; set; }
        private String operator { get; set; }
        private Object value { get; set; }

        private ComparisonExpression() {
        }

        private ComparisonExpression(String fieldName, String operator, Object value) {
            this.fieldName = fieldName;
            this.operator = operator;
            this.value = value;
        }

        public virtual void build(List<String> fragments, List<List<Object>> tmpVars) {
            fragments.add(this.fieldName);
            fragments.add(this.operator);
            if (this.value instanceof List<Object>) {
                tmpVars.add((List<Object>) this.value);
                fragments.add(':tmpVar' + tmpVars.size());
            } else if (this.value instanceof String || this.value instanceof Id) {
                fragments.add('\'');
                fragments.add(String.valueOf(this.value));
                fragments.add('\'');
            } else {
                fragments.add(String.valueOf(this.value));
            }
        }
    }

    public Query filterBy(Filterable filter) {
        this.getFilterManager().add(filter);
        return this;
    }

    public static FilterableList orx() {
        return new OrLogicalExpression();
    }

    public static FilterableList andx() {
        return new AndLogicalExpression();
    }

    // #endregion
    // ==================

    // =============
    // #region =, !=
    private class EQ extends ComparisonExpression {
        private EQ(String fieldName, Object value) {
            super(fieldName, ' = ', value);
        }
    }

    private class NE extends ComparisonExpression {
        private NE(String fieldName, Object value) {
            super(fieldName, ' != ', value);
        }
    }

    public static Filterable eq(String name, Object value) {
        return new EQ(name, value);
    }

    public static Filterable ne(String name, Object value) {
        return new NE(name, value);
    }
    // #endregion
    // =============

    // =========
    // #region >
    private abstract class GT extends ComparisonExpression {
        private GT(String fieldName, Object value) {
            super(fieldName, ' > ', value);
        }
    }

    private class GT_Decimal extends GT {
        private Decimal value { get; set; }

        private GT_Decimal(String fieldName, Decimal value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    private class GT_Date extends GT {
        private Date value { get; set; }

        private GT_Date(String fieldName, Date value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    private class GT_Datetime extends GT {
        private Datetime value { get; set; }

        private GT_Datetime(String fieldName, Datetime value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    private class GT_Time extends GT {
        private Time value { get; set; }

        private GT_Time(String fieldName, Time value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    private class GT_Id extends GT {
        private Id value { get; set; }

        private GT_Id(String fieldName, Id value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    private class GT_String extends GT {
        private String value { get; set; }

        private GT_String(String fieldName, String value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    public static Filterable gt(String name, Decimal value) {
        return new GT_Decimal(name, value);
    }

    public static Filterable gt(String name, Date value) {
        return new GT_Date(name, value);
    }

    public static Filterable gt(String name, Datetime value) {
        return new GT_Datetime(name, value);
    }

    public static Filterable gt(String name, Time value) {
        return new GT_Time(name, value);
    }

    public static Filterable gt(String name, Id value) {
        return new GT_Id(name, value);
    }

    public static Filterable gt(String name, String value) {
        return new GT_String(name, value);
    }

    // #endregion
    // ==========

    // ==========
    // #region >=
    private abstract class GTE extends ComparisonExpression {
        private GTE(String fieldName, Object value) {
            super(fieldName, ' >= ', value);
        }
    }

    private class GTE_Decimal extends GTE {
        private Decimal value { get; set; }

        private GTE_Decimal(String fieldName, Decimal value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    private class GTE_Date extends GTE {
        private Date value { get; set; }

        private GTE_Date(String fieldName, Date value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    private class GTE_Datetime extends GTE {
        private Datetime value { get; set; }

        private GTE_Datetime(String fieldName, Datetime value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    private class GTE_Time extends GTE {
        private Time value { get; set; }

        private GTE_Time(String fieldName, Time value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    private class GTE_Id extends GTE {
        private Id value { get; set; }

        private GTE_Id(String fieldName, Id value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    private class GTE_String extends GTE {
        private String value { get; set; }

        private GTE_String(String fieldName, String value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    public static Filterable gte(String name, Decimal value) {
        return new GTE_Decimal(name, value);
    }

    public static Filterable gte(String name, Date value) {
        return new GTE_Date(name, value);
    }

    public static Filterable gte(String name, Datetime value) {
        return new GTE_Datetime(name, value);
    }

    public static Filterable gte(String name, Time value) {
        return new GTE_Time(name, value);
    }

    public static Filterable gte(String name, Id value) {
        return new GTE_Id(name, value);
    }

    public static Filterable gte(String name, String value) {
        return new GTE_String(name, value);
    }

    // #endregion
    // ===========

    // ==========
    // #region <
    private abstract class LT extends ComparisonExpression {
        private LT(String fieldName, Object value) {
            super(fieldName, ' < ', value);
        }
    }

    private class LT_Decimal extends LT {
        private Decimal value { get; set; }
        private LT_Decimal(String fieldName, Decimal value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    private class LT_Date extends LT {
        private Date value { get; set; }
        private LT_Date(String fieldName, Date value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    private class LT_Datetime extends LT {
        private Datetime value { get; set; }
        private LT_Datetime(String fieldName, Datetime value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    private class LT_Time extends LT {
        private Time value { get; set; }
        private LT_Time(String fieldName, Time value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    private class LT_Id extends LT {
        private Id value { get; set; }
        private LT_Id(String fieldName, Id value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    private class LT_String extends LT {
        private String value { get; set; }
        private LT_String(String fieldName, String value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    public static Filterable lt(String name, Decimal value) {
        return new LT_Decimal(name, value);
    }

    public static Filterable lt(String name, Date value) {
        return new LT_Date(name, value);
    }

    public static Filterable lt(String name, Datetime value) {
        return new LT_Datetime(name, value);
    }

    public static Filterable lt(String name, Time value) {
        return new LT_Time(name, value);
    }

    public static Filterable lt(String name, Id value) {
        return new LT_Id(name, value);
    }

    public static Filterable lt(String name, String value) {
        return new LT_String(name, value);
    }
    // #endregion
    // ==========

    // ==========
    // #region <=
    private abstract class LTE extends ComparisonExpression {
        private Object value { get; set; }
        private LTE(String fieldName, Object value) {
            super(fieldName, ' <= ', value);
            this.value = value;
        }
    }

    private class LTE_Decimal extends LTE {
        private Decimal value { get; set; }
        private LTE_Decimal(String fieldName, Decimal value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    private class LTE_Date extends LTE {
        private Date value { get; set; }
        private LTE_Date(String fieldName, Date value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    private class LTE_Datetime extends LTE {
        private Datetime value { get; set; }
        private LTE_Datetime(String fieldName, Datetime value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    private class LTE_Time extends LTE {
        private Time value { get; set; }
        private LTE_Time(String fieldName, Time value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    private class LTE_Id extends LTE {
        private Id value { get; set; }
        private LTE_Id(String fieldName, Id value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    private class LTE_String extends LTE {
        private String value { get; set; }
        private LTE_String(String fieldName, String value) {
            super(fieldName, value);
            this.value = value;
        }
    }

    public static Filterable lte(String name, Decimal value) {
        return new LTE_Decimal(name, value);
    }

    public static Filterable lte(String name, Date value) {
        return new LTE_Date(name, value);
    }

    public static Filterable lte(String name, Datetime value) {
        return new LTE_Datetime(name, value);
    }

    public static Filterable lte(String name, Time value) {
        return new LTE_Time(name, value);
    }

    public static Filterable lte(String name, Id value) {
        return new LTE_Id(name, value);
    }

    public static Filterable lte(String name, String value) {
        return new LTE_String(name, value);
    }
    // #endregion
    // ==========

    // ===============
    // #region between
    private abstract class Between extends ComparisonExpression {
        private GTE gteFromValue { get; set; }
        private LTE lteToValue { get; set; }

        public override void build(List<String> fragments, List<List<Object>> tmpVars) {
            this.gteFromValue.build(fragments, tmpVars);
            fragments.add(' AND ');
            this.lteToValue.build(fragments, tmpVars);
        }
    }

    private class Between_Decimal extends Between {
        private Decimal fromValue { get; set; }
        private Decimal toValue { get; set; }

        private Between_Decimal(String fieldName, Decimal fromValue, Decimal toValue) {
            this.fromValue = fromValue;
            this.toValue = toValue;
            this.gteFromValue = new GTE_Decimal(fieldName, fromValue);
            this.lteToValue = new LTE_Decimal(fieldName, toValue);
        }
    }

    private class Between_Date extends Between {
        private Date fromValue { get; set; }
        private Date toValue { get; set; }

        private Between_Date(String fieldName, Date fromValue, Date toValue) {
            this.fromValue = fromValue;
            this.toValue = toValue;
            this.gteFromValue = new GTE_Date(fieldName, fromValue);
            this.lteToValue = new LTE_Date(fieldName, toValue);
        }
    }

    private class Between_Datetime extends Between {
        private Datetime fromValue { get; set; }
        private Datetime toValue { get; set; }

        private Between_Datetime(String fieldName, Datetime fromValue, Datetime toValue) {
            this.fromValue = fromValue;
            this.toValue = toValue;
            this.gteFromValue = new GTE_Datetime(fieldName, fromValue);
            this.lteToValue = new LTE_Datetime(fieldName, toValue);
        }
    }

    private class Between_Time extends Between {
        private Time fromValue { get; set; }
        private Time toValue { get; set; }

        private Between_Time(String fieldName, Time fromValue, Time toValue) {
            this.fromValue = fromValue;
            this.toValue = toValue;
            this.gteFromValue = new GTE_Time(fieldName, fromValue);
            this.lteToValue = new LTE_Time(fieldName, toValue);
        }
    }

    private class Between_Id extends Between {
        private Id fromValue { get; set; }
        private Id toValue { get; set; }

        private Between_Id(String fieldName, Id fromValue, Id toValue) {
            this.fromValue = fromValue;
            this.toValue = toValue;
            this.gteFromValue = new GTE_Id(fieldName, fromValue);
            this.lteToValue = new LTE_Id(fieldName, toValue);
        }
    }

    private class Between_String extends Between {
        private String fromValue { get; set; }
        private String toValue { get; set; }

        private Between_String(String fieldName, String fromValue, String toValue) {
            this.fromValue = fromValue;
            this.toValue = toValue;
            this.gteFromValue = new GTE_String(fieldName, fromValue);
            this.lteToValue = new LTE_String(fieldName, toValue);
        }
    }
    // prettier-ignore
    public static Filterable between(String name, Decimal fromValue, Decimal toValue) {
        return new Between_Decimal(name, fromValue, toValue);
    }
    // prettier-ignore
    public static Filterable between(String name, Date fromValue, Date toValue) {
        return new Between_Date(name, fromValue, toValue);
    }
    // prettier-ignore
    public static Filterable between(String name, Datetime fromValue, Datetime toValue) {
        return new Between_Datetime(name, fromValue, toValue);
    }
    // prettier-ignore
    public static Filterable between(String name, Time fromValue, Time toValue) {
        return new Between_Time(name, fromValue, toValue);
    }
    // prettier-ignore
    public static Filterable between(String name, Id fromValue, Id toValue) {
        return new Between_Id(name, fromValue, toValue);
    }
    // prettier-ignore
    public static Filterable between(String name, String fromValue, String toValue) {
        return new Between_String(name, fromValue, toValue);
    }
    // #endregion
    // ===============

    // ============
    // #region like
    private class LikeX extends ComparisonExpression {
        private LikeX(String fieldName, String value) {
            super(fieldName, 'LIKE', value);
        }
    }

    private class NLike extends ComparisonExpression {
        private NLike(String fieldName, String value) {
            super(fieldName, 'LIKE', value);
        }

        public override void build(List<String> fragments, List<List<Object>> tmpVars) {
            fragments.add('(NOT ');
            super.build(fragments, tmpVars);
            fragments.add(')');
        }
    }

    public static Filterable likex(String name, String value) {
        return new LikeX(name, value);
    }

    public static Filterable nlike(String name, String value) {
        return new NLike(name, value);
    }
    // #endregion
    // ============

    // ================
    // #region distance

    public class Distance {
        private String fieldName { get; set; }
        private Geolocation geo { get; set; }
        private Unit unit { get; set; }

        private Distance(String fieldName, Geolocation geo, Unit unit) {
            this.fieldName = fieldName;
            this.geo = geo;
            this.unit = unit;
        }
    }

    public class Geolocation {
        private Decimal latitude { get; set; }
        private Decimal longitude { get; set; }

        private geolocation(Decimal latitude, Decimal longitude) {
            this.latitude = latitude;
            this.longitude = longitude;
        }
    }

    public enum Unit {
        MILE,
        KILOMETER
    }

    public static Distance distance(String fieldName, Geolocation geo, Unit unit) {
        return new Distance(fieldName, geo, unit);
    }

    public static Geolocation geolocation(Decimal latitude, Decimal longitude) {
        return new Geolocation(latitude, longitude);
    }

    // #endregion
    // ================

    // ====================================
    // #region inx, nin, includes, excludes
    private class Includes extends ComparisonExpression {
        private Includes(String fieldName, List<Object> values) {
            super(fieldName, 'INCLUDES', values);
        }
    }

    private class Excludes extends ComparisonExpression {
        private Excludes(String fieldName, List<Object> values) {
            super(fieldName, 'EXCLUDES', values);
        }
    }

    private class INX extends ComparisonExpression {
        private INX(String fieldName, List<Object> values) {
            super(fieldName, ' IN ', values);
        }
    }

    private class NIN extends ComparisonExpression {
        private NIN(String fieldName, List<Object> values) {
            super(fieldName, 'NOT IN', values);
        }
    }

    private virtual class INX_Query extends ComparisonExpression {
        private INX_Query(String fieldName, Boolean isNot, Query query) {
            super(fieldName, isNot ? 'NOT IN' : 'IN', query);
        }

        public override void build(List<String> fragments, List<List<Object>> tmpVars) {
            if (this.value instanceof SoqlQuery) {
                fragments.add(this.fieldName);
                fragments.add(' ');
                fragments.add(this.operator);
                fragments.add(' ');
                fragments.add('(');
                ((SoqlQuery) this.value).buildSoql(fragments, tmpVars);
                fragments.add(')');
            }
        }
    }

    public static Filterable anyOf(String name, Filterable filter) {
        return null;
    }

    public static Filterable includes(String name, List<Object> values) {
        return new Includes(name, values);
    }

    public static Filterable excludes(String name, List<Object> query) {
        return new Excludes(name, query);
    }

    public static Filterable inx(String name, List<Object> values) {
        return new INX(name, values);
    }

    public static Filterable inx(String name, Query query) {
        return new INX_Query(name, false, query);
    }

    public static Filterable nin(String name, List<Object> values) {
        return new NIN(name, values);
    }

    public static Filterable nin(String name, Query query) {
        return new INX_Query(name, true, query);
    }

    // #endregion
    // ====================================

    // =====================
    // #region Date Literals

    public class DateLiteral {
        public final String YESTERDAY = 'YESTERDAY';
        public final String TODAY = 'TODAY';
        public final String TOMORROW = 'TOMORROW';
        public final String LAST_WEEK = 'LAST_WEEK';
        public final String THIS_WEEK = 'THIS_WEEK';
        public final String NEXT_WEEK = 'NEXT_WEEK';
        public final String LAST_MONTH = 'LAST_MONTH';
        public final String THIS_MONTH = 'THIS_MONTH';
        public final String NEXT_MONTH = 'NEXT_MONTH';
        public final String LAST_90_DAYS = 'LAST_90_DAYS';
        public final String NEXT_90_DAYS = 'NEXT_90_DAYS';
        public final String THIS_QUARTER = 'THIS_QUARTER';
        public final String LAST_QUARTER = 'LAST_QUARTER';
        public final String NEXT_QUARTER = 'NEXT_QUARTER';
        public final String THIS_YEAR = 'THIS_YEAR';
        public final String LAST_YEAR = 'LAST_YEAR';
        public final String NEXT_YEAR = 'NEXT_YEAR';
        public final String THIS_FISCAL_QUARTER = 'THIS_FISCAL_QUARTER';
        public final String LAST_FISCAL_QUARTER = 'LAST_FISCAL_QUARTER';
        public final String NEXT_FISCAL_QUARTER = 'NEXT_FISCAL_QUARTER';
        public final String THIS_FISCAL_YEAR = 'THIS_FISCAL_YEAR';
        public final String LAST_FISCAL_YEAR = 'LAST_FISCAL_YEAR';
        public final String NEXT_FISCAL_YEAR = 'NEXT_FISCAL_YEAR';

        public String LAST_N_DAYS(Integer n) {
            return 'LAST_N_DAYS:' + n;
        }

        public String NEXT_N_DAYS(Integer n) {
            return 'NEXT_N_DAYS:' + n;
        }

        public String N_DAYS_AGO(Integer n) {
            return 'N_DAYS_AGO:' + n;
        }

        public String NEXT_N_WEEKS(Integer n) {
            return 'NEXT_N_WEEKS:' + n;
        }

        public String LAST_N_WEEKS(Integer n) {
            return 'LAST_N_WEEKS:' + n;
        }

        public String N_WEEKS_AGO(Integer n) {
            return 'N_WEEKS_AGO:' + n;
        }

        public String NEXT_N_MONTHS(Integer n) {
            return 'NEXT_N_MONTHS:' + n;
        }

        public String LAST_N_MONTHS(Integer n) {
            return 'LAST_N_MONTHS:' + n;
        }

        public String N_MONTHS_AGO(Integer n) {
            return 'N_MONTHS_AGO:' + n;
        }

        public String NEXT_N_QUARTERS(Integer n) {
            return 'NEXT_N_QUARTERS:' + n;
        }

        public String LAST_N_QUARTERS(Integer n) {
            return 'LAST_N_QUARTERS:' + n;
        }

        public String N_QUARTERS_AGO(Integer n) {
            return 'N_QUARTERS_AGO:' + n;
        }

        public String NEXT_N_YEARS(Integer n) {
            return 'NEXT_N_YEARS:' + n;
        }

        public String LAST_N_YEARS(Integer n) {
            return 'LAST_N_YEARS:' + n;
        }

        public String N_YEARS_AGO(Integer n) {
            return 'N_YEARS_AGO:' + n;
        }

        public String NEXT_N_FISCAL_QUARTERS(Integer n) {
            return 'NEXT_N_FISCAL_QUARTERS:' + n;
        }

        public String N_FISCAL_QUARTERS_AGO(Integer n) {
            return 'N_FISCAL_QUARTERS_AGO:' + n;
        }

        public String NEXT_N_FISCAL_YEARS(Integer n) {
            return 'NEXT_N_FISCAL_YEARS:' + n;
        }

        public String LAST_N_FISCAL_YEARS(Integer n) {
            return 'LAST_N_FISCAL_YEARS:' + n;
        }

        public String N_FISCAL_YEARS_AGO(Integer n) {
            return 'N_FISCAL_YEARS_AGO:' + n;
        }
    }

    // #endregion
    // =====================

    // prettier-ignore
    public interface Querable {
        // Group By
        Query grouping(String name);
        Query grouping(String name, String alias);
        Query sum(String name);
        Query sum(String name, String alias);
        Query avg(String name);
        Query avg(String name, String alias);
        Query max(String name);
        Query max(String name, String alias);
        Query min(String name);
        Query min(String name, String alias);

        Query groupBy(String name);
        Query groupBy(String name1, String name2);
        Query groupBy(String name1, String name2, String name3);
        Query groupBy(String name1, String name2, String name3, String name4);
        Query groupBy(String name1, String name2, String name3, String name4, String name5);
        Query groupBy(List<String> names);
        Query rollup();
        Query cube();

        // Select
        Query selectAll();
        Query selectWith(String name);
        Query selectWith(String name1, String name2);
        Query selectWith(String name1, String name2, String name3);
        Query selectWith(String name1, String name2, String name3, String name4);
        Query selectWith(String name1, String name2, String name3, String name4, String name5);
        Query selectWith(List<String> names);
        Query selectWith(String name, Query query);


        // Order By
        Query orderBy(String name);
        Query orderBy(String name1, String name2);
        Query orderBy(String name1, String name2, String name3);
        Query orderBy(String name1, String name2, String name3, String name4);
        Query orderBy(String name1, String name2, String name3, String name4, String name5);
        Query orderBy(List<String> names);
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

        Query filterBy(Filterable filter);
        Object run();
    }
}
