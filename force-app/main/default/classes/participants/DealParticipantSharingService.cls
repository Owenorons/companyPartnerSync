/**
 * The doc's PartnerManagedSharingService, scoped to co-sell participants:
 * reconciles a deal's desired Apex Managed Sharing state (one share per
 * Active, non-originating, non-Internal-Only participant's partner
 * account) against its existing Share_Reason__c='Co-Sell' registry rows,
 * via PartnerShareService's non-interactive grant/revoke entry points.
 * Never touches shares with any other reason, preserving customer-created
 * or admin-granted sharing untouched.
 */
public without sharing class DealParticipantSharingService {
  private static final String SHARE_REASON = 'Co-Sell';

  /**
   * Reconciles sharing for the deal a single participant belongs to.
   * Always recomputes from the deal's full active roster (not just this
   * one participant) so a revoke never removes access another active
   * participant from the same partner account still justifies.
   *
   * @param participantId Id of the participant whose deal should be reconciled.
   */
  public static void reconcileForParticipant(Id participantId) {
    List<Deal_Participant__c> rows = [
      SELECT Deal__c
      FROM Deal_Participant__c
      WHERE Id = :participantId
      WITH SYSTEM_MODE
    ];
    if (rows.isEmpty()) {
      return;
    }
    reconcileForDeal(rows[0].Deal__c);
  }

  /**
   * Reconciles a deal's Co-Sell-reason sharing against its current active
   * participant roster.
   *
   * @param dealId Id of the deal to reconcile.
   */
  public static void reconcileForDeal(Id dealId) {
    List<Deal_Registration__c> deals = [
      SELECT Id, Partner_Account__c
      FROM Deal_Registration__c
      WHERE Id = :dealId
      WITH SYSTEM_MODE
    ];
    if (deals.isEmpty()) {
      return;
    }
    Deal_Registration__c deal = deals[0];

    Map<Id, Partner_Record_Share__c> existingCoSellSharesByPartner = new Map<Id, Partner_Record_Share__c>();
    for (
      Partner_Record_Share__c share : PartnerShareSelector.selectActiveSharesForRecord(
        dealId
      )
    ) {
      if (share.Share_Reason__c == SHARE_REASON) {
        existingCoSellSharesByPartner.put(share.Partner_Account__c, share);
      }
    }

    Set<Id> desiredPartnerIds = new Set<Id>();
    for (
      Deal_Participant__c participant : DealParticipantSelector.selectActiveParticipantsForDeal(
        dealId
      )
    ) {
      if (
        participant.Status__c != 'Active' ||
        participant.Participant_Type__c == 'Originating Partner' ||
        participant.Partner_Account__c == null ||
        participant.Partner_Account__c == deal.Partner_Account__c
      ) {
        continue;
      }

      String targetAccessLevel = mapAccessLevel(participant.Access_Level__c);
      if (targetAccessLevel == null) {
        continue;
      }

      desiredPartnerIds.add(participant.Partner_Account__c);

      if (
        !existingCoSellSharesByPartner.containsKey(
          participant.Partner_Account__c
        )
      ) {
        PartnerShareDTO request = new PartnerShareDTO();
        request.targetRecordId = dealId;
        request.targetObject = 'Deal Registration';
        request.partnerAccountId = participant.Partner_Account__c;
        request.accessLevel = targetAccessLevel;
        request.shareReason = SHARE_REASON;
        PartnerShareService.grantParticipantAccess(request);
      }
    }

    for (Id partnerAccountId : existingCoSellSharesByPartner.keySet()) {
      if (!desiredPartnerIds.contains(partnerAccountId)) {
        PartnerShareService.revokeParticipantAccess(
          existingCoSellSharesByPartner.get(partnerAccountId).Id
        );
      }
    }
  }

  // Summary/Contributor -> Read, Collaborator/Commercial/Full Partner ->
  // Edit, Internal Only (or unresolved) -> no share at all.
  private static String mapAccessLevel(String participantAccessLevel) {
    if (
      participantAccessLevel == 'Collaborator' ||
      participantAccessLevel == 'Commercial' ||
      participantAccessLevel == 'Full Partner'
    ) {
      return 'Edit';
    }
    if (
      participantAccessLevel == 'Summary' ||
      participantAccessLevel == 'Contributor'
    ) {
      return 'Read';
    }
    return null;
  }
}
