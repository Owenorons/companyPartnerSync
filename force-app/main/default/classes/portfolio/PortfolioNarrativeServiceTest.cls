/*
 * Covers PortfolioNarrativeService.generateNarrative(): a successful call
 * persists the narrative onto the snapshot, and the underlying
 * AI_Interaction__c's context snapshot never includes raw partner fields
 * beyond the portfolio snapshot's own already-computed numbers - the
 * "bounded narrative, not raw-record analysis" invariant, proven
 * end-to-end rather than only at the IntelligenceContextService layer.
 */
@IsTest
private class PortfolioNarrativeServiceTest {
  @IsTest
  static void generatesAndPersistsANarrativeFromOnlyTheSnapshotsOwnNumbers() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Narrative Test Partner'
    );
    insert partner;
    Partner_Portfolio_Snapshot__c snapshot = new Partner_Portfolio_Snapshot__c(
      Partner_Account__c = partner.Id,
      Snapshot_Date__c = Date.today(),
      Health_Score__c = 65,
      Health_Label__c = 'Developing',
      Open_Deal_Count__c = 3
    );
    insert snapshot;

    User aiUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(aiUser.Id, 'PartnerSync_AI_Admin');
    TenantConfigService.setConfigForTest(
      new Tenant_Config__mdt(Enable_AI__c = true)
    );
    Test.setMock(
      HttpCalloutMock.class,
      AIHttpCalloutMock.success(
        'This partner is developing, with a health score of 65 and 3 open deals.'
      )
    );

    Partner_Portfolio_Snapshot__c updated;
    System.runAs(aiUser) {
      AIProviderRouter.providerConfigForTest = new AI_Provider_Config__mdt(
        Active__c = true,
        Provider_Type__c = 'OpenAI'
      );
      Test.startTest();
      updated = PortfolioNarrativeService.generateNarrative(snapshot.Id);
      Test.stopTest();
      AIProviderRouter.providerConfigForTest = null;
    }

    Assert.isNotNull(updated.Narrative__c);
    Assert.isNotNull(updated.Narrative_Generated_On__c);

    AI_Interaction__c interaction = [
      SELECT Context_Snapshot__c
      FROM AI_Interaction__c
      WHERE
        Related_Record_Id__c = :snapshot.Id
        AND Use_Case_Key__c = 'PortfolioNarrative'
      LIMIT 1
    ];
    Map<String, Object> context = (Map<String, Object>) JSON.deserializeUntyped(
      interaction.Context_Snapshot__c
    );
    Assert.isTrue(context.containsKey('Health_Score__c'));
    Assert.isFalse(
      context.containsKey('Partner_Account__c'),
      'The context sent to the provider must never include the raw partner account lookup.'
    );
  }
}
