System.debug([
    SELECT Account.Name, COUNT(Id) idCount
    FROM Contact  
    GROUP BY Account.Name
    ORDER BY Account.Name, COUNT(Id)
]);