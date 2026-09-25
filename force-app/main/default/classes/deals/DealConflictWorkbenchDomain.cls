/**
 * Domain layer for the deal conflict workbench: maps queried
 * Deal_Conflict__c rows into workbench DTOs.
 */
public with sharing class DealConflictWorkbenchDomain {
  /**
   * Maps a Deal_Conflict__c to the row shape used in the workbench queue.
   *
   * @param record Conflict finding to map.
   * @return The mapped DealConflictWorkbenchListDTO.
   */
  public static DealConflictWorkbenchListDTO toListDTO(
    Deal_Conflict__c record
  ) {
    DealConflictWorkbenchListDTO dto = new DealConflictWorkbenchListDTO();

    dto.conflictId = record.Id;
    dto.dealId = record.Deal__c;
    dto.dealLabel = dealLabel(record.Deal__r);
    dto.matchedDealId = record.Matched_Deal__c;
    dto.matchedDealLabel = dealLabel(record.Matched_Deal__r);

    dto.type = record.Type__c;
    dto.subtype = record.Subtype__c;
    dto.severity = record.Severity__c;
    dto.confidence = record.Confidence__c;
    dto.matchScore = record.Match_Score__c;
    dto.blocking = record.Blocking__c;

    dto.status = record.Status__c;
    dto.assignedToId = record.Assigned_To__c;
    dto.detectedOn = record.CreatedDate;
    dto.escalatedOn = record.Escalated_On__c;

    dto.expectedVersion = record.Version_Number__c == null
      ? 0
      : Integer.valueOf(record.Version_Number__c);

    return dto;
  }

  /**
   * Maps a Deal_Conflict__c to the full detail shape used on the workbench detail screen.
   *
   * @param record Conflict finding to map.
   * @return The mapped DealConflictWorkbenchDetailDTO.
   */
  public static DealConflictWorkbenchDetailDTO toDetailDTO(
    Deal_Conflict__c record
  ) {
    DealConflictWorkbenchDetailDTO dto = new DealConflictWorkbenchDetailDTO();

    dto.conflictId = record.Id;
    dto.dealId = record.Deal__c;
    dto.dealLabel = dealLabel(record.Deal__r);
    dto.matchedDealId = record.Matched_Deal__c;
    dto.matchedDealLabel = dealLabel(record.Matched_Deal__r);

    dto.type = record.Type__c;
    dto.subtype = record.Subtype__c;
    dto.severity = record.Severity__c;
    dto.confidence = record.Confidence__c;
    dto.matchScore = record.Match_Score__c;
    dto.blocking = record.Blocking__c;
    dto.ruleVersion = record.Rule_Version__c;

    dto.status = record.Status__c;
    dto.assignedToId = record.Assigned_To__c;
    dto.detectedOn = record.CreatedDate;
    dto.investigationStartedOn = record.Investigation_Started_On__c;
    dto.escalatedOn = record.Escalated_On__c;
    dto.slaDue = record.SLA_Due__c;

    dto.evidenceSummary = record.Evidence_Summary__c;
    dto.evidenceRequestedOn = record.Evidence_Requested_On__c;
    dto.evidenceSubmittedOn = record.Evidence_Submitted_On__c;
    dto.reviewedEvidence = record.Reviewed_Evidence__c;

    dto.resolution = record.Resolution__c;
    dto.resolutionReason = record.Resolution_Reason__c;
    dto.resolvedById = record.Resolved_By__c;
    dto.resolvedOn = record.Resolved_On__c;

    dto.waivedById = record.Waived_By__c;
    dto.waivedOn = record.Waived_On__c;
    dto.waiverReason = record.Waiver_Reason__c;
    dto.waiverConditions = record.Waiver_Conditions__c;
    dto.waiverExpiresOn = record.Waiver_Expires_On__c;

    dto.partnerMessage = record.Partner_Message__c;
    dto.partnerClassification = record.Partner_Classification__c;

    dto.expectedVersion = record.Version_Number__c == null
      ? 0
      : Integer.valueOf(record.Version_Number__c);

    dto.canWaiveCritical = DealLifecyclePermissionService.hasPermission(
      'PartnerSync_Waive_Critical_Conflict'
    );

    return dto;
  }

  private static String dealLabel(Deal_Registration__c deal) {
    if (deal == null) {
      return null;
    }
    return deal.Name +
      (String.isBlank(deal.Customer_Name__c)
        ? ''
        : ' — ' + deal.Customer_Name__c);
  }
}
