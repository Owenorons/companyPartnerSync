/*
 * Test coverage for AIInsightGeneratorService, confirming generation is
 * blocked while AI is disabled at the tenant level.
 */
@IsTest
private class AIInsightGeneratorServiceTest {
  @IsTest
  static void generateThrowsWhenAiIsDisabled() {
    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(adminUser.Id, 'PartnerSync_AI_Admin');
    AIInsightRequestDTO request = new AIInsightRequestDTO();
    request.insightType = 'LeadFitScoring';

    Boolean threw = false;

    System.runAs(adminUser) {
      Test.startTest();
      try {
        AIInsightGeneratorService.generate(request);
      } catch (PartnerSyncHandledException ex) {
        threw = true;
        System.assertEquals('AI insights are disabled.', ex.getMessage());
      }
      Test.stopTest();
    }

    System.assertEquals(
      true,
      threw,
      'AI is disabled by default (Tenant_Config__mdt.Default.Enable_AI__c = false) until an admin opts in, so generation should be blocked.'
    );
  }

  @IsTest
  static void validatesRequestAndPersistsGovernedStructuredOutcome() {
    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(adminUser.Id, 'PartnerSync_AI_Admin');
    System.runAs(adminUser) {
      TenantConfigService.setConfigForTest(
        new Tenant_Config__mdt(Enable_AI__c = true)
      );
      try {
        AIInsightGeneratorService.generate(null);
        Assert.fail('Expected missing insight type rejection.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('Insight type'));
      }

      Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
      insert partner;
      AIInsightRequestDTO request = new AIInsightRequestDTO();
      request.partnerAccountId = partner.Id;
      request.insightType = 'LeadFitScoring';
      request.contextData = new Map<String, Object>{ 'health' => 42 };
      Test.setMock(
        HttpCalloutMock.class,
        AIHttpCalloutMock.success('Strong fit for this partner.')
      );
      AI_Insight__c insight = AIInsightGeneratorService.generate(request);
      Assert.areEqual('Draft', insight.Status__c);
      Assert.areEqual('OpenAI', insight.Provider__c);
      Assert.areEqual('Strong fit for this partner.', insight.Insight_Text__c);
      Assert.areEqual(
        'Follow the recommended next step.',
        insight.Recommendation__c
      );
      Assert.areEqual(82, insight.Confidence__c);
      Assert.isNotNull(insight.Id);
      TenantConfigService.clearCacheForTest();
    }
  }
}
