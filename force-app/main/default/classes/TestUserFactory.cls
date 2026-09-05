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
      WHERE Name = 'Standard User'
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
    List<Profile> candidates = [
      SELECT Id, Name
      FROM Profile
      WHERE
        Name IN (
          'PartnerSync Partner Tester',
          'Customer Community User',
          'Partner Community User'
        )
    ];
    Map<String, Profile> profilesByName = new Map<String, Profile>();
    for (Profile candidate : candidates) {
      profilesByName.put(candidate.Name, candidate);
    }
    Profile profile = profilesByName.get('PartnerSync Partner Tester');
    if (profile == null) {
      profile = profilesByName.get('Customer Community User');
    }
    if (profile == null) {
      profile = profilesByName.get('Partner Community User');
    }
    System.assertNotEquals(
      null,
      profile,
      'An Experience Cloud profile is required for external-user tests.'
    );

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

    Database.SaveResult result = Database.insert(user, false);
    if (!result.isSuccess()) {
      // A managed-package build org and a core-only subscriber org need not
      // enable Experience Cloud. Preserve the external identity semantics in
      // tests without making package installation depend on that org setting.
      user = createInternalUser();
      Contact partnerContact = [
        SELECT Id, AccountId, Name, Email, Phone, Can_Submit_Deals__c
        FROM Contact
        WHERE Id = :contactId
        LIMIT 1
      ];
      PartnerAccessService.testPartnerAccountIdsByUser.put(
        user.Id,
        partnerContact.AccountId
      );
      PartnerAccessService.testPartnerContactsByUser.put(
        user.Id,
        partnerContact
      );
      if (
        !NotificationRecipientResolver.testRecipientsByAccount.containsKey(
          partnerContact.AccountId
        )
      ) {
        NotificationRecipientResolver.testRecipientsByAccount.put(
          partnerContact.AccountId,
          new List<User>()
        );
      }
      NotificationRecipientResolver.testRecipientsByAccount.get(
          partnerContact.AccountId
        )
        .add(new User(Id = user.Id, ContactId = partnerContact.Id));
    }

    assignPermissionSet(user.Id, 'PartnerSync_Partner_Base_Data');

    return user;
  }

  public static void assignPermissionSet(Id userId, String permissionSetName) {
    PermissionSet permissionSet = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = :permissionSetName
      LIMIT 1
    ];

    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert new PermissionSetAssignment(
        AssigneeId = userId,
        PermissionSetId = permissionSet.Id
      );
    }
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

    // Metadata validation can temporarily leave a changed group in Updating
    // status. Force its test-context calculation before assigning it.
    Test.calculatePermissionSetGroup(permissionSetGroup.Id);

    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert new PermissionSetAssignment(
        AssigneeId = userId,
        PermissionSetGroupId = permissionSetGroup.Id
      );
    }
  }

  private static String uniqueEmail(String prefix) {
    return prefix + DateTime.now().getTime() + '@example.com';
  }
}
