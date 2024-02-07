public with sharing class MockDatabaseUtils {

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

            if(sObjectFieldValue instanceof Date) {
                fieldValue = parseDate((String) fieldValue);
                return fieldValue == (Date) sObjectFieldValue;
            } else if(SObjectFieldValue instanceof DateTime) {
                fieldValue = parseDateTime((String) fieldValue);
                return fieldValue == (DateTime) sObjectFieldValue;
            } else if(SObjectFieldValue instanceof Time) {
                fieldValue = parseTime((String) fieldValue);
                return fieldValue == (Time) sObjectFieldValue;
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

            if(sObjectFieldValue instanceof Date) {
                fieldValue = (Object) parseDate((String) fieldValue).toString();
            } else if(SObjectFieldValue instanceof DateTime) {
                fieldValue = (Object) parseDateTime((String) fieldValue).toString();
            } else if(SObjectFieldValue instanceof Time) {
                fieldValue = (Object) parseTime((String) fieldValue).toString();
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

    private static Time parseTime(String timeString) {
        Pattern timePattern = Pattern.compile('([0-9]{2}):([0-9]{2}):([0-9]{2})\\.([0-9]{3})Z');
        Matcher timeMatcher = timePattern.matcher(timeString);
        if(!timeMatcher.matches()) {
            throw new QueryException('Invalid time format');
        }
        return Time.newInstance( 
            Integer.valueOf(timeMatcher.group(1)),
            Integer.valueOf(timeMatcher.group(2)),
            Integer.valueOf(timeMatcher.group(3)),
            Integer.valueOf(timeMatcher.group(4))
        );
    }

    private static Date parseDate(String dateString) {
        Pattern datePattern = Pattern.compile('([0-9]{4})\\-([0-9]{2})\\-([0-9]{2})');
        Matcher dateMatcher = datePattern.matcher(dateString);
        if(!dateMatcher.matches()) {
            throw new QueryException('Invalid date format');
        }
        return Date.newInstance(
            Integer.valueOf(dateMatcher.group(1)),
            Integer.valueOf(dateMatcher.group(2)),
            Integer.valueOf(dateMatcher.group(3))
        );
    }

    private static DateTime parseDateTime(String dateTimeString) {
        // YYYY-MM-DDThh:mm:ss+hh:mm
        Pattern datePattern1 = Pattern.compile('([0-9]{4})\\-([0-9]{2})\\-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})\\+([0-9]{2}):([0-9]{2})');
        Matcher dateMatcher1 = datePattern1.matcher(dateTimeString);
        if(dateMatcher1.matches()) {
            Integer year = Integer.valueOf(dateMatcher1.group(1));
            Integer month = Integer.valueOf(dateMatcher1.group(2));
            Integer day = Integer.valueOf(dateMatcher1.group(3));
            Integer hour = Integer.valueOf(dateMatcher1.group(4));
            Integer min = Integer.valueOf(dateMatcher1.group(5));
            Integer sec = Integer.valueOf(dateMatcher1.group(6));
            Integer offsetHour = Integer.valueOf(dateMatcher1.group(7));
            Integer offsetMin = Integer.valueOf(dateMatcher1.group(8));
            return DateTime.newInstanceGmt(year, month, day, hour, min, sec)
                .addHours(offsetHour)
                .addMinutes(offsetMin);
        }
        // YYYY-MM-DDThh:mm:ss-hh:mm
        Pattern datePattern2 = Pattern.compile('([0-9]{4})\\-([0-9]{2})\\-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})\\-([0-9]{2}):([0-9]{2})');
        Matcher dateMatcher2 = datePattern2.matcher(dateTimeString);
        if(dateMatcher2.matches()) {
            Integer year = Integer.valueOf(dateMatcher2.group(1));
            Integer month = Integer.valueOf(dateMatcher2.group(2));
            Integer day = Integer.valueOf(dateMatcher2.group(3));
            Integer hour = Integer.valueOf(dateMatcher2.group(4));
            Integer min = Integer.valueOf(dateMatcher2.group(5));
            Integer sec = Integer.valueOf(dateMatcher2.group(6));
            Integer offsetHour = Integer.valueOf(dateMatcher2.group(7));
            Integer offsetMin = Integer.valueOf(dateMatcher2.group(8));
            return DateTime.newInstanceGmt(year, month, day, hour, min, sec)
                .addHours(-offsetHour)
                .addMinutes(-offsetMin);
        }
        // YYYY-MM-DDThh:mm:ssZ
        Pattern datePattern3 = Pattern.compile('([0-9]{4})\\-([0-9]{2})\\-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})Z');
        Matcher dateMatcher3 = datePattern3.matcher(dateTimeString);
        if(dateMatcher3.matches()) {
            Integer year = Integer.valueOf(dateMatcher3.group(1));
            Integer month = Integer.valueOf(dateMatcher3.group(2));
            Integer day = Integer.valueOf(dateMatcher3.group(3));
            Integer hour = Integer.valueOf(dateMatcher3.group(4));
            Integer min = Integer.valueOf(dateMatcher3.group(5));
            Integer sec = Integer.valueOf(dateMatcher3.group(6));
            return DateTime.newInstanceGmt(year, month, day, hour, min, sec);
        }

        throw new QueryException('Invalid date time format');
    }

    public class GreaterThanHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            if(sObjectFieldValue == null) {
                return false;
            }

            if(sObjectFieldValue instanceOf Date) {
                Date fieldDate = parseDate((String) fieldValue);
                Date sObjDate = (Date) sObjectFieldValue;
                return sObjDate > fieldDate;
            } else if(sObjectFieldValue instanceOf DateTime) {
                DateTime fieldDateTime = parseDateTime((String) fieldValue);
                DateTime sObjDateTime = (DateTime) sObjectFieldValue;
                return sObjDateTime > fieldDateTime;
            } else if(sObjectFieldValue instanceOf Time) {
                Time sObjTime = (Time) sObjectFieldValue;
                return sObjTime > parseTime((String) fieldValue);
            } else if(sObjectFieldValue instanceOf Integer) {
                Integer fieldInt = Integer.valueOf((String)fieldValue);
                Integer sObjInt = (Integer) sObjectFieldValue;
                return sObjInt > fieldInt;
            }  else if(sObjectFieldValue instanceOf Long) {
                Long fieldLong = Long.valueOf((String) fieldValue);
                Long sObjLong = (Long) sObjectFieldValue;
                return sObjLong > fieldLong;
            } else if(sObjectFieldValue instanceOf String) {
                String fieldString = ((String) fieldValue).toLowerCase();
                String sObjString = ((String) sObjectFieldValue).toLowerCase();
                return sObjString > fieldString;
            } else if(sObjectFieldValue instanceOf Decimal) {
                // Doubles are 64-bit floating point numbers, Decimals are 128-bit floating point numbers
                // i.e. it's safe to compare a Decimal to a Double, and all Decimals and Doubles are instances of each other.
                // i.e. (Double instanceof Decimal) == (Decimal instanceof Double) == true
                // it's dumb as fuck
                Decimal fieldDec = Decimal.valueOf((String)fieldValue);
                Decimal sObjDec = (Decimal) sObjectFieldValue;
                return sObjDec > fieldDec;
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
                Date fieldDate = parseDate((String) fieldValue);
                Date sObjDate = (Date) sObjectFieldValue;
                return sObjDate < fieldDate;
            } else if(sObjectFieldValue instanceOf DateTime) {
                DateTime fieldDateTime = parseDateTime((String) fieldValue);
                DateTime sObjDateTime = (DateTime) sObjectFieldValue;
                return sObjDateTime < fieldDateTime;
            } else if(sObjectFieldValue instanceOf Time) {
                Time sObjTime = (Time) sObjectFieldValue;
                return sObjTime < parseTime((String) fieldValue);
            } else if(sObjectFieldValue instanceOf Integer) {
                Integer fieldInt = Integer.valueOf((String)fieldValue);
                Integer sObjInt = (Integer) sObjectFieldValue;
                return sObjInt < fieldInt;
            }  else if(sObjectFieldValue instanceOf Long) {
                Long fieldLong = Long.valueOf((String) fieldValue);
                Long sObjLong = (Long) sObjectFieldValue;
                return sObjLong < fieldLong;
            } else if(sObjectFieldValue instanceOf String) {
                String fieldString = ((String) fieldValue).toLowerCase();
                String sObjString = ((String) sObjectFieldValue).toLowerCase();
                return sObjString < fieldString;
            } else if(sObjectFieldValue instanceOf Decimal) {
                Decimal fieldDec = Decimal.valueOf((String)fieldValue);
                Decimal sObjDec = (Decimal) sObjectFieldValue;
                return sObjDec < fieldDec;
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
                Date fieldDate = parseDate((String) fieldValue);
                Date sObjDate = (Date) sObjectFieldValue;
                return sObjDate >= fieldDate;
            } else if(sObjectFieldValue instanceOf DateTime) {
                DateTime fieldDateTime = parseDateTime((String) fieldValue);
                DateTime sObjDateTime = (DateTime) sObjectFieldValue;
                return sObjDateTime >= fieldDateTime;
            } else if(sObjectFieldValue instanceOf Time) {
                Time sObjTime = (Time) sObjectFieldValue;
                return sObjTime >= parseTime((String) fieldValue);
            } else if(sObjectFieldValue instanceOf Integer) {
                Integer fieldInt = Integer.valueOf((String)fieldValue);
                Integer sObjInt = (Integer) sObjectFieldValue;
                return sObjInt >= fieldInt;
            }  else if(sObjectFieldValue instanceOf Long) {
                Long fieldLong = Long.valueOf((String) fieldValue);
                Long sObjLong = (Long) sObjectFieldValue;
                return sObjLong >= fieldLong;
            } else if(sObjectFieldValue instanceOf String) {
                String fieldString = ((String) fieldValue).toLowerCase();
                String sObjString = ((String) sObjectFieldValue).toLowerCase();
                return sObjString >= fieldString;
            } else if(sObjectFieldValue instanceOf Decimal) {
                Decimal fieldDec = Decimal.valueOf((String)fieldValue);
                Decimal sObjDec = (Decimal) sObjectFieldValue;
                return sObjDec >= fieldDec;
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
                Date fieldDate = parseDate((String) fieldValue);
                Date sObjDate = (Date) sObjectFieldValue;
                return sObjDate <= fieldDate;
            } else if(sObjectFieldValue instanceOf DateTime) {
                DateTime fieldDateTime = parseDateTime((String) fieldValue);
                DateTime sObjDateTime = (DateTime) sObjectFieldValue;
                return sObjDateTime <= fieldDateTime;
            } else if(sObjectFieldValue instanceOf Time) {
                Time sObjTime = (Time) sObjectFieldValue;
                return sObjTime <= parseTime((String) fieldValue);
            } else if(sObjectFieldValue instanceOf Integer) {
                Integer fieldInt = Integer.valueOf((String)fieldValue);
                Integer sObjInt = (Integer) sObjectFieldValue;
                return sObjInt <= fieldInt;
            }  else if(sObjectFieldValue instanceOf Long) {
                Long fieldLong = Long.valueOf((String) fieldValue);
                Long sObjLong = (Long) sObjectFieldValue;
                return sObjLong <= fieldLong;
            } else if(sObjectFieldValue instanceOf String) {
                String fieldString = ((String) fieldValue).toLowerCase();
                String sObjString = ((String) sObjectFieldValue).toLowerCase();
                return sObjString <= fieldString;
            } else if(sObjectFieldValue instanceOf Decimal) {
                Decimal fieldDec = Decimal.valueOf((String)fieldValue);
                Decimal sObjDec = (Decimal) sObjectFieldValue;
                return sObjDec <= fieldDec;
            } else {
                throw new QueryException('Invalid field type');
            }
        }
    }

    public class IncludesHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            List<String> values = new List<String>();
            try {
                List<Object> objList = (List<Object>) fieldValue;
                for(Object obj : objList) {
                    values.add(
                        ((String) obj).toLowerCase() + ';'
                    );
                }
            } catch(Exception ex) {
                throw new QueryException('Includes expects a list of strings');
            }
            String fieldString = ((String) sObjectFieldValue).toLowerCase();
            for(String value : values) {
                if(fieldString.contains(value)) {
                    return true;
                }
            }
            return false;
        }
    }

    public class ExcludesHandler implements OperatorHandler {
        public Boolean handle(Object sObjectFieldValue, Object fieldValue) {
            IncludesHandler includesHandler = new IncludesHandler();
            return !includesHandler.handle(sObjectFieldValue, fieldValue);
        }
    }

    public class OperatorHandlerFactory {
        public OperatorHandler getHandler(String operator) {
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
}