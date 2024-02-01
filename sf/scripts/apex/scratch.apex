//Time t = DateTime.parse( '1970-01-01 ' + '09:45:25.000Z').time();
DateTime dt = DateTime.newInstance(2002, 11, 21, 0, 2, 2);
Time t = dt.timeGmt();
String strTime = '09:45:25.000Z';
String[] strTimeSplit = strTime.split(':');

String strHour = strTimeSplit[0];
String strMin = strTimeSplit[1];
String strSec = strTimeSplit[2].substringBefore('.');
String strMilliSec = strTimeSplit[2].substringAfter('.').removeEnd('Z');
Time timeChange = Time.newInstance( Integer.valueOf(strHour) //hour
                                     ,Integer.valueOf(strMin) //min
                                     ,Integer.valueOf(strSec)  //sec
                                     ,Integer.valueOf(strMilliSec)); //millisecond
System.debug(timeChange);