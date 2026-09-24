@IsTest
private class AIInsightGovernanceServiceTest {
  @IsTest
  static void decideThrowsWhenUserLacksReviewPermission() {
    // No permission set assigned, so this user holds none of the
    // PartnerSync_Review_AI_Insights custom permission that decide() requires.
    User unauthorizedUser = TestUserFactory.createInternalUser();
    System.runAs(unauthorizedUser) {
      try {
        AIInsightGovernanceService.decide(
          '000000000000000AAA',
          'Accepted',
          null
        );
        Assert.fail('A user without review permission must be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.areEqual(
          'You do not have permission to review AI insights.',
          expected.getMessage()
        );
      }
    }
  }

  @IsTest
  static void reviewerAcceptsAndDismissesDraftInsights() {
    // PartnerSync_AI_Admin grants editable=false on Status__c and
    // Recommendation__c, so this also proves persistDecision()'s deliberate
    // FLS bypass: the write below succeeds for a reviewer with zero
    // field-level edit access on either field, because that bypass is what
    // the review boundary depends on.
    User reviewer = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(reviewer.Id, 'PartnerSync_AI_Admin');
    System.runAs(reviewer) {
      Account partner = PartnerSyncTestDataFactory.partnerAccount('AI Review');
      insert partner;
      AI_Insight__c accepted = draft(partner.Id, 'Publish this action.');
      AI_Insight__c dismissed = draft(partner.Id, 'Dismiss this action.');
      insert new List<AI_Insight__c>{ accepted, dismissed };
      List<AIInsightDTO> pending = AIInsightGovernanceService.getPendingReview();
      Assert.areEqual(2, pending.size());
      Assert.areEqual(partner.Id, pending[0].partnerAccountId);
      Assert.areEqual('AI Review', pending[0].partnerName);
      AIInsightDTO result = AIInsightGovernanceService.decide(
        accepted.Id,
        'Accepted',
        'Reviewed action.'
      );
      Assert.areEqual('Accepted', result.status);
      Assert.areEqual('Reviewed action.', result.recommendation);
      Assert.areEqual(
        'Dismissed',
        AIInsightGovernanceService.decide(dismissed.Id, 'Dismissed', null)
          .status
      );
      Assert.areEqual(0, AIInsightGovernanceService.getPendingReview().size());
      Set<Id> reviewedIds = new Set<Id>{ accepted.Id, dismissed.Id };
      Map<Id, AI_Insight__c> saved = new Map<Id, AI_Insight__c>(
        [
          SELECT Id, Status__c, Recommendation__c
          FROM AI_Insight__c
          WHERE Id IN :reviewedIds
        ]
      );
      Assert.areEqual('Accepted', saved.get(accepted.Id).Status__c);
      Assert.areEqual(
        'Reviewed action.',
        saved.get(accepted.Id).Recommendation__c
      );
      Assert.areEqual('Dismissed', saved.get(dismissed.Id).Status__c);
    }
  }

  @IsTest
  static void generationEnforcesDailyLimitAndQueuesCalloutWork() {
    User generator = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(generator.Id, 'PartnerSync_AI_Admin');
    Account partner = PartnerSyncTestDataFactory.partnerAccount('AI Limit');
    insert partner;
    System.runAs(generator) {
      TenantConfigService.setConfigForTest(
        new Tenant_Config__mdt(Enable_AI__c = true)
      );
      AIUsageService.testDailyLimit = 0;
      AIInsightRequestDTO request = new AIInsightRequestDTO();
      request.partnerAccountId = partner.Id;
      request.insightType = 'LeadFitScoring';
      try {
        AIInsightGeneratorService.generate(request);
        Assert.fail('Expected daily AI limit rejection.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('daily AI request limit'));
      }
      AIUsageService.testDailyLimit = 10;
      AIInsightGenerationQueueable.skipExecutionForTest = true;
      Test.startTest();
      Id jobId = AIInsightController.enqueueInsight(request);
      Test.stopTest();
      Assert.isNotNull(jobId);
      TenantConfigService.clearCacheForTest();
    }
  }

  @IsTest
  static void getInsightTypesListsActiveFeaturesForInternalUsers() {
    User admin = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(admin.Id, 'PartnerSync_AI_Admin');
    System.runAs(admin) {
      List<AIInsightTypeDTO> types = AIInsightController.getInsightTypes();
      Assert.isTrue(
        types.size() > 0,
        'At least one active AI feature type should be available.'
      );
      for (AIInsightTypeDTO type : types) {
        Assert.isNotNull(type.developerName);
        Assert.isNotNull(type.label);
      }
    }
  }

  @IsTest
  static void getInsightTypesRejectsExternalUsers() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'AI Types Partner'
    );
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;
    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    System.runAs(partnerUser) {
      try {
        AIInsightController.getInsightTypes();
        Assert.fail('Expected an internal-user-only failure.');
      } catch (AuraHandledException expected) {
        Assert.isTrue(true);
      }
    }
  }

  private static AI_Insight__c draft(Id partnerId, String recommendation) {
    return new AI_Insight__c(
      Partner_Account__c = partnerId,
      Feature_Name__c = 'AI',
      Provider__c = 'OpenAI',
      Confidence__c = 80,
      Insight_Text__c = 'Reviewed summary.',
      Recommendation__c = recommendation,
      Status__c = 'Draft'
    );
  }
}
