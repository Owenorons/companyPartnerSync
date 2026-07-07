public with sharing class LeadDistributionController {
  @AuraEnabled
  public static void assignLeadToPartner(LeadAssignmentRequestDTO request) {
    try {
      LeadDistributionService.assignLeadToPartner(request);
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'LeadDistributionController',
        'Unable to assign lead.',
        ex
      );

      throw new AuraHandledException('Unable to assign lead.');
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<LeadDistributionDTO> getMyLeads() {
    try {
      return LeadDistributionService.getMyLeads();
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'LeadDistributionController',
        'Unable to load partner leads.',
        ex
      );

      throw new AuraHandledException('Unable to load leads.');
    }
  }

  @AuraEnabled
  public static void processDecision(LeadDecisionRequestDTO request) {
    try {
      LeadDecisionService.processDecision(request);
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'LeadDistributionController',
        'Unable to process lead decision.',
        ex
      );

      throw new AuraHandledException('Unable to process lead decision.');
    }
  }
}
