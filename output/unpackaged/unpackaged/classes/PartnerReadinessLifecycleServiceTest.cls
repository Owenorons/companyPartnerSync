@IsTest
private class PartnerReadinessLifecycleServiceTest {
  private class Context {
    Partner_Onboarding__c onboarding;
    Partner_Relationship__c relationship;
    Partner_Access_Request__c request;
  }

  private static Context context(Boolean complete) {
    PartnerReadinessLifecycleService.testLifecycleAuthority = true;
    Account account = new Account(Name = 'Readiness Account');
    insert account;
    Contact contact = new Contact(
      AccountId = account.Id,
      LastName = 'Ready',
      Email = 'ready@example.test'
    );
    insert contact;
    Partner_Application__c application = new Partner_Application__c(
      Name = 'Readiness Partner',
      Company_Name__c = 'Readiness Partner',
      Business_Email__c = 'ready@example.test',
      Application_Status__c = 'Approved',
      Country__c = 'Australia',
      Partner_Type__c = 'Reseller',
      Requested_Tier__c = 'Gold'
    );
    insert application;
    Partner_Onboarding__c onboarding = new Partner_Onboarding__c(
      Application__c = application.Id,
      Onboarding_Key__c = String.valueOf(application.Id),
      Status__c = 'Onboarding',
      Current_Stage__c = 'Readiness',
      Activation_Gate_Status__c = 'Blocked',
      Version_Number__c = 1
    );
    insert onboarding;
    Context value = new Context();
    value.onboarding = onboarding;
    if (!complete)
      return value;
    insert new Partner_Document_Requirement__c(
      Onboarding__c = onboarding.Id,
      Requirement_Key__c = onboarding.Id + ':READY-DOC',
      Document_Type__c = 'Business Registration',
      Requirement_Level__c = 'Mandatory',
      Gate__c = 'Approval',
      Status__c = 'Accepted',
      Blocking__c = true,
      Waiver_Eligible__c = false
    );
    insert new Partner_Approval_Plan__c(
      Onboarding__c = onboarding.Id,
      Plan_Key__c = onboarding.Id + ':READY-PLAN',
      Version_Number__c = 1,
      Current__c = true,
      Status__c = 'Approved for Contracting',
      Generated_On__c = System.now()
    );
    insert new Partner_Agreement__c(
      Onboarding__c = onboarding.Id,
      Agreement_Key__c = onboarding.Id + ':READY-AGREEMENT',
      Agreement_Type__c = 'Programme Agreement',
      Status__c = 'Effective',
      Template_Key__c = 'PROGRAMME',
      Template_Version__c = 1,
      Executed_On__c = System.now(),
      Effective_On__c = Date.today()
    );
    value.relationship = new Partner_Relationship__c(
      Onboarding__c = onboarding.Id,
      Relationship_Key__c = onboarding.Id + ':READY-REL',
      Account__c = account.Id,
      Programme_Key__c = 'RESELLER',
      Status__c = 'Active',
      Effective_On__c = Date.today()
    );
    insert value.relationship;
    value.request = new Partner_Access_Request__c(
      Onboarding__c = onboarding.Id,
      Request_Key__c = onboarding.Id + ':READY-ACCESS',
      Relationship__c = value.relationship.Id,
      Contact__c = contact.Id,
      Access_Bundle__c = 'PSG_Partner_User',
      Status__c = 'Provisioned',
      Expires_On__c = Date.today().addYears(1)
    );
    insert value.request;
    Partner_Training_Assignment__c training = PartnerReadinessLifecycleService.assignTraining(
      onboarding.Id,
      'PARTNER-FOUNDATIONS',
      true,
      Date.today().addDays(14)
    );
    training.Status__c = 'Completed';
    training.Completed_On__c = System.now();
    update training;
    return value;
  }

  @IsTest
  static void incompleteGatesPersistBlockedAssessment() {
    Context value = context(false);
    PartnerReadinessLifecycleService.GateResult result = PartnerReadinessLifecycleService.evaluate(
      value.onboarding.Id
    );
    System.assertEquals(false, result.ready);
    System.assert(result.blockers.size() >= 5);
    String readinessKey = value.onboarding.Id + ':Readiness';
    Partner_Assessment__c readiness = [
      SELECT Status__c
      FROM Partner_Assessment__c
      WHERE Assessment_Key__c = :readinessKey
    ];
    System.assertEquals('Failed', readiness.Status__c);
  }

  @IsTest
  static void completeGatesPermitControlledActivation() {
    Context value = context(true);
    PartnerReadinessLifecycleService.testAccountPartnerEnabled = true;
    PartnerReadinessLifecycleService.GateResult result = PartnerReadinessLifecycleService.evaluate(
      value.onboarding.Id
    );
    System.assertEquals(true, result.ready);
    PartnerReadinessLifecycleService.testLifecycleAuthority = true;
    Partner_Onboarding__c activated = PartnerReadinessLifecycleService.activate(
      value.onboarding.Id
    );
    System.assertEquals('Active', activated.Status__c);
    System.assertNotEquals(null, activated.Hypercare_Ends_On__c);
    System.assertNotEquals(null, activated.Recertification_Due_On__c);
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM Partner_Lifecycle_Event__c
        WHERE
          Onboarding__c = :value.onboarding.Id
          AND Event_Type__c = 'Partner Activated'
      ]
    );
  }

  @IsTest
  static void activationRequiresAuthorityAndReadyResult() {
    Context value = context(false);
    User unprivilegedUser = TestUserFactory.createInternalUser();
    System.runAs(unprivilegedUser) {
      PartnerReadinessLifecycleService.testLifecycleAuthority = false;
      try {
        PartnerReadinessLifecycleService.activate(value.onboarding.Id);
        System.assert(false);
      } catch (PartnerReadinessLifecycleService.LifecycleException expected) {
        System.assert(expected.getMessage().contains('authority'));
      }
    }
    PartnerReadinessLifecycleService.testLifecycleAuthority = true;
    try {
      PartnerReadinessLifecycleService.activate(value.onboarding.Id);
      System.assert(false);
    } catch (PartnerReadinessLifecycleService.LifecycleException expected) {
      System.assert(expected.getMessage().contains('Ready'));
    }
  }

  @IsTest
  static void terminationClosesRelationshipAndAccess() {
    Context value = context(true);
    PartnerReadinessLifecycleService.testLifecycleAuthority = true;
    PartnerReadinessLifecycleService.transition(
      value.onboarding.Id,
      'Terminated',
      'Material programme breach.'
    );
    System.assertEquals(
      'Terminated',
      [
        SELECT Status__c
        FROM Partner_Relationship__c
        WHERE Id = :value.relationship.Id
      ]
      .Status__c
    );
    System.assertEquals(
      'Expired',
      [
        SELECT Status__c
        FROM Partner_Access_Request__c
        WHERE Id = :value.request.Id
      ]
      .Status__c
    );
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM Partner_Lifecycle_Event__c
        WHERE
          Onboarding__c = :value.onboarding.Id
          AND Event_Type__c = 'Partner Terminated'
      ]
    );
  }
}
