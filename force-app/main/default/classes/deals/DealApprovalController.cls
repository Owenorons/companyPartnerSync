/**
 * Aura-enabled entry point for the "my pending approval steps" LWC (queue,
 * detail, decision). Thin wrapper only: delegates to
 * DealApprovalWorkspaceService and translates handled exceptions into
 * AuraHandledException. Compare to DealReviewController, the equivalent
 * entry point for the internal deal review workflow.
 */
public with sharing class DealApprovalController {
  /**
   * Loads the running user's pending approval steps.
   *
   * @return Row shapes for steps the running user can decide.
   */
  @AuraEnabled(cacheable=true)
  public static List<DealApprovalStepListDTO> getMyPendingSteps() {
    try {
      return DealApprovalWorkspaceService.getMyPendingSteps();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealApprovalController',
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
  public static DealApprovalStepDetailDTO getStepDetail(Id approvalId) {
    try {
      return DealApprovalWorkspaceService.getStepDetail(approvalId);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealApprovalController',
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
  public static void decide(DealApprovalDecisionDTO request) {
    try {
      DealApprovalWorkspaceService.decide(request);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealApprovalController',
        'Unable to process approval step decision.',
        'Unable to process approval step decision.',
        ex
      );
    }
  }
}
