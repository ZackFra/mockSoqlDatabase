String dateTimeString = '2020-01-01T01:01:01-00:00';
Pattern datePattern1 = Pattern.compile('([0-9]{4})\\-([0-9]{2})\\-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})\\-([0-9]{2}):([0-9]{2})');
Matcher dateMatcher1 = datePattern1.matcher(dateTimeString);
dateMatcher1.matches();
Integer year = Integer.valueOf(dateMatcher1.group(1));
Integer month = Integer.valueOf(dateMatcher1.group(2));
Integer day = Integer.valueOf(dateMatcher1.group(3));
Integer hour = Integer.valueOf(dateMatcher1.group(4));
Integer min = Integer.valueOf(dateMatcher1.group(5));
Integer sec = Integer.valueOf(dateMatcher1.group(6));
Integer offsetHour = Integer.valueOf(dateMatcher1.group(7));
Integer offsetMin = Integer.valueOf(dateMatcher1.group(8));
DateTime comparable1 = DateTime.newInstanceGmt(year, month, day, hour, min, sec)
                .addHours(offsetHour)
                .addMinutes(offsetMin);

DateTime comparable2 = DateTime.newInstanceGmt(2020, 1, 1, 1, 1, 1);

System.debug(comparable1);
System.debug(comparable2);