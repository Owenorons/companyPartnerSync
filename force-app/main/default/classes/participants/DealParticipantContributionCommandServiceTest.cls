/*
 * Covers DealParticipantContributionCommandService: a contribution is
 * recorded independently of protection (no Deal_Protection_Participant__c
 * involvement at all), and approval is idempotent-guarded against
 * double-approval.
 */
@IsTest
private class DealParticipantContributionCommandServiceTest {
  @IsTest
  static void contributionIsRecordedIndependentlyOfProtection() {
    Deal_Participant__c participant = createParticipant();

    RecordParticipantContributionCommand command = new RecordParticipantContributionCommand();
    command.participantId = participant.Id;
    command.contributionType = 'Technical';
    command.percentage = 70;
    command.source = 'Manual entry';

    Deal_Participant_Contribution__c contribution = DealParticipantContributionCommandService.recordContribution(
      command
    );

    Assert.areEqual('Technical', contribution.Contribution_Type__c);
    Assert.areEqual(70, contribution.Percentage__c);
    Assert.isFalse(contribution.Approved__c);
    Assert.areEqual(
      0,
      [
        SELECT COUNT()
        FROM Deal_Protection_Participant__c
        WHERE Deal_Participant__c = :participant.Id
      ]
    );
  }

  @IsTest
  static void approvalCannotBeAppliedTwice() {
    Deal_Participant__c participant = createParticipant();

    RecordParticipantContributionCommand recordCommand = new RecordParticipantContributionCommand();
    recordCommand.participantId = participant.Id;
    recordCommand.contributionType = 'Origination';
    recordCommand.percentage = 100;

    Deal_Participant_Contribution__c contribution = DealParticipantContributionCommandService.recordContribution(
      recordCommand
    );

    ApproveParticipantContributionCommand approve = new ApproveParticipantContributionCommand();
    approve.contributionId = contribution.Id;

    DealParticipantContributionCommandService.approveContribution(approve);

    try {
      DealParticipantContributionCommandService.approveContribution(approve);
      Assert.fail('Expected a second approval to be rejected.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains('already been approved'));
    }
  }

  private static Deal_Participant__c createParticipant() {
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

    Deal_Participant__c participant = new Deal_Participant__c(
      Deal__c = deal.Id,
      Partner_Account__c = partner.Id,
      Participant_Type__c = 'Co-Sell Partner',
      Participant_Role__c = 'Co-Sell Contributor',
      Status__c = 'Active',
      Access_Level__c = 'Collaborator',
      Version_Number__c = 0
    );
    insert participant;
    return participant;
  }
}
