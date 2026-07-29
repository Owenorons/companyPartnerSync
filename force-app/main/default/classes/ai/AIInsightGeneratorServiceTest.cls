/*
 * Test coverage for AIInsightGeneratorService, confirming generation is
 * blocked while AI is disabled at the tenant level.
 */
@IsTest
private class AIInsightGeneratorServiceTest {
  @IsTest
  static void generateThrowsWhenAiIsDisabled() {
    AIInsightRequestDTO request = new AIInsightRequestDTO();
    request.insightType = 'LeadFitScoring';

    Boolean threw = false;

    Test.startTest();
    try {
      AIInsightGeneratorService.generate(request);
    } catch (PartnerSyncHandledException ex) {
      threw = true;
      System.assertEquals('AI insights are disabled.', ex.getMessage());
    }
    Test.stopTest();

    System.assertEquals(
      true,
      threw,
      'AI is disabled by default (Tenant_Config__mdt.Default.Enable_AI__c = false) until an admin opts in, so generation should be blocked.'
    );
  }
}
