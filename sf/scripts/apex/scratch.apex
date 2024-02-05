Integer limitSize = 5;
Integer offsetSize = 10;

System.debug([
    SELECT Id
    FROM Account
    LIMIT :limitSize
    OFFSET :offsetSize
]);