public without sharing class DealConflictApprovalGuard {
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
