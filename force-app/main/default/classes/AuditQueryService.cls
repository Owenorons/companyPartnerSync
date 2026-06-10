public with sharing class AuditQueryService {
  public static List<Audit_Log__c> getAuditForRecord(Id recordId) {
    PartnerPermissionService.assertCanAccessInternalAnalytics();

    return [
      SELECT
        Id,
        Audit_Timestamp__c,
        Action__c,
        Severity__c,
        Object_Name__c,
        Performed_By_Name__c,
        Status__c
      FROM Audit_Log__c
      WHERE Record_Id__c = :String.valueOf(recordId)
      ORDER BY Audit_Timestamp__c DESC
      LIMIT 500
    ];
  }
}
