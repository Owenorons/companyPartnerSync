/**
 * Domain layer for the "my pending approval steps" workspace: maps queried
 * Deal_Approval__c rows into approval DTOs and computes the current user's
 * decide-authority hint. Compare to DealReviewDomain, the equivalent mapping
 * layer for the internal deal review workflow.
 */
public with sharing class DealApprovalDomain {
  /**
   * Maps a Deal_Approval__c to the row shape used in the "my pending approval steps" queue.
   *
   * @param record Approval step record to map.
   * @return The mapped DealApprovalStepListDTO.
   */
  public static DealApprovalStepListDTO toListDTO(Deal_Approval__c record) {
    DealApprovalStepListDTO dto = new DealApprovalStepListDTO();

    dto.approvalId = record.Id;
    dto.dealId = record.Deal__c;
    dto.dealNumber = record.Deal__r == null ? null : record.Deal__r.Name;

    dto.customerName = record.Deal__r == null ||
      record.Deal__r.Customer_Account__r == null
      ? null
      : record.Deal__r.Customer_Account__r.Name;

    dto.stepKey = record.Step_Key__c;
    dto.sequence = record.Sequence__c == null
      ? null
      : Integer.valueOf(record.Sequence__c);
    dto.status = record.Status__c;

    dto.estimatedRevenue = record.Deal__r == null
      ? null
      : record.Deal__r.Estimated_Revenue__c;
    dto.authorityLimit = record.Authority_Limit__c;
    dto.submittedOn = record.Deal__r == null
      ? null
      : record.Deal__r.Submitted_On__c;

    return dto;
  }

  /**
   * Maps a Deal_Approval__c to the full detail shape used on the approval step detail screen.
   *
   * @param record Approval step record to map.
   * @return The mapped DealApprovalStepDetailDTO.
   */
  public static DealApprovalStepDetailDTO toDetailDTO(Deal_Approval__c record) {
    DealApprovalStepDetailDTO dto = new DealApprovalStepDetailDTO();

    dto.approvalId = record.Id;
    dto.dealId = record.Deal__c;
    dto.dealNumber = record.Deal__r == null ? null : record.Deal__r.Name;

    dto.customerName = record.Deal__r == null ||
      record.Deal__r.Customer_Account__r == null
      ? null
      : record.Deal__r.Customer_Account__r.Name;

    dto.partnerName = record.Deal__r == null ||
      record.Deal__r.Partner_Account__r == null
      ? null
      : record.Deal__r.Partner_Account__r.Name;

    dto.stepKey = record.Step_Key__c;
    dto.sequence = record.Sequence__c == null
      ? null
      : Integer.valueOf(record.Sequence__c);
    dto.status = record.Status__c;

    dto.estimatedRevenue = record.Deal__r == null
      ? null
      : record.Deal__r.Estimated_Revenue__c;
    dto.authorityLimit = record.Authority_Limit__c;
    dto.submittedOn = record.Deal__r == null
      ? null
      : record.Deal__r.Submitted_On__c;

    dto.decision = record.Decision__c;
    dto.decisionReason = record.Decision_Reason__c;
    dto.decisionOn = record.Decision_On__c;

    dto.expectedVersion = record.Version_Number__c == null
      ? 0
      : Integer.valueOf(record.Version_Number__c);

    dto.canDecide = canDecide(record);

    return dto;
  }

  /**
   * Mirrors DealApprovalCommandService.assertAuthority()'s rule as a non-throwing hint, for UI
   * hide/disable purposes only. Not a security boundary - complete() re-checks authority.
   *
   * @param record Approval step record to check.
   * @return True if the running user appears able to decide this step right now.
   */
  private static Boolean canDecide(Deal_Approval__c record) {
    if (record.Status__c != 'Pending') {
      return false;
    }

    Boolean hasRoutedAuthority = record.Assigned_To__c != null
      ? record.Assigned_To__c == UserInfo.getUserId()
      : String.isNotBlank(record.Approver_Permission_Set__c) &&
        PermissionService.hasPermissionSet(record.Approver_Permission_Set__c);

    if (!hasRoutedAuthority) {
      return false;
    }

    if (record.Authority_Limit__c == null) {
      return true;
    }

    Decimal amount = record.Deal__r == null ||
      record.Deal__r.Estimated_Revenue__c == null
      ? 0
      : record.Deal__r.Estimated_Revenue__c;
    return amount <= record.Authority_Limit__c;
  }
}
