/*
 * Read-side of the audit trail: lets internal users pull audit history for
 * a specific record. Gated behind the internal-analytics permission —
 * partner/community users have no path to this service.
 */
public without sharing class AuditQueryService {
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
      // Record_Id__c is a text field, not a lookup, because audit entries
      // are written against many unrelated SObject types (polymorphic
      // reference); comparing on Id-as-String is intentional, not a bug.
      WHERE Record_Id__c = :String.valueOf(recordId)
      WITH SYSTEM_MODE
      ORDER BY Audit_Timestamp__c DESC
      LIMIT 500
    ];
  }
}
