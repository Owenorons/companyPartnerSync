/*
 * End-to-end coverage for DealExpiryBatch: an Approved deal past its
 * Protection_End_Date__c is actually expired when the batch runs, deals
 * still within their protection window are left alone, and the batch can
 * be scheduled at all.
 */
@IsTest
private class DealExpiryBatchTest {
  private static Deal_Registration__c createApprovedDeal(
    Date protectionEndDate
  ) {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;

    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      partner.Id,
      null,
      null
    );
    deal.Status__c = 'Approved';
    deal.Protection_Start_Date__c = protectionEndDate.addDays(-30);
    deal.Protection_End_Date__c = protectionEndDate;
    insert deal;
    insert new Deal_Protection_Grant__c(
      Deal__c = deal.Id,
      Current__c = true,
      Current_Grant_Key__c = String.valueOf(deal.Id),
      Status__c = 'Active',
      Start_Date__c = protectionEndDate.addDays(-30),
      End_Date__c = protectionEndDate,
      Version_Number__c = 0,
      Extension_Count__c = 0
    );

    return deal;
  }

  @IsTest
  static void batchExpiresApprovedDealsPastProtectionWindow() {
    Deal_Registration__c expiredDeal = createApprovedDeal(
      Date.today().addDays(-1)
    );

    Test.startTest();
    Database.executeBatch(new DealExpiryBatch(), 100);
    Test.stopTest();

    Deal_Registration__c updated = [
      SELECT Status__c
      FROM Deal_Registration__c
      WHERE Id = :expiredDeal.Id
    ];

    System.assertEquals(
      'Expired',
      updated.Status__c,
      'Approved deal past its protection window should be expired by the batch.'
    );
  }

  @IsTest
  static void batchLeavesDealsWithinProtectionWindowAlone() {
    Deal_Registration__c activeDeal = createApprovedDeal(
      Date.today().addDays(30)
    );

    Test.startTest();
    Database.executeBatch(new DealExpiryBatch(), 100);
    Test.stopTest();

    Deal_Registration__c updated = [
      SELECT Status__c
      FROM Deal_Registration__c
      WHERE Id = :activeDeal.Id
    ];

    System.assertEquals(
      'Approved',
      updated.Status__c,
      'Deal still within its protection window should not be expired.'
    );
  }

  @IsTest
  static void scheduledRunKicksOffBatch() {
    Test.startTest();
    String jobId = System.schedule(
      'DealExpiryBatch Test',
      '0 0 2 * * ?',
      new DealExpiryBatch()
    );
    Test.stopTest();

    System.assertNotEquals(
      null,
      jobId,
      'Scheduling the deal expiry batch should return a job id.'
    );
  }
}
