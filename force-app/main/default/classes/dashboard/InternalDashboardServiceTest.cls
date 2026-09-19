/*
 * Verifies InternalDashboardService's permission-gated counts: a user with
 * the review permission set sees real counts and alerts, while a plain
 * internal user sees zeros instead of an error.
 */
@IsTest
private class InternalDashboardServiceTest {
  @IsTest
  static void channelManagerSeesPendingCountsAndAlerts() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;

    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      partner.Id,
      null,
      null
    );
    insert deal;

    MDF_Request__c mdfRequest = PartnerSyncTestDataFactory.mdfRequest(
      partner.Id,
      null
    );
    insert mdfRequest;

    User channelManager = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(channelManager) {
      insert new Partner_Notification__c(
        Recipient_User__c = channelManager.Id,
        Title__c = 'Heads up',
        Message__c = 'Something needs attention.',
        Is_Read__c = false,
        Dismissed__c = false
      );

      InternalDashboardDTO dto = InternalDashboardService.getDashboard();

      System.assertEquals(1, dto.pendingDealReviewCount);
      System.assertEquals(1, dto.pendingMdfReviewCount);
      System.assertEquals(1, dto.unreadNotificationCount);
      System.assertEquals(2, dto.unifiedWorkCount);
      System.assertEquals(
        new Set<String>{ 'Deals', 'MDF' },
        new Set<String>{
          dto.unifiedWorkItems[0].domain,
          dto.unifiedWorkItems[1].domain
        }
      );
      System.assertEquals(
        3,
        dto.alerts.size(),
        'A deal, MDF, and notification alert should each be present.'
      );
    }
  }

  @IsTest
  static void plainInternalUserSeesZeroRestrictedCounts() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;

    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      partner.Id,
      null,
      null
    );
    insert deal;

    User plainInternalUser = TestUserFactory.createInternalUser();

    System.runAs(plainInternalUser) {
      InternalDashboardDTO dto = InternalDashboardService.getDashboard();

      System.assertEquals(
        0,
        dto.pendingDealReviewCount,
        'A user with no deal-review permission set should see zero, not an error.'
      );
      System.assertEquals(0, dto.pendingMdfReviewCount);
      System.assertEquals(0, dto.unreadNotificationCount);
      System.assertEquals(0, dto.alerts.size());
    }
  }

  @IsTest
  static void channelManagerSeesOnboardingOperationsQueue() {
    Account account = new Account(Name = 'Operations Partner');
    insert account;
    Contact contact = new Contact(
      AccountId = account.Id,
      LastName = 'Operator',
      Email = 'operator@example.test'
    );
    insert contact;
    Partner_Application__c application = new Partner_Application__c(
      Name = 'Operations Partner',
      Company_Name__c = 'Operations Partner',
      Business_Email__c = 'operator@example.test',
      Application_Status__c = 'Approved',
      Country__c = 'Australia',
      Partner_Type__c = 'Reseller',
      Requested_Tier__c = 'Gold'
    );
    insert application;
    Partner_Onboarding__c onboarding = new Partner_Onboarding__c(
      Application__c = application.Id,
      Onboarding_Key__c = String.valueOf(application.Id),
      Status__c = 'Active',
      Current_Stage__c = 'Active',
      Activation_Gate_Status__c = 'Ready',
      Version_Number__c = 1,
      Recertification_Due_On__c = Date.today().addDays(10)
    );
    insert onboarding;
    insert new Partner_Onboarding_Task__c(
      Onboarding__c = onboarding.Id,
      Task_Type__c = 'Governance',
      Title__c = 'Resolve overdue governance task',
      Status__c = 'In Progress',
      Blocking__c = true,
      Due_On__c = System.now().addDays(-1)
    );
    Partner_Approval_Plan__c plan = new Partner_Approval_Plan__c(
      Onboarding__c = onboarding.Id,
      Plan_Key__c = onboarding.Id + ':DASHBOARD-PLAN',
      Version_Number__c = 1,
      Current__c = true,
      Status__c = 'Pending',
      Generated_On__c = System.now()
    );
    insert plan;
    insert new Partner_Approval_Step__c(
      Plan__c = plan.Id,
      Step_Key__c = plan.Id + ':LEGAL',
      Dimension__c = 'Legal',
      Sequence__c = 1,
      Status__c = 'Pending'
    );
    Partner_Assessment__c assessment = new Partner_Assessment__c(
      Onboarding__c = onboarding.Id,
      Assessment_Key__c = onboarding.Id + ':DASHBOARD-RISK',
      Assessment_Type__c = 'Sanctions',
      Status__c = 'Failed',
      Blocking__c = true
    );
    insert assessment;
    insert new Partner_Assessment_Finding__c(
      Assessment__c = assessment.Id,
      Finding_Key__c = assessment.Id + ':FINDING',
      Severity__c = 'Critical',
      Status__c = 'Open',
      Blocking__c = true,
      Description__c = 'Resolve sanctions screening match.'
    );
    Partner_Relationship__c relationship = new Partner_Relationship__c(
      Onboarding__c = onboarding.Id,
      Relationship_Key__c = onboarding.Id + ':DASHBOARD-REL',
      Account__c = account.Id,
      Programme_Key__c = 'RESELLER',
      Status__c = 'Active'
    );
    insert relationship;
    Partner_Access_Request__c request = new Partner_Access_Request__c(
      Onboarding__c = onboarding.Id,
      Request_Key__c = onboarding.Id + ':DASHBOARD-ACCESS',
      Relationship__c = relationship.Id,
      Contact__c = contact.Id,
      Access_Bundle__c = 'PSG_Partner_User',
      Status__c = 'Failed'
    );
    insert request;
    insert new Partner_Provisioning_Attempt__c(
      Access_Request__c = request.Id,
      Attempt_Key__c = request.Id + ':ATTEMPT',
      Status__c = 'Failed',
      Outcome__c = 'ProvisioningFailed',
      Started_On__c = System.now().addHours(-1),
      Completed_On__c = System.now()
    );

    User manager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      manager.Id,
      'PartnerSync_Channel_Manager'
    );
    System.runAs(manager) {
      InternalDashboardDTO dto = InternalDashboardService.getDashboard();
      System.assertEquals(5, dto.onboardingWorkCount);
      System.assertEquals(1, dto.provisioningFailureCount);
      System.assertEquals(1, dto.recertificationDueCount);
      System.assertEquals(5, dto.onboardingWorkItems.size());
      System.assertEquals(6, dto.unifiedWorkCount);
      System.assert(
        dto.alerts[dto.alerts.size() - 1].contains('onboarding work items')
      );
    }
  }

  @IsTest
  static void operationalManagerSeesFilterableAlertHistory() {
    Datetime detected = System.now();
    List<Partner_Operational_Alert__c> alerts = new List<Partner_Operational_Alert__c>{
      new Partner_Operational_Alert__c(
        Alert_Key__c = 'DASHBOARD:OPEN',
        Alert_Type__c = 'Provisioning Failure',
        Severity__c = 'High',
        Status__c = 'Open',
        Source_Record_Id__c = UserInfo.getUserId(),
        Message__c = 'Provisioning requires attention.',
        Occurrence_Count__c = 2,
        First_Detected_On__c = detected,
        Last_Detected_On__c = detected
      ),
      new Partner_Operational_Alert__c(
        Alert_Key__c = 'DASHBOARD:ACK',
        Alert_Type__c = 'Overdue Work',
        Severity__c = 'Medium',
        Status__c = 'Acknowledged',
        Source_Record_Id__c = UserInfo.getUserId(),
        Message__c = 'Already handled.',
        Occurrence_Count__c = 1,
        First_Detected_On__c = detected,
        Last_Detected_On__c = detected
      )
    };
    insert alerts;
    insert new Partner_Alert_Delivery_Attempt__c(
      Alert__c = alerts[0].Id,
      Channel__c = 'Email',
      Recipient__c = 'operator@example.test',
      Status__c = 'Failed',
      Attempted_On__c = detected,
      Retry_On__c = detected.addHours(1),
      Error_Detail__c = 'Mailbox unavailable.'
    );
    User manager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      manager.Id,
      'PartnerSync_Operational_Alert_Manager'
    );
    System.runAs(manager) {
      InternalDashboardDTO dto = InternalDashboardService.getDashboard();
      System.assertEquals(1, dto.openOperationalAlertCount);
      System.assertEquals(2, dto.operationalAlerts.size());
      System.assertEquals(1, dto.unifiedWorkCount);
      System.assertEquals('Notifications', dto.unifiedWorkItems[0].domain);
      Set<String> statuses = new Set<String>();
      for (OperationalAlertDTO item : dto.operationalAlerts)
        statuses.add(item.status);
      System.assertEquals(new Set<String>{ 'Open', 'Acknowledged' }, statuses);
      System.assert(
        dto.alerts[dto.alerts.size() - 1].contains('operational alerts')
      );
    }
  }
}
