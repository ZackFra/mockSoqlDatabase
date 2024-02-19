public abstract class OrderByHandler {
    protected OrderByOptions options;
    public OrderByHandler(OrderByOptions options) {
        this.options = options;
    }

    public abstract Object handleOrderBy();
    protected abstract Object sortByOrderBy();
}