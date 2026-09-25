/*
 * Covers DealProtectionParticipantCommandService's request/approve flow
 * and the structural invariant that activating a participant never itself
 * creates protection linkage. Documents the Sprint 38 plan's Known
 * Adaptation #1: approval bumps Version_Number__c and flips
 * Exclusivity_Type__c on the existing Deal_Protection_Grant__c rather
 * than creating a new versioned grant.
 */
@IsTest
private class DealProtectionParticipantCommandServiceTest {
  @IsTest
  static void activatingAParticipantNeverAutomaticallyCreatesProtectionLinkage() {
    Fixture fixture = createFixture();

    System.runAs(fixture.channelManager) {
      Deal_Participant__c participant = DealParticipantCommandService.execute(
        inviteCommand(fixture.deal.Id, fixture.coSellPartner.Id)
      );

      DealParticipantCommand accept = new DealParticipantCommand();
      accept.participantId = participant.Id;
      accept.action = 'Accept';
      accept.expectedVersion = 0;
      participant = DealParticipantCommandService.execute(accept);

      DealParticipantCommand activate = new DealParticipantCommand();
      activate.participantId = participant.Id;
      activate.action = 'Activate';
      activate.expectedVersion = 1;
      participant = DealParticipantCommandService.execute(activate);

      Assert.areEqual('Active', participant.Status__c);
      Assert.areEqual(
        0,
        [
          SELECT COUNT()
          FROM Deal_Protection_Participant__c
          WHERE Deal_Participant__c = :participant.Id
        ]
      );
    }
  }

  @IsTest
  static void requestingSharedProtectionAloneDoesNotActivateIt() {
    Fixture fixture = createFixture();
    Deal_Participant__c participant;

    System.runAs(fixture.channelManager) {
      participant = activeParticipant(fixture);
    }

    RequestSharedProtectionCommand request = new RequestSharedProtectionCommand();
    request.dealId = fixture.deal.Id;
    request.participantId = participant.Id;
    request.protectionRole = 'Shared Protected Partner';
    request.sharePercentage = 40;

    Deal_Protection_Participant__c protectionParticipant;
    System.runAs(fixture.channelManager) {
      protectionParticipant = DealProtectionParticipantCommandService.requestSharedProtection(
        request
      );
    }

    Assert.areEqual('Proposed', protectionParticipant.Status__c);
  }

  @IsTest
  static void approvalActivatesAndFlipsExclusivityToShared() {
    Fixture fixture = createFixture();
    Deal_Participant__c participant;

    System.runAs(fixture.channelManager) {
      participant = activeParticipant(fixture);
    }

    RequestSharedProtectionCommand request = new RequestSharedProtectionCommand();
    request.dealId = fixture.deal.Id;
    request.participantId = participant.Id;
    request.protectionRole = 'Shared Protected Partner';
    request.sharePercentage = 40;

    Deal_Protection_Participant__c protectionParticipant;
    System.runAs(fixture.channelManager) {
      protectionParticipant = DealProtectionParticipantCommandService.requestSharedProtection(
        request
      );
    }

    User pdlmAdmin = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(pdlmAdmin.Id, 'PartnerSync_PDLM_Admin');

    ApproveSharedProtectionCommand approve = new ApproveSharedProtectionCommand();
    approve.protectionParticipantId = protectionParticipant.Id;
    approve.expectedGrantVersion = 0;

    System.runAs(pdlmAdmin) {
      protectionParticipant = DealProtectionParticipantCommandService.approveSharedProtection(
        approve
      );
    }

    Assert.areEqual('Active', protectionParticipant.Status__c);
    Assert.isFalse(
      protectionParticipant.Primary__c,
      'A co-sell participant should not become primary.'
    );

    Deal_Protection_Grant__c grant = [
      SELECT Exclusivity_Type__c, Version_Number__c
      FROM Deal_Protection_Grant__c
      WHERE Deal__c = :fixture.deal.Id AND Current__c = TRUE
    ];
    Assert.areEqual('Shared', grant.Exclusivity_Type__c);
    Assert.areEqual(1, grant.Version_Number__c);
  }

  @IsTest
  static void approvalRequiresThePermission() {
    Fixture fixture = createFixture();
    Deal_Participant__c participant;

    System.runAs(fixture.channelManager) {
      participant = activeParticipant(fixture);
    }

    RequestSharedProtectionCommand request = new RequestSharedProtectionCommand();
    request.dealId = fixture.deal.Id;
    request.participantId = participant.Id;
    request.protectionRole = 'Shared Protected Partner';

    Deal_Protection_Participant__c protectionParticipant;
    System.runAs(fixture.channelManager) {
      protectionParticipant = DealProtectionParticipantCommandService.requestSharedProtection(
        request
      );
    }

    ApproveSharedProtectionCommand approve = new ApproveSharedProtectionCommand();
    approve.protectionParticipantId = protectionParticipant.Id;
    approve.expectedGrantVersion = 0;

    // fixture.channelManager holds no PartnerSync_Approve_Shared_Protection.
    System.runAs(fixture.channelManager) {
      try {
        DealProtectionParticipantCommandService.approveSharedProtection(
          approve
        );
        Assert.fail('Expected the approval to require the permission.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('do not have permission'));
      }
    }
  }

  private static Deal_Participant__c activeParticipant(Fixture fixture) {
    Deal_Participant__c participant = DealParticipantCommandService.execute(
      inviteCommand(fixture.deal.Id, fixture.coSellPartner.Id)
    );

    DealParticipantCommand accept = new DealParticipantCommand();
    accept.participantId = participant.Id;
    accept.action = 'Accept';
    accept.expectedVersion = 0;
    participant = DealParticipantCommandService.execute(accept);

    DealParticipantCommand activate = new DealParticipantCommand();
    activate.participantId = participant.Id;
    activate.action = 'Activate';
    activate.expectedVersion = 1;
    return DealParticipantCommandService.execute(activate);
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

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    fixture.channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      fixture.channelManager.Id,
      'PartnerSync_Channel_Manager'
    );
    // Activating a participant grants a Partner_Record_Share__c row via
    // DealParticipantSharingService; PSG_Internal_Administrator is the
    // permission set group PartnerShareServiceTest already relies on for
    // full Partner_Record_Share__c field access.
    TestUserFactory.assignPermissionSetGroup(
      fixture.channelManager.Id,
      'PSG_Internal_Administrator'
    );

    Account originatingPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Originating Partner'
    );
    fixture.coSellPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Co-Sell Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert new List<Account>{
      originatingPartner,
      fixture.coSellPartner,
      customer
    };

    // Activating a participant triggers DealParticipantSharingService,
    // which needs a partner access group to grant a share through.
    Group partnerGroup = new Group(
      Name = 'Protection Participant Test Group',
      DeveloperName = 'Protection_Participant_Test_Group',
      Type = 'Regular'
    );
    insert partnerGroup;
    insert new Partner_Access_Group__c(
      Partner_Account__c = fixture.coSellPartner.Id,
      Group_Id__c = String.valueOf(partnerGroup.Id),
      Active__c = true
    );

    insert new Partner_Account_Relationship__c(
      Source_Account__c = originatingPartner.Id,
      Target_Account__c = fixture.coSellPartner.Id,
      Relationship_Type__c = 'Co-Sell',
      Status__c = 'Active',
      Allows_CoSell__c = true,
      Version_Number__c = 0
    );

    fixture.deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      originatingPartner.Id,
      null,
      null
    );
    fixture.deal.Status__c = 'Approved';
    insert fixture.deal;

    insert new Deal_Protection_Grant__c(
      Deal__c = fixture.deal.Id,
      Current__c = true,
      Current_Grant_Key__c = String.valueOf(fixture.deal.Id),
      Status__c = 'Active',
      Start_Date__c = Date.today(),
      End_Date__c = Date.today().addDays(30),
      Version_Number__c = 0,
      Extension_Count__c = 0
    );

    return fixture;
  }

  private class Fixture {
    User channelManager;
    Account coSellPartner;
    Deal_Registration__c deal;
  }
}
