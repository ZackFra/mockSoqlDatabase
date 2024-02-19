/**
 * @description This class is responsible for handling the aggregate queries
 */
public with sharing class AggregateQueryHandler {
    MockDatabase db;
    TopLevelNodes topLevelNodes;

    AggregateProcessor standardProcessor;
    AggregateProcessor rollupProcessor;
    
    public AggregateQueryHandler(MockDatabase db, TopLevelNodes topLevelNodes) {
        this.topLevelNodes = topLevelNodes;
        this.db = db;

        Node groupByNode = topLevelNodes.groupByNode;

        standardProcessor = new AggregateStandardProcessor()
            .setDatabase(db)
            .setTopLevelNodes(topLevelNodes);

        if(isRollup(groupByNode)) {
            rollupProcessor = new AggregateRollupProcessor()
                .setDatabase(db)
                .setTopLevelNodes(topLevelNodes);
        }
    }

    public List<ProtoAggregate> finish() {
        List<ProtoAggregate> finalResults = new List<ProtoAggregate>();
        finalResults.addAll(standardProcessor.finish());


        if(isRollup(topLevelNodes.groupByNode)) {
            finalResults.addAll(rollupProcessor.finish());
            AggregateComparator comparator = buildRollupComparator();
            finalResults.sort(comparator);
        }
        finalResults = replaceWithAliases(finalResults);
        return finalResults;
    }

    public void processRecord(SObject databaseRecord) {
        standardProcessor.processRecord(databaseRecord);
        Node groupByNode = topLevelNodes.groupByNode;
        if(isRollup(groupByNode)) {
            rollupProcessor.processRecord(databaseRecord);
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

    private Boolean isRollup(Node groupByNode) {
        return (
            groupByNode != null && 
            groupByNode.id == 'rollup'
        );
    }
}