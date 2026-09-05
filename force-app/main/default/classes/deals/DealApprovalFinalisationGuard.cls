public without sharing class DealApprovalFinalisationGuard {
  @SuppressWarnings('PMD.ApexCRUDViolation')
  public static Deal_Approval_Plan__c assertReady(
    Id dealId,
    Integer dealVersion
  ) {
    List<Deal_Approval_Plan__c> plans = [
      SELECT Id, Status__c, Deal_Version__c
      FROM Deal_Approval_Plan__c
      WHERE Deal__c = :dealId AND Current__c = TRUE
      LIMIT 2
    ];
    if (plans.size() != 1)
      throw new DealLifecycleException(
        'Exactly one current approval plan is required.'
      );
    Deal_Approval_Plan__c plan = plans[0];
    if (
      !new Set<String>{ 'Approved', 'Approved with Conditions' }
        .contains(plan.Status__c)
    )
      throw new DealLifecycleException(
        'The current approval plan is not final.'
      );
    if (plan.Deal_Version__c != dealVersion)
      throw new DealLifecycleException(
        'The approval plan was generated for a different deal version.'
      );
    List<Deal_Approval__c> decisions = [
      SELECT Status__c, Authority_Snapshot__c
      FROM Deal_Approval__c
      WHERE Plan__c = :plan.Id
    ];
    if (decisions.isEmpty())
      throw new DealLifecycleException('The approval plan has no decisions.');
    for (Deal_Approval__c decision : decisions) {
      if (
        decision.Status__c != 'Completed' ||
        String.isBlank(decision.Authority_Snapshot__c)
      )
        throw new DealLifecycleException(
          'Every approval decision requires a valid authority snapshot.'
        );
    }
    Integer incompleteReviews = [
      SELECT COUNT()
      FROM Deal_Review__c
      WHERE
        Deal__c = :dealId
        AND Plan__r.Current__c = TRUE
        AND Blocking__c = TRUE
        AND Status__c NOT IN ('Completed', 'Waived')
    ];
    if (incompleteReviews > 0)
      throw new DealLifecycleException(
        'Blocking reviews must complete before final approval.'
      );
    Integer openRequests = [
      SELECT COUNT()
      FROM Deal_Information_Request__c
      WHERE
        Deal__c = :dealId
        AND Review__r.Blocking__c = TRUE
        AND Status__c NOT IN ('Accepted', 'Closed', 'Cancelled')
    ];
    if (openRequests > 0)
      throw new DealLifecycleException(
        'Blocking information requests remain open.'
      );
    return plan;
  }
}
