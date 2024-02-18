public with sharing class RecordOffsetHandler implements IOffsetHandler {

    private OffsetOptions options;
    public RecordOffsetHandler(OffsetOptions options) {
        this.options = options;
    }

    public Object handleOffset() {
        Integer offset = options.offset;
        Object obj = options.obj;

        List<SObject> sObjResults = new List<SObject>((List<SObject>) obj);
        while(offset > 0) {
            sObjResults.remove(0);
            offset--;
        }
        return sObjResults;
    }
}