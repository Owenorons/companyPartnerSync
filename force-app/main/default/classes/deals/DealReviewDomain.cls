/**
 * Domain layer for the internal review/decision workflow: maps queried
 * Deal_Registration__c rows (plus their conflicting siblings) into review
 * DTOs, and validates a reviewer's decision. The internal-review
 * counterpart to DealRegistrationDomain, which builds/maps the record on
 * the partner-submission side before any review has happened.
 */
public with sharing class DealReviewDomain {
  /**
   * Maps a Deal_Registration__c to the row shape used in the internal review queue.
   *
   * @param record Deal registration record to map.
   * @return The mapped DealReviewListDTO.
   */
  public static DealReviewListDTO toListDTO(Deal_Registration__c record) {
    DealReviewListDTO dto = new DealReviewListDTO();

    dto.dealId = record.Id;
    dto.dealNumber = record.Name;

    // WITH USER_MODE queries don't throw on an inaccessible parent lookup —
    // the relationship just comes back null. Guarding here avoids a null
    // pointer if the running user can't see the related Account.
    dto.customerName = record.Customer_Account__r == null
      ? null
      : record.Customer_Account__r.Name;

    dto.partnerName = record.Partner_Account__r == null
      ? null
      : record.Partner_Account__r.Name;

    dto.estimatedRevenue = record.Estimated_Revenue__c;
    dto.estimatedCloseDate = record.Estimated_Close_Date__c;

    dto.status = record.Status__c;
    dto.conflictStatus = record.Conflict_Status__c;

    dto.protectionEndDate = record.Protection_End_Date__c;
    dto.submittedOn = record.Submitted_On__c;

    return dto;
  }

  /**
   * Maps a Deal_Registration__c and its conflicting siblings to the full detail shape used on
   * the internal review screen, including mapped conflict rows and computed risk fields from
   * DealRiskScoringService.
   *
   * @param record Deal registration record to map.
   * @param conflicts Competing deal registrations found for the same customer account.
   * @return The mapped DealReviewDetailDTO.
   */
  public static DealReviewDetailDTO toDetailDTO(
    Deal_Registration__c record,
    List<Deal_Registration__c> conflicts
  ) {
    DealReviewDetailDTO dto = new DealReviewDetailDTO();

    dto.dealId = record.Id;
    dto.dealNumber = record.Name;

    dto.opportunityId = record.Opportunity__c;
    dto.customerAccountId = record.Customer_Account__c;
    dto.partnerAccountId = record.Partner_Account__c;

    dto.customerName = record.Customer_Account__r == null
      ? null
      : record.Customer_Account__r.Name;

    dto.partnerName = record.Partner_Account__r == null
      ? null
      : record.Partner_Account__r.Name;

    dto.estimatedRevenue = record.Estimated_Revenue__c;
    dto.estimatedCloseDate = record.Estimated_Close_Date__c;

    dto.businessProblem = record.Business_Problem__c;
    dto.proposedSolution = record.Proposed_Solution__c;
    dto.implementationTimeline = record.Implementation_Timeline__c;
    dto.notes = record.Notes__c;

    dto.status = record.Status__c;
    dto.conflictStatus = record.Conflict_Status__c;

    dto.protectionEndDate = record.Protection_End_Date__c;
    dto.submittedOn = record.Submitted_On__c;

    dto.approvalNotes = record.Approval_Notes__c;
    dto.rejectionReason = record.Rejection_Reason__c;
    dto.conflictResolutionNotes = record.Conflict_Resolution_Notes__c;

    dto.attributionType = record.Attribution_Type__c;

    dto.conflicts = new List<DealConflictDetailDTO>();

    for (Deal_Registration__c conflict : conflicts) {
      dto.conflicts.add(toConflictDTO(conflict));
    }

    dto.riskScore = DealRiskScoringService.score(record, conflicts);
    dto.riskLevel = DealRiskScoringService.level(dto.riskScore);
    dto.riskSummary = DealRiskScoringService.summary(
      record,
      conflicts,
      dto.riskScore
    );
    dto.riskRecommendation = DealRiskScoringService.recommendation(
      record,
      conflicts,
      dto.riskScore
    );

    return dto;
  }

  /**
   * Maps a competing Deal_Registration__c to the per-conflict detail shape shown to internal
   * reviewers.
   *
   * @param record Competing deal registration record to map.
   * @return The mapped DealConflictDetailDTO.
   */
  public static DealConflictDetailDTO toConflictDTO(
    Deal_Registration__c record
  ) {
    DealConflictDetailDTO dto = new DealConflictDetailDTO();

    dto.dealId = record.Id;
    dto.dealNumber = record.Name;

    dto.partnerName = record.Partner_Account__r == null
      ? null
      : record.Partner_Account__r.Name;

    dto.customerName = record.Customer_Account__r == null
      ? null
      : record.Customer_Account__r.Name;

    dto.estimatedRevenue = record.Estimated_Revenue__c;
    dto.status = record.Status__c;
    dto.protectionEndDate = record.Protection_End_Date__c;

    return dto;
  }

  /**
   * Validates that an internal reviewer's decision request is well-formed: a deal Id and a
   * supported decision value are present, a rejection reason is given for 'Rejected', and a
   * positive extension length is given for 'Protection Extended'.
   *
   * @param request The reviewer's decision request.
   */
  public static void validateDecision(DealReviewDecisionDTO request) {
    if (request == null || request.dealId == null) {
      throw new PartnerSyncHandledException(
        'Deal review decision request is invalid.'
      );
    }

    Set<String> allowed = new Set<String>{
      'Approved',
      'Rejected',
      'Conflict Resolved',
      'Protection Extended'
    };

    if (!allowed.contains(request.decision)) {
      throw new PartnerSyncHandledException(
        'Unsupported deal review decision.'
      );
    }

    if (
      request.decision == 'Rejected' && String.isBlank(request.rejectionReason)
    ) {
      throw new PartnerSyncHandledException('Rejection reason is required.');
    }

    if (
      request.decision == 'Protection Extended' &&
      (request.protectionExtensionDays == null ||
      request.protectionExtensionDays <= 0)
    ) {
      throw new PartnerSyncHandledException(
        'Protection extension days must be greater than zero.'
      );
    }
  }
}
