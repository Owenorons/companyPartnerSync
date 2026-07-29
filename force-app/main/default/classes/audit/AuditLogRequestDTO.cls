/*
 * Transport DTO carrying an audit entry from a calling service to
 * AuditService.log(). Decouples callers from the Audit_Log__c SObject shape
 * and from needing object-level access to it directly.
 */
public with sharing class AuditLogRequestDTO {
  public Id partnerAccountId;
  public Id partnerContactId;
  public Id customerAccountId;

  public String objectName;

  public Id recordId;
  public String recordName;

  public String action;
  public String severity;

  public String oldJson;
  public String newJson;
  public String metadataJson;

  public String status;
}
