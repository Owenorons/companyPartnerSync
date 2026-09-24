/**
 * Selector layer for the "my pending approval steps" workspace. Deliberately
 * not scoped to a single reviewer role: authority is data-driven (an exact
 * Assigned_To__c match, or holding the step's Approver_Permission_Set__c),
 * not FLS-driven, matching DealApprovalCommandService.assertAuthority() and
 * the rest of the Deal_Approval__c family (DealApprovalPlanService,
 * DealApprovalFinalisationGuard), which are all SYSTEM_MODE/no-sharing.
 */
public without sharing class DealApprovalSelector {
  /**
   * Queries the running user's pending approval steps: those directly assigned to them, plus
   * those routed to any permission set they hold.
   *
   * @return Up to 200 pending Deal_Approval__c records the running user can decide.
   */
  public static List<Deal_Approval__c> selectMyPendingSteps() {
    Id currentUserId = UserInfo.getUserId();
    Set<String> myPermissionSetNames = PermissionService.getPermissionSetNames();

    return [
      SELECT
        Id,
        Deal__c,
        Deal__r.Name,
        Deal__r.Customer_Account__r.Name,
        Deal__r.Estimated_Revenue__c,
        Deal__r.Submitted_On__c,
        Step_Key__c,
        Sequence__c,
        Status__c,
        Authority_Limit__c,
        Assigned_To__c,
        Approver_Permission_Set__c,
        Version_Number__c
      FROM Deal_Approval__c
      WHERE
        Status__c = 'Pending'
        AND (Assigned_To__c = :currentUserId
        OR Approver_Permission_Set__c IN :myPermissionSetNames)
      WITH SYSTEM_MODE
      ORDER BY Deal__r.Submitted_On__c ASC NULLS LAST, CreatedDate ASC
      LIMIT 200
    ];
  }

  /**
   * Queries a single approval step, with the fields needed for the step detail screen.
   *
   * @param approvalId Id of the approval step to load.
   * @return The Deal_Approval__c record.
   */
  public static Deal_Approval__c selectStepDetail(Id approvalId) {
    List<Deal_Approval__c> rows = [
      SELECT
        Id,
        Deal__c,
        Deal__r.Name,
        Deal__r.Customer_Account__r.Name,
        Deal__r.Partner_Account__r.Name,
        Deal__r.Estimated_Revenue__c,
        Deal__r.Submitted_On__c,
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
      FROM Deal_Approval__c
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
