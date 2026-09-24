/**
 * Orchestrates the "my pending approval steps" workspace: lists and loads
 * steps the running user can act on, and dispatches decisions to
 * DealApprovalCommandService. Gated only by PartnerAccessService
 * .isInternalUser() - deliberately not PartnerPermissionService
 * .assertCanReviewDeals(), since a step-decider (e.g. a role routed by
 * Approver_Permission_Set__c) may hold neither PartnerSync_Channel_Manager
 * nor PartnerSync_Deal_Reviewer. Relevance is proven by having pending
 * steps, the same "my queue" pattern used elsewhere in this app (e.g. the
 * AI_Insight_Request__c queue) - DealApprovalCommandService.complete()
 * remains the real authority check.
 */
public with sharing class DealApprovalWorkspaceService {
  /**
   * Loads the running user's pending approval steps.
   *
   * @return Row shapes for steps the running user can decide.
   */
  public static List<DealApprovalStepListDTO> getMyPendingSteps() {
    assertInternalUser();

    List<DealApprovalStepListDTO> results = new List<DealApprovalStepListDTO>();

    for (
      Deal_Approval__c record : DealApprovalSelector.selectMyPendingSteps()
    ) {
      results.add(DealApprovalDomain.toListDTO(record));
    }

    return results;
  }

  /**
   * Loads the full detail for a single approval step, including a canDecide hint.
   *
   * @param approvalId Id of the approval step to load.
   * @return The full detail DTO for the step.
   */
  public static DealApprovalStepDetailDTO getStepDetail(Id approvalId) {
    assertInternalUser();

    Deal_Approval__c record = DealApprovalSelector.selectStepDetail(approvalId);

    return DealApprovalDomain.toDetailDTO(record);
  }

  /**
   * Processes a decision on a pending approval step.
   *
   * @param request The decision request.
   */
  public static void decide(DealApprovalDecisionDTO request) {
    assertInternalUser();

    if (request == null || request.approvalId == null) {
      throw new PartnerSyncHandledException(
        'Approval decision request is invalid.'
      );
    }

    DealApprovalCommand command = new DealApprovalCommand();
    command.approvalId = request.approvalId;
    command.decision = request.decision;
    command.reason = request.reason;
    command.expectedVersion = request.expectedVersion;
    command.conditionType = request.conditionType;
    command.conditionDescription = request.conditionDescription;

    DealApprovalCommandService.complete(command);

    LoggingService.info(
      'DealApprovalWorkspaceService',
      'Approval step decision processed. ApprovalId=' + request.approvalId
    );
  }

  private static void assertInternalUser() {
    if (!PartnerAccessService.isInternalUser()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to decide approval steps.'
      );
    }
  }
}
