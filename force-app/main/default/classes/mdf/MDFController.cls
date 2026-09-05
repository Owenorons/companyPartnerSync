/*
 * Aura/LWC entry point for MDF: submission, the partner's own requests
 * and budget, the internal review queue, and decisions. Thin boundary
 * only — all rules live in MDFService/MDFApprovalService/MDFSelector;
 * this class just translates exceptions into AuraHandledException.
 */
public with sharing class MDFController {
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
