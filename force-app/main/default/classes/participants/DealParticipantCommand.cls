/**
 * Request payload for a Deal_Participant__c lifecycle command, covering
 * both the invitation inputs (used only by the 'Invite' action) and the
 * decision inputs shared by every other action.
 */
public class DealParticipantCommand {
  public Id dealId;
  public Id participantId;
  public String action;
  public Integer expectedVersion;
  public String reason;

  // Invite-only fields.
  public Id partnerAccountId;
  public Id targetContactId;
  public Id targetUserId;
  public String participantType;
  public String participantRole;
  public Datetime respondBy;
  public String requestedAccessLevel;
  public Boolean requestedProtectionParticipation;
  public Boolean autoAccept;

  /**
   * Validates that the command has the fields its action requires, throwing
   * a PartnerSyncHandledException otherwise.
   */
  public void validate() {
    if (String.isBlank(action)) {
      throw new PartnerSyncHandledException(
        'A participant command action is required.'
      );
    }

    if (action == 'Invite') {
      if (
        dealId == null ||
        partnerAccountId == null ||
        String.isBlank(participantType) ||
        String.isBlank(participantRole)
      ) {
        throw new PartnerSyncHandledException(
          'Deal, partner account, participant type, and role are required to invite a participant.'
        );
      }
      return;
    }

    if (participantId == null) {
      throw new PartnerSyncHandledException(
        'A participant is required for this command.'
      );
    }
  }
}
