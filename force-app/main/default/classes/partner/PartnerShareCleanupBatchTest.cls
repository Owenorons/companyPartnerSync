/*
 * End-to-end coverage for PartnerShareCleanupBatch: an expired share is
 * actually revoked (registry deactivated, Salesforce share row removed)
 * when the batch runs, and the batch can be scheduled at all.
 */
@IsTest
private class PartnerShareCleanupBatchTest {
  @IsTest
  static void batchRevokesExpiredActiveShares() {
    Account owningPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Owning Partner'
    );
    insert owningPartner;

    Account coSellPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Co-Sell Partner'
    );
    insert coSellPartner;

    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;

    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      owningPartner.Id,
      null,
      null
    );
    insert deal;

    Group partnerGroup = new Group(
      Name = 'Escalation Partner Group',
      Type = 'Regular'
    );
    insert partnerGroup;

    insert new Partner_Access_Group__c(
      Partner_Account__c = coSellPartner.Id,
      Group_Id__c = partnerGroup.Id,
      Active__c = true
    );

    PartnerShareDTO request = new PartnerShareDTO();
    request.targetRecordId = deal.Id;
    request.targetObject = 'Deal Registration';
    request.partnerAccountId = coSellPartner.Id;
    request.accessLevel = 'Read';
    request.shareReason = 'Escalation';
    request.expiryDate = Date.today().addDays(-1);

    Id registryId = PartnerShareService.grantAccess(request);

    Test.startTest();
    Database.executeBatch(new PartnerShareCleanupBatch(), 100);
    Test.stopTest();

    Partner_Record_Share__c registry = [
      SELECT Id, Active__c
      FROM Partner_Record_Share__c
      WHERE Id = :registryId
    ];

    System.assertEquals(
      false,
      registry.Active__c,
      'Expired share should be revoked by the cleanup batch.'
    );

    List<Deal_Registration__Share> shares = [
      SELECT Id
      FROM Deal_Registration__Share
      WHERE ParentId = :deal.Id AND RowCause = 'Partner_Record_Share__c'
    ];

    System.assertEquals(
      0,
      shares.size(),
      'Manual share row should be removed once expired.'
    );
  }

  @IsTest
  static void scheduledRunKicksOffBatch() {
    Test.startTest();
    String jobId = System.schedule(
      'PartnerShareCleanupBatch Test',
      '0 0 2 * * ?',
      new PartnerShareCleanupBatch()
    );
    Test.stopTest();

    System.assertNotEquals(
      null,
      jobId,
      'Scheduling the cleanup batch should return a job id.'
    );
  }
}
