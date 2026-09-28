/**
 * Resolves Revenue_Reconciliation__c rows - links the associated
 * Deal_Revenue__c to the chosen candidate Deal rather than leaving it
 * permanently unmatched (doc Sprint 41 §41.16).
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class RevenueReconciliationCommandService {
  /**
   * Resolves an open reconciliation by linking its revenue record to the
   * chosen candidate deal.
   *
   * @param command reconciliationId + candidateDealId + resolution + resolutionReason.
   */
  public static void resolve(RevenueReconciliationCommand command) {
    PartnerAccessService.assertInternalUser();
    if (
      !DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Manage_Revenue_Reconciliation'
      )
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to resolve revenue reconciliations.'
      );
    }
    if (command.reconciliationId == null || command.candidateDealId == null) {
      throw new PartnerSyncHandledException(
        'A reconciliation and a candidate deal are required.'
      );
    }

    Revenue_Reconciliation__c reconciliation = RevenueReconciliationSelector.selectForUpdate(
      command.reconciliationId
    );
    if (
      reconciliation.Status__c != 'Open' &&
      reconciliation.Status__c != 'Manual Review Required'
    ) {
      throw new PartnerSyncHandledException(
        'This reconciliation has already been resolved.'
      );
    }

    Deal_Revenue__c revenue = RevenueSelector.selectForUpdate(
      reconciliation.Revenue__c
    );
    revenue.Deal__c = command.candidateDealId;
    revenue.Status__c = 'Validated';
    revenue.Version_Number__c = revenue.Version_Number__c == null
      ? 1
      : Integer.valueOf(revenue.Version_Number__c) + 1;
    Database.update(revenue, AccessLevel.SYSTEM_MODE);

    reconciliation.Candidate_Deal__c = command.candidateDealId;
    reconciliation.Status__c = 'Resolved';
    reconciliation.Resolution__c = String.isBlank(command.resolution)
      ? 'Matched'
      : command.resolution;
    reconciliation.Resolution_Reason__c = command.resolutionReason;
    reconciliation.Resolved_By__c = UserInfo.getUserId();
    reconciliation.Resolved_On__c = System.now();
    Database.update(reconciliation, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'DealRevenueMatched',
      command.candidateDealId,
      'Deal_Registration__c',
      null,
      'Unmatched revenue was manually reconciled to a deal.',
      'Info'
    );
  }
}
