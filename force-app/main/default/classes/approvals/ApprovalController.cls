/**
 * Aura-enabled entry point for the "my pending approval steps" LWC (queue,
 * detail, decision). Thin wrapper only: delegates to
 * ApprovalWorkspaceService and translates handled exceptions into
 * AuraHandledException. Object-agnostic - compare to DealReviewController,
 * the equivalent entry point for the internal deal review workflow, which
 * (unlike this one) is scoped to a single object.
 */
public with sharing class ApprovalController {
  /**
   * Loads the running user's pending approval steps.
   *
   * @return Row shapes for steps the running user can decide.
   */
  @AuraEnabled(cacheable=true)
  public static List<ApprovalStepListDTO> getMyPendingSteps() {
    try {
      return ApprovalWorkspaceService.getMyPendingSteps();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ApprovalController',
        'Unable to load pending approval steps.',
        'Unable to load pending approval steps.',
        ex
      );
    }
  }

  /**
   * Loads the full detail for a single approval step.
   *
   * @param approvalId Id of the approval step to load.
   * @return The full detail DTO for the step.
   */
  @AuraEnabled(cacheable=true)
  public static ApprovalStepDetailDTO getStepDetail(Id approvalId) {
    try {
      return ApprovalWorkspaceService.getStepDetail(approvalId);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ApprovalController',
        'Unable to load approval step detail.',
        'Unable to load approval step detail.',
        ex
      );
    }
  }

  /**
   * Processes a decision on a pending approval step.
   *
   * @param request The decision request.
   */
  @AuraEnabled
  public static void decide(ApprovalDecisionDTO request) {
    try {
      ApprovalWorkspaceService.decide(request);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ApprovalController',
        'Unable to process approval step decision.',
        'Unable to process approval step decision.',
        ex
      );
    }
  }
}
