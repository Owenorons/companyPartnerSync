@IsTest
public class TestUserFactory {
  public static User createInternalUser() {
    Profile profile = [
      SELECT Id
      FROM Profile
      WHERE UserType = 'Standard'
      LIMIT 1
    ];

    User user = new User(
      FirstName = 'Internal',
      LastName = 'User',
      Email = uniqueEmail('internal'),
      Username = uniqueEmail('internal'),
      Alias = 'intusr',
      TimeZoneSidKey = 'Australia/Melbourne',
      LocaleSidKey = 'en_AU',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      ProfileId = profile.Id
    );

    insert user;

    return user;
  }

  public static User createExternalUser(Id contactId) {
    Profile profile = [
      SELECT Id
      FROM Profile
      WHERE UserType != 'Standard'
      LIMIT 1
    ];

    User user = new User(
      FirstName = 'Partner',
      LastName = 'User',
      Email = uniqueEmail('partner'),
      Username = uniqueEmail('partner'),
      Alias = 'prtusr',
      TimeZoneSidKey = 'Australia/Melbourne',
      LocaleSidKey = 'en_AU',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      ProfileId = profile.Id,
      ContactId = contactId
    );

    insert user;

    return user;
  }

  private static String uniqueEmail(String prefix) {
    return prefix + DateTime.now().getTime() + '@example.com';
  }
}
