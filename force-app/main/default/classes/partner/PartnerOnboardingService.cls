/*
 * Decisioning logic for an already-submitted partner application: rejects
 * outright, or approves by creating the partner's Account/Contact pair and
 * linking them back onto the application. Submission itself is handled by
 * PartnerApplicationService — this class only covers what happens after a
 * reviewer decides.
 */
public with sharing class PartnerOnboardingService {
  public static void processDecision(PartnerApprovalRequestDTO request) {
    PartnerPermissionService.assertCanApprovePartnerApplications();

    PartnerApplicationApprovalDomain.validateDecision(request);

    SecurityUtil.assertUpdateable(Partner_Application__c.SObjectType);

    Partner_Application__c application = PartnerApplicationSelector.selectById(
      request.applicationId
    );

    if (
      application.Application_Status__c == 'Approved' ||
      application.Application_Status__c == 'Rejected'
    ) {
      throw new PartnerSyncHandledException(
        'This application has already been decided.'
      );
    }

    if (request.decision == 'Rejected') {
      rejectApplication(application, request);
      return;
    }

    approveApplication(application, request);
  }

  private static void rejectApplication(
    Partner_Application__c application,
    PartnerApprovalRequestDTO request
  ) {
    application.Application_Status__c = 'Rejected';
    application.Decision__c = 'Rejected';
    application.Decision_By__c = UserInfo.getUserId();
    application.Decision_On__c = System.now();
    application.Rejection_Reason__c = request.rejectionReason;

    update SecurityUtil.stripForUpdate(new List<SObject>{ application });

    LoggingService.info(
      'PartnerOnboardingService',
      'Partner application rejected: ' + application.Id
    );
  }

  private static void approveApplication(
    Partner_Application__c application,
    PartnerApprovalRequestDTO request
  ) {
    SecurityUtil.assertCreateable(Account.SObjectType);
    SecurityUtil.assertCreateable(Contact.SObjectType);

    Account partnerAccount = PartnerApplicationApprovalDomain.buildPartnerAccount(
      application
    );

    List<SObject> sanitizedAccounts = SecurityUtil.stripForCreate(
      new List<SObject>{ partnerAccount }
    );

    Database.insert(sanitizedAccounts, AccessLevel.USER_MODE);

    Account insertedAccount = (Account) sanitizedAccounts[0];

    Contact partnerContact = PartnerApplicationApprovalDomain.buildPrimaryPartnerContact(
      application,
      insertedAccount.Id
    );

    List<SObject> sanitizedContacts = SecurityUtil.stripForCreate(
      new List<SObject>{ partnerContact }
    );

    Database.insert(sanitizedContacts, AccessLevel.USER_MODE);

    Contact insertedContact = (Contact) sanitizedContacts[0];

    application.Application_Status__c = 'Approved';
    application.Decision__c = 'Approved';
    application.Decision_By__c = UserInfo.getUserId();
    application.Decision_On__c = System.now();
    application.Approval_Notes__c = request.approvalNotes;
    application.Created_Account__c = insertedAccount.Id;
    application.Created_Contact__c = insertedContact.Id;

    update SecurityUtil.stripForUpdate(new List<SObject>{ application });

    LoggingService.info(
      'PartnerOnboardingService',
      'Partner application approved: ' + application.Id
    );
  }
}
