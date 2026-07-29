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
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'MDFController',
        'Unable to submit MDF request.',
        ex
      );
      throw new AuraHandledException('Unable to submit MDF request.');
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<MDFListDTO> getMyRequests() {
    try {
      return MDFService.getMyRequests();
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error('MDFController', 'Unable to load MDF requests.', ex);
      throw new AuraHandledException('Unable to load MDF requests.');
    }
  }

  @AuraEnabled(cacheable=true)
  public static MDFBudgetDTO getMyBudget() {
    try {
      return MDFService.getMyBudget();
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error('MDFController', 'Unable to load MDF budget.', ex);
      throw new AuraHandledException('Unable to load MDF budget.');
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
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'MDFController',
        'Unable to load MDF review queue.',
        ex
      );
      throw new AuraHandledException('Unable to load MDF review queue.');
    }
  }

  @AuraEnabled
  public static void processDecision(MDFDecisionDTO request) {
    try {
      MDFApprovalService.processDecision(request);
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'MDFController',
        'Unable to process MDF decision.',
        ex
      );
      throw new AuraHandledException('Unable to process MDF decision.');
    }
  }
}
