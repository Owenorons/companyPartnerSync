/**
 * Domain layer for the "my pending deal review steps" workspace: maps
 * queried Deal_Review__c rows into review-step DTOs and computes the
 * current user's work-authority hint.
 */
public with sharing class DealReviewStepDomain {
  /**
   * Maps a Deal_Review__c to the row shape used in the "my pending deal review steps" queue.
   *
   * @param record Review step record to map.
   * @return The mapped DealReviewStepListDTO.
   */
  public static DealReviewStepListDTO toListDTO(Deal_Review__c record) {
    DealReviewStepListDTO dto = new DealReviewStepListDTO();

    dto.reviewId = record.Id;
    dto.dealId = record.Deal__c;
    dto.dealLabel = dealLabel(record);

    dto.reviewKey = record.Review_Key__c;
    dto.reviewType = record.Review_Type__c;
    dto.sequence = record.Sequence__c == null
      ? null
      : Integer.valueOf(record.Sequence__c);
    dto.status = record.Status__c;
    dto.blocking = record.Blocking__c;

    dto.dueOn = record.Due_On__c;
    dto.generatedOn = record.CreatedDate;
    dto.needsReassignment = record.Status__c == 'Routing Failed';

    return dto;
  }

  /**
   * Maps a Deal_Review__c to the full detail shape used on the review step detail screen.
   *
   * @param record Review step record to map.
   * @return The mapped DealReviewStepDetailDTO.
   */
  public static DealReviewStepDetailDTO toDetailDTO(Deal_Review__c record) {
    DealReviewStepDetailDTO dto = new DealReviewStepDetailDTO();

    dto.reviewId = record.Id;
    dto.dealId = record.Deal__c;
    dto.dealLabel = dealLabel(record);

    dto.reviewKey = record.Review_Key__c;
    dto.reviewType = record.Review_Type__c;
    dto.sequence = record.Sequence__c == null
      ? null
      : Integer.valueOf(record.Sequence__c);
    dto.status = record.Status__c;
    dto.blocking = record.Blocking__c;
    dto.dependsOnKey = record.Depends_On_Key__c;

    dto.dueOn = record.Due_On__c;
    dto.generatedOn = record.CreatedDate;

    dto.outcome = record.Outcome__c;
    dto.recusalReason = record.Recusal_Reason__c;
    dto.waiverReason = record.Waiver_Reason__c;
    dto.startedOn = record.Started_On__c;
    dto.completedOn = record.Completed_On__c;
    dto.escalatedOn = record.Escalated_On__c;

    dto.expectedVersion = record.Version_Number__c == null
      ? 0
      : Integer.valueOf(record.Version_Number__c);

    dto.canDecide = canDecide(record);
    dto.canReassign = canReassign(record);

    return dto;
  }

  private static String dealLabel(Deal_Review__c record) {
    if (record.Deal__r == null) {
      return null;
    }
    return record.Deal__r.Name +
      (String.isBlank(record.Deal__r.Customer_Name__c)
        ? ''
        : ' — ' + record.Deal__r.Customer_Name__c);
  }

  /**
   * Mirrors DealReviewCommandService.assertAuthority()'s rule as a non-throwing hint, for UI
   * hide/disable purposes only. Not a security boundary - execute() re-checks authority.
   *
   * @param record Review step record to check.
   * @return True if the running user appears able to work this step right now.
   */
  private static Boolean canDecide(Deal_Review__c record) {
    Set<String> workableStatuses = new Set<String>{
      'Ready',
      'In Progress',
      'Waiting for Information',
      'Escalated'
    };
    if (!workableStatuses.contains(record.Status__c)) {
      return false;
    }

    return record.Assigned_To__c != null
      ? record.Assigned_To__c == UserInfo.getUserId()
      : String.isNotBlank(record.Approver_Permission_Set__c) &&
        PermissionService.hasPermissionSet(record.Approver_Permission_Set__c);
  }

  /**
   * Mirrors DealReviewCommandService.apply()'s Reassign gate (general
   * review-management authority, not the routed-step check) as a
   * non-throwing hint.
   *
   * @param record Review step record to check.
   * @return True if the running user appears able to reassign this step right now.
   */
  private static Boolean canReassign(Deal_Review__c record) {
    Set<String> reassignableStatuses = new Set<String>{
      'Ready',
      'In Progress',
      'Waiting for Information',
      'Escalated',
      'Routing Failed'
    };
    return reassignableStatuses.contains(record.Status__c) &&
      PartnerPermissionService.canReviewDeals();
  }
}
