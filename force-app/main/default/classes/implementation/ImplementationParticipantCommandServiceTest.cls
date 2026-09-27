/*
 * Covers ImplementationParticipantCommandService: assign() links a Deal_
 * Participant__c to an implementation and materializes Deal_Implementation__c
 * sharing to that participant's partner account; assign() rejects a
 * participant belonging to a different deal or lacking authority; remove()
 * deactivates the row and revokes sharing once no other active participant
 * from that partner account remains.
 */
@IsTest
private class ImplementationParticipantCommandServiceTest {
  @IsTest
  static void assignGrantsAccessToTheParticipantsPartnerAccount() {
    Fixture fixture = createFixture();

    System.runAs(fixture.manager) {
      ImplementationParticipantCommand command = new ImplementationParticipantCommand();
      command.implementationId = fixture.implementation.Id;
      command.dealParticipantId = fixture.dealParticipant.Id;
      command.role = 'Implementation Lead';
      command.primary = true;

      Implementation_Participant__c participant = ImplementationParticipantCommandService.assign(
        command
      );

      Assert.areEqual('Active', participant.Status__c);
      Assert.isTrue(
        PartnerShareSelector.hasActiveGrant(
          fixture.implementation.Id,
          fixture.partnerAccount.Id
        )
      );
    }
  }

  @IsTest
  static void assignRejectsAParticipantFromADifferentDeal() {
    Fixture fixture = createFixture();
    Account otherCustomer = PartnerSyncTestDataFactory.customerAccount(
      'Other Customer'
    );
    insert otherCustomer;
    Deal_Registration__c otherDeal = PartnerSyncTestDataFactory.deal(
      otherCustomer.Id,
      fixture.partnerAccount.Id,
      null,
      null
    );
    insert otherDeal;
    Deal_Participant__c otherDealParticipant = new Deal_Participant__c(
      Deal__c = otherDeal.Id,
      Partner_Account__c = fixture.partnerAccount.Id,
      Participant_Type__c = 'Implementation Partner',
      Participant_Role__c = 'Implementation Lead',
      Status__c = 'Active',
      Access_Level__c = 'Collaborator',
      Active_Participant_Key__c = otherDeal.Id +
        '|Implementation Partner|' +
        fixture.partnerAccount.Id +
        '|Implementation Lead',
      Version_Number__c = 0
    );
    insert otherDealParticipant;

    System.runAs(fixture.manager) {
      ImplementationParticipantCommand command = new ImplementationParticipantCommand();
      command.implementationId = fixture.implementation.Id;
      command.dealParticipantId = otherDealParticipant.Id;
      command.role = 'Implementation Lead';

      try {
        ImplementationParticipantCommandService.assign(command);
        Assert.fail('Expected a cross-deal participant to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('deal'));
      }
    }
  }

  @IsTest
  static void assignRejectsWithoutAuthority() {
    Fixture fixture = createFixture();
    User unauthorizedUser = TestUserFactory.createInternalUser();

    System.runAs(unauthorizedUser) {
      ImplementationParticipantCommand command = new ImplementationParticipantCommand();
      command.implementationId = fixture.implementation.Id;
      command.dealParticipantId = fixture.dealParticipant.Id;
      command.role = 'Implementation Lead';

      try {
        ImplementationParticipantCommandService.assign(command);
        Assert.fail('Expected an unauthorized user to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('authority'));
      }
    }
  }

  @IsTest
  static void removeDeactivatesAndRevokesAccess() {
    Fixture fixture = createFixture();

    Implementation_Participant__c participant;
    System.runAs(fixture.manager) {
      ImplementationParticipantCommand assignCommand = new ImplementationParticipantCommand();
      assignCommand.implementationId = fixture.implementation.Id;
      assignCommand.dealParticipantId = fixture.dealParticipant.Id;
      assignCommand.role = 'Implementation Lead';
      participant = ImplementationParticipantCommandService.assign(
        assignCommand
      );
      Assert.isTrue(
        PartnerShareSelector.hasActiveGrant(
          fixture.implementation.Id,
          fixture.partnerAccount.Id
        )
      );

      ImplementationParticipantCommand removeCommand = new ImplementationParticipantCommand();
      removeCommand.implementationParticipantId = participant.Id;
      ImplementationParticipantCommandService.remove(removeCommand);
    }

    Assert.areEqual(
      'Inactive',
      [
        SELECT Status__c
        FROM Implementation_Participant__c
        WHERE Id = :participant.Id
      ]
      .Status__c
    );
    Assert.isFalse(
      PartnerShareSelector.hasActiveGrant(
        fixture.implementation.Id,
        fixture.partnerAccount.Id
      )
    );
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    fixture.manager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      fixture.manager.Id,
      'PartnerSync_Channel_Manager'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Manage_Implementation',
      true
    );

    Group partnerGroup = new Group(
      Name = 'Implementation Participant Test Group',
      DeveloperName = 'Implementation_Participant_Test_Group',
      Type = 'Regular'
    );
    insert partnerGroup;

    fixture.partnerAccount = PartnerSyncTestDataFactory.partnerAccount(
      'Implementation Delivery Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Implementation Participant Customer'
    );
    insert new List<Account>{ fixture.partnerAccount, customer };
    insert new Partner_Access_Group__c(
      Partner_Account__c = fixture.partnerAccount.Id,
      Group_Id__c = String.valueOf(partnerGroup.Id),
      Active__c = true
    );

    fixture.deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      fixture.partnerAccount.Id,
      null,
      null
    );
    fixture.deal.Status__c = 'Approved';
    insert fixture.deal;

    fixture.dealParticipant = new Deal_Participant__c(
      Deal__c = fixture.deal.Id,
      Partner_Account__c = fixture.partnerAccount.Id,
      Participant_Type__c = 'Implementation Partner',
      Participant_Role__c = 'Implementation Lead',
      Status__c = 'Active',
      Access_Level__c = 'Collaborator',
      Active_Participant_Key__c = fixture.deal.Id +
        '|Implementation Partner|' +
        fixture.partnerAccount.Id +
        '|Implementation Lead',
      Version_Number__c = 0
    );
    insert fixture.dealParticipant;

    fixture.implementation = new Deal_Implementation__c(
      Deal__c = fixture.deal.Id,
      Implementation_Type__c = 'Initial Implementation',
      Status__c = 'Planned',
      Health__c = 'Healthy',
      Version_Number__c = 0
    );
    insert fixture.implementation;

    return fixture;
  }

  private class Fixture {
    User manager;
    Account partnerAccount;
    Deal_Registration__c deal;
    Deal_Participant__c dealParticipant;
    Deal_Implementation__c implementation;
  }
}
