@IsTest
private class PartnerOnboardingServiceTest {
  private static Partner_Application__c createApplication() {
    Partner_Application__c application = new Partner_Application__c(
      Name = 'Review Test Partner',
      Company_Name__c = 'Review Test Partner',
      Business_Email__c = 'business@review-test.example.com',
      Phone__c = '555-0199',
      Region__c = 'ANZ',
      Requested_Tier__c = 'Gold',
      Partner_Type__c = 'Reseller',
      Submitted_By_Contact_Name__c = 'Alex Reviewer',
      Submitted_By_Email__c = 'alex@review-test.example.com',
      Application_Status__c = 'Submitted',
      Decision__c = 'Pending',
      Assigned_Reviewer__c = UserInfo.getUserId(),
      Active_Company_Key__c = 'reviewtestpartner',
      Active_Email_Key__c = 'business@review-test.example.com'
    );
    insert application;
    return application;
  }

  @IsTest
  static void channelManagerCanApproveApplication() {
    User reviewer = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      reviewer.Id,
      'PartnerSync_Channel_Manager'
    );

    PartnerApprovalRequestDTO request = new PartnerApprovalRequestDTO();
    request.decision = 'Approved';
    request.approvalNotes = 'Meets program requirements.';

    Partner_Application__c application;
    System.runAs(reviewer) {
      application = createApplication();
      request.applicationId = application.Id;
      PartnerOnboardingService.processDecision(request);
    }

    Partner_Application__c approved = [
      SELECT
        Application_Status__c,
        Decision__c,
        Approval_Date__c,
        Created_Account__c,
        Created_Contact__c,
        Provisioning_Status__c
      FROM Partner_Application__c
      WHERE Id = :application.Id
    ];

    System.assertEquals('Approved', approved.Application_Status__c);
    System.assertEquals('Approved', approved.Decision__c);
    System.assertEquals(Date.today(), approved.Approval_Date__c);
    System.assertNotEquals(null, approved.Created_Account__c);
    System.assertNotEquals(null, approved.Created_Contact__c);
    System.assertEquals(
      'Awaiting Partner Enablement',
      approved.Provisioning_Status__c
    );
  }

  @IsTest
  static void rejectionReleasesActiveDuplicateKeys() {
    User reviewer = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      reviewer.Id,
      'PartnerSync_Channel_Manager'
    );

    PartnerApprovalRequestDTO request = new PartnerApprovalRequestDTO();
    request.decision = 'Rejected';
    request.rejectionReason = 'Does not meet program requirements.';

    Partner_Application__c application;
    System.runAs(reviewer) {
      application = createApplication();
      request.applicationId = application.Id;
      PartnerOnboardingService.processDecision(request);
    }

    Partner_Application__c rejected = [
      SELECT
        Application_Status__c,
        Decision__c,
        Rejection_Reason__c,
        Active_Company_Key__c,
        Active_Email_Key__c
      FROM Partner_Application__c
      WHERE Id = :application.Id
    ];

    System.assertEquals('Rejected', rejected.Application_Status__c);
    System.assertEquals('Rejected', rejected.Decision__c);
    System.assertEquals(null, rejected.Active_Company_Key__c);
    System.assertEquals(null, rejected.Active_Email_Key__c);
  }

  @IsTest
  static void applicationCannotBeDecidedTwice() {
    User reviewer = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      reviewer.Id,
      'PartnerSync_Channel_Manager'
    );

    PartnerApprovalRequestDTO request = new PartnerApprovalRequestDTO();
    request.decision = 'Approved';

    System.runAs(reviewer) {
      Partner_Application__c application = createApplication();
      application.Application_Status__c = 'Approved';
      application.Decision__c = 'Approved';
      application.Provisioning_Status__c = 'Queued';
      update application;
      request.applicationId = application.Id;

      Boolean threw = false;
      try {
        PartnerOnboardingService.processDecision(request);
      } catch (PartnerSyncHandledException ex) {
        threw = true;
        System.assert(ex.getMessage().contains('already been decided'));
      }
      System.assertEquals(true, threw);
    }
  }

  @IsTest
  static void reviewerCanClaimSubmittedApplication() {
    User reviewer = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      reviewer.Id,
      'PartnerSync_Channel_Manager'
    );

    Partner_Application__c application;
    System.runAs(reviewer) {
      application = createApplication();
      application.Assigned_Reviewer__c = null;
      update application;

      PartnerApplicationService.claimApplication(application.Id);
    }

    Partner_Application__c claimed = [
      SELECT Application_Status__c, Assigned_Reviewer__c
      FROM Partner_Application__c
      WHERE Id = :application.Id
    ];
    System.assertEquals('Under Review', claimed.Application_Status__c);
    System.assertEquals(reviewer.Id, claimed.Assigned_Reviewer__c);
  }

  @IsTest
  static void approvalRequiresAcknowledgementOfExistingMatches() {
    User reviewer = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      reviewer.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(reviewer) {
      insert new Account(Name = 'Review Test Partner');
      Partner_Application__c application = createApplication();

      PartnerApprovalRequestDTO request = new PartnerApprovalRequestDTO();
      request.applicationId = application.Id;
      request.decision = 'Approved';

      Boolean threw = false;
      try {
        PartnerOnboardingService.processDecision(request);
      } catch (PartnerSyncHandledException ex) {
        threw = true;
        System.assert(ex.getMessage().contains('Potential existing'));
      }
      System.assertEquals(true, threw);
    }
  }

  @IsTest
  static void provisioningRequiresPartnerEnabledAccount() {
    User reviewer = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      reviewer.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(reviewer) {
      Account account = new Account(Name = 'Not Yet Partner Enabled');
      insert account;
      Contact contact = new Contact(
        AccountId = account.Id,
        LastName = 'Provisioning Contact',
        Email = 'provisioning@example.com'
      );
      insert contact;
      Partner_Application__c application = createApplication();
      application.Application_Status__c = 'Approved';
      application.Decision__c = 'Approved';
      application.Created_Account__c = account.Id;
      application.Created_Contact__c = contact.Id;
      update application;

      Boolean threw = false;
      try {
        PartnerUserProvisioningService.requestProvisioning(application.Id);
      } catch (PartnerSyncHandledException ex) {
        threw = true;
        System.assert(ex.getMessage().contains('Enable the created Account'));
      }
      System.assertEquals(true, threw);
    }
  }

  @IsTest
  static void provisioningStatusQueueableRecordsSuccess() {
    User provisionedUser = TestUserFactory.createInternalUser();

    System.runAs(provisionedUser) {
      Partner_Application__c application = createApplication();
      application.Application_Status__c = 'Approved';
      application.Decision__c = 'Approved';
      application.Provisioning_Status__c = 'Queued';
      update application;

      new PartnerProvisioningStatusQueueable(
          application.Id,
          provisionedUser.Id,
          null,
          null
        )
        .execute(null);

      Partner_Application__c updated = [
        SELECT Provisioning_Status__c, Provisioned_User__c, Provisioned_On__c
        FROM Partner_Application__c
        WHERE Id = :application.Id
      ];
      System.assertEquals('Complete', updated.Provisioning_Status__c);
      System.assertEquals(provisionedUser.Id, updated.Provisioned_User__c);
      System.assertNotEquals(null, updated.Provisioned_On__c);
    }
  }

  @IsTest
  static void duplicateQueuedProvisioningRequestIsRejected() {
    User reviewer = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      reviewer.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(reviewer) {
      Partner_Application__c application = createApplication();
      application.Application_Status__c = 'Approved';
      application.Decision__c = 'Approved';
      application.Created_Account__c = insertAccount();
      application.Created_Contact__c = insertContact(
        application.Created_Account__c
      );
      application.Provisioning_Status__c = 'Queued';
      update application;

      Boolean threw = false;
      try {
        PartnerUserProvisioningService.requestProvisioning(application.Id);
      } catch (PartnerSyncHandledException ex) {
        threw = true;
        System.assert(ex.getMessage().contains('already queued'));
      }
      System.assertEquals(true, threw);
    }
  }

  @IsTest
  static void staleQueuedProvisioningIsMarkedFailed() {
    Partner_Application__c application = createApplication();
    application.Application_Status__c = 'Approved';
    application.Decision__c = 'Approved';
    application.Provisioning_Status__c = 'Queued';
    application.Provisioning_Started_On__c = System.now().addHours(-25);
    update application;

    PartnerProvisioningReconciler.reconcileStaleProvisioning();

    Partner_Application__c updated = [
      SELECT Provisioning_Status__c, Provisioning_Error__c
      FROM Partner_Application__c
      WHERE Id = :application.Id
    ];
    System.assertEquals('Failed', updated.Provisioning_Status__c);
    System.assert(updated.Provisioning_Error__c.contains('Retry provisioning'));
  }

  private static Id insertAccount() {
    Account account = new Account(Name = 'Provisioning Test Account');
    insert account;
    return account.Id;
  }

  private static Id insertContact(Id accountId) {
    Contact contact = new Contact(
      AccountId = accountId,
      LastName = 'Provisioning Test Contact',
      Email = 'queued-provisioning@example.com'
    );
    insert contact;
    return contact.Id;
  }
}
