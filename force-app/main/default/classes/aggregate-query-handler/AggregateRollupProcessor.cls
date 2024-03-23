public with sharing class AggregateRollupProcessor extends AggregateProcessor {
    private List<ProtoAggregate> summaryResults = new List<ProtoAggregate>();
    private List<ProtoAggregate> summarySubResults = new List<ProtoAggregate>();
    private ProtoAggregate grandSummaryResult = null;

    public override void processRecord(SObject databaseRecord) {
        Node selectNode = topLevelNodes.selectNode;
        Node groupByNode = topLevelNodes.groupByNode;

        Map<String, List<String>> aggrFields = AggregateService.getAggregateFields(topLevelNodes);
        List<String> groupByFields = aggrFields.get('groupByFields');
        
        // if it's not a rollup, then we don't need to calculate the summary results
        // if there's only one field, the grand summary is the same as the grouped aggregate

        ProtoAggregate summaryResult = null;
        ProtoAggregate summarySubResult = null;

        // first run, we'll need to create this
        if(grandSummaryResult == null) {
            grandSummaryResult = createGrandSummaryAggregate();
        }
        

        if(groupByFields.size() >= 2) {
            summaryResult = findSummaryAggregateFieldOne(databaseRecord);
            if(summaryResult == null) {
                summaryResult = createSummaryAggregateFieldOne(databaseRecord);
                summaryResults.add(summaryResult);
            }
        } 
        
        if(groupByFields.size() == 3) {
            summarySubResult = findSummaryAggregateFieldTwo(databaseRecord);
            if(summarySubResult == null) {
                summarySubResult = createSummaryAggregateFieldTwo(databaseRecord);
                summarySubResults.add(summarySubResult);
            }
        }

        Integer exprNumber = 0;
        for(Node currSelect = selectNode.left; currSelect != null; currSelect = currSelect.left) {
            Boolean isAggregateFunc = (currSelect.nodeType == 'aggregate function');

            if(!isAggregateFunc) {
                continue;
            }


            Node fieldNode = currSelect.right;
            Node aliasNode = fieldNode.left;
            String fieldName = fieldNode.id;

            Map<String, Object> comparableInfo = this.db.getComparables(databaseRecord, fieldName);
            sObject comparableRecord = (SObject) comparableInfo.get('comparableRecord');
            String comparableField = (String) comparableInfo.get('comparableField');

            Schema.SObjectType sot = SchemaService.getSObjectType(comparableRecord);
            Schema.DisplayType fieldType = SchemaService.getFieldType(sot, comparableField);
            
            String alias = 'expr' + exprNumber;

            if(aliasNode != null) {
                alias = aliasNode.id;
            } else {
                exprNumber++;
            }

            Boolean isFieldNumeric = SchemaService.isFieldNumeric(fieldType);

            List<String> numericFuncs = new List<String> {
                'sum', 'max', 'min', 'avg'
            };

            Boolean isExpectingNumeric = (numericFuncs.contains(currSelect.id));
            if(isExpectingNumeric && !isFieldNumeric) {
                throw new QueryException('Invalid field type');
            }

            List<ProtoAggregate> aggregates = new List<ProtoAggregate> {
                summaryResult,
                summarySubResult,
                grandSummaryResult
            };

            for(ProtoAggregate aggr : aggregates) {
                if(aggr == null) {
                    continue;
                }
                calculateAggregate(
                    currSelect, 
                    alias, 
                    aggr,
                    comparableRecord.get(comparableField)
                );
            }

        }
    }

    public override List<ProtoAggregate> finish() {
        List<ProtoAggregate> results = new List<ProtoAggregate>();
        results.addAll(summaryResults);
        results.addAll(summarySubResults);
        results.add(grandSummaryResult);
        return results;
    }

    private ProtoAggregate createGrandSummaryAggregate() {
        Node selectNode = topLevelNodes.selectNode;
        Node groupByNode = topLevelNodes.groupByNode;

        List<String> fields = buildRollupFields();
        ProtoAggregate aggregateResult = new ProtoAggregate();

        if(fields.size() >= 1) {
            String alias1 = AliasService.getRollupFieldOrAlias(selectNode, groupByNode.left).get('fieldOrAlias');
            aggregateResult.put(alias1, null);
        }

        if(fields.size() >= 2) {
            String alias2 = AliasService.getRollupFieldOrAlias(selectNode, groupByNode.left.left).get('fieldOrAlias');
            aggregateResult.put(alias2, null);
        }

        if(fields.size() == 3) {
            String alias3 = AliasService.getRollupFieldOrAlias(selectNode, groupByNode.left.left.left).get('fieldOrAlias');
            aggregateResult.put(alias3, null);
        }
        return aggregateResult;
    }
    

    private ProtoAggregate createSummaryAggregateFieldOne(SObject databaseRecord) {
        Node selectNode = topLevelNodes.selectNode;
        Node groupByNode = topLevelNodes.groupByNode;

        List<String> fields = buildRollupFields();

        ProtoAggregate aggregateResult = new ProtoAggregate();

        String field1 = fields[0];
        String alias1 = AliasService.getRollupFieldOrAlias(selectNode, groupByNode.left).get('fieldOrAlias');
        String field2 = fields[1];
        String alias2 = AliasService.getRollupFieldOrAlias(selectNode, groupByNode.left.left).get('fieldOrAlias');
        aggregateResult.put(alias1, databaseRecord.get(field1));
        aggregateResult.put(alias2, null);

        return aggregateResult;
    }

    private ProtoAggregate createSummaryAggregateFieldTwo(SObject databaseRecord) {
        Node selectNode = topLevelNodes.selectNode;
        Node groupByNode = topLevelNodes.groupByNode;

        List<String> fields = buildRollupFields();

        ProtoAggregate aggregateResult = new ProtoAggregate();

        String field1 = fields[0];
        String alias1 = AliasService.getRollupFieldOrAlias(selectNode, groupByNode.left).get('fieldOrAlias');
        String field2 = fields[1];
        String alias2 = AliasService.getRollupFieldOrAlias(selectNode, groupByNode.left.left).get('fieldOrAlias');
        String field3 = fields[2];
        String alias3 = AliasService.getRollupFieldOrAlias(selectNode, groupByNode.left.left.left).get('fieldOrAlias');
        aggregateResult.put(alias1, databaseRecord.get(field1));
        aggregateResult.put(alias2, databaseRecord.get(field2));
        aggregateResult.put(alias3, null);

        return aggregateResult;        
    }

    // expects there are two fields to group by
    public ProtoAggregate findSummaryAggregateFieldOne(SObject databaseRecord) {
        Node selectNode = topLevelNodes.selectNode;
        Node groupByNode = topLevelNodes.groupByNode;

        List<String> fields = buildRollupFields();
        String field1 = fields[0];
        String alias1 = AliasService.getRollupFieldOrAlias(selectNode, groupByNode.left).get('fieldOrAlias');
        String alias2 = AliasService.getRollupFieldOrAlias(selectNode, groupByNode.left.left).get('fieldOrAlias');

        // find the aggregate result that matches the current rollup aggregate
        for(ProtoAggregate sr : summaryResults) {
            // if field == null, there's only the grand total in the list
            if(
                sr.get(alias1) == databaseRecord.get(field1) && 
                sr.get(alias2) == null
            ) {
                return sr;
            }
        }
        return null;
    }

    // only called when there are three fields to group by
    private ProtoAggregate findSummaryAggregateFieldTwo(
        SObject databaseRecord
    ) {
        Node selectNode = topLevelNodes.selectNode;
        Node groupByNode = topLevelNodes.groupByNode;

        List<String> fields = buildRollupFields();
        String field1 = fields[0];
        String alias1 = AliasService.getRollupFieldOrAlias(selectNode, groupByNode.left).get('fieldOrAlias');
        String field2 = fields[1];
        String alias2 = AliasService.getRollupFieldOrAlias(selectNode, groupByNode.left.left).get('fieldOrAlias');
        String alias3 = AliasService.getRollupFieldOrAlias(selectNode, groupByNode.left.left.left).get('fieldOrAlias');

        // find the aggregate result that matches the current rollup aggregate
        for(ProtoAggregate sr : summarySubResults) {
            if(
                sr.get(alias1) == databaseRecord.get(field1) && 
                sr.get(alias2) == databaseRecord.get(field2) && 
                sr.get(alias3) == null
            ) {
                return sr;
            }
        }
        return null;
    }

    private AggregateComparator buildRollupComparator() {
        Node selectNode = topLevelNodes.selectNode;
        Node groupByNode = topLevelNodes.groupByNode;

        Map<String, Map<String, String>> fieldsSortData = new Map<String, Map<String, String>>();
        for(Node currNode = groupByNode.left; currNode != null; currNode = currNode.left) {
            Map<String, String> rollupFieldOrAlias = AliasService.getRollupFieldOrAlias(selectNode, currNode);
            String fieldOrAlias = rollupFieldOrAlias.get('fieldOrAlias');
            String relationshipName = rollupFieldOrAlias.get('relationshipName');
        
            Map<String, String> fieldData = new Map<String, String> {
                'fieldApiName' => fieldOrAlias,
                'relationshipName' => relationshipName,
                'order' => 'asc',
                'nullDir' => 'last'
            };
            fieldsSortData.put(fieldOrAlias, fieldData);
        }

        AggregateComparator comparator = new AggregateComparator(fieldsSortData);
        return comparator;
    }

    private List<String> buildRollupFields() {
        Node selectNode = topLevelNodes.selectNode;
        Node groupByNode = topLevelNodes.groupByNode;

        List<String> fields = new List<String>();
        for(Node rollupNode = groupByNode.left; rollupNode != null; rollupNode = rollupNode.left) {
            Map<String, String> rollupFieldOrAlias = AliasService.getRollupFieldOrAlias(selectNode, rollupNode);
            String fieldOrAlias = rollupFieldOrAlias.get('fieldOrAlias');
            fields.add(
                fieldOrAlias
            );
        }
        return fields;
    }
}