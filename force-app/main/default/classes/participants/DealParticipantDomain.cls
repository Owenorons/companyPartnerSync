/**
 * Pure validation and shaping for Deal_Participant__c commands - no DML,
 * mirrors PartnerShareDomain's separation of concerns.
 */
public with sharing class DealParticipantDomain {
  /**
   * Builds the Active_Participant_Key__c value for a given slot: one key
   * per deal/type/actor/role combination.
   *
   * @param dealId Id of the deal.
   * @param participantType The participant type occupying the slot.
   * @param actorId Id of the Account, Contact, or User identifying the participant.
   * @param participantRole The participant role occupying the slot.
   * @return The composed active-participant key.
   */
  public static String buildActiveKey(
    Id dealId,
    String participantType,
    Id actorId,
    String participantRole
  ) {
    return String.valueOf(dealId) +
      '|' +
      participantType +
      '|' +
      String.valueOf(actorId) +
      '|' +
      participantRole;
  }

  /**
   * Resolves the identifying actor Id for a new participant - the account,
   * contact, or user that occupies its active-key slot. Exactly one should
   * be supplied by the inviter for a given participant type.
   *
   * @param command The invitation command.
   * @return The first non-null of partnerAccountId, targetContactId, targetUserId.
   */
  public static Id resolveActorId(DealParticipantCommand command) {
    if (command.targetContactId != null) {
      return command.targetContactId;
    }
    if (command.targetUserId != null) {
      return command.targetUserId;
    }
    return command.partnerAccountId;
  }

  /**
   * Maps a Deal_Participant__c row to the partner-safe summary DTO (doc
   * §38.24) - no internal conflict/review/approval fields, ever.
   *
   * @param participant The participant record to map.
   * @param partnerAccountName The related Partner_Account__c's Name (queried separately - not on the base object).
   * @param currentPartnerAccountId The current user's own partner account Id, or null for an internal user.
   * @return The partner-safe summary DTO.
   */
  public static DealParticipantSummaryDTO toSummaryDTO(
    Deal_Participant__c participant,
    String partnerAccountName,
    Id currentPartnerAccountId
  ) {
    DealParticipantSummaryDTO dto = new DealParticipantSummaryDTO();
    dto.participantId = participant.Id;
    dto.dealId = participant.Deal__c;
    dto.organisationName = partnerAccountName;
    dto.participantType = participant.Participant_Type__c;
    dto.participantRole = participant.Participant_Role__c;
    dto.status = participant.Status__c;
    dto.accessLevel = participant.Access_Level__c;
    dto.invitedOn = participant.Invited_On__c;
    dto.respondBy = participant.Respond_By__c;
    dto.effectiveFrom = participant.Effective_From__c;
    dto.versionNumber = participant.Version_Number__c == null
      ? 0
      : Integer.valueOf(participant.Version_Number__c);

    Boolean isOwnRow =
      currentPartnerAccountId != null &&
      participant.Partner_Account__c == currentPartnerAccountId;
    dto.isOwnOrganisation = isOwnRow;
    dto.canAccept = isOwnRow && participant.Status__c == 'Invited';
    dto.canDecline = isOwnRow && participant.Status__c == 'Invited';

    return dto;
  }
}
