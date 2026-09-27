/*
 * Covers DealSalesStageProjectionService: exact-match resolution against
 * Deal_Sales_Stage_Map__mdt, fallback to the Default record for an
 * unmapped custom stage name, and recompute() persisting the projected
 * Stage__c onto the deal.
 */
@IsTest
private class DealSalesStageProjectionServiceTest {
  @IsTest
  static void resolveCanonicalStageMapsAKnownStageName() {
    Assert.areEqual(
      'Proposal',
      DealSalesStageProjectionService.resolveCanonicalStage(
        'Proposal/Price Quote'
      )
    );
  }

  @IsTest
  static void resolveCanonicalStageFallsBackToDefaultForAnUnmappedStage() {
    Assert.areEqual(
      'Qualification',
      DealSalesStageProjectionService.resolveCanonicalStage(
        'Some Custom Stage Nobody Mapped'
      )
    );
  }

  @IsTest
  static void resolveMappingReturnsIsWonAndIsClosedForClosedWon() {
    Deal_Sales_Stage_Map__mdt mapping = DealSalesStageProjectionService.resolveMapping(
      'Closed Won'
    );
    Assert.areEqual('Closed Won', mapping.Canonical_Stage__c);
    Assert.isTrue(mapping.Is_Won__c);
    Assert.isTrue(mapping.Is_Closed__c);
  }

  @IsTest
  static void recomputePersistsTheProjectedStageOntoTheDeal() {
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Stage Customer'
    );
    insert customer;
    Opportunity opportunity = PartnerSyncTestDataFactory.opportunity(
      customer.Id,
      null,
      null
    );
    opportunity.StageName = 'Negotiation/Review';
    insert opportunity;

    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      null,
      null,
      opportunity.Id
    );
    insert deal;
    insert new Deal_Opportunity__c(
      Deal__c = deal.Id,
      Opportunity__c = opportunity.Id,
      Relationship_Type__c = 'Primary',
      Primary__c = true,
      Current__c = true,
      Relationship_Key__c = deal.Id + '|' + opportunity.Id,
      Version_Number__c = 0
    );

    Test.startTest();
    DealSalesStageProjectionService.recompute(deal.Id);
    Test.stopTest();

    Deal_Registration__c updated = [
      SELECT Stage__c
      FROM Deal_Registration__c
      WHERE Id = :deal.Id
    ];
    Assert.areEqual('Negotiation', updated.Stage__c);
  }

  @IsTest
  static void recomputeNoOpsWhenTheDealHasNoPrimaryRelationship() {
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'No Relationship Customer'
    );
    insert customer;
    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      null,
      null,
      null
    );
    insert deal;

    Test.startTest();
    DealSalesStageProjectionService.recompute(deal.Id);
    Test.stopTest();

    Deal_Registration__c unchanged = [
      SELECT Stage__c
      FROM Deal_Registration__c
      WHERE Id = :deal.Id
    ];
    Assert.isNull(unchanged.Stage__c);
  }
}
