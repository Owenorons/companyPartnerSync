/*
 * Covers DealParticipantCommandService's invite/accept/decline lifecycle:
 * the invitation validation chain (relationship gating, inactive-partner
 * rejection, duplicate-slot prevention), the accept/decline authority
 * check, and the remove-participant protection-linkage guard.
 */
@IsTest
private class DealParticipantCommandServiceTest {
  @IsTest
  static void validInvitationCreatesAnInvitedParticipant() {
    Account originatingPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Originating Partner'
    );
    Account coSellPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Co-Sell Partner'
    );
    insert new List<Account>{ originatingPartner, coSellPartner };
    Deal_Registration__c deal = approvedDeal(originatingPartner.Id);
    activeRelationship(originatingPartner.Id, coSellPartner.Id);

    User channelManager = internalUser();

    Deal_Participant__c participant;
    System.runAs(channelManager) {
      participant = DealParticipantCommandService.execute(
        inviteCommand(deal.Id, coSellPartner.Id)
      );
    }

    Assert.areEqual('Invited', participant.Status__c);
    Assert.isNotNull(participant.Active_Participant_Key__c);
    Assert.areEqual(0, participant.Version_Number__c);
  }

  @IsTest
  static void duplicateInvitationForTheSameSlotIsPrevented() {
    Account originatingPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Originating Partner'
    );
    Account coSellPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Co-Sell Partner'
    );
    insert new List<Account>{ originatingPartner, coSellPartner };
    Deal_Registration__c deal = approvedDeal(originatingPartner.Id);
    activeRelationship(originatingPartner.Id, coSellPartner.Id);

    User channelManager = internalUser();

    System.runAs(channelManager) {
      DealParticipantCommandService.execute(
        inviteCommand(deal.Id, coSellPartner.Id)
      );

      try {
        DealParticipantCommandService.execute(
          inviteCommand(deal.Id, coSellPartner.Id)
        );
        Assert.fail('Expected a duplicate invitation to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('already has an active'));
      }
    }
  }

  @IsTest
  static void inactivePartnerIsRejected() {
    Account originatingPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Originating Partner'
    );
    Account inactivePartner = PartnerSyncTestDataFactory.partnerAccount(
      'Inactive Partner'
    );
    inactivePartner.Partner_Status__c = 'Inactive';
    insert new List<Account>{ originatingPartner, inactivePartner };
    Deal_Registration__c deal = approvedDeal(originatingPartner.Id);
    activeRelationship(originatingPartner.Id, inactivePartner.Id);

    User channelManager = internalUser();

    System.runAs(channelManager) {
      try {
        DealParticipantCommandService.execute(
          inviteCommand(deal.Id, inactivePartner.Id)
        );
        Assert.fail('Expected an inactive partner to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('not active'));
      }
    }
  }

  @IsTest
  static void relationshipRequirementIsEnforced() {
    Account originatingPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Originating Partner'
    );
    Account unrelatedPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Unrelated Partner'
    );
    insert new List<Account>{ originatingPartner, unrelatedPartner };
    Deal_Registration__c deal = approvedDeal(originatingPartner.Id);
    // No Partner_Account_Relationship__c seeded between these two accounts.

    User channelManager = internalUser();

    System.runAs(channelManager) {
      try {
        DealParticipantCommandService.execute(
          inviteCommand(deal.Id, unrelatedPartner.Id)
        );
        Assert.fail('Expected the missing relationship to block the invite.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(
          expected.getMessage().contains('active partner relationship')
        );
      }
    }
  }

  @IsTest
  static void invitedPartnerCanAcceptAndInactiveDealNoLongerBlocks() {
    Account originatingPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Originating Partner'
    );
    Account coSellPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Co-Sell Partner'
    );
    insert new List<Account>{ originatingPartner, coSellPartner };
    Contact coSellContact = PartnerSyncTestDataFactory.partnerContact(
      coSellPartner.Id
    );
    insert coSellContact;
    Deal_Registration__c deal = approvedDeal(originatingPartner.Id);
    activeRelationship(originatingPartner.Id, coSellPartner.Id);

    User channelManager = internalUser();
    Deal_Participant__c participant;
    System.runAs(channelManager) {
      participant = DealParticipantCommandService.execute(
        inviteCommand(deal.Id, coSellPartner.Id)
      );
    }

    User coSellUser = TestUserFactory.createExternalUser(coSellContact.Id);
    DealParticipantCommand accept = new DealParticipantCommand();
    accept.participantId = participant.Id;
    accept.action = 'Accept';
    accept.expectedVersion = 0;

    System.runAs(coSellUser) {
      participant = DealParticipantCommandService.execute(accept);
    }

    Assert.areEqual('Accepted', participant.Status__c);
    Assert.isNotNull(participant.Accepted_On__c);
  }

  @IsTest
  static void partnerCannotAcceptAnotherPartnersInvitation() {
    Account originatingPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Originating Partner'
    );
    Account coSellPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Co-Sell Partner'
    );
    Account otherPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Other Partner'
    );
    insert new List<Account>{ originatingPartner, coSellPartner, otherPartner };
    Contact otherContact = PartnerSyncTestDataFactory.partnerContact(
      otherPartner.Id
    );
    insert otherContact;
    Deal_Registration__c deal = approvedDeal(originatingPartner.Id);
    activeRelationship(originatingPartner.Id, coSellPartner.Id);

    User channelManager = internalUser();
    Deal_Participant__c participant;
    System.runAs(channelManager) {
      participant = DealParticipantCommandService.execute(
        inviteCommand(deal.Id, coSellPartner.Id)
      );
    }

    User otherUser = TestUserFactory.createExternalUser(otherContact.Id);
    DealParticipantCommand accept = new DealParticipantCommand();
    accept.participantId = participant.Id;
    accept.action = 'Accept';
    accept.expectedVersion = 0;

    System.runAs(otherUser) {
      try {
        DealParticipantCommandService.execute(accept);
        Assert.fail('Expected a non-owning partner to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('lacks authority'));
      }
    }
  }

  @IsTest
  static void invitedPartnerCanDecline() {
    Account originatingPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Originating Partner'
    );
    Account coSellPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Co-Sell Partner'
    );
    insert new List<Account>{ originatingPartner, coSellPartner };
    Contact coSellContact = PartnerSyncTestDataFactory.partnerContact(
      coSellPartner.Id
    );
    insert coSellContact;
    Deal_Registration__c deal = approvedDeal(originatingPartner.Id);
    activeRelationship(originatingPartner.Id, coSellPartner.Id);

    User channelManager = internalUser();
    Deal_Participant__c participant;
    System.runAs(channelManager) {
      participant = DealParticipantCommandService.execute(
        inviteCommand(deal.Id, coSellPartner.Id)
      );
    }

    User coSellUser = TestUserFactory.createExternalUser(coSellContact.Id);
    DealParticipantCommand decline = new DealParticipantCommand();
    decline.participantId = participant.Id;
    decline.action = 'Decline';
    decline.expectedVersion = 0;
    decline.reason = 'Not able to support this deal.';

    System.runAs(coSellUser) {
      participant = DealParticipantCommandService.execute(decline);
    }

    Assert.areEqual('Declined', participant.Status__c);
    Assert.isNull(participant.Active_Participant_Key__c);
  }

  @IsTest
  static void removalIsBlockedByAnActiveProtectionLinkage() {
    Account originatingPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Originating Partner'
    );
    Account coSellPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Co-Sell Partner'
    );
    insert new List<Account>{ originatingPartner, coSellPartner };
    Deal_Registration__c deal = approvedDeal(originatingPartner.Id);
    activeRelationship(originatingPartner.Id, coSellPartner.Id);

    User channelManager = internalUser();
    Deal_Participant__c participant;
    System.runAs(channelManager) {
      participant = DealParticipantCommandService.execute(
        inviteCommand(deal.Id, coSellPartner.Id)
      );
    }

    Deal_Protection_Grant__c grant = new Deal_Protection_Grant__c(
      Deal__c = deal.Id,
      Current__c = true,
      Current_Grant_Key__c = String.valueOf(deal.Id),
      Status__c = 'Active',
      Start_Date__c = Date.today(),
      End_Date__c = Date.today().addDays(30),
      Version_Number__c = 0,
      Extension_Count__c = 0
    );
    insert grant;
    insert new Deal_Protection_Participant__c(
      Protection__c = grant.Id,
      Deal_Participant__c = participant.Id,
      Partner_Account__c = coSellPartner.Id,
      Protection_Role__c = 'Shared Protected Partner',
      Status__c = 'Active'
    );

    DealParticipantCommand remove = new DealParticipantCommand();
    remove.participantId = participant.Id;
    remove.action = 'Remove';
    remove.expectedVersion = 0;
    remove.reason = 'No longer collaborating.';

    System.runAs(channelManager) {
      try {
        DealParticipantCommandService.execute(remove);
        Assert.fail(
          'Expected removal to be blocked by the active protection linkage.'
        );
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(
          expected.getMessage().contains('shared protection interest')
        );
      }
    }
  }

  private static Deal_Registration__c approvedDeal(Id partnerAccountId) {
    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;
    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      partnerAccountId,
      null,
      null
    );
    deal.Status__c = 'Approved';
    insert deal;
    return deal;
  }

  private static void activeRelationship(
    Id sourceAccountId,
    Id targetAccountId
  ) {
    insert new Partner_Account_Relationship__c(
      Source_Account__c = sourceAccountId,
      Target_Account__c = targetAccountId,
      Relationship_Type__c = 'Co-Sell',
      Status__c = 'Active',
      Allows_CoSell__c = true,
      Version_Number__c = 0
    );
  }

  private static DealParticipantCommand inviteCommand(
    Id dealId,
    Id partnerAccountId
  ) {
    DealParticipantCommand command = new DealParticipantCommand();
    command.dealId = dealId;
    command.action = 'Invite';
    command.partnerAccountId = partnerAccountId;
    command.participantType = 'Co-Sell Partner';
    command.participantRole = 'Co-Sell Contributor';
    command.reason = 'Bringing in a technical specialist.';
    return command;
  }

  private static User internalUser() {
    User channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );
    return channelManager;
  }
}
