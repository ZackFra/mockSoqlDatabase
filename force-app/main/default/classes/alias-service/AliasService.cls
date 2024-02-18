/**
 * @description Tool for finding the aliases on nodes
 */
public with sharing class AliasService {
    public static Map<String, String> getFieldAlias(Node curr, Node fieldNode, Node selectNode) {
        Node aliasNode = curr.right;
        String fieldApiName;
        String relationshipName;
        if(aliasNode != null) {
            fieldApiName = aliasNode.id;
            relationshipName = null;
        } else {
            Map<String, Object> comparables = ComparableService.getComparableDataFromNodes(fieldNode, selectNode);
            relationshipName = (String) comparables.get('relationshipName');
            fieldApiName = (String) comparables.get('comparableField');
        }

        return new Map<String, String> {
            'fieldApiName' => fieldApiName,
            'relationshipName' => relationshipName
        };       
    }

    private static Map<String, String> getAggrFuncAlias(Node curr, Integer exprNumber) {
        Node aggrFieldNode = curr.right;
        Node aliasNode = aggrFieldNode.left;
        String fieldApiName;
        if(aliasNode != null) {
            fieldApiName = aliasNode.id;
        } else {
            fieldApiName = 'expr' + exprNumber;
        }

        return new Map<String, String> {
            'fieldApiName' => fieldApiName,
            'relationshipName' => null
        };
    }
    
    public static Map<String, String> getAlias(Node selectNode, Node fieldNode) {
        Integer exprNumber = 0;

        Node curr = selectNode.left;
        while(curr != null) {
            Boolean isField = (curr.nodeType == 'field');
            Boolean isSameId = (curr.id == fieldNode.id);
            
            Boolean isAggregateFunc = (curr.nodeType == 'aggregate function');
            Boolean isSameAggrField = (isAggregateFunc && curr.right.id == fieldNode?.right?.id);

            if(isField && isSameId) {
                return getFieldAlias(curr, fieldNode, selectNode);
            } else if(isAggregateFunc && isSameAggrField && isSameId) {
                return getAggrFuncAlias(curr, exprNumber);
            } else if(isAggregateFunc) {
                exprNumber++;
            }
            curr = curr.left;
        }
        throw new QueryException('No alias found');
    }

    /** scary function, needs refactor */
    public static Map<String, String> getRollupFieldOrAlias(Node selectNode, Node rollupNode) {
        String fieldApiName;
        String relationshipName;
        Map<String, Object> aliasData;

        for(Node currSelect = selectNode.left; currSelect != null; currSelect = currSelect.left) {
            if(currSelect.id == rollupNode.id) {
                try {
                    aliasData = AliasService.getAlias(selectNode, currSelect);
                    fieldApiName = (String) aliasData.get('fieldApiName');
                    relationshipName = (String) aliasData.get('relationshipName');
                    break;
                } catch(QueryException ex) {
                    aliasData = ComparableService.getComparableDataFromNodes(currSelect, selectNode);
                    fieldApiName = (String) aliasData.get('comparableField');
                    relationshipName = (String) aliasData.get('relationshipName');
                    break;
                } catch(Exception ex) {
                    throw new QueryException('Invalid field or relationship name');
                }
            }
        }

        if(fieldApiName == null) {
            aliasData = ComparableService.getComparableDataFromNodes(rollupNode, selectNode);
            fieldApiName = (String) aliasData.get('comparableField');
            relationshipName = (String) aliasData.get('relationshipName');
            if(fieldApiName == null) {
                throw new QueryException('Invalid field or relationship name');
            }
        }

        return new Map<String, String> {
            'fieldOrAlias' => fieldApiName,
            'relationshipName' => relationshipName
        };
    }
}