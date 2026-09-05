@IsTest
private class AIInsightGovernanceServiceTest {
  @IsTest
  static void reviewerAcceptsAndDismissesDraftInsights() {
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
