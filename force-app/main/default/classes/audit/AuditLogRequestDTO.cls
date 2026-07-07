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
