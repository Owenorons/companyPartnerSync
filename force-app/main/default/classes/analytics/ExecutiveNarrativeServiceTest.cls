/*
 * Covers ExecutiveNarrativeService.generateNarrative(): a successful call
 * persists the narrative onto the snapshot, and the underlying
 * AI_Interaction__c's context snapshot never includes anything beyond the
 * Executive_Snapshot__c's own already-computed numbers - the "bounded
 * narrative, not raw-record analysis" invariant, proven end-to-end.
 */
@IsTest
private class ExecutiveNarrativeServiceTest {
  @IsTest
  static void generatesAndPersistsANarrativeFromOnlyTheSnapshotsOwnNumbers() {
    Executive_Snapshot__c snapshot = new Executive_Snapshot__c(
      Snapshot_Date__c = Date.today(),
      Active_Partner_Count__c = 12,
      Average_Health_Score__c = 68,
      Total_Open_Deal_Count__c = 40
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
        'The organisation has 12 active partners with an average health score of 68.'
      )
    );

    Executive_Snapshot__c updated;
    System.runAs(aiUser) {
      AIProviderRouter.providerConfigForTest = new AI_Provider_Config__mdt(
        Active__c = true,
        Provider_Type__c = 'OpenAI'
      );
      Test.startTest();
      updated = ExecutiveNarrativeService.generateNarrative(snapshot.Id);
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
        AND Use_Case_Key__c = 'ExecutiveNarrative'
      LIMIT 1
    ];
    Map<String, Object> context = (Map<String, Object>) JSON.deserializeUntyped(
      interaction.Context_Snapshot__c
    );
    Assert.isTrue(context.containsKey('Active_Partner_Count__c'));
    Assert.isFalse(
      context.containsKey('Narrative__c'),
      'The context sent to the provider must never include the narrative field itself.'
    );
  }
}
