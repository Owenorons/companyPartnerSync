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
      Assert.areEqual(2, AIInsightGovernanceService.getPendingReview().size());
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
