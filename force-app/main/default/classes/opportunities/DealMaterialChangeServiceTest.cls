/*
 * Covers DealMaterialChangeService: variance under/over the configured
 * threshold for AmountChanged, a non-amount change type that's always
 * material, a change type policy that never requires reapproval, and that
 * a material change actually regenerates the approval plan and moves the
 * deal back to Under Review via the standard command path.
 */
@IsTest
private class DealMaterialChangeServiceTest {
  @IsTest
  static void varianceUnderThresholdDoesNotRequireReapproval() {
    Deal_Registration__c deal = approvedDeal(100000);

    Test.startTest();
    DealMaterialChangeService.evaluate(
      deal.Id,
      'AmountChanged',
      'Amount drifted slightly.',
      105000,
      100000
    );
    Test.stopTest();

    assertStatusUnchanged(deal.Id, 'Approved');
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Audit_Log__c
        WHERE
          Record_Id__c = :deal.Id
          AND Action__c = 'Acknowledge Material Change'
      ]
    );
  }

  @IsTest
  static void varianceOverThresholdRequiresReapproval() {
    Deal_Registration__c deal = approvedDeal(100000);

    Test.startTest();
    DealMaterialChangeService.evaluate(
      deal.Id,
      'AmountChanged',
      'Amount changed significantly.',
      50000,
      100000
    );
    Test.stopTest();

    assertStatusUnchanged(deal.Id, 'Under Review');
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Approval_Plan__c
        WHERE Target_Record_Id__c = :deal.Id AND Current__c = TRUE
      ]
    );
  }

  @IsTest
  static void nonAmountChangeTypeIsAlwaysMaterial() {
    Deal_Registration__c deal = approvedDeal(100000);

    Test.startTest();
    DealMaterialChangeService.evaluate(
      deal.Id,
      'CustomerChanged',
      'The opportunity\'s account changed.',
      null,
      null
    );
    Test.stopTest();

    assertStatusUnchanged(deal.Id, 'Under Review');
  }

  @IsTest
  static void closeDateChangedNeverRequiresReapproval() {
    Deal_Registration__c deal = approvedDeal(100000);

    Test.startTest();
    DealMaterialChangeService.evaluate(
      deal.Id,
      'CloseDateChanged',
      'The close date moved out.',
      null,
      null
    );
    Test.stopTest();

    assertStatusUnchanged(deal.Id, 'Approved');
  }

  private static Deal_Registration__c approvedDeal(Decimal estimatedRevenue) {
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Material Change Customer'
    );
    insert customer;
    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      null,
      null,
      null
    );
    deal.Status__c = 'Approved';
    deal.Estimated_Revenue__c = estimatedRevenue;
    deal.Version_Number__c = 0;
    insert deal;
    return deal;
  }

  private static void assertStatusUnchanged(Id dealId, String expectedStatus) {
    Deal_Registration__c stored = [
      SELECT Status__c
      FROM Deal_Registration__c
      WHERE Id = :dealId
    ];
    Assert.areEqual(expectedStatus, stored.Status__c);
  }
}
