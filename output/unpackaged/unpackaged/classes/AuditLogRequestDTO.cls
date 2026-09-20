/**
 * Transport DTO carrying an audit entry from a calling service to
 * AuditService.log(). Decouples callers from the Audit_Log__c SObject shape
 * and from needing object-level access to it directly.
 */
public with sharing class AuditLogRequestDTO {
  /** The partner account associated with the audited action, if any. */
  public Id partnerAccountId;
  /** The partner contact associated with the audited action, if any. */
  public Id partnerContactId;
  /** The customer account associated with the audited action, if any. */
  public Id customerAccountId;

  /** The name of the SObject the audited action was performed on. */
  public String objectName;

  /** The id of the record the audited action was performed on. */
  public Id recordId;
  /** The name/label of the record the audited action was performed on. */
  public String recordName;

  /** The action that was performed (e.g. Submit, Approve). */
  public String action;
  /** The severity of the audit entry (e.g. Info, Error). */
  public String severity;

  /** JSON snapshot of the record's field values before the action, if captured. */
  public String oldJson;
  /** JSON snapshot of the record's field values after the action, if captured. */
  public String newJson;
  /** JSON blob of additional contextual metadata for the audit entry. */
  public String metadataJson;

  /** The outcome status of the audited action (e.g. Success, Failed). */
  public String status;
}
