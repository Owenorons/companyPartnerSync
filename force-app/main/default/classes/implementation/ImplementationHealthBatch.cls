/**
 * Scheduled/batch job that re-evaluates Health__c daily for every
 * non-terminal implementation, catching overdue-blocking-milestone drift
 * that wouldn't otherwise trigger a recompute (raise/resolve on an issue
 * already does).
 *
 * Bulk-safety: aggregates open issues and overdue blocking milestones
 * across the whole chunk in two queries total (not one per
 * implementation), resolves the health policy once, computes each row's
 * health with ImplementationHealthService.computeHealth()'s pure
 * (no-SOQL) core, and flushes all changed Health__c values in one bulk
 * DML call - the same accumulate-then-flush-once pattern
 * DealOpportunityReconciliationBatch uses. Implementation_Status__c
 * re-projection for deals whose health actually changed is per-row
 * (accepted risk, bounded to rows that changed - not every row in the
 * chunk), matching that batch's own documented pattern for its
 * closed-lost/material-change paths.
 */
public with sharing class ImplementationHealthBatch implements Database.Batchable<SObject>, Schedulable {
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
   * Builds the query locator for every non-terminal implementation.
   *
   * @param context Batch execution context (unused).
   * @return A query locator over active implementations.
   */
  public Database.QueryLocator start(Database.BatchableContext context) {
    Set<String> activeStatuses = ACTIVE_STATUSES;
    return Database.getQueryLocator(
      [
        SELECT Id, Deal__c, Health__c
        FROM Deal_Implementation__c
        WHERE Status__c IN :activeStatuses
      ]
    );
  }

  /**
   * Recomputes health for every implementation in scope in bulk.
   *
   * @param context Batch execution context (unused).
   * @param scope Batch of active implementations to re-evaluate.
   */
  public void execute(
    Database.BatchableContext context,
    List<Deal_Implementation__c> scope
  ) {
    Set<Id> implementationIds = new Set<Id>();
    for (Deal_Implementation__c implementation : scope) {
      implementationIds.add(implementation.Id);
    }

    Map<Id, Integer> criticalCountByImplementation = new Map<Id, Integer>();
    Map<Id, Integer> highCountByImplementation = new Map<Id, Integer>();
    for (AggregateResult row : [
      SELECT Implementation__c impId, Severity__c severity, COUNT(Id) issueCount
      FROM Implementation_Issue__c
      WHERE
        Implementation__c IN :implementationIds
        AND Status__c NOT IN ('Resolved', 'Accepted Risk', 'Closed')
      WITH SYSTEM_MODE
      GROUP BY Implementation__c, Severity__c
    ]) {
      Id implementationId = (Id) row.get('impId');
      Integer count = (Integer) row.get('issueCount');
      if (row.get('severity') == 'Critical') {
        criticalCountByImplementation.put(implementationId, count);
      } else if (row.get('severity') == 'High') {
        highCountByImplementation.put(implementationId, count);
      }
    }

    Map<Id, Integer> maxOverdueDaysByImplementation = new Map<Id, Integer>();
    Date today = System.today();
    for (Implementation_Milestone__c milestone : [
      SELECT Implementation__c, Due_On__c
      FROM Implementation_Milestone__c
      WHERE
        Implementation__c IN :implementationIds
        AND Blocking__c = TRUE
        AND Status__c NOT IN ('Completed', 'Waived')
        AND Due_On__c != NULL
        AND Due_On__c < :today
      WITH SYSTEM_MODE
    ]) {
      Integer overdueDays = milestone.Due_On__c.daysBetween(today);
      Integer current = maxOverdueDaysByImplementation.containsKey(
          milestone.Implementation__c
        )
        ? maxOverdueDaysByImplementation.get(milestone.Implementation__c)
        : 0;
      if (overdueDays > current) {
        maxOverdueDaysByImplementation.put(
          milestone.Implementation__c,
          overdueDays
        );
      }
    }

    Implementation_Health_Policy__mdt policy = ImplementationHealthService.resolvePolicy();
    List<Deal_Implementation__c> changedImplementations = new List<Deal_Implementation__c>();
    Set<Id> changedDealIds = new Set<Id>();

    for (Deal_Implementation__c implementation : scope) {
      String newHealth = ImplementationHealthService.computeHealth(
        policy,
        criticalCountByImplementation.containsKey(implementation.Id)
          ? criticalCountByImplementation.get(implementation.Id)
          : 0,
        highCountByImplementation.containsKey(implementation.Id)
          ? highCountByImplementation.get(implementation.Id)
          : 0,
        maxOverdueDaysByImplementation.containsKey(implementation.Id)
          ? maxOverdueDaysByImplementation.get(implementation.Id)
          : 0
      );
      if (implementation.Health__c != newHealth) {
        changedImplementations.add(
          new Deal_Implementation__c(
            Id = implementation.Id,
            Health__c = newHealth
          )
        );
        changedDealIds.add(implementation.Deal__c);
      }
    }

    if (!changedImplementations.isEmpty()) {
      Database.update(changedImplementations, AccessLevel.SYSTEM_MODE);
    }
    for (Id dealId : changedDealIds) {
      try {
        ImplementationStatusProjectionService.recompute(dealId);
      } catch (Exception ex) {
        LoggingService.error(
          'ImplementationHealthBatch',
          'Failed to re-project Implementation_Status__c for deal ' + dealId,
          ex
        );
      }
    }
  }

  /**
   * No post-processing is required after this batch runs.
   *
   * @param context Batch execution context (unused).
   */
  public void finish(Database.BatchableContext context) {
  }

  /**
   * Scheduled entry point: launches this class as a batch job with a chunk size of 200.
   *
   * @param context Scheduled execution context (unused).
   */
  public void execute(SchedulableContext context) {
    Database.executeBatch(new ImplementationHealthBatch(), 200);
  }
}
