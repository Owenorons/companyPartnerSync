/**
 * Maintains Deal_Registration__c.CoSell_Status__c as a projection of the
 * deal's non-originating Deal_Participant__c roster - not directly
 * user-editable, only DealParticipantCommandService's calls after a
 * state-changing command should write it. Trimmed to the 3 reachable
 * values (Not Applicable/Inviting/Active); Completed/Cancelled need a
 * deal-closure hook Sprint 39 doesn't exist yet to provide.
 */
public without sharing class DealCoSellStatusProjectionService {
  /**
   * Recomputes and persists the deal's CoSell_Status__c from its current
   * participant roster, publishing CoSellActivated the first time it
   * transitions to Active. A no-op (no DML, no event) if the computed
   * status matches what's already stored.
   *
   * @param dealId Id of the deal to recompute.
   */
  public static void recompute(Id dealId) {
    List<Deal_Registration__c> deals = [
      SELECT Id, CoSell_Status__c, Partner_Account__c, Attribution_Type__c
      FROM Deal_Registration__c
      WHERE Id = :dealId
      WITH SYSTEM_MODE
    ];
    if (deals.isEmpty()) {
      return;
    }
    Deal_Registration__c deal = deals[0];

    Boolean hasActiveParticipant = false;
    Boolean hasInvitingParticipant = false;
    Boolean hasActiveReferralParticipant = false;
    for (Deal_Participant__c participant : [
      SELECT Status__c, Participant_Type__c
      FROM Deal_Participant__c
      WHERE
        Deal__c = :dealId
        AND Participant_Type__c != 'Originating Partner'
        AND Status__c IN ('Invited', 'Accepted', 'Active')
      WITH SYSTEM_MODE
    ]) {
      if (participant.Status__c == 'Active') {
        hasActiveParticipant = true;
        if (participant.Participant_Type__c == 'Referral Partner') {
          hasActiveReferralParticipant = true;
        }
      } else {
        hasInvitingParticipant = true;
      }
    }

    String newStatus = hasActiveParticipant
      ? 'Active'
      : (hasInvitingParticipant ? 'Inviting' : 'Not Applicable');

    Boolean statusChanged = deal.CoSell_Status__c != newStatus;
    // Reclassifies Attribution_Type__c to Referral once an active Referral
    // Partner participant exists (Sprint 39 channel/influence analytics) -
    // never reclassifies away from Referral even if that participant later
    // leaves, since the deal genuinely was referral-driven at some point.
    Boolean attributionChanged =
      hasActiveReferralParticipant &&
      deal.Attribution_Type__c != DealAttributionEngine.REFERRAL;

    if (!statusChanged && !attributionChanged) {
      return;
    }

    Boolean wasActive = deal.CoSell_Status__c == 'Active';
    deal.CoSell_Status__c = newStatus;
    if (attributionChanged) {
      deal.Attribution_Type__c = DealAttributionEngine.REFERRAL;
    }
    Database.update(deal, AccessLevel.SYSTEM_MODE);

    if (newStatus == 'Active' && !wasActive) {
      // Notifies the originating partner (the one well-defined single
      // recipient for a deal-level event) - not the full multi-recipient
      // fan-out (originating partner + every co-sell partner + internal
      // owner) the doc envisions, which needs shared notification
      // infrastructure this codebase doesn't have yet. See
      // docs/deal-participant-management-review.md, Known Adaptation #6.
      PlatformEventPublisherService.publish(
        'CoSellActivated',
        dealId,
        'Deal_Registration__c',
        deal.Partner_Account__c,
        'Co-sell participation became active on this deal.',
        'Info'
      );
    }
  }
}
