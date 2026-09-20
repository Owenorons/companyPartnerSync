/**
 * Aura-enabled entry point for the internal partner risk-approval LWC
 * (queue, decision). Thin wrapper only: delegates to
 * PartnerRiskApprovalService and translates handled exceptions into
 * AuraHandledException. Compare to DealReviewController, the equivalent
 * entry point for the internal deal review workspace.
 */
public with sharing class PartnerRiskApprovalController {
  /**
   * Loads the internal risk-approval queue for reviewers with the required
   * decision permission.
   *
   * @return Row shapes for approval steps awaiting or already through decision.
   */
  @AuraEnabled(cacheable=true)
  public static List<PartnerApprovalStepListDTO> getApprovalQueue() {
    try {
      return PartnerRiskApprovalService.getApprovalQueue();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerRiskApprovalController',
        'Unable to load partner risk-approval queue.',
        'Unable to load partner risk-approval queue.',
        ex
      );
    }
  }

  /**
   * Processes an internal reviewer's decision on a single approval step.
   *
   * @param request The reviewer's decision request.
   */
  @AuraEnabled
  public static void decideStep(PartnerApprovalStepDecisionDTO request) {
    try {
      PartnerRiskApprovalService.decideStep(
        request?.stepId,
        request?.decision,
        request?.reason
      );
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerRiskApprovalController',
        'Unable to process approval-step decision.',
        'Unable to process approval-step decision.',
        ex
      );
    }
  }
}
