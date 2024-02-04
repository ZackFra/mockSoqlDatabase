/**
 * Description: This class is used to compare two generic objects of the same type.
 */
public with sharing class ObjectComparator implements Comparable {

    private Object obj;
    public ObjectComparator(Object obj) {
        this.obj = obj;
    }

    /**
     * Description: This method compares two generic objects of the same type.
     * @param obj1: The first object to compare.
     * @param obj2: The second object to compare.
     * @return: An integer value indicating the result of the comparison.
     * @throws UnsupportedTypeException: If the type of the objects is not supported.
     */
    public Integer compareTo(Object objectToCompareto) {
        if(!checkType(objectToCompareto)) {
            throw new UnsupportedTypeException('These objects must be of the same type');
        }

        Integer result = checkNull(objectToCompareto);
        if(result != null) {
            return result;
        }
        result = checkSupportedObjects(objectToCompareto);
        if(result != null) {
            return result;
        }
        throw new UnsupportedTypeException('The type of the objects is not supported.');
    }

    private class UnsupportedTypeException extends Exception {}

    private Boolean checkType(Object obj) {
        if(this.obj instanceof String && obj instanceof String) {
            return true;
        } else if(this.obj instanceof Integer && obj instanceof Integer) {
            return true;
        } else if(this.obj instanceof Decimal && obj instanceof Decimal) {
            return true;
        } else if(this.obj instanceof Date && obj instanceof Date) {
            return true;
        } else if(this.obj instanceof DateTime && obj instanceof DateTime) {
            return true;
        } else if(this.obj instanceof Time && obj instanceof Time) {
            return true;
        } else if(this.obj instanceof Boolean && obj instanceof Boolean) {
            return true;
        } else if(this.obj instanceof Id && obj instanceof Id) {
            return true;
        }

        return false;
    }

    /**
     * Description: This method compares two generic objects of the same type.
     * @param obj: The object to compare.
     * @return: An integer value indicating the result of the comparison.
     */
    private Integer checkSupportedObjects(Object objectToCompareTo) {
        Object obj1 = this.obj;
        Object obj2 = objectToCompareTo;

        if (obj1 instanceof String) {
            return ((String)obj1).compareTo((String)obj2);
        } else if (obj1 instanceof Integer) {
            return (Integer)obj1 - (Integer) obj2;
        } else if (obj1 instanceof Decimal) {
            Decimal result = (Decimal) obj1 - (Decimal) obj2;
            if(result == 0) {
                return 0;
            } else if(result > 0) {
                return 1;
            } else {
                return -1;
            }
        } else if (obj1 instanceof Date) {
            Boolean result = ((Date) obj1).isSameDay((Date) obj2);
            if(result) {
                return 0;
            } else if(((Date) obj1) > ((Date) obj2)) {
                return 1;
            } else {
                return -1;
            }
        } else if (obj1 instanceof DateTime) {
            Boolean result = ((DateTime) obj1).isSameDay((DateTime) obj2);
            if(result) {
                return 0;
            } else if(((DateTime) obj1) > ((DateTime) obj2)) {
                return 1;
            } else {
                return -1;
            }
        } else if (obj1 instanceof Time) {
            DateTime dt1 = DateTime.newInstanceGmt(2000, 1, 1, ((Time) obj1).hour(), ((Time) obj1).minute(), ((Time) obj1).second());
            DateTime dt2 = DateTime.newInstanceGmt(2000, 1, 1, ((Time) obj2).hour(), ((Time) obj2).minute(), ((Time) obj2).second());
            Long result = dt1.getTime() - dt2.getTime();
            if(result == 0) {
                return 0;
            } else if(result > 0) {
                return 1;
            } else {
                return -1;
            }
        } else if (obj1 instanceof Boolean) {
            if( ((Boolean)obj1) && ((Boolean)obj2)) {
                return 0;
            } else if((Boolean)obj1) {
                return 1;
            }
            return -1;
        } else if (obj1 instanceof Id) {
            return ((String)obj1).compareTo((String)obj2);
        }
        return null;
    }

    private Integer checkNull(Object objectToCompareTo) {
        Object obj1 = this.obj;
        Object obj2 = objectToCompareTo;

        if (obj1 == null && obj2 == null) {
            return 0;
        } else if (obj1 == null) {
            return -1;
        } else if (obj2 == null) {
            return 1;
        }
        return null;
    }
}