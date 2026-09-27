/*
 * Covers DealParticipantController: getDealTeam is accessible to both the
 * originating partner and an active co-sell participant (via the
 * PartnerAccessService.canViewDeal extension), getPendingInvitations is
 * internal-only, and the returned DTO never carries internal conflict/
 * review/approval fields - it has none defined at all, by construction.
 */
@IsTest
private class DealParticipantControllerTest {
  @IsTest
  static void originatingPartnerCanViewTheDealTeam() {
    Fixture fixture = createFixture();

    Contact originatingContact = PartnerSyncTestDataFactory.partnerContact(
      fixture.originatingPartner.Id
    );
    insert originatingContact;
    User originatingUser = TestUserFactory.createExternalUser(
      originatingContact.Id
    );

    List<DealParticipantSummaryDTO> team;
    System.runAs(originatingUser) {
      team = DealParticipantController.getDealTeam(fixture.deal.Id);
    }

    Assert.areEqual(1, team.size());
    Assert.isTrue(team[0].isOwnOrganisation);
  }

  @IsTest
  static void activeCoSellParticipantCanViewTheDealTeam() {
    Fixture fixture = createFixture();

    Account coSellPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Co-Sell Partner'
    );
    insert coSellPartner;
    Contact coSellContact = PartnerSyncTestDataFactory.partnerContact(
      coSellPartner.Id
    );
    insert coSellContact;
    insert new Deal_Participant__c(
      Deal__c = fixture.deal.Id,
      Partner_Account__c = coSellPartner.Id,
      Participant_Type__c = 'Co-Sell Partner',
      Participant_Role__c = 'Co-Sell Contributor',
      Status__c = 'Active',
      Access_Level__c = 'Collaborator',
      Version_Number__c = 0
    );

    User coSellUser = TestUserFactory.createExternalUser(coSellContact.Id);

    List<DealParticipantSummaryDTO> team;
    System.runAs(coSellUser) {
      team = DealParticipantController.getDealTeam(fixture.deal.Id);
    }

    Assert.areEqual(2, team.size());
  }

  @IsTest
  static void unrelatedPartnerCannotViewTheDealTeam() {
    Fixture fixture = createFixture();

    Account unrelatedPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Unrelated Partner'
    );
    insert unrelatedPartner;
    Contact unrelatedContact = PartnerSyncTestDataFactory.partnerContact(
      unrelatedPartner.Id
    );
    insert unrelatedContact;
    User unrelatedUser = TestUserFactory.createExternalUser(
      unrelatedContact.Id
    );

    System.runAs(unrelatedUser) {
      try {
        DealParticipantController.getDealTeam(fixture.deal.Id);
        Assert.fail('Expected an unrelated partner to be rejected.');
      } catch (AuraHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('not accessible'));
      }
    }
  }

  @IsTest
  static void pendingInvitationsIsInternalOnly() {
    Fixture fixture = createFixture();
    Contact originatingContact = PartnerSyncTestDataFactory.partnerContact(
      fixture.originatingPartner.Id
    );
    insert originatingContact;
    User originatingUser = TestUserFactory.createExternalUser(
      originatingContact.Id
    );

    System.runAs(originatingUser) {
      try {
        DealParticipantController.getPendingInvitations();
        Assert.fail('Expected a partner user to be rejected.');
      } catch (AuraHandledException expected) {
        Assert.isTrue(
          expected.getMessage().contains('only available to internal users')
        );
      }
    }

    User internalUser = TestUserFactory.createInternalUser();
    List<DealParticipantSummaryDTO> invitations;
    System.runAs(internalUser) {
      invitations = DealParticipantController.getPendingInvitations();
    }
    Assert.isNotNull(invitations);
  }

  @IsTest
  static void getActiveCoSellDealsListsDealsWithActiveCoSellStatus() {
    Fixture fixture = createFixture();
    fixture.deal.CoSell_Status__c = 'Active';
    update fixture.deal;

    User internalUser = TestUserFactory.createInternalUser();
    List<CoSellDealSummaryDTO> deals;
    System.runAs(internalUser) {
      deals = DealParticipantController.getActiveCoSellDeals();
    }

    Assert.areEqual(1, deals.size());
    Assert.areEqual(fixture.deal.Id, deals[0].dealId);
    Assert.areEqual('Active', deals[0].coSellStatus);
  }

  @IsTest
  static void getActiveCoSellDealsIsInternalOnly() {
    Fixture fixture = createFixture();
    Contact originatingContact = PartnerSyncTestDataFactory.partnerContact(
      fixture.originatingPartner.Id
    );
    insert originatingContact;
    User partnerUser = TestUserFactory.createExternalUser(
      originatingContact.Id
    );

    System.runAs(partnerUser) {
      try {
        DealParticipantController.getActiveCoSellDeals();
        Assert.fail('Expected a partner user to be rejected.');
      } catch (AuraHandledException expected) {
        Assert.isTrue(
          expected.getMessage().contains('only available to internal users')
        );
      }
    }
  }

  @IsTest
  static void getParticipantChangesReturnsAuditedParticipantActions() {
    User internalUser = TestUserFactory.createInternalUser();
    System.runAs(internalUser) {
      AuditEventConsumerService.logBusinessEvent(
        new PartnerSync_Event__e(
          Event_Type__c = 'DealParticipantInvited',
          Object_Name__c = 'Deal_Registration__c',
          Record_Id__c = null,
          Partner_Account_Id__c = null
        )
      );

      List<ParticipantChangeDTO> changes = DealParticipantController.getParticipantChanges();

      Assert.areEqual(1, changes.size());
      Assert.areEqual('Invite Participant', changes[0].action);
    }
  }

  @IsTest
  static void getPendingSharedProtectionRequestsAndApproval() {
    Fixture fixture = createFixture();
    Account coSellPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Co-Sell Partner'
    );
    insert coSellPartner;
    Deal_Participant__c participant = new Deal_Participant__c(
      Deal__c = fixture.deal.Id,
      Partner_Account__c = coSellPartner.Id,
      Participant_Type__c = 'Co-Sell Partner',
      Participant_Role__c = 'Co-Sell Contributor',
      Status__c = 'Active',
      Access_Level__c = 'Collaborator',
      Version_Number__c = 0
    );
    insert participant;
    Deal_Protection_Grant__c grant = new Deal_Protection_Grant__c(
      Deal__c = fixture.deal.Id,
      Current__c = true,
      Current_Grant_Key__c = String.valueOf(fixture.deal.Id),
      Status__c = 'Active',
      Start_Date__c = Date.today(),
      End_Date__c = Date.today().addDays(30),
      Version_Number__c = 0,
      Extension_Count__c = 0
    );
    insert grant;
    Deal_Protection_Participant__c request = new Deal_Protection_Participant__c(
      Protection__c = grant.Id,
      Deal_Participant__c = participant.Id,
      Partner_Account__c = coSellPartner.Id,
      Protection_Role__c = 'Shared Protected Partner',
      Status__c = 'Proposed',
      Share_Percentage__c = 40
    );
    insert request;

    User pdlmAdmin = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(pdlmAdmin.Id, 'PartnerSync_PDLM_Admin');

    List<SharedProtectionRequestDTO> pending;
    System.runAs(pdlmAdmin) {
      pending = DealParticipantController.getPendingSharedProtectionRequests();
    }
    Assert.areEqual(1, pending.size());
    Assert.areEqual(request.Id, pending[0].protectionParticipantId);

    System.runAs(pdlmAdmin) {
      DealParticipantController.approveSharedProtectionRequest(
        pending[0].protectionParticipantId,
        pending[0].grantVersionNumber
      );
    }

    Assert.areEqual(
      'Active',
      [
        SELECT Status__c
        FROM Deal_Protection_Participant__c
        WHERE Id = :request.Id
      ]
      .Status__c
    );
  }

  @IsTest
  static void getRelationshipExceptionsListsSuspendedAndExpiredRelationships() {
    Account source = PartnerSyncTestDataFactory.partnerAccount('Source');
    Account target = PartnerSyncTestDataFactory.partnerAccount('Target');
    insert new List<Account>{ source, target };
    insert new Partner_Account_Relationship__c(
      Source_Account__c = source.Id,
      Target_Account__c = target.Id,
      Relationship_Type__c = 'Co-Sell',
      Status__c = 'Suspended',
      Allows_CoSell__c = true,
      Version_Number__c = 0
    );

    User internalUser = TestUserFactory.createInternalUser();
    List<RelationshipExceptionDTO> exceptions;
    System.runAs(internalUser) {
      exceptions = DealParticipantController.getRelationshipExceptions();
    }

    Assert.areEqual(1, exceptions.size());
    Assert.areEqual('Suspended', exceptions[0].status);
  }

  @IsTest
  static void getSlaBreachesListsAtRiskAndExpiredParticipants() {
    Fixture fixture = createFixture();
    Account coSellPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Co-Sell Partner'
    );
    insert coSellPartner;
    insert new Deal_Participant__c(
      Deal__c = fixture.deal.Id,
      Partner_Account__c = coSellPartner.Id,
      Participant_Type__c = 'Co-Sell Partner',
      Participant_Role__c = 'Co-Sell Contributor',
      Status__c = 'Invited',
      Invited_On__c = System.now().addHours(-60),
      Respond_By__c = System.now().addHours(12),
      At_Risk_Notified__c = true,
      Version_Number__c = 0
    );

    User internalUser = TestUserFactory.createInternalUser();
    List<DealParticipantSummaryDTO> breaches;
    System.runAs(internalUser) {
      breaches = DealParticipantController.getSlaBreaches();
    }

    Assert.areEqual(1, breaches.size());
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    fixture.originatingPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Originating Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert new List<Account>{ fixture.originatingPartner, customer };
    fixture.deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      fixture.originatingPartner.Id,
      null,
      null
    );
    fixture.deal.Status__c = 'Approved';
    insert fixture.deal;

    insert new Deal_Participant__c(
      Deal__c = fixture.deal.Id,
      Partner_Account__c = fixture.originatingPartner.Id,
      Participant_Type__c = 'Originating Partner',
      Participant_Role__c = 'Deal Owner',
      Status__c = 'Active',
      Access_Level__c = 'Full Partner',
      Version_Number__c = 0
    );

    return fixture;
  }

  private class Fixture {
    Account originatingPartner;
    Deal_Registration__c deal;
  }
}
