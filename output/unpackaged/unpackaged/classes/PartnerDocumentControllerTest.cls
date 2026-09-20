@IsTest
private class PartnerDocumentControllerTest {
  @IsTest
  static void getMyRequirementsReturnsCallersOwnRequirements() {
    Account partnerAccount = PartnerSyncTestDataFactory.partnerAccount(
      'Document Portal Partner'
    );
    insert partnerAccount;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(
      partnerAccount.Id
    );
    insert contact;

    Partner_Onboarding__c onboarding = onboarding(partnerAccount.Id);
    PartnerDocumentService.generateRequirements(onboarding.Id);

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);
    TestUserFactory.assignPermissionSet(
      partnerUser.Id,
      'PartnerSync_Partner_User'
    );

    System.runAs(partnerUser) {
      List<PartnerDocumentRequirementListDTO> requirements = PartnerDocumentController.getMyRequirements();
      Assert.areEqual(2, requirements.size());
      Assert.isNull(requirements[0].latestDocumentId);
    }
  }

  @IsTest
  static void submitDocumentDelegatesToServiceAndCreatesADocument() {
    Account partnerAccount = PartnerSyncTestDataFactory.partnerAccount(
      'Document Submit Partner'
    );
    insert partnerAccount;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(
      partnerAccount.Id
    );
    insert contact;

    Partner_Onboarding__c onboarding = onboarding(partnerAccount.Id);
    PartnerDocumentService.generateRequirements(onboarding.Id);
    Partner_Document_Requirement__c requirement = [
      SELECT Id
      FROM Partner_Document_Requirement__c
      WHERE Onboarding__c = :onboarding.Id
      LIMIT 1
    ];

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);
    TestUserFactory.assignPermissionSet(
      partnerUser.Id,
      'PartnerSync_Partner_User'
    );

    System.runAs(partnerUser) {
      PartnerDocumentSubmissionDTO request = new PartnerDocumentSubmissionDTO();
      request.requirementId = requirement.Id;
      request.contentDocumentId = '069000000000021AAA';
      PartnerDocumentController.submitDocument(request);
    }

    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Partner_Document__c
        WHERE Requirement__c = :requirement.Id
      ]
    );
  }

  private static Partner_Onboarding__c onboarding(Id partnerAccountId) {
    Partner_Application__c application = new Partner_Application__c(
      Name = 'Document Portal Applicant',
      Company_Name__c = 'Document Portal Applicant',
      Business_Email__c = 'document-portal-' +
        System.now().getTime() +
        '@example.com',
      Application_Status__c = 'Approved',
      Requested_Tier__c = 'Gold',
      Partner_Type__c = 'Reseller',
      Country__c = 'Australia'
    );
    insert application;
    Partner_Onboarding__c onboarding = new Partner_Onboarding__c(
      Application__c = application.Id,
      Onboarding_Key__c = String.valueOf(application.Id),
      Partner_Account__c = partnerAccountId,
      Status__c = 'Onboarding',
      Current_Stage__c = 'Evidence',
      Activation_Gate_Status__c = 'Blocked',
      Version_Number__c = 1
    );
    insert onboarding;
    return onboarding;
  }
}
