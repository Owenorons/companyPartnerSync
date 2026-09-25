/**
 * Domain layer for the "my pending approval steps" workspace: maps queried
 * Approval__c rows into approval DTOs and computes the current user's
 * decide-authority hint. Object-agnostic - never reads a field specific to
 * any one target object, only the denormalized Target_Label__c/
 * Target_Amount__c the generating caller already snapshotted.
 */
public with sharing class ApprovalDomain {
  /**
   * Maps an Approval__c to the row shape used in the "my pending approval steps" queue.
   *
   * @param record Approval step record to map.
   * @return The mapped ApprovalStepListDTO.
   */
  public static ApprovalStepListDTO toListDTO(Approval__c record) {
    ApprovalStepListDTO dto = new ApprovalStepListDTO();

    dto.approvalId = record.Id;
    dto.objectName = record.Object_Name__c;
    dto.targetRecordId = record.Target_Record_Id__c;
    dto.targetLabel = record.Target_Label__c;

    dto.stepKey = record.Step_Key__c;
    dto.sequence = record.Sequence__c == null
      ? null
      : Integer.valueOf(record.Sequence__c);
    dto.status = record.Status__c;

    dto.targetAmount = record.Target_Amount__c;
    dto.authorityLimit = record.Authority_Limit__c;
    dto.generatedOn = record.CreatedDate;

    return dto;
  }

  /**
   * Maps an Approval__c to the full detail shape used on the approval step detail screen.
   *
   * @param record Approval step record to map.
   * @return The mapped ApprovalStepDetailDTO.
   */
  public static ApprovalStepDetailDTO toDetailDTO(Approval__c record) {
    ApprovalStepDetailDTO dto = new ApprovalStepDetailDTO();

    dto.approvalId = record.Id;
    dto.objectName = record.Object_Name__c;
    dto.targetRecordId = record.Target_Record_Id__c;
    dto.targetLabel = record.Target_Label__c;

    dto.stepKey = record.Step_Key__c;
    dto.sequence = record.Sequence__c == null
      ? null
      : Integer.valueOf(record.Sequence__c);
    dto.status = record.Status__c;

    dto.targetAmount = record.Target_Amount__c;
    dto.authorityLimit = record.Authority_Limit__c;
    dto.generatedOn = record.CreatedDate;

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
   * Mirrors ApprovalCommandService.assertAuthority()'s rule as a non-throwing hint, for UI
   * hide/disable purposes only. Not a security boundary - complete() re-checks authority.
   *
   * @param record Approval step record to check.
   * @return True if the running user appears able to decide this step right now.
   */
  private static Boolean canDecide(Approval__c record) {
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

    Decimal amount = record.Target_Amount__c == null
      ? 0
      : record.Target_Amount__c;
    return amount <= record.Authority_Limit__c;
  }
}
