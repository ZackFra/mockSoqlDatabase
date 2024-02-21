MockDatabase db = new MockDatabase();
TestDataFactory.createUsers(db);
Integer k = 0;
for(User u : (List<User>) db.query('SELECT FirstName, LastName, UserRole.Name, Profile.Name, Profile.UserLicense.Name FROM User')) {
    System.debug('User ' + (k++));
    System.debug('First Name ' + u.FirstName);
    System.debug('Last Name ' + u.LastName);
    System.debug('Role Name ' + u.UserRole.Name);
    System.debug('Profile Name ' + u.Profile.Name);
    System.debug('User License Name ' + u.Profile.UserLicense.Name);
}
System.debug('');
for(UserRole ur : (List<UserRole>) db.query('SELECT (SELECT FirstName, LastName, Profile.Name FROM Users) FROM UserRole WHERE Name = \'CEO\'')) {
    Integer i = 0;
    for(User u : ur.Users) {
        System.debug('User ' + (i++));
        System.debug('First Name ' + u.FirstName);
        System.debug('Last Name ' + u.LastName);
        System.debug('Profile Name ' + u.Profile.Name);
    }
}