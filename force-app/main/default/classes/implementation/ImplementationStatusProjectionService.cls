/**
 * Maintains Deal_Registration__c.Implementation_Status__c as a projection
 * of the deal's Deal_Implementation__c rows (Sprint 40 §40.35 precedence:
 * any critical-health active implementation -> At Risk; any In Progress ->
 * In Progress; all required completed -> Completed; only planned ->
 * Planned; no implementation -> Not Required). Same recompute/no-op-when-
 * unchanged shape as DealCoSellStatusProjectionService.
 */
public without sharing class ImplementationStatusProjectionService {
  private static final Set<String> ACTIVE_STATUSES = new Set<String>{
    'Planned',
    'Handoff Pending',
    'Handoff Accepted',
    'Not Started',
    'In Progress',
    'On Hold',
    'At Risk',
    'Blocked',
    'Pending Customer Acceptance',
    'Customer Accepted',
    'Validation'
  };

  /**
   * Recomputes and, if changed, persists a deal's Implementation_Status__c
   * from its current implementation roster.
   *
   * @param dealId Id of the deal to recompute.
   */
  public static void recompute(Id dealId) {
    List<Deal_Registration__c> deals = [
      SELECT Id, Implementation_Status__c
      FROM Deal_Registration__c
      WHERE Id = :dealId
      WITH SYSTEM_MODE
    ];
    if (deals.isEmpty()) {
      return;
    }

    List<Deal_Implementation__c> implementations = [
      SELECT Status__c, Health__c
      FROM Deal_Implementation__c
      WHERE Deal__c = :dealId
      WITH SYSTEM_MODE
    ];

    String newStatus = computeStatus(implementations);

    if (deals[0].Implementation_Status__c == newStatus) {
      return;
    }

    Database.update(
      new Deal_Registration__c(
        Id = dealId,
        Implementation_Status__c = newStatus
      ),
      AccessLevel.SYSTEM_MODE
    );
  }

  private static String computeStatus(
    List<Deal_Implementation__c> implementations
  ) {
    if (implementations.isEmpty()) {
      return 'Not Required';
    }

    Boolean hasActiveAtRiskOrBlocked = false;
    Boolean hasInProgress = false;
    Boolean allCompletedOrTerminal = true;
    Boolean anyPlanned = false;

    for (Deal_Implementation__c implementation : implementations) {
      Boolean isActive = ACTIVE_STATUSES.contains(implementation.Status__c);

      if (
        isActive &&
        (implementation.Health__c == 'Blocked' ||
        implementation.Health__c == 'At Risk' ||
        implementation.Health__c == 'Overdue')
      ) {
        hasActiveAtRiskOrBlocked = true;
      }
      if (implementation.Status__c == 'In Progress') {
        hasInProgress = true;
      }
      if (implementation.Status__c == 'Planned') {
        anyPlanned = true;
      }
      if (
        implementation.Status__c != 'Completed' &&
        implementation.Status__c != 'Cancelled' &&
        implementation.Status__c != 'Failed' &&
        implementation.Status__c != 'Superseded'
      ) {
        allCompletedOrTerminal = false;
      }
    }

    if (hasActiveAtRiskOrBlocked) {
      return 'At Risk';
    }
    if (hasInProgress) {
      return 'In Progress';
    }
    if (allCompletedOrTerminal) {
      return 'Completed';
    }
    if (anyPlanned) {
      return 'Planned';
    }
    return 'In Progress';
  }
}
