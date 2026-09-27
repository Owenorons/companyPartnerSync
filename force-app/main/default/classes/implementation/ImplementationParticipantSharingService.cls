/**
 * Reconciles Deal_Implementation__c Apex-managed sharing against a single
 * implementation's active Implementation_Participant__c roster - one
 * share per active participant's partner account, via PartnerShareService's
 * non-interactive grant/revoke entry points. Same "recompute the whole
 * desired state from scratch" shape as DealParticipantSharingService, scoped
 * to a Deal_Implementation__c (Target_Object__c = 'Deal Implementation')
 * instead of a Deal_Registration__c.
 */
public without sharing class ImplementationParticipantSharingService {
  private static final String SHARE_REASON = 'Implementation';
  private static final String TARGET_OBJECT = 'Deal Implementation';
  private static final String ACCESS_LEVEL = 'Edit';

  /**
   * Reconciles a single implementation's sharing against its current
   * active participant roster.
   *
   * @param implementationId Id of the implementation to reconcile.
   */
  public static void reconcileForImplementation(Id implementationId) {
    Map<Id, Partner_Record_Share__c> existingSharesByPartner = new Map<Id, Partner_Record_Share__c>();
    for (
      Partner_Record_Share__c share : PartnerShareSelector.selectActiveSharesForRecord(
        implementationId
      )
    ) {
      if (share.Share_Reason__c == SHARE_REASON) {
        existingSharesByPartner.put(share.Partner_Account__c, share);
      }
    }

    Set<Id> desiredPartnerIds = new Set<Id>();
    List<PartnerShareDTO> grantsNeeded = new List<PartnerShareDTO>();
    for (
      Implementation_Participant__c participant : ImplementationParticipantSelector.selectActiveForImplementation(
        implementationId
      )
    ) {
      Id partnerAccountId = participant.Deal_Participant__r.Partner_Account__c;
      if (partnerAccountId == null) {
        continue;
      }
      desiredPartnerIds.add(partnerAccountId);

      if (!existingSharesByPartner.containsKey(partnerAccountId)) {
        PartnerShareDTO request = new PartnerShareDTO();
        request.targetRecordId = implementationId;
        request.targetObject = TARGET_OBJECT;
        request.partnerAccountId = partnerAccountId;
        request.accessLevel = ACCESS_LEVEL;
        request.shareReason = SHARE_REASON;
        grantsNeeded.add(request);
      }
    }

    if (!grantsNeeded.isEmpty()) {
      PartnerShareService.grantParticipantAccessBulk(grantsNeeded);
    }

    List<Id> revokesNeeded = new List<Id>();
    for (Id partnerAccountId : existingSharesByPartner.keySet()) {
      if (!desiredPartnerIds.contains(partnerAccountId)) {
        revokesNeeded.add(existingSharesByPartner.get(partnerAccountId).Id);
      }
    }
    if (!revokesNeeded.isEmpty()) {
      PartnerShareService.revokeParticipantAccessBulk(revokesNeeded);
    }
  }
}
