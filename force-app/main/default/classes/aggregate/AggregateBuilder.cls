/**
 * @description Creates Aggregate objects from ProtoAggregates
 */
public with sharing class AggregateBuilder {
    List<ProtoAggregate> protoAggregates;
    TopLevelNodes topLevelNodes;
    Map<String, Object> params;
    
    /**
     * @description Setter for proto-aggregates
     */
    public AggregateBuilder setProtoAggregates(List<ProtoAggregate> protoAggregates) {
        this.protoAggregates = protoAggregates;
        return this;
    }

    /**
     * @description sets the top level nodes
     */
    public AggregateBuilder setTopLevelNodes(TopLevelNodes topLevelNodes) {
        this.topLevelNodes = topLevelNodes;
        return this;
    }

    /**
     * @description sets the params
     */
    public AggregateBuilder setParams(Map<String, Object> params) {
        this.params = params;
        return this;
    }

    /**
     * @description Remove the fields that are not in the select clause
     * @param aggregateResults : the aggregate result list
     * @param selectNode : the select node
     * @return : the cleaned up aggregate result list
     */
    public List<Aggregate> build() {
        Node selectNode = topLevelNodes.selectNode;

        // get list of all fields to group by, if is aggregate query
        Map<String, List<String>> aggregateFields = AggregateService.getAggregateFields(topLevelNodes);
        List<String> groupByFields = aggregateFields.get('groupByFields');
        List<String> selectFields = aggregateFields.get('selectFields');

        List<Aggregate> aggregateResultsList = new List<Aggregate>();
        for(Integer i = 0; i < protoAggregates.size(); i++) {
            ProtoAggregate ar = protoAggregates[i];

            ar = cleanUpAggregateResult(ar, groupByFields, selectFields);
            Aggregate arp = new Aggregate(ar);
            aggregateResultsList.add(arp);
        }
        return aggregateResultsList;
    }

    private ProtoAggregate cleanUpAggregateResult(
        ProtoAggregate aggr, 
        List<String> groupByFields, 
        List<String> selectFields
    ) {
        aggr = aggr.clone();

        // remove any fields that are grouped by, but not selected
        for(String groupByField : groupByFields) {
            if(selectFields.contains(groupByField)) {
                continue;
            }

            for(String key : aggr.keySet()) {
                if(key.toLowerCase() == groupByField) {
                    aggr.remove(key);
                }
            }
        }
        
        // remove the internal fields used for COUNT_DISTINCT and AVG
        for(String key : aggr.keySet()) {
            Boolean isAvg = key.endsWith('__n');
            Boolean isDistinct = key.endsWith('__distinct');
            if(isAvg || isDistinct) {
                aggr.remove(key);
            }
        }
        return aggr;
    }

}