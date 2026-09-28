/*
 * Covers PartnerShareCleanupBatch: expired shares are actually revoked
 * (the registry's own Target_Object__c must be one PartnerShareService
 * genuinely supports - 'Opportunity' is a valid picklist value but has no
 * Apex branch, so using it here would silently mask whether the revoke
 * path even ran, the exact gap a pre-beta bulk-safety audit caught), and
 * a real 100-row chunk (the batch's own configured chunk size) stays
 * within governor limits via PartnerShareService.revokeParticipantAccessBulk.
 */
@IsTest
private class PartnerShareCleanupBatchTest {
  @IsTest
  static void queriesAndRevokesAnExpiredShare() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Cleanup Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Cleanup Customer'
    );
    insert new List<Account>{ partner, customer };
    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      partner.Id,
      null,
      null
    );
    insert deal;
    Partner_Record_Share__c registry = new Partner_Record_Share__c(
      Partner_Account__c = partner.Id,
      Target_Record_Id__c = deal.Id,
      Target_Object__c = 'Deal Registration',
      Access_Level__c = 'Read',
      Share_Reason__c = 'Co-Sell',
      Active__c = true,
      Expiry_Date__c = Date.today().addDays(-1)
    );
    insert registry;

    PartnerShareCleanupBatch batchJob = new PartnerShareCleanupBatch();
    Assert.isNotNull(batchJob.start(null));
    batchJob.execute(null, new List<Partner_Record_Share__c>{ registry });
    batchJob.finish(null);

    Test.startTest();
    batchJob.execute((SchedulableContext) null);
    Test.stopTest();

    Assert.isFalse(
      [
        SELECT Active__c
        FROM Partner_Record_Share__c
        WHERE Id = :registry.Id
      ]
      .Active__c
    );
  }

  // Proves this batch's own configured 100-row chunk size (the exact
  // scale a pre-beta audit found the old per-row revokeExpiredAccess()
  // call would exceed at - 1 SOQL + 3 DML per row, 300 DML statements at
  // 100 rows) now stays within governor limits via the bulk revoke path.
  @IsTest
  static void revokes100ExpiredSharesWithinGovernorLimits() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Bulk Cleanup Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Bulk Cleanup Customer'
    );
    insert new List<Account>{ partner, customer };

    List<Deal_Registration__c> deals = new List<Deal_Registration__c>();
    for (Integer index = 0; index < 100; index++) {
      deals.add(
        PartnerSyncTestDataFactory.deal(customer.Id, partner.Id, null, null)
      );
    }
    insert deals;

    List<Partner_Record_Share__c> registries = new List<Partner_Record_Share__c>();
    for (Deal_Registration__c deal : deals) {
      registries.add(
        new Partner_Record_Share__c(
          Partner_Account__c = partner.Id,
          Target_Record_Id__c = deal.Id,
          Target_Object__c = 'Deal Registration',
          Access_Level__c = 'Read',
          Share_Reason__c = 'Co-Sell',
          Active__c = true,
          Expiry_Date__c = Date.today().addDays(-1)
        )
      );
    }
    insert registries;

    Test.startTest();
    new PartnerShareCleanupBatch().execute(null, registries);
    Test.stopTest();

    Assert.areEqual(
      100,
      [
        SELECT COUNT()
        FROM Partner_Record_Share__c
        WHERE Active__c = FALSE
      ]
    );
  }
}
