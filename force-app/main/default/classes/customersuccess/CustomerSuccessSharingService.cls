/**
 * Reconciles Customer_Success_Engagement__c Apex-managed sharing against
 * the engagement's current partner roster (its Primary_Partner__c, plus
 * its Current_Renewal__c's Primary_Partner__c if a reassignment has moved
 * it to a different partner) - same "recompute the whole desired state
 * from scratch" shape as ImplementationParticipantSharingService, scoped
 * to Target_Object__c = 'Customer Success Engagement'. Removes only
 * PartnerSync-owned access (Share_Reason__c = 'Customer Success') when a
 * partner is no longer in the desired set - it never touches shares
 * created for a different reason on the same record.
 */
public without sharing class CustomerSuccessSharingService {
  private static final String SHARE_REASON = 'Customer Success';
  private static final String TARGET_OBJECT = 'Customer Success Engagement';
  private static final String ACCESS_LEVEL = 'Edit';

  /**
   * Reconciles a single engagement's sharing against its current desired
   * partner roster.
   *
   * @param engagementId Id of the engagement to reconcile.
   */
  public static void reconcileForEngagement(Id engagementId) {
    List<Customer_Success_Engagement__c> rows = [
      SELECT Primary_Partner__c, Current_Renewal__r.Primary_Partner__c
      FROM Customer_Success_Engagement__c
      WHERE Id = :engagementId
      WITH SYSTEM_MODE
    ];
    if (rows.isEmpty()) {
      return;
    }
    Customer_Success_Engagement__c engagement = rows[0];

    Set<Id> desiredPartnerIds = new Set<Id>();
    if (engagement.Primary_Partner__c != null) {
      desiredPartnerIds.add(engagement.Primary_Partner__c);
    }
    if (
      engagement.Current_Renewal__r != null &&
      engagement.Current_Renewal__r.Primary_Partner__c != null
    ) {
      desiredPartnerIds.add(engagement.Current_Renewal__r.Primary_Partner__c);
    }

    Map<Id, Partner_Record_Share__c> existingSharesByPartner = new Map<Id, Partner_Record_Share__c>();
    for (
      Partner_Record_Share__c share : PartnerShareSelector.selectActiveSharesForRecord(
        engagementId
      )
    ) {
      if (share.Share_Reason__c == SHARE_REASON) {
        existingSharesByPartner.put(share.Partner_Account__c, share);
      }
    }

    List<PartnerShareDTO> grantsNeeded = new List<PartnerShareDTO>();
    for (Id partnerId : desiredPartnerIds) {
      if (!existingSharesByPartner.containsKey(partnerId)) {
        PartnerShareDTO request = new PartnerShareDTO();
        request.targetRecordId = engagementId;
        request.targetObject = TARGET_OBJECT;
        request.partnerAccountId = partnerId;
        request.accessLevel = ACCESS_LEVEL;
        request.shareReason = SHARE_REASON;
        grantsNeeded.add(request);
      }
    }
    if (!grantsNeeded.isEmpty()) {
      PartnerShareService.grantParticipantAccessBulk(grantsNeeded);
    }

    List<Id> revokesNeeded = new List<Id>();
    for (Id partnerId : existingSharesByPartner.keySet()) {
      if (!desiredPartnerIds.contains(partnerId)) {
        revokesNeeded.add(existingSharesByPartner.get(partnerId).Id);
      }
    }
    if (!revokesNeeded.isEmpty()) {
      PartnerShareService.revokeParticipantAccessBulk(revokesNeeded);
    }
  }
}
