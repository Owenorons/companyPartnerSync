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

    Partner_Application__c application = PartnerApplicationSelector.selectForDecisionById(
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

    if (application.Assigned_Reviewer__c == null) {
      throw new PartnerSyncHandledException(
        'Claim this application before making a decision.'
      );
    }

    if (application.Assigned_Reviewer__c != UserInfo.getUserId()) {
      throw new PartnerSyncHandledException(
        'This application is assigned to another reviewer.'
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
    application.Active_Company_Key__c = null;
    application.Active_Email_Key__c = null;

    update SecurityUtil.stripForUpdate(new List<SObject>{ application });

    PartnerOnboardingLifecycleService.initialise(application, 'Rejected');

    LoggingService.info(
      'PartnerOnboardingService',
      'Partner application rejected: ' + application.Id
    );
  }

  private static void approveApplication(
    Partner_Application__c application,
    PartnerApprovalRequestDTO request
  ) {
    List<PartnerApplicationMatchDTO> potentialMatches = PartnerApplicationMatchSelector.findPotentialMatches(
      application
    );

    if (
      !potentialMatches.isEmpty() && request.confirmPotentialMatches != true
    ) {
      throw new PartnerSyncHandledException(
        'Potential existing Account or Contact matches must be reviewed before approval.'
      );
    }

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
    application.Approval_Date__c = Date.today();
    application.Approval_Notes__c = request.approvalNotes;
    application.Created_Account__c = insertedAccount.Id;
    application.Created_Contact__c = insertedContact.Id;
    application.Provisioning_Status__c = 'Awaiting Partner Enablement';
    application.Provisioning_Error__c = 'Enable the created Account as a Partner, then request provisioning.';

    update SecurityUtil.stripForUpdate(new List<SObject>{ application });

    PartnerOnboardingLifecycleService.initialise(application, 'Approved');

    LoggingService.info(
      'PartnerOnboardingService',
      'Partner application approved: ' + application.Id
    );
  }
}
