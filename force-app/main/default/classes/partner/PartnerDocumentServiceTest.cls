@IsTest
private class PartnerDocumentServiceTest {
  private static Partner_Onboarding__c onboarding() {
    Partner_Application__c application = new Partner_Application__c(
      Name = 'Evidence Applicant',
      Company_Name__c = 'Evidence Applicant',
      Business_Email__c = 'evidence@example.com',
      Application_Status__c = 'Approved',
      Requested_Tier__c = 'Gold',
      Partner_Type__c = 'Reseller',
      Country__c = 'Australia'
    );
    insert application;
    Partner_Onboarding__c record = new Partner_Onboarding__c(
      Application__c = application.Id,
      Onboarding_Key__c = String.valueOf(application.Id),
      Status__c = 'Onboarding',
      Current_Stage__c = 'Evidence',
      Activation_Gate_Status__c = 'Blocked',
      Version_Number__c = 1
    );
    insert record;
    return record;
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

    Partner_Document_Review__c review = PartnerDocumentService.reviewDocument(
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
