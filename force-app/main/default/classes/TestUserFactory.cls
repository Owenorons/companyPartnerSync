/*
 * Builds and inserts User records for tests that need to run assertions
 * under a specific access profile (System.runAs). Distinguishes three
 * distinct access levels - arbitrary internal, admin-with-no-permission-sets,
 * and external/partner community user - since sharing and FLS behavior
 * differs meaningfully between them; see createInternalAdminUser() below for
 * why that one in particular is not just "an internal user with more access".
 */
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

  /*
   * A System Administrator has View/Modify All Data, so unlike
   * createInternalUser() (an arbitrary Standard-type profile with no implicit
   * data access), this user can read/write any record without needing
   * sharing or field-level security granted — while still having none of the
   * org's business permission sets assigned. Use this to model a real admin
   * who schedules/runs a job but was never assigned a feature-specific
   * permission set, as opposed to a user blocked by data access entirely.
   */
  public static User createInternalAdminUser() {
    Profile profile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'System Administrator'
      LIMIT 1
    ];

    User user = new User(
      FirstName = 'Internal',
      LastName = 'Admin',
      Email = uniqueEmail('admin'),
      Username = uniqueEmail('admin'),
      Alias = 'adminusr',
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

  public static void assignPermissionSet(Id userId, String permissionSetName) {
    PermissionSet permissionSet = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = :permissionSetName
      LIMIT 1
    ];

    insert new PermissionSetAssignment(
      AssigneeId = userId,
      PermissionSetId = permissionSet.Id
    );
  }

  public static void assignPermissionSetGroup(
    Id userId,
    String permissionSetGroupName
  ) {
    PermissionSetGroup permissionSetGroup = [
      SELECT Id
      FROM PermissionSetGroup
      WHERE DeveloperName = :permissionSetGroupName
      LIMIT 1
    ];

    insert new PermissionSetAssignment(
      AssigneeId = userId,
      PermissionSetGroupId = permissionSetGroup.Id
    );
  }

  private static String uniqueEmail(String prefix) {
    return prefix + DateTime.now().getTime() + '@example.com';
  }
}
