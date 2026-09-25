/*
 * Covers TransferDealOwnershipService: a governed transfer requires the
 * restricted permission and an active co-sell relationship, supersedes
 * the old originating participant while creating the new one, and
 * updates the Deal_Registration__c.Partner_Account__c projection under
 * its own version check.
 */
@IsTest
private class TransferDealOwnershipServiceTest {
  @IsTest
  static void transferSupersedesTheOldOriginatingParticipantAndUpdatesTheDeal() {
    Fixture fixture = createFixture();

    TransferDealOwnershipCommand command = new TransferDealOwnershipCommand();
    command.dealId = fixture.deal.Id;
    command.newPartnerAccountId = fixture.newPartner.Id;
    command.expectedDealVersion = 0;
    command.reason = 'Original partner exited the territory.';

    User pdlmAdmin = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(pdlmAdmin.Id, 'PartnerSync_PDLM_Admin');

    System.runAs(pdlmAdmin) {
      TransferDealOwnershipService.execute(command);
    }

    Deal_Registration__c updated = [
      SELECT Partner_Account__c, Version_Number__c
      FROM Deal_Registration__c
      WHERE Id = :fixture.deal.Id
    ];
    Assert.areEqual(fixture.newPartner.Id, updated.Partner_Account__c);
    Assert.areEqual(1, updated.Version_Number__c);

    List<Deal_Participant__c> participants = [
      SELECT Partner_Account__c, Status__c
      FROM Deal_Participant__c
      WHERE
        Deal__c = :fixture.deal.Id
        AND Participant_Type__c = 'Originating Partner'
      ORDER BY CreatedDate ASC
    ];
    Assert.areEqual(2, participants.size());
    Assert.areEqual('Superseded', participants[0].Status__c);
    Assert.areEqual(
      fixture.originalPartner.Id,
      participants[0].Partner_Account__c
    );
    Assert.areEqual('Active', participants[1].Status__c);
    Assert.areEqual(fixture.newPartner.Id, participants[1].Partner_Account__c);
  }

  @IsTest
  static void transferRequiresThePermission() {
    Fixture fixture = createFixture();

    TransferDealOwnershipCommand command = new TransferDealOwnershipCommand();
    command.dealId = fixture.deal.Id;
    command.newPartnerAccountId = fixture.newPartner.Id;
    command.expectedDealVersion = 0;

    User plainInternalUser = TestUserFactory.createInternalUser();

    System.runAs(plainInternalUser) {
      try {
        TransferDealOwnershipService.execute(command);
        Assert.fail('Expected the transfer to require the permission.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('do not have permission'));
      }
    }
  }

  @IsTest
  static void transferRequiresAnActiveRelationship() {
    Account originalPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Original Partner'
    );
    Account unrelatedPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Unrelated Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert new List<Account>{ originalPartner, unrelatedPartner, customer };
    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      originalPartner.Id,
      null,
      null
    );
    deal.Status__c = 'Approved';
    insert deal;

    TransferDealOwnershipCommand command = new TransferDealOwnershipCommand();
    command.dealId = deal.Id;
    command.newPartnerAccountId = unrelatedPartner.Id;
    command.expectedDealVersion = 0;

    User pdlmAdmin = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(pdlmAdmin.Id, 'PartnerSync_PDLM_Admin');

    System.runAs(pdlmAdmin) {
      try {
        TransferDealOwnershipService.execute(command);
        Assert.fail('Expected the missing relationship to block the transfer.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(
          expected.getMessage().contains('active partner relationship')
        );
      }
    }
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    fixture.originalPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Original Partner'
    );
    fixture.newPartner = PartnerSyncTestDataFactory.partnerAccount(
      'New Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert new List<Account>{
      fixture.originalPartner,
      fixture.newPartner,
      customer
    };
    insert new Partner_Account_Relationship__c(
      Source_Account__c = fixture.originalPartner.Id,
      Target_Account__c = fixture.newPartner.Id,
      Relationship_Type__c = 'Co-Sell',
      Status__c = 'Active',
      Allows_CoSell__c = true,
      Version_Number__c = 0
    );

    fixture.deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      fixture.originalPartner.Id,
      null,
      null
    );
    fixture.deal.Status__c = 'Approved';
    insert fixture.deal;

    insert new Deal_Participant__c(
      Deal__c = fixture.deal.Id,
      Partner_Account__c = fixture.originalPartner.Id,
      Participant_Type__c = 'Originating Partner',
      Participant_Role__c = 'Deal Owner',
      Status__c = 'Active',
      Access_Level__c = 'Full Partner',
      Version_Number__c = 0
    );

    return fixture;
  }

  private class Fixture {
    Account originalPartner;
    Account newPartner;
    Deal_Registration__c deal;
  }
}
