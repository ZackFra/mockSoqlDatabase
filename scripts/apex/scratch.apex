MockDatabase db = new MockDatabase();
TestDataFactory.createUsers(db);
for(User u : (List<User>) db.query('SELECT FirstName, LastName, UserRole.Name, Profile.Name, Profile.UserLicense.Name FROM User')) {
    System.debug(u.FirstName);
    System.debug(u.LastName);
    System.debug(u.UserRole.Name);
    System.debug(u.Profile.Name);
    System.debug(u.Profile.UserLicense.Name);
}
System.debug('');
for(UserRole ur : (List<UserRole>) db.query('SELECT (SELECT FirstName, LastName, Profile.Name FROM Users) FROM UserRole WHERE Name = \'CEO\'')) {
    for(User u : ur.Users) {
        System.debug(u.FirstName);
        System.debug(u.LastName);
        System.debug(u.Profile.Name);
    }
}