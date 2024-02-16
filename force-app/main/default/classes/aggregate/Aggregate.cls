/**
 * @description Mock class for AggregateResult, acts as a read-only map
 */
public with sharing class Aggregate {
    private Map<String, Object> ar;

    /**
     * @description Constructor
     * @param ar - the map to be used
     */
    public Aggregate(Map<String, Object> ar) {
        this.ar = ar;
    }

    /**
     * @description Returns the value to which the specified key is mapped, or null if this map contains no mapping for the key.
     * @param key - the key whose associated value is to be returned
     * @return the value to which the specified key is mapped, or null if this map contains no mapping for the key
     */
    public Object get(String key) {
        return this.ar.get(key);
    }

    @TestVisible
    private Set<String> keySet() {
        return this.ar.keySet();
    }

    /**
     * @description Returns the map as a string
     * @return the map as a string
     */
    public override String toString() {
        return this.ar.toString();
    }
}