/**
 * @description This class is responsible for handling the aggregate queries
 */
public with sharing class AggregateQueryHandler {
    MockDatabase db;
    TopLevelNodes topLevelNodes;

    AggregateProcessor standardProcessor;
    
    public AggregateQueryHandler(MockDatabase db, TopLevelNodes topLevelNodes) {
        this.topLevelNodes = topLevelNodes;
        this.db = db;

        Node groupByNode = topLevelNodes.groupByNode;

        if(isRollup(groupByNode)) {
            throw new AggregateQueryException('GROUP BY ROLLUP is not supported');
        }

        if(isCube(groupByNode)) {
            throw new AggregateQueryException('GROUP BY CUBE is not supported');
        }

        standardProcessor = new AggregateStandardProcessor()
            .setDatabase(db)
            .setTopLevelNodes(topLevelNodes);
    }

    public List<ProtoAggregate> finish() {
        List<ProtoAggregate> finalResults = new List<ProtoAggregate>();
        finalResults.addAll(standardProcessor.finish());
        finalResults = replaceWithAliases(finalResults);
        return finalResults;
    }

    public void processRecord(SObject databaseRecord) {
        standardProcessor.processRecord(databaseRecord);
        Node groupByNode = topLevelNodes.groupByNode;
    }

    public class AggregateQueryException extends Exception {}

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

    private Boolean isRollup(Node groupByNode) {
        return (
            groupByNode != null && 
            groupByNode.id == 'rollup'
        );
    }

    private Boolean isCube(Node groupByNode) {
        return (
            groupByNode != null && 
            groupByNode.id == 'cube'
        );
    }
}