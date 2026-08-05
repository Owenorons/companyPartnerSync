public without sharing class PartnerUserProvisioningQueueable implements Queueable {
  private static final String PROFILE_NAME = 'PartnerSync Partner User';
  private static final String PERMISSION_GROUP_NAME = 'PSG_Partner_Administrator';

  private Id applicationId;
  private Id contactId;

  public PartnerUserProvisioningQueueable(Id applicationId, Id contactId) {
    this.applicationId = applicationId;
    this.contactId = contactId;
  }

  public void execute(QueueableContext context) {
    String provisioningJobId = context == null
      ? null
      : String.valueOf(context.getJobId());
    try {
      Contact partnerContact = [
        SELECT Id, FirstName, LastName, Email
        FROM Contact
        WHERE Id = :contactId
        LIMIT 1
      ];

      List<User> existingUsers = [
        SELECT Id, IsActive
        FROM User
        WHERE ContactId = :contactId
        LIMIT 1
      ];

      User partnerUser;
      if (existingUsers.isEmpty()) {
        Profile partnerProfile = [
          SELECT Id, UserLicense.Name
          FROM Profile
          WHERE Name = :PROFILE_NAME
          LIMIT 1
        ];

        if (partnerProfile.UserLicense.Name != 'Partner Community') {
          throw new PartnerSyncHandledException(
            PROFILE_NAME + ' must use the Partner Community license.'
          );
        }

        partnerUser = new User(
          FirstName = partnerContact.FirstName,
          LastName = partnerContact.LastName,
          Email = partnerContact.Email,
          Username = buildUsername(partnerContact),
          Alias = 'pspartnr',
          CommunityNickname = 'ps' + String.valueOf(contactId),
          TimeZoneSidKey = 'Australia/Melbourne',
          LocaleSidKey = 'en_AU',
          EmailEncodingKey = 'UTF-8',
          LanguageLocaleKey = 'en_US',
          ProfileId = partnerProfile.Id,
          ContactId = contactId
        );
        insert partnerUser;
      } else {
        partnerUser = existingUsers[0];
        if (!partnerUser.IsActive) {
          throw new PartnerSyncHandledException(
            'The existing partner user is inactive.'
          );
        }
      }

      assignPartnerAdministratorAccess(partnerUser.Id);
      System.enqueueJob(
        new PartnerProvisioningStatusQueueable(
          applicationId,
          partnerUser.Id,
          null,
          provisioningJobId
        )
      );
    } catch (Exception ex) {
      System.enqueueJob(
        new PartnerProvisioningStatusQueueable(
          applicationId,
          null,
          ex.getMessage(),
          provisioningJobId
        )
      );
    }
  }

  private static void assignPartnerAdministratorAccess(Id userId) {
    PermissionSetGroup permissionGroup = [
      SELECT Id
      FROM PermissionSetGroup
      WHERE DeveloperName = :PERMISSION_GROUP_NAME
      LIMIT 1
    ];

    if (
      [
        SELECT COUNT()
        FROM PermissionSetAssignment
        WHERE
          AssigneeId = :userId
          AND PermissionSetGroupId = :permissionGroup.Id
      ] == 0
    ) {
      insert new PermissionSetAssignment(
        AssigneeId = userId,
        PermissionSetGroupId = permissionGroup.Id
      );
    }
  }

  private static String buildUsername(Contact partnerContact) {
    return 'partner.' +
      String.valueOf(partnerContact.Id).toLowerCase() +
      '.' +
      UserInfo.getOrganizationId().toLowerCase() +
      '@partnersync.invalid';
  }
}
