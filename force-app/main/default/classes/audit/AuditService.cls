public with sharing class AuditService {
  public static void log(AuditLogRequestDTO request) {
    if (request == null) {
      return;
    }

    try {
      Audit_Log__c audit = new Audit_Log__c();

      audit.Audit_Timestamp__c = System.now();

      audit.Partner_Account__c = request.partnerAccountId;

      audit.Partner_Contact__c = request.partnerContactId;

      audit.Customer_Account__c = request.customerAccountId;

      audit.Object_Name__c = request.objectName;

      audit.Record_Id__c = String.valueOf(request.recordId);

      audit.Record_Name__c = request.recordName;

      audit.Action__c = request.action;

      audit.Severity__c = request.severity;

      audit.Old_Value_JSON__c = request.oldJson;

      audit.New_Value_JSON__c = request.newJson;

      audit.Metadata_JSON__c = request.metadataJson;

      audit.Status__c = request.status;

      audit.Performed_By__c = UserInfo.getUserId();

      audit.Performed_By_Name__c = UserInfo.getName();

      audit.Performed_By_Type__c = determineActorType();

      insert audit;
    } catch (Exception ex) {
      LoggingService.error('AuditService', 'Unable to create audit log.', ex);
    }
  }

  private static String determineActorType() {
    if (PartnerAccessService.isInternalUser()) {
      return 'Internal';
    }

    return 'Partner';
  }
}
