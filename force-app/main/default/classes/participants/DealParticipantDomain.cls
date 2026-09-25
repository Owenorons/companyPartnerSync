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
}
