Tokenizer t = new Tokenizer();
Tokenizer.Node head = t.parse('SELECT Id FROM Account');
String result = head.toString();
System.debug(result);