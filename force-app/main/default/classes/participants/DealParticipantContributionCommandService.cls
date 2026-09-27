/**
 * Records and approves participant contributions (doc §38.30-31) -
 * independent of protection and revenue share, dimension-specific, and
 * need not total 100% across dimensions. A contribution row is
 * append-mostly and doesn't gate access or protection, so this doesn't
 * carry the FOR UPDATE/Version_Number__c rigor of the aggregate-root
 * command services.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class DealParticipantContributionCommandService {
  /**
   * Records a new contribution for a participant.
   *
   * @param command The contribution to record.
   * @return The new Deal_Participant_Contribution__c row.
   */
  public static Deal_Participant_Contribution__c recordContribution(
    RecordParticipantContributionCommand command
  ) {
    if (
      command == null ||
      command.participantId == null ||
      String.isBlank(command.contributionType) ||
      command.percentage == null
    ) {
      throw new PartnerSyncHandledException(
        'Participant, contribution type, and percentage are required.'
      );
    }

    Deal_Participant_Contribution__c contribution = new Deal_Participant_Contribution__c(
      Deal_Participant__c = command.participantId,
      Contribution_Type__c = command.contributionType,
      Percentage__c = command.percentage,
      Source__c = command.source,
      Effective_From__c = Date.today(),
      Approved__c = false
    );
    Database.insert(contribution, AccessLevel.SYSTEM_MODE);

    publishEvent('DealParticipantContributionRecorded', command.participantId);

    return contribution;
  }

  /**
   * Approves a previously-recorded contribution.
   *
   * @param command The approval request.
   * @return The approved Deal_Participant_Contribution__c row.
   */
  public static Deal_Participant_Contribution__c approveContribution(
    ApproveParticipantContributionCommand command
  ) {
    if (command == null || command.contributionId == null) {
      throw new PartnerSyncHandledException('A contribution is required.');
    }

    Deal_Participant_Contribution__c contribution = DealParticipantContributionSelector.selectById(
      command.contributionId
    );
    if (contribution.Approved__c == true) {
      throw new PartnerSyncHandledException(
        'This contribution has already been approved.'
      );
    }

    contribution.Approved__c = true;
    contribution.Approved_By__c = UserInfo.getUserId();
    Database.update(contribution, AccessLevel.SYSTEM_MODE);

    publishEvent(
      'DealParticipantContributionApproved',
      contribution.Deal_Participant__c
    );

    return contribution;
  }

  private static void publishEvent(String eventType, Id participantId) {
    List<Deal_Participant__c> participants = [
      SELECT Deal__c, Partner_Account__c
      FROM Deal_Participant__c
      WHERE Id = :participantId
      WITH SYSTEM_MODE
    ];
    if (participants.isEmpty()) {
      return;
    }

    PlatformEventPublisherService.publish(
      eventType,
      participants[0].Deal__c,
      'Deal_Registration__c',
      participants[0].Partner_Account__c,
      'A co-sell participant contribution was ' +
      (eventType == 'DealParticipantContributionApproved'
        ? 'approved.'
        : 'recorded.'),
      'Info'
    );
  }
}
