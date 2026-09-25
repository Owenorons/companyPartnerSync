/*
 * Covers DealParticipantExpiryBatch: an overdue Invited participant is
 * expired (via DealParticipantCommandService, not direct DML - the key is
 * released), a participant still within its response window is left
 * alone, and the batch can be scheduled.
 */
@IsTest
private class DealParticipantExpiryBatchTest {
  @IsTest
  static void expiresOverdueInvitationsAndReleasesTheActiveKey() {
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
    insert deal;

    Deal_Participant__c overdue = new Deal_Participant__c(
      Deal__c = deal.Id,
      Partner_Account__c = partner.Id,
      Participant_Type__c = 'Co-Sell Partner',
      Participant_Role__c = 'Co-Sell Contributor',
      Status__c = 'Invited',
      Invited_On__c = System.now().addDays(-5),
      Respond_By__c = System.now().addDays(-1),
      Active_Participant_Key__c = deal.Id +
        '|Co-Sell Partner|' +
        partner.Id +
        '|Co-Sell Contributor',
      Version_Number__c = 0
    );
    insert overdue;

    Test.startTest();
    Database.executeBatch(new DealParticipantExpiryBatch(), 100);
    Test.stopTest();

    Deal_Participant__c updated = [
      SELECT Status__c, Active_Participant_Key__c
      FROM Deal_Participant__c
      WHERE Id = :overdue.Id
    ];
    Assert.areEqual('Expired', updated.Status__c);
    Assert.isNull(updated.Active_Participant_Key__c);
  }

  @IsTest
  static void leavesParticipantsWithinTheirResponseWindowAlone() {
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
    insert deal;

    Deal_Participant__c pending = new Deal_Participant__c(
      Deal__c = deal.Id,
      Partner_Account__c = partner.Id,
      Participant_Type__c = 'Co-Sell Partner',
      Participant_Role__c = 'Co-Sell Contributor',
      Status__c = 'Invited',
      Invited_On__c = System.now(),
      Respond_By__c = System.now().addDays(3),
      Active_Participant_Key__c = deal.Id +
        '|Co-Sell Partner|' +
        partner.Id +
        '|Co-Sell Contributor',
      Version_Number__c = 0
    );
    insert pending;

    Test.startTest();
    Database.executeBatch(new DealParticipantExpiryBatch(), 100);
    Test.stopTest();

    Assert.areEqual(
      'Invited',
      [SELECT Status__c FROM Deal_Participant__c WHERE Id = :pending.Id]
      .Status__c
    );
  }

  @IsTest
  static void canBeScheduled() {
    Test.startTest();
    String jobId = System.schedule(
      'DealParticipantExpiryBatchTest',
      '0 0 2 * * ?',
      new DealParticipantExpiryBatch()
    );
    Test.stopTest();

    Assert.isNotNull(jobId);
  }
}
