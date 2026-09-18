/**
 * Guard that prevents a deal from being approved while it has current,
 * unresolved blocking conflict findings.
 */
public without sharing class DealConflictApprovalGuard {
  /**
   * Throws a DealLifecycleException if the deal has any current, blocking
   * conflict finding that has not been resolved, waived, marked a false
   * positive, or superseded.
   *
   * @param dealId Id of the deal to check for blocking conflicts.
   */
  @SuppressWarnings('PMD.ApexCRUDViolation')
  public static void assertNoBlockingConflicts(Id dealId) {
    Integer blocking = [
      SELECT COUNT()
      FROM Deal_Conflict__c
      WHERE
        Deal__c = :dealId
        AND Current__c = TRUE
        AND Blocking__c = TRUE
        AND Status__c NOT IN (
          'Resolved',
          'Waived',
          'False Positive',
          'Superseded'
        )
    ];
    if (blocking > 0) {
      throw new DealLifecycleException(
        'This deal has current blocking conflict findings and cannot be approved.'
      );
    }
  }
}
