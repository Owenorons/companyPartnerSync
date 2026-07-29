/*
 * Row shape for the partner application review queue list view — summary
 * fields only, not the full application detail (see
 * PartnerApplicationDetailDTO for that).
 */
public with sharing class PartnerApplicationListDTO {
  @AuraEnabled
  public Id applicationId;
  @AuraEnabled
  public String applicationNumber;

  @AuraEnabled
  public String companyName;

  @AuraEnabled
  public String requestedTier;
  @AuraEnabled
  public String partnerType;

  @AuraEnabled
  public String status;
  @AuraEnabled
  public Datetime submittedOn;
}
