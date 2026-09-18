/**
 * Writes immutable audit trail entries for partner-visible actions (deal
 * decisions, content downloads, MDF approvals, etc.). This is the single
 * write path into Audit_Log__c — build the request via AuditFactory, then
 * call log() here.
 */
public with sharing class AuditService {
  /**
   * Writes an Audit_Log__c record from the given request, stamping the
   * running user and timestamp. The insert runs in system mode so the audit
   * trail is captured even for least-privilege users, and any failure is
   * caught and logged rather than rethrown so audit logging never breaks
   * the operation it's recording.
   *
   * @param request The audit entry to write; a null request is a no-op.
   */
  public static void log(AuditLogRequestDTO request) {
    if (request == null) {
      return;
    }

    try {
      // Audit logging must never break the operation it's recording (e.g.
      // a deal submission shouldn't fail because the audit insert did) —
      // any failure here is caught and logged, never rethrown to the caller.
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

      // This is an internal, immutable telemetry write. Running it in the
      // actor's user mode makes the audit trail disappear for least-privilege
      // users, which is both a compliance and operability defect.
      Database.insert(audit, AccessLevel.SYSTEM_MODE);
    } catch (Exception ex) {
      LoggingService.error('AuditService', 'Unable to create audit log.', ex);
    }
  }

  // Distinguishes internal (employee) actors from partner/community actors
  // for audit reporting; community users are never "internal" here.
  private static String determineActorType() {
    if (PartnerAccessService.isInternalUser()) {
      return 'Internal';
    }

    return 'Partner';
  }
}
