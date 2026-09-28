/**
 * Executes Partner_Revenue_Dispute__c commands: open (partner-facing),
 * resolve (internal). Deliberately does not itself mutate the referenced
 * revenue/attribution/incentive record (doc §41.43) - resolving a dispute
 * only records the outcome; any actual correction goes through the normal
 * RevenueCommandService.adjustRevenue()/RevenueAttributionCommandService.
 * overrideAttribution() commands as a separate, audited step.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class RevenueDisputeCommandService {
  /**
   * Opens a new revenue dispute.
   *
   * @param command partnerAccountId + disputeType + description (+ optional deal/revenue/attribution/incentive references).
   * @return The inserted dispute record.
   */
  public static Partner_Revenue_Dispute__c open(RevenueDisputeCommand command) {
    if (
      !PartnerAccessService.isInternalUser() &&
      !DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Submit_Revenue_Dispute'
      )
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to submit a revenue dispute.'
      );
    }
    if (
      command.partnerAccountId == null || String.isBlank(command.description)
    ) {
      throw new PartnerSyncHandledException(
        'A partner account and a description are required to open a dispute.'
      );
    }
    if (
      !PartnerAccessService.isInternalUser() &&
      command.partnerAccountId !=
      PartnerAccessService.getCurrentPartnerAccountId()
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to open a dispute for this partner account.'
      );
    }

    Partner_Revenue_Dispute__c dispute = new Partner_Revenue_Dispute__c(
      Partner_Account__c = command.partnerAccountId,
      Deal__c = command.dealId,
      Revenue__c = command.revenueId,
      Revenue_Attribution__c = command.revenueAttributionId,
      Incentive__c = command.incentiveId,
      Dispute_Type__c = String.isBlank(command.disputeType)
        ? 'Other'
        : command.disputeType,
      Status__c = 'Open',
      Description__c = command.description,
      Requested_Adjustment__c = command.requestedAdjustment,
      Submitted_On__c = System.now()
    );
    Database.insert(dispute, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'PartnerRevenueDisputeOpened',
      command.dealId,
      'Deal_Registration__c',
      command.partnerAccountId,
      'A partner revenue dispute was opened.',
      'Warning'
    );

    return dispute;
  }

  /**
   * Resolves an open dispute, recording the outcome only - never mutates
   * the referenced revenue/attribution/incentive record itself.
   *
   * @param command disputeId + resolution.
   */
  public static void resolve(RevenueDisputeCommand command) {
    PartnerAccessService.assertInternalUser();
    if (
      !DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Manage_Revenue_Reconciliation'
      )
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to resolve revenue disputes.'
      );
    }
    if (command.disputeId == null) {
      throw new PartnerSyncHandledException(
        'A dispute is required for this command.'
      );
    }

    Partner_Revenue_Dispute__c dispute = RevenueDisputeSelector.selectForUpdate(
      command.disputeId
    );
    if (dispute.Status__c != 'Open' && dispute.Status__c != 'Under Review') {
      throw new PartnerSyncHandledException(
        'This dispute has already been resolved.'
      );
    }

    dispute.Status__c = 'Resolved';
    dispute.Resolution__c = command.resolution;
    dispute.Resolved_By__c = UserInfo.getUserId();
    dispute.Resolved_On__c = System.now();
    Database.update(dispute, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'PartnerRevenueDisputeResolved',
      dispute.Deal__c,
      'Deal_Registration__c',
      dispute.Partner_Account__c,
      'A partner revenue dispute was resolved.',
      'Info'
    );
  }
}
