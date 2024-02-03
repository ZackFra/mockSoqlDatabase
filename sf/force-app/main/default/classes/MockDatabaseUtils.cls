public with sharing class MockDatabaseUtils {


    /** comparison handlers for WHERE and HAVING clauses */
    public interface OperatorHandler {
        Boolean handle(Object sObjectFieldValue, Object fieldValue);
    }

    public class EqualityHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            Boolean isSObjNull = (sObjectFieldValue == null);
            Boolean isFieldNull = (fieldValue == null);
            if(isSObjNull && isFieldNull) {
                return true;
            } else if(isSObjNull || isFieldNull) {
                return false;
            }

            return (String.valueOf(sObjectFieldValue).toLowerCase() == ((String)fieldValue).toLowerCase());
        }
    }

    public class InequalityHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            Boolean isSObjNull = (sObjectFieldValue == null);
            Boolean isFieldNull = (fieldValue == null);
            if(isSObjNull && isFieldNull) {
                return false;
            } else if(isSObjNull || isFieldNull) {
                return true;
            }
            return (String.valueOf(sObjectFieldValue).toLowerCase() != ((String)fieldValue).toLowerCase());
        }
    }

    public class LikeHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            if(sObjectFieldValue == null) {
                return false;
            }

            String regexPattern = String.valueOf(fieldValue)
                .toLowerCase()
                .replaceAll('%', '.*')
                .replaceAll('_', '.');
            Pattern regex = Pattern.compile(regexPattern);
            Matcher regexMatcher = regex.matcher(String.valueOf(sObjectFieldValue).toLowerCase());
            return regexMatcher.matches();
        }
    }

    public class InHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            if(sObjectFieldValue == null) {
                return false;
            }

            List<Object> values = (List<Object>) fieldValue;
            for(Integer i = 0; i < values.size(); i++) {
                if(values[i] instanceof String) {
                    values[i] = (Object) ((String) values[i]).toLowerCase();
                }
            }
            String nodeValue = String.valueOf(sObjectFieldValue).toLowerCase();
            return values.contains(nodeValue);
        }
    }

    public class NotInHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            if(sObjectFieldValue == null) {
                return false;
            }

            List<Object> values = (List<Object>) fieldValue;
            for(Integer i = 0; i < values.size(); i++) {
                if(values[i] instanceof String) {
                    values[i] = (Object) ((String) values[i]).toLowerCase();
                }
            }
            String nodeValue = String.valueOf(sObjectFieldValue).toLowerCase();
            return !values.contains(nodeValue);
        }
    }

    /**
     * @description : Clones a node and all of its children, recursively
     * @param head : Node, the head of the tree to clone
     * @return : Node, the cloned tree
     */
    public static Lexer.Node cloneNode(Lexer.Node head) {
        if(head == null) {
            return null;
        }
        Lexer.NodeBuilder nb = new Lexer.NodeBuilder()
            .setId(head.id)
            .setNodeType(head.nodeType);
        if(head.left != null) {
            nb.setLeft(cloneNode(head.left));
        }
        if(head.right != null) {
            nb.setRight(cloneNode(head.right));
        }
        return nb.build();
    }

    private static Time parseTime(String timeString) {
        List<String> strTimeSplit = timeString.split(':');
        String strHour = strTimeSplit[0];
        String strMin = strTimeSplit[1];
        String strSec = strTimeSplit[2].substringBefore('.');
        String strMilliSec = strTimeSplit[2].substringAfter('.').removeEnd('Z');
        return Time.newInstance( 
            Integer.valueOf(strHour),
            Integer.valueOf(strMin),
            Integer.valueOf(strSec),
            Integer.valueOf(strMilliSec)
        );
    }

    public class GreaterThanHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            if(sObjectFieldValue == null) {
                return false;
            }

            if(sObjectFieldValue instanceOf Date) {
                Date fieldDate = Date.parse((String) fieldValue);
                Date sObjDate = (Date) sObjectFieldValue;
                return sObjDate > fieldDate;
            } else if(sObjectFieldValue instanceOf DateTime) {
                DateTime fieldDateTime = DateTime.parse((String) fieldValue);
                DateTime sObjDateTime = (DateTime) sObjectFieldValue;
                return sObjDateTime > fieldDateTime;
            } else if(sObjectFieldValue instanceOf Time) {
                Time sObjTime = (Time) sObjectFieldValue;
                return sObjTime > parseTime((String) fieldValue);
            } else if(sObjectFieldValue instanceOf Integer) {
                Integer fieldInt = Integer.valueOf((String)fieldValue);
                Integer sObjInt = (Integer) sObjectFieldValue;
                return sObjInt > fieldInt;
            } else if(sObjectFieldValue instanceOf Decimal) {
                Decimal fieldDec = Decimal.valueOf((String)fieldValue);
                Decimal sObjDec = (Decimal) sObjectFieldValue;
                return sObjDec > fieldDec;
            } else if(sObjectFieldValue instanceOf Double) {
                Double fieldDouble = Double.valueOf((String)fieldValue);
                Double sObjDouble = (Double) sObjectFieldValue;
                return sObjDouble > fieldDouble;
            } else if(sObjectFieldValue instanceOf Long) {
                Long fieldLong = Long.valueOf((String) fieldValue);
                Long sObjLong = (Long) sObjectFieldValue;
                return sObjLong > fieldLong;
            } else if(sObjectFieldValue instanceOf String) {
                String fieldString = ((String) fieldValue).toLowerCase();
                String sObjString = ((String) sObjectFieldValue).toLowerCase();
                return sObjString > fieldString;
            } else {
                throw new QueryException('Invalid field type');
            }
        }
    }

    public class LessThanHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            if(sObjectFieldValue == null) {
                return false;
            }

            if(sObjectFieldValue instanceOf Date) {
                Date fieldDate = Date.valueOf((String) fieldValue);
                Date sObjDate = (Date) sObjectFieldValue;
                return sObjDate < fieldDate;
            } else if(sObjectFieldValue instanceOf DateTime) {
                DateTime fieldDateTime = DateTime.valueOf((String) fieldValue);
                DateTime sObjDateTime = (DateTime) sObjectFieldValue;
                return sObjDateTime < fieldDateTime;
            } else if(sObjectFieldValue instanceOf Time) {
                Time sObjTime = (Time) sObjectFieldValue;
                return sObjTime < parseTime((String) fieldValue);
            } else if(sObjectFieldValue instanceOf Integer) {
                Integer fieldInt = Integer.valueOf((String)fieldValue);
                Integer sObjInt = (Integer) sObjectFieldValue;
                return sObjInt < fieldInt;
            } else if(sObjectFieldValue instanceOf Decimal) {
                Decimal fieldDec = Decimal.valueOf((String)fieldValue);
                Decimal sObjDec = (Decimal) sObjectFieldValue;
                return sObjDec < fieldDec;
            } else if(sObjectFieldValue instanceOf Double) {
                Double fieldDouble = Double.valueOf((String)fieldValue);
                Double sObjDouble = (Double) sObjectFieldValue;
                return sObjDouble < fieldDouble;
            } else if(sObjectFieldValue instanceOf Long) {
                Long fieldLong = Long.valueOf((String) fieldValue);
                Long sObjLong = (Long) sObjectFieldValue;
                return sObjLong < fieldLong;
            } else if(sObjectFieldValue instanceOf String) {
                String fieldString = ((String) fieldValue).toLowerCase();
                String sObjString = ((String) sObjectFieldValue).toLowerCase();
                return sObjString < fieldString;
            } else {
                throw new QueryException('Invalid field type');
            }
        }
    }

    public class GreaterThanOrEqualHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            if(sObjectFieldValue == null) {
                return false;
            }

            if(sObjectFieldValue instanceOf Date) {
                Date fieldDate = Date.valueOf((String) fieldValue);
                Date sObjDate = (Date) sObjectFieldValue;
                return sObjDate >= fieldDate;
            } else if(sObjectFieldValue instanceOf DateTime) {
                DateTime fieldDateTime = DateTime.valueOf((String) fieldValue);
                DateTime sObjDateTime = (DateTime) sObjectFieldValue;
                return sObjDateTime >= fieldDateTime;
            } else if(sObjectFieldValue instanceOf Time) {
                Time sObjTime = (Time) sObjectFieldValue;
                return sObjTime >= parseTime((String) fieldValue);
            } else if(sObjectFieldValue instanceOf Integer) {
                Integer fieldInt = Integer.valueOf((String)fieldValue);
                Integer sObjInt = (Integer) sObjectFieldValue;
                return sObjInt >= fieldInt;
            } else if(sObjectFieldValue instanceOf Decimal) {
                Decimal fieldDec = Decimal.valueOf((String)fieldValue);
                Decimal sObjDec = (Decimal) sObjectFieldValue;
                return sObjDec >= fieldDec;
            } else if(sObjectFieldValue instanceOf Double) {
                Double fieldDouble = Double.valueOf((String)fieldValue);
                Double sObjDouble = (Double) sObjectFieldValue;
                return sObjDouble >= fieldDouble;
            } else if(sObjectFieldValue instanceOf Long) {
                Long fieldLong = Long.valueOf((String) fieldValue);
                Long sObjLong = (Long) sObjectFieldValue;
                return sObjLong >= fieldLong;
            } else if(sObjectFieldValue instanceOf String) {
                String fieldString = ((String) fieldValue).toLowerCase();
                String sObjString = ((String) sObjectFieldValue).toLowerCase();
                return sObjString >= fieldString;
            } else {
                throw new QueryException('Invalid field type');
            }
        }
    }

    public class LessThanOrEqualHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            if(sObjectFieldValue == null) {
                return false;
            }

            if(sObjectFieldValue instanceOf Date) {
                Date fieldDate = Date.valueOf((String) fieldValue);
                Date sObjDate = (Date) sObjectFieldValue;
                return sObjDate <= fieldDate;
            } else if(sObjectFieldValue instanceOf DateTime) {
                DateTime fieldDateTime = DateTime.valueOf((String) fieldValue);
                DateTime sObjDateTime = (DateTime) sObjectFieldValue;
                return sObjDateTime <= fieldDateTime;
            } else if(sObjectFieldValue instanceOf Time) {
                Time sObjTime = (Time) sObjectFieldValue;
                return sObjTime <= parseTime((String) fieldValue);
            } else if(sObjectFieldValue instanceOf Integer) {
                Integer fieldInt = Integer.valueOf((String)fieldValue);
                Integer sObjInt = (Integer) sObjectFieldValue;
                return sObjInt <= fieldInt;
            } else if(sObjectFieldValue instanceOf Decimal) {
                Decimal fieldDec = Decimal.valueOf((String)fieldValue);
                Decimal sObjDec = (Decimal) sObjectFieldValue;
                return sObjDec <= fieldDec;
            } else if(sObjectFieldValue instanceOf Double) {
                Double fieldDouble = Double.valueOf((String)fieldValue);
                Double sObjDouble = (Double) sObjectFieldValue;
                return sObjDouble <= fieldDouble;
            } else if(sObjectFieldValue instanceOf Long) {
                Long fieldLong = Long.valueOf((String) fieldValue);
                Long sObjLong = (Long) sObjectFieldValue;
                return sObjLong <= fieldLong;
            } else if(sObjectFieldValue instanceOf String) {
                String fieldString = ((String) fieldValue).toLowerCase();
                String sObjString = ((String) sObjectFieldValue).toLowerCase();
                return sObjString <= fieldString;
            } else {
                throw new QueryException('Invalid field type');
            }
        }
    }

    public class IncludesHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            List<Object> values = (List<Object>) fieldValue;
            return values.contains(sObjectFieldValue);
        }
    }

    public class ExcludesHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            List<Object> values = (List<Object>) fieldValue;
            return !values.contains(sObjectFieldValue);
        }
    }

    public class OperatorHandlerFactory {
        public OperatorHandler getHandler(String operator) {
            switch on operator {
                when '=' {
                    return new EqualityHandler();
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
}