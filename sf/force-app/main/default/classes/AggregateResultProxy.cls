// a map with no put method
public with sharing class AggregateResultProxy {
    private Map<String, Object> ar;
    public AggregateResultProxy(Map<String, Object> ar) {
        this.ar = ar;
    }

    public Object get(String key) {
        return this.ar.get(key);
    }

    public override String toString() {
        return this.ar.toString();
    }
}