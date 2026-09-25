/**
 * Guard that verifies a target record's current approval plan is ready for final approval,
 * before a caller is allowed to finalise it. Object-agnostic: only checks the approval plan/step
 * mechanics themselves. Object-specific finalisation preconditions (e.g. Deal's blocking
 * Deal_Review__c/Deal_Information_Request__c checks) are the caller's responsibility, asserted
 * alongside this guard rather than inside it.
 */
public without sharing class ApprovalFinalisationGuard {
  /**
   * Asserts that the target record's current approval plan is final, matches the expected
   * version, and has fully completed decisions with authority snapshots. Throws an
   * ApprovalPlanNotReadyException when any precondition fails.
   *
   * @param objectName API name of the target object.
   * @param targetRecordId Id of the target record whose approval plan is being finalised.
   * @param targetVersion Expected version of the target record the approval plan was generated for.
   * @return The current, ready-for-finalisation approval plan.
   */
  @SuppressWarnings('PMD.ApexCRUDViolation')
  public static Approval_Plan__c assertReady(
    String objectName,
    Id targetRecordId,
    Integer targetVersion
  ) {
    List<Approval_Plan__c> plans = [
      SELECT Id, Status__c, Target_Version__c
      FROM Approval_Plan__c
      WHERE
        Object_Name__c = :objectName
        AND Target_Record_Id__c = :targetRecordId
        AND Current__c = TRUE
      LIMIT 2
    ];
    if (plans.size() != 1)
      throw new ApprovalPlanNotReadyException(
        'Exactly one current approval plan is required.'
      );
    Approval_Plan__c plan = plans[0];
    if (
      !new Set<String>{ 'Approved', 'Approved with Conditions' }
        .contains(plan.Status__c)
    )
      throw new ApprovalPlanNotReadyException(
        'The current approval plan is not final.'
      );
    if (plan.Target_Version__c != targetVersion)
      throw new ApprovalPlanNotReadyException(
        'The approval plan was generated for a different record version.'
      );
    List<Approval__c> decisions = [
      SELECT Status__c, Authority_Snapshot__c
      FROM Approval__c
      WHERE Plan__c = :plan.Id
    ];
    if (decisions.isEmpty())
      throw new ApprovalPlanNotReadyException(
        'The approval plan has no decisions.'
      );
    for (Approval__c decision : decisions) {
      if (
        decision.Status__c != 'Completed' ||
        String.isBlank(decision.Authority_Snapshot__c)
      )
        throw new ApprovalPlanNotReadyException(
          'Every approval decision requires a valid authority snapshot.'
        );
    }
    return plan;
  }
  /**
   * Thrown when a target record's approval plan isn't ready for finalisation, e.g. missing,
   * not final, version-mismatched, or missing a decision's authority snapshot.
   */
  public class ApprovalPlanNotReadyException extends Exception {
  }
}
