/**
 * Selector layer for the "my pending approval steps" workspace. Deliberately
 * not scoped to a single object type or reviewer role: authority is
 * data-driven (an exact Assigned_To__c match, or holding the step's
 * Approver_Permission_Set__c), not FLS-driven, matching
 * ApprovalCommandService.assertAuthority() and the rest of the Approval__c
 * family (ApprovalPlanService, ApprovalFinalisationGuard), which are all
 * SYSTEM_MODE/no-sharing.
 */
public without sharing class ApprovalSelector {
  /**
   * Queries the running user's pending approval steps across every approval-routed object:
   * those directly assigned to them, plus those routed to any permission set they hold.
   *
   * @return Up to 200 pending Approval__c records the running user can decide.
   */
  public static List<Approval__c> selectMyPendingSteps() {
    Id currentUserId = UserInfo.getUserId();
    Set<String> myPermissionSetNames = PermissionService.getPermissionSetNames();

    return [
      SELECT
        Id,
        CreatedDate,
        Object_Name__c,
        Target_Record_Id__c,
        Target_Label__c,
        Target_Amount__c,
        Step_Key__c,
        Sequence__c,
        Status__c,
        Authority_Limit__c,
        Assigned_To__c,
        Approver_Permission_Set__c,
        Version_Number__c
      FROM Approval__c
      WHERE
        Status__c = 'Pending'
        AND (Assigned_To__c = :currentUserId
        OR Approver_Permission_Set__c IN :myPermissionSetNames)
      WITH SYSTEM_MODE
      ORDER BY CreatedDate ASC
      LIMIT 200
    ];
  }

  /**
   * Queries a single approval step, with the fields needed for the step detail screen.
   *
   * @param approvalId Id of the approval step to load.
   * @return The Approval__c record.
   */
  public static Approval__c selectStepDetail(Id approvalId) {
    List<Approval__c> rows = [
      SELECT
        Id,
        CreatedDate,
        Object_Name__c,
        Target_Record_Id__c,
        Target_Label__c,
        Target_Amount__c,
        Step_Key__c,
        Sequence__c,
        Status__c,
        Authority_Limit__c,
        Assigned_To__c,
        Approver_Permission_Set__c,
        Decision__c,
        Decision_Reason__c,
        Decision_On__c,
        Version_Number__c
      FROM Approval__c
      WHERE Id = :approvalId
      WITH SYSTEM_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Approval step not found.');
    }

    return rows[0];
  }
}
