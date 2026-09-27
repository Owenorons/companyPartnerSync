/**
 * Computes and persists Deal_Implementation__c.Health__c from
 * Implementation_Health_Policy__mdt thresholds: open issues
 * (severity-weighted) and overdue blocking milestones. Same recompute/
 * no-op-when-unchanged shape as every other projection service this
 * session. recompute() is for single-implementation call sites
 * (ImplementationIssueCommandService.raise()/resolve()); computeHealth()
 * is the pure, bulk-safe core ImplementationHealthBatch calls directly
 * with pre-aggregated counts, avoiding a query per implementation.
 */
public without sharing class ImplementationHealthService {
  @TestVisible
  private static Implementation_Health_Policy__mdt testPolicy;

  /**
   * Recomputes and, if changed, persists a single implementation's
   * Health__c. Not for bulk/batch use - issues a handful of queries per
   * call; ImplementationHealthBatch computes health for many
   * implementations in bulk instead.
   *
   * @param implementationId Id of the implementation to recompute.
   */
  public static void recompute(Id implementationId) {
    List<Deal_Implementation__c> implementations = [
      SELECT Id, Deal__c, Health__c, Status__c
      FROM Deal_Implementation__c
      WHERE Id = :implementationId
      WITH SYSTEM_MODE
    ];
    if (implementations.isEmpty()) {
      return;
    }
    Deal_Implementation__c implementation = implementations[0];

    Integer criticalCount = 0;
    Integer highCount = 0;
    for (
      Implementation_Issue__c issue : ImplementationIssueSelector.selectOpenForImplementation(
        implementation.Id
      )
    ) {
      if (issue.Severity__c == 'Critical') {
        criticalCount++;
      } else if (issue.Severity__c == 'High') {
        highCount++;
      }
    }

    String newHealth = computeHealth(
      resolvePolicy(),
      criticalCount,
      highCount,
      maxOverdueBlockingMilestoneDays(implementation.Id)
    );
    if (implementation.Health__c == newHealth) {
      return;
    }

    Database.update(
      new Deal_Implementation__c(Id = implementationId, Health__c = newHealth),
      AccessLevel.SYSTEM_MODE
    );

    ImplementationStatusProjectionService.recompute(implementation.Deal__c);
  }

  /**
   * Pure computation of an implementation's health from pre-aggregated
   * counts - no SOQL, so bulk callers (ImplementationHealthBatch) can
   * aggregate once across many implementations and call this per row
   * with no additional query cost.
   *
   * @param policy The resolved health policy.
   * @param criticalCount Count of open Critical-severity issues.
   * @param highCount Count of open High-severity issues.
   * @param maxOverdueBlockingMilestoneDays The largest overdue-day count across the implementation's open blocking milestones, or 0 if none.
   * @return The computed Health__c value.
   */
  public static String computeHealth(
    Implementation_Health_Policy__mdt policy,
    Integer criticalCount,
    Integer highCount,
    Integer maxOverdueBlockingMilestoneDays
  ) {
    if (policy.Critical_Issue_Triggers_Red__c == true && criticalCount > 0) {
      return 'Blocked';
    }

    Integer redDays = policy.Overdue_Red_Days__c == null
      ? 15
      : Integer.valueOf(policy.Overdue_Red_Days__c);
    Integer amberDays = policy.Overdue_Amber_Days__c == null
      ? 5
      : Integer.valueOf(policy.Overdue_Amber_Days__c);
    Integer highThreshold = policy.High_Issue_Amber_Threshold__c == null
      ? 2
      : Integer.valueOf(policy.High_Issue_Amber_Threshold__c);

    if (maxOverdueBlockingMilestoneDays >= redDays) {
      return 'Overdue';
    }
    if (
      maxOverdueBlockingMilestoneDays >= amberDays ||
      highCount >= highThreshold
    ) {
      return 'At Risk';
    }
    return 'Healthy';
  }

  private static Integer maxOverdueBlockingMilestoneDays(Id implementationId) {
    Integer maxDays = 0;
    Date today = System.today();
    for (Implementation_Milestone__c milestone : [
      SELECT Due_On__c
      FROM Implementation_Milestone__c
      WHERE
        Implementation__c = :implementationId
        AND Blocking__c = TRUE
        AND Status__c NOT IN ('Completed', 'Waived')
        AND Due_On__c != NULL
        AND Due_On__c < :today
      WITH SYSTEM_MODE
    ]) {
      Integer overdueDays = milestone.Due_On__c.daysBetween(today);
      if (overdueDays > maxDays) {
        maxDays = overdueDays;
      }
    }
    return maxDays;
  }

  /**
   * Resolves the active health policy - public so
   * ImplementationHealthBatch can resolve it once and reuse it across
   * every implementation in a chunk.
   *
   * @return The active Implementation_Health_Policy__mdt row.
   */
  public static Implementation_Health_Policy__mdt resolvePolicy() {
    if (Test.isRunningTest() && testPolicy != null) {
      return testPolicy;
    }
    List<Implementation_Health_Policy__mdt> rows = [
      SELECT
        Overdue_Amber_Days__c,
        Overdue_Red_Days__c,
        Critical_Issue_Triggers_Red__c,
        High_Issue_Amber_Threshold__c
      FROM Implementation_Health_Policy__mdt
      WHERE Active__c = TRUE
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    return rows.isEmpty() ? new Implementation_Health_Policy__mdt() : rows[0];
  }
}
