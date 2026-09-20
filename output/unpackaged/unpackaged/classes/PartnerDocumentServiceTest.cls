@IsTest
private class PartnerDocumentServiceTest {
  private static Partner_Onboarding__c onboarding() {
    return onboarding(null);
  }

  private static Partner_Onboarding__c onboarding(Id partnerAccountId) {
    Partner_Application__c application = new Partner_Application__c(
      Name = 'Evidence Applicant',
      Company_Name__c = 'Evidence Applicant',
      Business_Email__c = 'evidence-' + System.now().getTime() + '@example.com',
      Application_Status__c = 'Approved',
      Requested_Tier__c = 'Gold',
      Partner_Type__c = 'Reseller',
      Country__c = 'Australia'
    );
    insert application;
    Partner_Onboarding__c record = new Partner_Onboarding__c(
      Application__c = application.Id,
      Onboarding_Key__c = String.valueOf(application.Id),
      Partner_Account__c = partnerAccountId,
      Status__c = 'Onboarding',
      Current_Stage__c = 'Evidence',
      Activation_Gate_Status__c = 'Blocked',
      Version_Number__c = 1
    );
    insert record;
    return record;
  }

  private static User reviewerUser() {
    User reviewer = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      reviewer.Id,
      'PartnerSync_Internal_Admin'
    );
    return reviewer;
  }

  @IsTest
  static void rulesGenerateIdempotentTierAwareRequirements() {
    Partner_Onboarding__c record = onboarding();
    Test.startTest();
    PartnerDocumentService.generateRequirements(record.Id);
    PartnerDocumentService.generateRequirements(record.Id);
    Test.stopTest();
    List<Partner_Document_Requirement__c> requirements = [
      SELECT Document_Type__c, Blocking__c
      FROM Partner_Document_Requirement__c
      WHERE Onboarding__c = :record.Id
    ];
    System.assertEquals(2, requirements.size());
  }

  @IsTest
  static void submissionAndReviewAreDurableAndIdempotent() {
    Partner_Onboarding__c record = onboarding();
    PartnerDocumentService.generateRequirements(record.Id);
    Partner_Document_Requirement__c requirement = [
      SELECT Id
      FROM Partner_Document_Requirement__c
      WHERE Onboarding__c = :record.Id
      LIMIT 1
    ];
    Partner_Document__c document = PartnerDocumentService.submitDocument(
      requirement.Id,
      '069000000000001AAA',
      'upload-001',
      'Confidential'
    );
    System.assertEquals(
      document.Id,
      PartnerDocumentService.submitDocument(
          requirement.Id,
          '069000000000001AAA',
          'upload-001',
          'Confidential'
        )
        .Id
    );

    User reviewer = reviewerUser();
    Partner_Document_Review__c review;
    System.runAs(reviewer) {
      review = PartnerDocumentService.reviewDocument(
        document.Id,
        'Accepted',
        null,
        'review-001'
      );
      System.assertEquals(
        review.Id,
        PartnerDocumentService.reviewDocument(
            document.Id,
            'Accepted',
            null,
            'review-001'
          )
          .Id
      );
    }
    System.assertEquals(
      'Accepted',
      [SELECT Status__c FROM Partner_Document__c WHERE Id = :document.Id]
      .Status__c
    );
    System.assertEquals(
      'Accepted',
      [
        SELECT Status__c
        FROM Partner_Document_Requirement__c
        WHERE Id = :requirement.Id
      ]
      .Status__c
    );
  }

  @IsTest
  static void replacementRequiresReason() {
    Partner_Onboarding__c record = onboarding();
    PartnerDocumentService.generateRequirements(record.Id);
    Partner_Document_Requirement__c requirement = [
      SELECT Id
      FROM Partner_Document_Requirement__c
      WHERE Onboarding__c = :record.Id
      LIMIT 1
    ];
    Partner_Document__c document = PartnerDocumentService.submitDocument(
      requirement.Id,
      '069000000000002AAA',
      'upload-002',
      null
    );
    User reviewer = reviewerUser();
    System.runAs(reviewer) {
      try {
        PartnerDocumentService.reviewDocument(
          document.Id,
          'Replacement Required',
          null,
          'review-002'
        );
        System.assert(false, 'Expected a required reason.');
      } catch (IllegalArgumentException expected) {
        System.assert(expected.getMessage().contains('reason'));
      }
    }
  }

  @IsTest
  static void reviewDocumentRequiresReviewPermission() {
    Partner_Onboarding__c record = onboarding();
    PartnerDocumentService.generateRequirements(record.Id);
    Partner_Document_Requirement__c requirement = [
      SELECT Id
      FROM Partner_Document_Requirement__c
      WHERE Onboarding__c = :record.Id
      LIMIT 1
    ];
    Partner_Document__c document = PartnerDocumentService.submitDocument(
      requirement.Id,
      '069000000000003AAA',
      'upload-003',
      null
    );
    User unpermissioned = TestUserFactory.createInternalUser();
    System.runAs(unpermissioned) {
      try {
        PartnerDocumentService.reviewDocument(
          document.Id,
          'Accepted',
          null,
          'review-003'
        );
        Assert.fail('Expected document review permission guard.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('permission'));
      }
    }
  }

  @IsTest
  static void reviewDocumentRejectsAnAlreadyDecidedDocument() {
    Partner_Onboarding__c record = onboarding();
    PartnerDocumentService.generateRequirements(record.Id);
    Partner_Document_Requirement__c requirement = [
      SELECT Id
      FROM Partner_Document_Requirement__c
      WHERE Onboarding__c = :record.Id
      LIMIT 1
    ];
    Partner_Document__c document = PartnerDocumentService.submitDocument(
      requirement.Id,
      '069000000000004AAA',
      'upload-004',
      null
    );
    User reviewer = reviewerUser();
    System.runAs(reviewer) {
      PartnerDocumentService.reviewDocument(
        document.Id,
        'Accepted',
        null,
        'review-004a'
      );
      try {
        PartnerDocumentService.reviewDocument(
          document.Id,
          'Rejected',
          'Reconsidered.',
          'review-004b'
        );
        Assert.fail('Expected already-decided guard.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('already been decided'));
      }
    }
  }

  @IsTest
  static void submitDocumentRejectsARequirementBelongingToAnotherPartner() {
    Account owningPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Owning Partner'
    );
    insert owningPartner;
    Account otherPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Other Partner'
    );
    insert otherPartner;
    Contact otherContact = PartnerSyncTestDataFactory.partnerContact(
      otherPartner.Id
    );
    insert otherContact;

    Partner_Onboarding__c record = onboarding(owningPartner.Id);
    PartnerDocumentService.generateRequirements(record.Id);
    Partner_Document_Requirement__c requirement = [
      SELECT Id
      FROM Partner_Document_Requirement__c
      WHERE Onboarding__c = :record.Id
      LIMIT 1
    ];

    User otherPartnerUser = TestUserFactory.createExternalUser(otherContact.Id);

    System.runAs(otherPartnerUser) {
      try {
        PartnerDocumentService.submitDocument(
          requirement.Id,
          '069000000000005AAA',
          'upload-005',
          null
        );
        Assert.fail('Expected document requirement ownership guard.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('not accessible'));
      }
    }
  }
}
