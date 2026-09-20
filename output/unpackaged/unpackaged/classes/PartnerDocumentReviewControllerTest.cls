@IsTest
private class PartnerDocumentReviewControllerTest {
  @IsTest
  static void getReviewQueueReturnsRowsForAuthorizedReviewer() {
    Partner_Onboarding__c onboarding = onboarding();
    PartnerDocumentService.generateRequirements(onboarding.Id);
    Partner_Document_Requirement__c requirement = [
      SELECT Id
      FROM Partner_Document_Requirement__c
      WHERE Onboarding__c = :onboarding.Id
      LIMIT 1
    ];
    PartnerDocumentService.submitDocument(
      requirement.Id,
      '069000000000011AAA',
      'upload-011',
      null
    );

    User reviewer = reviewerUser();
    System.runAs(reviewer) {
      List<PartnerDocumentReviewListDTO> queue = PartnerDocumentReviewController.getReviewQueue();
      Assert.areEqual(1, queue.size());
      Assert.isNotNull(queue[0].partnerName);
      Assert.areEqual('Submitted', queue[0].status);
    }
  }

  @IsTest
  static void getReviewQueueThrowsForUnauthorizedUser() {
    Partner_Onboarding__c onboarding = onboarding();
    PartnerDocumentService.generateRequirements(onboarding.Id);

    User unpermissioned = TestUserFactory.createInternalUser();
    System.runAs(unpermissioned) {
      try {
        PartnerDocumentReviewController.getReviewQueue();
        Assert.fail('Expected document review permission guard.');
      } catch (AuraHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('permission'));
      }
    }
  }

  @IsTest
  static void reviewDocumentDelegatesToServiceAndUpdatesStatus() {
    Partner_Onboarding__c onboarding = onboarding();
    PartnerDocumentService.generateRequirements(onboarding.Id);
    Partner_Document_Requirement__c requirement = [
      SELECT Id
      FROM Partner_Document_Requirement__c
      WHERE Onboarding__c = :onboarding.Id
      LIMIT 1
    ];
    Partner_Document__c document = PartnerDocumentService.submitDocument(
      requirement.Id,
      '069000000000012AAA',
      'upload-012',
      null
    );

    User reviewer = reviewerUser();
    System.runAs(reviewer) {
      PartnerDocumentReviewDecisionDTO request = new PartnerDocumentReviewDecisionDTO();
      request.documentId = document.Id;
      request.outcome = 'Accepted';
      PartnerDocumentReviewController.reviewDocument(request);
    }

    Assert.areEqual(
      'Accepted',
      [SELECT Status__c FROM Partner_Document__c WHERE Id = :document.Id]
      .Status__c
    );
  }

  private static Partner_Onboarding__c onboarding() {
    Account partnerAccount = PartnerSyncTestDataFactory.partnerAccount(
      'Document Controller Partner'
    );
    insert partnerAccount;
    Partner_Application__c application = new Partner_Application__c(
      Name = 'Document Controller Applicant',
      Company_Name__c = 'Document Controller Applicant',
      Business_Email__c = 'document-controller-' +
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
      Partner_Account__c = partnerAccount.Id,
      Status__c = 'Onboarding',
      Current_Stage__c = 'Evidence',
      Activation_Gate_Status__c = 'Blocked',
      Version_Number__c = 1
    );
    insert onboarding;
    return onboarding;
  }

  private static User reviewerUser() {
    User reviewer = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      reviewer.Id,
      'PartnerSync_Internal_Admin'
    );
    return reviewer;
  }
}
