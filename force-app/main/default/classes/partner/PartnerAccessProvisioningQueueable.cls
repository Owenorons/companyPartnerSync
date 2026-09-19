/** Setup-object provisioning runs asynchronously and records a durable outcome. */
public without sharing class PartnerAccessProvisioningQueueable implements Queueable {
  private Id requestId;
  private Id contactId;
  private Id attemptId;

  /**
   * Creates a queueable that provisions setup-object access for a partner
   * contact and records the outcome against a provisioning attempt.
   *
   * @param requestId Id of the Partner_Access_Request__c the outcome should be recorded against.
   * @param contactId Id of the Contact to provision (or verify) a partner user for.
   * @param attemptId Id of the Partner_Provisioning_Attempt__c record to update on completion.
   */
  public PartnerAccessProvisioningQueueable(
    Id requestId,
    Id contactId,
    Id attemptId
  ) {
    this.requestId = requestId;
    this.contactId = contactId;
    this.attemptId = attemptId;
  }

  /**
   * Finds or creates a partner community User for the contact, then records
   * the resulting Succeeded/Failed outcome onto the provisioning attempt and
   * access request.
   *
   * @param context The queueable execution context provided by the platform.
   */
  public void execute(QueueableContext context) {
    try {
      Contact contact = [
        SELECT Id, FirstName, LastName, Email
        FROM Contact
        WHERE Id = :contactId
        WITH SYSTEM_MODE
        LIMIT 1
      ];
      if (String.isBlank(contact.Email))
        throw new ProvisioningException('Contact email is required.');
      List<User> users = [
        SELECT Id, IsActive
        FROM User
        WHERE ContactId = :contactId
        WITH SYSTEM_MODE
        LIMIT 1
      ];
      User partnerUser;
      if (users.isEmpty()) {
        Profile partnerProfile = [
          SELECT Id, UserLicense.Name
          FROM Profile
          WHERE Name = 'PartnerSync Partner User'
          WITH SYSTEM_MODE
          LIMIT 1
        ];
        if (partnerProfile.UserLicense.Name != 'Partner Community') {
          throw new ProvisioningException(
            'Partner profile must use the Partner Community license.'
          );
        }
        partnerUser = buildUser(contact, partnerProfile.Id);
        Database.insert(partnerUser, AccessLevel.SYSTEM_MODE);
      } else {
        partnerUser = users[0];
        if (!partnerUser.IsActive)
          throw new ProvisioningException('Existing partner user is inactive.');
      }
      complete('Succeeded', 'Provisioned', null, partnerUser.Id);
    } catch (Exception error) {
      complete('Failed', 'ProvisioningFailed', error.getMessage(), null);
    }
  }

  @TestVisible
  private static User buildUser(Contact contact, Id profileId) {
    return new User(
      FirstName = contact.FirstName,
      LastName = contact.LastName,
      Email = contact.Email,
      Username = 'partner.' +
        contact.Id +
        '.' +
        UserInfo.getOrganizationId() +
        '@partnersync.invalid',
      Alias = 'pspartnr',
      CommunityNickname = 'ps' + contact.Id,
      TimeZoneSidKey = 'Australia/Melbourne',
      LocaleSidKey = 'en_AU',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      ProfileId = profileId,
      ContactId = contact.Id
    );
  }

  private void complete(
    String attemptStatus,
    String outcome,
    String errorDetail,
    Id userId
  ) {
    Database.update(
      new Partner_Provisioning_Attempt__c(
        Id = attemptId,
        Status__c = attemptStatus,
        Outcome__c = outcome,
        Error_Detail__c = errorDetail,
        Completed_On__c = System.now()
      ),
      AccessLevel.SYSTEM_MODE
    );
    Database.update(
      new Partner_Access_Request__c(
        Id = requestId,
        Status__c = attemptStatus == 'Succeeded' ? 'Provisioned' : 'Failed',
        Provisioned_User__c = userId
      ),
      AccessLevel.SYSTEM_MODE
    );
  }

  /**
   * Thrown when a partner user cannot be provisioned or verified (missing
   * contact email, misconfigured partner profile/license, or an inactive
   * existing user).
   */
  public class ProvisioningException extends Exception {
  }
}
