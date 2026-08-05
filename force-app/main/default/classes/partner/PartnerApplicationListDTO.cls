/*
 * Row shape for the partner application review queue list view — summary
 * fields only, not the full application detail (see
 * PartnerApplicationDetailDTO for that).
 */
public with sharing class PartnerApplicationListDTO {
  @AuraEnabled
  public Id applicationId { get; set; }
  @AuraEnabled
  public String applicationNumber { get; set; }

  @AuraEnabled
  public String companyName { get; set; }

  @AuraEnabled
  public String requestedTier { get; set; }
  @AuraEnabled
  public String partnerType { get; set; }

  @AuraEnabled
  public String status { get; set; }
  @AuraEnabled
  public Datetime submittedOn { get; set; }
}
