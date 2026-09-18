/**
 * Aura controller surface for the lead distribution flows: assigning a lead
 * to a partner, listing a partner's leads, and processing accept/reject
 * decisions. Pure pass-through/exception-translation layer over
 * LeadDistributionService and LeadDecisionService — no business logic here.
 */
public with sharing class LeadDistributionController {
  /**
   * Assigns a Lead to a partner.
   *
   * @param request The lead assignment request.
   */
  @AuraEnabled
  public static void assignLeadToPartner(LeadAssignmentRequestDTO request) {
    try {
      LeadDistributionService.assignLeadToPartner(request);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'LeadDistributionController',
        'Unable to assign lead.',
        'Unable to assign lead.',
        ex
      );
    }
  }

  /**
   * Loads the leads currently visible to the signed-in partner user.
   *
   * @return The signed-in partner's leads.
   */
  @AuraEnabled(cacheable=true)
  public static List<LeadDistributionDTO> getMyLeads() {
    try {
      return LeadDistributionService.getMyLeads();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'LeadDistributionController',
        'Unable to load partner leads.',
        'Unable to load leads.',
        ex
      );
    }
  }

  /**
   * Processes a partner's accept/reject decision on an assigned lead.
   *
   * @param request The lead decision request.
   */
  @AuraEnabled
  public static void processDecision(LeadDecisionRequestDTO request) {
    try {
      LeadDecisionService.processDecision(request);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'LeadDistributionController',
        'Unable to process lead decision.',
        'Unable to process lead decision.',
        ex
      );
    }
  }
}
