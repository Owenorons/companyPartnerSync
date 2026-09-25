/**
 * Aura/LWC entry point for MDF: submission, the partner's own requests
 * and budget, the internal review queue, and decisions. Thin boundary
 * only — all rules live in MDFService/MDFApprovalService/MDFSelector;
 * this class just translates exceptions into AuraHandledException.
 */
public with sharing class MDFController {
  /**
   * Submits a new MDF request on behalf of the running partner user.
   *
   * @param request The MDF request details to submit.
   */
  @AuraEnabled
  public static void submitRequest(MDFRequestDTO request) {
    try {
      MDFService.submitRequest(request);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'MDFController',
        'Unable to submit MDF request.',
        'Unable to submit MDF request.',
        ex
      );
    }
  }

  /**
   * Resubmits an MDF request a pre-approval chain step returned for correction.
   *
   * @param requestId Id of the MDF request to resubmit.
   */
  @AuraEnabled
  public static void resubmitRequest(Id requestId) {
    try {
      MDFService.resubmitRequest(requestId);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'MDFController',
        'Unable to resubmit MDF request.',
        'Unable to resubmit MDF request.',
        ex
      );
    }
  }

  /**
   * Returns the running partner user's own MDF requests.
   *
   * @return List of the caller's MDF requests as list-row DTOs.
   */
  @AuraEnabled(cacheable=true)
  public static List<MDFListDTO> getMyRequests() {
    try {
      return MDFService.getMyRequests();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'MDFController',
        'Unable to load MDF requests.',
        'Unable to load MDF requests.',
        ex
      );
    }
  }

  /**
   * Returns the running partner user's MDF budget standing.
   *
   * @return The caller's annual/used/remaining MDF budget.
   */
  @AuraEnabled(cacheable=true)
  public static MDFBudgetDTO getMyBudget() {
    try {
      return MDFService.getMyBudget();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'MDFController',
        'Unable to load MDF budget.',
        'Unable to load MDF budget.',
        ex
      );
    }
  }

  /**
   * Returns the queue of MDF requests awaiting internal review, for
   * users with the internal MDF-review permission.
   *
   * @return List of pending MDF requests as list-row DTOs.
   */
  @AuraEnabled(cacheable=true)
  public static List<MDFListDTO> getReviewQueue() {
    try {
      List<MDFListDTO> results = new List<MDFListDTO>();

      for (MDF_Request__c record : MDFSelector.selectReviewQueue()) {
        results.add(MDFDomain.toListDTO(record));
      }

      return results;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'MDFController',
        'Unable to load MDF review queue.',
        'Unable to load MDF review queue.',
        ex
      );
    }
  }

  /**
   * Records an internal reviewer's approve/reject decision on an MDF
   * request.
   *
   * @param request The decision (approve or reject) and its details.
   */
  @AuraEnabled
  public static void processDecision(MDFDecisionDTO request) {
    try {
      MDFApprovalService.processDecision(request);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'MDFController',
        'Unable to process MDF decision.',
        'Unable to process MDF decision.',
        ex
      );
    }
  }
}
