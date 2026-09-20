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
  static void generateThrowsWhenUserLacksGeneratePermission() {
    // No PartnerSync_AI_Admin (or any other) permission set assigned, so this
    // user holds none of the PartnerSync_Generate_AI_Insights custom
    // permission that AIInsightGeneratorService.validate() requires.
    User unauthorizedUser = TestUserFactory.createInternalUser();
    AIInsightRequestDTO request = new AIInsightRequestDTO();
    request.insightType = 'LeadFitScoring';

    System.runAs(unauthorizedUser) {
      TenantConfigService.setConfigForTest(
        new Tenant_Config__mdt(Enable_AI__c = true)
      );
      try {
        AIInsightGeneratorService.generate(request);
        Assert.fail('A user without generate permission must be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.areEqual(
          'You do not have permission to generate AI insights.',
          expected.getMessage()
        );
      }
      TenantConfigService.clearCacheForTest();
    }
  }

  @IsTest
  static void validatesRequestAndPersistsGovernedStructuredOutcome() {
    // PartnerSync_AI_Admin grants editable=false on every AI_Insight__c
    // field, so this run also proves the queueable's deliberate FLS bypass:
    // the insert below succeeds for a user with zero field-level create
    // access on the object, because that bypass is what the review
    // boundary depends on.
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
      // The package deliberately ships with providers inactive. Activate only
      // this test's routing configuration so the real adapter reaches the mock.
      AIProviderRouter.providerConfigForTest = new AI_Provider_Config__mdt(
        Active__c = true,
        Provider_Type__c = 'OpenAI'
      );
      Test.setMock(HttpCalloutMock.class, new NoDmlBeforeCalloutMock());
      Test.startTest();
      try {
        new AIInsightGenerationQueueable(request, System.now().dateGMT())
          .execute(null);
        Test.stopTest();
      } finally {
        AIProviderRouter.providerConfigForTest = null;
        TenantConfigService.clearCacheForTest();
      }
      AI_Insight__c insight = [
        SELECT
          Id,
          Status__c,
          Provider__c,
          Insight_Text__c,
          Recommendation__c,
          Confidence__c
        FROM AI_Insight__c
        WHERE Partner_Account__c = :partner.Id
        LIMIT 1
      ];
      Assert.areEqual('Draft', insight.Status__c);
      Assert.areEqual('OpenAI', insight.Provider__c);
      Assert.areEqual('Strong fit for this partner.', insight.Insight_Text__c);
      Assert.areEqual(
        'Follow the recommended next step.',
        insight.Recommendation__c
      );
      Assert.areEqual(82, insight.Confidence__c);
      Assert.isNotNull(insight.Id);
      Assert.areEqual(
        1,
        [
          SELECT COUNT()
          FROM Usage_Metric__c
          WHERE
            Partner_Account__c = :partner.Id
            AND Metric_Type__c = 'AI Request'
        ]
      );
    }
  }

  @IsTest
  static void queueRequestPreservesScalarContextAndNulls() {
    AIInsightRequestDTO original = new AIInsightRequestDTO();
    original.partnerAccountId = '001000000000001';
    original.relatedRecordId = '001000000000002';
    original.relatedObject = 'Account';
    original.insightType = 'LeadFitScoring';
    original.contextData = new Map<String, Object>{
      'score' => 42,
      'ratio' => 0.5,
      'active' => true,
      'label' => 'Partner',
      'missing' => null
    };
    AIInsightRequestDTO restored = AIInsightGenerationQueueable.deserializeRequest(
      JSON.serialize(original)
    );
    Assert.areEqual(original.partnerAccountId, restored.partnerAccountId);
    Assert.areEqual(original.relatedRecordId, restored.relatedRecordId);
    Assert.areEqual(original.relatedObject, restored.relatedObject);
    Assert.areEqual(original.insightType, restored.insightType);
    Assert.areEqual(42, restored.contextData.get('score'));
    Assert.areEqual(0.5, restored.contextData.get('ratio'));
    Assert.areEqual(true, restored.contextData.get('active'));
    Assert.areEqual('Partner', restored.contextData.get('label'));
    Assert.isTrue(restored.contextData.containsKey('missing'));
    Assert.isNull(restored.contextData.get('missing'));
    original.contextData = null;
    Assert.isNull(
      AIInsightGenerationQueueable.deserializeRequest(JSON.serialize(original))
        .contextData
    );
  }

  private class NoDmlBeforeCalloutMock implements HttpCalloutMock {
    /**
     * Asserts no DML has run yet, then delegates to a successful mock response.
     *
     * @param request The outgoing HTTP request.
     * @return A simulated successful AI provider response.
     */
    public HttpResponse respond(HttpRequest request) {
      Assert.areEqual(
        0,
        Limits.getDmlStatements(),
        'Worker must not reserve quota in the callout transaction.'
      );
      return AIHttpCalloutMock.success('Strong fit for this partner.')
        .respond(request);
    }
  }
}
