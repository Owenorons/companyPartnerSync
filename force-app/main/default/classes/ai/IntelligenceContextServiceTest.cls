/*
 * Covers IntelligenceContextService.buildContext(): only fields named in
 * the matching AI_Context_Policy__mdt.Allowed_Fields__c ever appear in the
 * built context (a real, populated field left off the allowlist never
 * leaks in), and a use case/object with no matching policy fails closed
 * to an empty context rather than falling back to an unbounded one.
 */
@IsTest
private class IntelligenceContextServiceTest {
  @IsTest
  static void onlyAllowlistedFieldsAppearInTheBuiltContext() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Context Test Partner'
    );
    insert partner;

    Partner_Portfolio_Snapshot__c snapshot = new Partner_Portfolio_Snapshot__c(
      Partner_Account__c = partner.Id,
      Snapshot_Date__c = Date.today(),
      Health_Score__c = 72,
      Health_Label__c = 'Healthy',
      Narrative__c = 'A pre-existing narrative that must never be echoed back as context.'
    );
    insert snapshot;

    Map<String, Object> context = IntelligenceContextService.buildContext(
      'PortfolioNarrative',
      'Partner_Portfolio_Snapshot__c',
      snapshot.Id
    );

    Assert.areEqual(72, context.get('Health_Score__c'));
    Assert.areEqual('Healthy', context.get('Health_Label__c'));
    Assert.isFalse(
      context.containsKey('Narrative__c'),
      'Narrative__c is not in the shipped allowlist and must never appear in built context.'
    );
    Assert.isFalse(
      context.containsKey('Partner_Account__c'),
      'Partner_Account__c is not in the shipped allowlist and must never appear in built context.'
    );
  }

  @IsTest
  static void anUnconfiguredUseCaseFailsClosedToAnEmptyContext() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Context Test Partner Two'
    );
    insert partner;
    Partner_Portfolio_Snapshot__c snapshot = new Partner_Portfolio_Snapshot__c(
      Partner_Account__c = partner.Id,
      Snapshot_Date__c = Date.today(),
      Health_Score__c = 50
    );
    insert snapshot;

    Map<String, Object> context = IntelligenceContextService.buildContext(
      'NoSuchUseCase',
      'Partner_Portfolio_Snapshot__c',
      snapshot.Id
    );

    Assert.isTrue(
      context.isEmpty(),
      'An unconfigured use case must fail closed, never fall back to an unbounded context.'
    );
  }
}
