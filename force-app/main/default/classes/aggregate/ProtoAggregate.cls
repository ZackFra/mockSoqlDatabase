/**
 * @description before we create an aggregate, wean a proto-aggregate,
 * i.e. a Map<String, Object> that will be used to store the aggregate
 */
public with sharing class ProtoAggregate {
    Map<String, Object> prototype = new Map<String, Object>();

    public ProtoAggregate(Map<String, Object> prototype) {
        this.prototype = prototype;
    }

    public ProtoAggregate() {
        this.prototype = new Map<String, Object>();
    }

    public void put(String key, Object value) {
        this.prototype.put(key, value);
    }

    public Object get(String key) {
        return this.prototype.get(key);
    }

    public void remove(String key) {
        this.prototype.remove(key);
    }

    public void clear() {
        this.prototype.clear();
    }

    public Integer size() {
        return this.prototype.size();
    }

    public Boolean isEmpty() {
        return this.prototype.isEmpty();
    }

    public Boolean containsKey(String key) {
        return this.prototype.containsKey(key);
    }

    public Set<String> keySet() {
        return this.prototype.keySet();
    }

    public List<Object> values() {
        return this.prototype.values();
    }

}