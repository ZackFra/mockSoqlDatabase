public class OperatorHandlerFactory {
    public IOperatorHandler getHandler(String operator) {
        switch on operator {
            when '=' {
                return new EqualityHandler();
            }
            when '<>' {
                return new InequalityHandler();
            } 
            when '!=' {
                return new InequalityHandler();
            }
            when 'like' {
                return new LikeHandler();
            }
            when 'in' {
                return new InHandler();
            }
            when 'not in' {
                return new NotInHandler();
            }
            when '>' {
                return new GreaterThanHandler();
            }
            when '<' {
                return new LessThanHandler();
            }
            when '>=' {
                return new GreaterThanOrEqualHandler();
            }
            when '<=' {
                return new LessThanOrEqualHandler();
            }
            when 'includes' {
                return new IncludesHandler();
            }
            when 'excludes' {
                return new ExcludesHandler();
            }
            when else {
                throw new QueryException('Invalid operator');
            }
        }
    }
}