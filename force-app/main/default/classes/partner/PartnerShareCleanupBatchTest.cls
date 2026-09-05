@IsTest
private class PartnerShareCleanupBatchTest {
  @IsTest
  static void queriesProcessesAndSchedulesExpiredShares() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Cleanup Partner'
    );
    insert partner;
    Partner_Record_Share__c registry = new Partner_Record_Share__c(
      Partner_Account__c = partner.Id,
      Target_Record_Id__c = partner.Id,
      Target_Object__c = 'Opportunity',
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

    Assert.isTrue(
      [
        SELECT Active__c
        FROM Partner_Record_Share__c
        WHERE Id = :registry.Id
      ]
      .Active__c
    );
  }
}
