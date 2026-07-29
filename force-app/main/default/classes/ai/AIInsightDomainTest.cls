/*
 * Test coverage for AIInsightDomain.toDTO, confirming field mapping from
 * AI_Insight__c onto AIInsightDTO.
 */
@IsTest
private class AIInsightDomainTest {
  @IsTest
  static void toDtoMapsInsightFields() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    AI_Insight__c insight = PartnerSyncTestDataFactory.insight(partner.Id);
    insert insight;

    AIInsightDTO dto = AIInsightDomain.toDTO(insight);

    System.assertEquals(insight.Id, dto.insightId);
    System.assertEquals('Deal Risk', dto.insightType);
    System.assertEquals('Rules', dto.provider);
    System.assertEquals(85, dto.confidence);
    System.assertEquals('Generated', dto.status);
  }
}
