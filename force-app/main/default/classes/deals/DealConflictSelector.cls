/**
 * Selector layer for the deal conflict workbench. Deal_Conflict__c
 * authority is a single flat custom permission
 * (PartnerSync_Resolve_Deal_Conflict), not per-record assignment - see
 * DealConflictCommandService.assertAuthority() - so unlike
 * ApprovalSelector/DealReviewStepSelector there is no "my queue" filter:
 * anyone holding the permission can see and work every open finding.
 */
public without sharing class DealConflictSelector {
  private static final Set<String> TERMINAL_STATUSES = new Set<String>{
    'Resolved',
    'Waived',
    'False Positive',
    'Superseded'
  };

  /**
   * Queries every current, non-terminal conflict finding, oldest first.
   *
   * @return Up to 200 pending Deal_Conflict__c records.
   */
  public static List<Deal_Conflict__c> selectPendingConflicts() {
    return [
      SELECT
        Id,
        Deal__c,
        Deal__r.Name,
        Deal__r.Customer_Name__c,
        Matched_Deal__c,
        Matched_Deal__r.Name,
        Matched_Deal__r.Customer_Name__c,
        Type__c,
        Subtype__c,
        Severity__c,
        Confidence__c,
        Match_Score__c,
        Blocking__c,
        Status__c,
        Assigned_To__c,
        Escalated_On__c,
        Version_Number__c,
        CreatedDate
      FROM Deal_Conflict__c
      WHERE Current__c = TRUE AND Status__c NOT IN :TERMINAL_STATUSES
      WITH SYSTEM_MODE
      ORDER BY CreatedDate ASC
      LIMIT 200
    ];
  }

  /**
   * Queries a single conflict finding, with the fields needed for the detail screen.
   *
   * @param conflictId Id of the conflict finding to load.
   * @return The Deal_Conflict__c record.
   */
  public static Deal_Conflict__c selectConflictDetail(Id conflictId) {
    List<Deal_Conflict__c> rows = [
      SELECT
        Id,
        Deal__c,
        Deal__r.Name,
        Deal__r.Customer_Name__c,
        Matched_Deal__c,
        Matched_Deal__r.Name,
        Matched_Deal__r.Customer_Name__c,
        Type__c,
        Subtype__c,
        Severity__c,
        Confidence__c,
        Match_Score__c,
        Blocking__c,
        Rule_Version__c,
        Status__c,
        Assigned_To__c,
        Investigation_Started_On__c,
        Escalated_On__c,
        SLA_Due__c,
        Evidence_Summary__c,
        Evidence_Requested_On__c,
        Evidence_Submitted_On__c,
        Reviewed_Evidence__c,
        Resolution__c,
        Resolution_Reason__c,
        Resolved_By__c,
        Resolved_On__c,
        Waived_By__c,
        Waived_On__c,
        Waiver_Reason__c,
        Waiver_Conditions__c,
        Waiver_Expires_On__c,
        Partner_Message__c,
        Partner_Classification__c,
        Version_Number__c,
        CreatedDate
      FROM Deal_Conflict__c
      WHERE Id = :conflictId
      WITH SYSTEM_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Conflict finding not found.');
    }

    return rows[0];
  }
}
