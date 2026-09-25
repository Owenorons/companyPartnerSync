/**
 * Selector layer for the "my pending deal review steps" workspace, the
 * Deal_Review__c counterpart to ApprovalSelector. Authority is
 * data-driven (an exact Assigned_To__c match, or holding the step's
 * Approver_Permission_Set__c), matching DealReviewCommandService
 * .assertAuthority() - SYSTEM_MODE/no-sharing since authority is proven by
 * permission-set membership, not record sharing.
 */
public without sharing class DealReviewStepSelector {
  private static final Set<String> PENDING_STATUSES = new Set<String>{
    'Ready',
    'In Progress',
    'Waiting for Information',
    'Escalated'
  };

  /**
   * Queries the running user's pending deal review steps: those directly assigned to them, plus
   * those routed to any permission set they hold. A Routing Failed step (nobody is routed to it)
   * is also surfaced to anyone holding general review-management authority, since Reassign - the
   * only way to recover one - is gated by that authority instead of the routed-step check.
   *
   * @return Up to 200 pending Deal_Review__c records the running user can work.
   */
  public static List<Deal_Review__c> selectMyPendingSteps() {
    Id currentUserId = UserInfo.getUserId();
    Set<String> myPermissionSetNames = PermissionService.getPermissionSetNames();

    List<Deal_Review__c> results = [
      SELECT
        Id,
        Deal__c,
        Deal__r.Name,
        Deal__r.Customer_Name__c,
        Review_Key__c,
        Review_Type__c,
        Sequence__c,
        Status__c,
        Blocking__c,
        Depends_On_Key__c,
        Due_On__c,
        Assigned_To__c,
        Approver_Permission_Set__c,
        Version_Number__c,
        CreatedDate
      FROM Deal_Review__c
      WHERE
        Status__c IN :PENDING_STATUSES
        AND (Assigned_To__c = :currentUserId
        OR Approver_Permission_Set__c IN :myPermissionSetNames)
      WITH SYSTEM_MODE
      ORDER BY CreatedDate ASC
      LIMIT 200
    ];

    if (PartnerPermissionService.canReviewDeals()) {
      results.addAll(
        [
          SELECT
            Id,
            Deal__c,
            Deal__r.Name,
            Deal__r.Customer_Name__c,
            Review_Key__c,
            Review_Type__c,
            Sequence__c,
            Status__c,
            Blocking__c,
            Depends_On_Key__c,
            Due_On__c,
            Assigned_To__c,
            Approver_Permission_Set__c,
            Version_Number__c,
            CreatedDate
          FROM Deal_Review__c
          WHERE Status__c = 'Routing Failed'
          WITH SYSTEM_MODE
          ORDER BY CreatedDate ASC
          LIMIT 200
        ]
      );
    }

    return results;
  }

  /**
   * Queries a single deal review step, with the fields needed for the step detail screen.
   *
   * @param reviewId Id of the review step to load.
   * @return The Deal_Review__c record.
   */
  public static Deal_Review__c selectStepDetail(Id reviewId) {
    List<Deal_Review__c> rows = [
      SELECT
        Id,
        Deal__c,
        Deal__r.Name,
        Deal__r.Customer_Name__c,
        Review_Key__c,
        Review_Type__c,
        Sequence__c,
        Status__c,
        Blocking__c,
        Depends_On_Key__c,
        Due_On__c,
        Assigned_To__c,
        Approver_Permission_Set__c,
        Version_Number__c,
        Outcome__c,
        Recusal_Reason__c,
        Waiver_Reason__c,
        Started_On__c,
        Completed_On__c,
        Escalated_On__c,
        CreatedDate
      FROM Deal_Review__c
      WHERE Id = :reviewId
      WITH SYSTEM_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Review step not found.');
    }

    return rows[0];
  }
}
