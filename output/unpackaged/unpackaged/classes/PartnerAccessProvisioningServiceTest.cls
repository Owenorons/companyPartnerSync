@IsTest
private class PartnerAccessProvisioningServiceTest {
  private class Context {
    Partner_Onboarding__c onboarding;
    Account account;
    Contact contact;
  }

  @TestSetup
  static void authorisedOperator() {
    User operator = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      operator.Id,
      'PartnerSync_Partner_Access_Approver'
    );
    TestUserFactory.assignPermissionSet(
      operator.Id,
      'PartnerSync_Partner_Access_Provisioner'
    );
    TestUserFactory.assignPermissionSet(
      operator.Id,
      'PartnerSync_Channel_Manager'
    );
  }

  private static Context setupContext(Boolean effectiveAgreement) {
    PartnerAccessProvisioningService.testAccessManagementAuthority = true;
    Account account = new Account(Name = 'Access Test Account');
    insert account;
    Contact contact = new Contact(
      AccountId = account.Id,
      LastName = 'Access Contact',
      Email = 'access@example.test'
    );
    insert contact;
    Partner_Application__c application = new Partner_Application__c(
      Name = 'Access Test Partner',
      Company_Name__c = 'Access Test Partner',
      Business_Email__c = 'access@example.test',
      Application_Status__c = 'Approved',
      Country__c = 'Australia',
      Partner_Type__c = 'Reseller',
      Requested_Tier__c = 'Gold',
      Created_Account__c = account.Id,
      Created_Contact__c = contact.Id
    );
    insert application;
    Partner_Onboarding__c onboarding = new Partner_Onboarding__c(
      Application__c = application.Id,
      Onboarding_Key__c = String.valueOf(application.Id),
      Status__c = 'Onboarding',
      Current_Stage__c = 'Enablement',
      Activation_Gate_Status__c = 'Blocked',
      Version_Number__c = 1
    );
    insert onboarding;
    if (effectiveAgreement) {
      insert new Partner_Agreement__c(
        Onboarding__c = onboarding.Id,
        Agreement_Key__c = onboarding.Id + ':PROGRAMME:1',
        Agreement_Type__c = 'Programme Agreement',
        Status__c = 'Effective',
        Template_Key__c = 'PROGRAMME-AU',
        Template_Version__c = 1,
        Executed_On__c = System.now(),
        Effective_On__c = Date.today()
      );
    }
    Context value = new Context();
    value.onboarding = onboarding;
    value.account = account;
    value.contact = contact;
    return value;
  }

  @IsTest
  static void relationshipManagementRequiresDedicatedAuthority() {
    User unprivilegedUser = TestUserFactory.createInternalUser();
    System.runAs(unprivilegedUser) {
      PartnerAccessProvisioningService.testAccessManagementAuthority = false;
      try {
        PartnerAccessProvisioningService.establishRelationship(
          null,
          null,
          'RESELLER',
          'Gold',
          'unauthorised'
        );
        Assert.fail('Expected partner access management authority.');
      } catch (PartnerAccessProvisioningService.PartnerAccessException expected) {
        Assert.isTrue(expected.getMessage().contains('management authority'));
      }
    }
  }

  @IsTest
  static void relationshipRequiresEffectiveAgreement() {
    Context value = setupContext(false);
    try {
      PartnerAccessProvisioningService.establishRelationship(
        value.onboarding.Id,
        value.account.Id,
        'RESELLER',
        'Gold',
        'relationship-blocked'
      );
      System.assert(false, 'Expected agreement gate.');
    } catch (PartnerAccessProvisioningService.PartnerAccessException expected) {
      System.assert(expected.getMessage().contains('effective agreement'));
    }
  }

  @IsTest
  static void relationshipAndRequestAreIdempotent() {
    Context value = setupContext(true);
    Partner_Relationship__c first = PartnerAccessProvisioningService.establishRelationship(
      value.onboarding.Id,
      value.account.Id,
      'RESELLER',
      'Gold',
      'relationship-001'
    );
    Partner_Relationship__c second = PartnerAccessProvisioningService.establishRelationship(
      value.onboarding.Id,
      value.account.Id,
      'RESELLER',
      'Gold',
      'relationship-001'
    );
    System.assertEquals(first.Id, second.Id);
    first.Status__c = 'Active';
    update first;
    Partner_Access_Request__c request1 = PartnerAccessProvisioningService.requestAccess(
      value.onboarding.Id,
      first.Id,
      value.contact.Id,
      'PSG_Partner_User',
      'request-001',
      Date.today().addDays(30)
    );
    Partner_Access_Request__c request2 = PartnerAccessProvisioningService.requestAccess(
      value.onboarding.Id,
      first.Id,
      value.contact.Id,
      'PSG_Partner_User',
      'request-001',
      Date.today().addDays(30)
    );
    System.assertEquals(request1.Id, request2.Id);
  }

  @IsTest
  static void diagnosticsPersistEnablementBlockers() {
    Context value = setupContext(true);
    Partner_Relationship__c relationship = PartnerAccessProvisioningService.establishRelationship(
      value.onboarding.Id,
      value.account.Id,
      'RESELLER',
      'Gold',
      'relationship-diagnostic'
    );
    PartnerAccessProvisioningService.EnablementDiagnostic diagnostic = PartnerAccessProvisioningService.evaluateEnablement(
      relationship.Id,
      value.contact.Id
    );
    System.assertEquals(true, diagnostic.agreementsEffective);
    System.assertEquals(false, diagnostic.accountIsPartner);
    System.assertEquals(true, diagnostic.contactEligible);
    System.assertEquals(false, diagnostic.ready);
    System.assert(diagnostic.blockers[0].contains('partner'));
  }

  @IsTest
  static void approvalAndProvisioningRequireSeparateAuthorities() {
    Context value = setupContext(true);
    Partner_Relationship__c relationship = PartnerAccessProvisioningService.establishRelationship(
      value.onboarding.Id,
      value.account.Id,
      'RESELLER',
      'Gold',
      'relationship-authority'
    );
    relationship.Status__c = 'Active';
    update relationship;
    Partner_Access_Request__c request = PartnerAccessProvisioningService.requestAccess(
      value.onboarding.Id,
      relationship.Id,
      value.contact.Id,
      'PSG_Partner_User',
      'request-authority',
      Date.today().addDays(30)
    );
    User unprivilegedUser = TestUserFactory.createInternalUser();
    System.runAs(unprivilegedUser) {
      try {
        PartnerAccessProvisioningService.approveAccess(request.Id);
        System.assert(false, 'Expected approval authority.');
      } catch (PartnerAccessProvisioningService.PartnerAccessException expected) {
        System.assert(expected.getMessage().contains('approval authority'));
      }
      try {
        PartnerAccessProvisioningService.provisionApprovedAccess(
          request.Id,
          'attempt-001'
        );
        System.assert(false, 'Expected provisioning authority.');
      } catch (PartnerAccessProvisioningService.PartnerAccessException expected) {
        System.assert(expected.getMessage().contains('provisioning authority'));
      }
    }
  }

  @IsTest
  static void authorisedApprovalReachesTechnicalEnablementGate() {
    User operator = [SELECT Id FROM User WHERE Alias = 'intusr' LIMIT 1];
    System.runAs(operator) {
      Context value = setupContext(true);
      Partner_Relationship__c relationship = PartnerAccessProvisioningService.establishRelationship(
        value.onboarding.Id,
        value.account.Id,
        'RESELLER',
        'Gold',
        'relationship-authorised'
      );
      relationship.Status__c = 'Active';
      update relationship;
      Partner_Access_Request__c request = PartnerAccessProvisioningService.requestAccess(
        value.onboarding.Id,
        relationship.Id,
        value.contact.Id,
        'PSG_Partner_User',
        'request-authorised',
        Date.today().addDays(30)
      );
      request = PartnerAccessProvisioningService.approveAccess(request.Id);
      System.assertEquals('Approved', request.Status__c);
      try {
        PartnerAccessProvisioningService.provisionApprovedAccess(
          request.Id,
          'attempt-authorised'
        );
        System.assert(false, 'Expected partner Account enablement gate.');
      } catch (Exception expected) {
        System.assert(
          expected.getMessage().contains('Partner') ||
          expected.getMessage().contains('partner')
        );
      }
    }
  }

  @IsTest
  static void provisioningAttemptRecordsDurableFailure() {
    Context value = setupContext(true);
    Partner_Relationship__c relationship = PartnerAccessProvisioningService.establishRelationship(
      value.onboarding.Id,
      value.account.Id,
      'RESELLER',
      'Gold',
      'relationship-queueable'
    );
    relationship.Status__c = 'Active';
    update relationship;
    Partner_Access_Request__c request = PartnerAccessProvisioningService.requestAccess(
      value.onboarding.Id,
      relationship.Id,
      value.contact.Id,
      'PSG_Partner_User',
      'request-queueable',
      Date.today().addDays(30)
    );
    request.Status__c = 'Provisioning';
    update request;
    Partner_Provisioning_Attempt__c attempt = new Partner_Provisioning_Attempt__c(
      Access_Request__c = request.Id,
      Attempt_Key__c = 'attempt-queueable',
      Status__c = 'Started',
      Started_On__c = System.now()
    );
    insert attempt;
    Test.startTest();
    new PartnerAccessProvisioningQueueable(
        request.Id,
        value.contact.Id,
        attempt.Id
      )
      .execute(null);
    Test.stopTest();
    attempt = [
      SELECT Status__c, Outcome__c, Error_Detail__c
      FROM Partner_Provisioning_Attempt__c
      WHERE Id = :attempt.Id
    ];
    request = [
      SELECT Status__c
      FROM Partner_Access_Request__c
      WHERE Id = :request.Id
    ];
    System.assertEquals('Failed', attempt.Status__c);
    System.assertEquals('ProvisioningFailed', attempt.Outcome__c);
    System.assertNotEquals(null, attempt.Error_Detail__c);
    System.assertEquals('Failed', request.Status__c);

    Profile profile = [
      SELECT Id
      FROM Profile
      WHERE UserType = 'Standard'
      LIMIT 1
    ];
    User constructed = PartnerAccessProvisioningQueueable.buildUser(
      value.contact,
      profile.Id
    );
    System.assert(constructed.Username.startsWith('partner.'));
    System.assertEquals(value.contact.Id, constructed.ContactId);
  }
}
