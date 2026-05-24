public with sharing class LeadDistributionLogService {
  public static void logAction(
    Id leadId,
    Id partnerAccountId,
    Id partnerContactId,
    String action,
    String status,
    String notes
  ) {
    if (!Schema.sObjectType.Lead_Distribution_Log__c.isCreateable()) {
      LoggingService.warn(
        'LeadDistributionLogService',
        'Skipping lead distribution log because user lacks create access.'
      );
      return;
    }

    try {
      Lead_Distribution_Log__c log = new Lead_Distribution_Log__c();
      log.Lead__c = leadId;
      log.Partner_Account__c = partnerAccountId;
      log.Partner_Contact__c = partnerContactId;
      log.Action__c = action;
      log.Status__c = status;
      log.Notes__c = notes;
      log.Performed_By__c = UserInfo.getUserId();
      log.Performed_On__c = System.now();

      insert SecurityUtil.stripForCreate(new List<SObject>{ log });
    } catch (Exception ex) {
      LoggingService.error(
        'LeadDistributionLogService',
        'Unable to create lead distribution log.',
        ex
      );
    }
  }
}
