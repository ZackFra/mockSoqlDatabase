/**
 * @description This class is responsible for handling the aggregate queries
 */
public with sharing class AggregateQueryHandler {
    MockDatabase db;
    TopLevelNodes topLevelNodes;

    private List<ProtoAggregate> aggregateResults = new List<ProtoAggregate>();
    private List<ProtoAggregate> summaryResults = new List<ProtoAggregate>();
    private List<ProtoAggregate> summarySubResults = new List<ProtoAggregate>();
    private ProtoAggregate grandSummaryResult = new ProtoAggregate();
    
    public AggregateQueryHandler(MockDatabase db, TopLevelNodes topLevelNodes) {
        this.topLevelNodes = topLevelNodes;
        this.db = db;
        this.grandSummaryResult = createGrandSummaryAggregate();
    }

    public List<ProtoAggregate> finish() {
        List<ProtoAggregate> finalResults = new List<ProtoAggregate>();
        finalResults.addAll(aggregateResults);

        if(isRollup(topLevelNodes.groupByNode)) {
            finalResults.addAll(summaryResults);
            finalResults.addAll(summarySubResults);
            finalResults.add(grandSummaryResult);
            AggregateComparator comparator = buildRollupComparator();
            finalResults.sort(comparator);
        }
        finalResults = replaceWithAliases(finalResults);
        return finalResults;
    }

    public void processRecord(SObject databaseRecord) {
        Node selectNode = topLevelNodes.selectNode;
        Node groupByNode = topLevelNodes.groupByNode;

        Map<String, List<String>> aggrFields = AggregateService.getAggregateFields(topLevelNodes);
        List<String> groupByFields = aggrFields.get('groupByFields');
        
        ProtoAggregate aggregateResult = findGroupedAggregate(databaseRecord, groupByFields);
        if(aggregateResult == null) {
            aggregateResult = createGroupedAggregate(databaseRecord, groupByFields);
            aggregateResults.add(aggregateResult);
        }

        // if it's not a rollup, then we don't need to calculate the summary results
        // if there's only one field, the grand summary is the same as the grouped aggregate

        ProtoAggregate summaryResult = null;
        ProtoAggregate summarySubResult = null;
        

        if(isRollup(groupByNode)) {

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
                aggregateResult,
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

    private List<ProtoAggregate> replaceWithAliases(List<ProtoAggregate> aggregates) {
        List<ProtoAggregate> aggregateResults = new List<ProtoAggregate>(aggregates);
        Node selectNode = topLevelNodes.selectNode;
        
        for(ProtoAggregate aggr : aggregateResults) {
            for(Node currSelect = selectNode.left; currSelect != null; currSelect = currSelect.left) {
                String fieldOrAliasFromSelect = AliasService.getAlias(selectNode, currSelect).get('fieldApiName');
                for(String key : aggr.keySet()) {
                    if(key.toLowerCase() == currSelect.id && key != fieldOrAliasFromSelect) {
                        aggr.put(fieldOrAliasFromSelect, aggr.get(key));
                        aggr.remove(key);
                        break;
                    }
                }
            }
        }

        return aggregateResults;
    }

    private ProtoAggregate createGrandSummaryAggregate() {
        Node selectNode = topLevelNodes.selectNode;
        Node groupByNode = topLevelNodes.groupByNode;
        if(!isRollup(groupByNode)) {
            return null;
        }

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

    private ProtoAggregate calculateAggregate(
        Node currSelect,
        String alias, 
        ProtoAggregate aggregateResult,
        Object value
    ) {
        AggregateCalculatorOptions options = new AggregateCalculatorOptions()
            .setAlias(alias)
            .setAggregateResult(aggregateResult)
            .setValue(value);


        IAggregateCalculator calculator = AggregateCalculatorFactory.getCalculator(currSelect.id, options);
        return calculator.calculate();
    }

    private Boolean isRollup(Node groupByNode) {
        return (
            groupByNode != null && 
            groupByNode.id == 'rollup'
        );
    }

    /**
     * @description : find the grouped aggregate
     * @param databaseRecord : the database record
     * @param aggregateResults : the aggregate results list to search
     * @param groupByFields : the fields to group by
     * @return : the grouped aggregate
     */
    private ProtoAggregate findGroupedAggregate(SObject databaseRecord, List<String> groupByFields) {
        for(ProtoAggregate ar : aggregateResults) {
            Boolean isSame = true;
            for(String groupByField : groupByFields) {
                Map<String, Object> comparableInfo = this.db.getComparables(databaseRecord, groupByField);
                sObject comparableRecord = (sObject) comparableInfo.get('comparableRecord');
                String comparableField = (String) comparableInfo.get('comparableField');

                Schema.SObjectType sot = SchemaService.getSObjectType(comparableRecord);
                Schema.SObjectField comparableSObjField = SchemaService.getField(sot, comparableField);
                Boolean isPolymorphic = (Boolean) comparableInfo.get('isPolymorphic');
                Boolean isType = (comparableField == 'Type');
                if(isPolymorphic && isType) {
                    String type = SchemaService.getSObjectName(comparableRecord);
                    isSame = (isSame && (type == ar.get(comparableField)));
                } else {
                    isSame = (isSame && (comparableRecord.get(comparableField) == ar.get(comparableField)));
                }
            }
            if(isSame) {
                return ar;
            }
        }
        return null;
    }

    /**
     * @description create a new aggregate result for the grouped aggregate
     * @param databaseRecord the database record
     * @param groupByFields the fields to group by
     * @return the new aggregate result
     */
    private ProtoAggregate createGroupedAggregate(SObject databaseRecord, List<String> groupByFields) {
        ProtoAggregate aggregateResult = new ProtoAggregate();
        for(String groupByField : groupByFields) {
            Map<String, Object> comparableInfo = this.db.getComparables(databaseRecord, groupByField);
            sObject comparableRecord = (sObject) comparableInfo.get('comparableRecord');
            String comparableField = (String) comparableInfo.get('comparableField');

            Boolean isPolymorphic = (Boolean) comparableInfo.get('isPolymorphic');
            Boolean isType = (comparableField == 'Type');
            if(isPolymorphic && isType) {
                String type = SchemaService.getSObjectName(comparableRecord);
                aggregateResult.put(comparableField, type);
            } else if(isPolymorphic) {
                try {
                    aggregateResult.put(comparableField, comparableRecord.get(comparableField));
                } catch(System.SObjectException e) {
                    aggregateResult.put(comparableField, null);
                } catch(Exception e) {
                    throw e;
                }
            } else {
                aggregateResult.put(comparableField, comparableRecord.get(comparableField));
            }
        }
        return aggregateResult; 
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