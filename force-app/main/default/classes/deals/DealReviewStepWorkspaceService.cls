/**
 * Orchestrates the "my pending deal review steps" workspace: lists and
 * loads steps the running user can act on, and dispatches actions to
 * DealReviewCommandService. Gated only by
 * PartnerAccessService.isInternalUser() - deliberately not any specific
 * review permission, since a step-worker (e.g. a role routed by
 * Approver_Permission_Set__c) may hold neither PartnerSync_Channel_Manager
 * nor PartnerSync_Deal_Reviewer specifically. Relevance is proven by having
 * pending steps - DealReviewCommandService.execute() remains the real
 * authority check.
 */
public with sharing class DealReviewStepWorkspaceService {
  /**
   * Loads the running user's pending deal review steps.
   *
   * @return Row shapes for steps the running user can work.
   */
  public static List<DealReviewStepListDTO> getMyPendingSteps() {
    assertInternalUser();

    List<DealReviewStepListDTO> results = new List<DealReviewStepListDTO>();

    for (
      Deal_Review__c record : DealReviewStepSelector.selectMyPendingSteps()
    ) {
      results.add(DealReviewStepDomain.toListDTO(record));
    }

    return results;
  }

  /**
   * Loads the full detail for a single deal review step, including a canDecide hint.
   *
   * @param reviewId Id of the review step to load.
   * @return The full detail DTO for the step.
   */
  public static DealReviewStepDetailDTO getStepDetail(Id reviewId) {
    assertInternalUser();

    Deal_Review__c record = DealReviewStepSelector.selectStepDetail(reviewId);

    return DealReviewStepDomain.toDetailDTO(record);
  }

  /**
   * Processes an action on a pending deal review step.
   *
   * @param request The action request.
   */
  public static void decide(DealReviewStepDecisionDTO request) {
    assertInternalUser();

    if (request == null || request.reviewId == null) {
      throw new PartnerSyncHandledException(
        'Deal review step request is invalid.'
      );
    }

    DealReviewCommand command = new DealReviewCommand();
    command.reviewId = request.reviewId;
    command.action = request.action;
    command.outcome = request.outcome;
    command.reason = request.reason;
    command.assigneeId = request.assigneeId;
    command.question = request.question;
    command.audience = request.audience;
    command.evidenceRequirement = request.evidenceRequirement;
    command.dueOn = request.dueOn;
    command.expectedVersion = request.expectedVersion;

    DealReviewCommandService.execute(new List<DealReviewCommand>{ command });

    LoggingService.info(
      'DealReviewStepWorkspaceService',
      'Deal review step action processed. ReviewId=' + request.reviewId
    );
  }

  private static void assertInternalUser() {
    if (!PartnerAccessService.isInternalUser()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to work deal review steps.'
      );
    }
  }
}
