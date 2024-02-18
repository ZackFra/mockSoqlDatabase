public with sharing class CountOffsetHandler implements IOffsetHandler {
    private final OffsetOptions options;
    public CountOffsetHandler(OffsetOptions options) {
        this.options = options;
    }

    public Object handleOffset() {
        Integer offset = options.offset;
        Object obj = options.obj;

        Integer value = (Integer) obj - offset;
        if(value < 0) {
            value = 0;
        }
        return value;
    }
}