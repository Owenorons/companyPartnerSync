/*
 * Result payload returned to the LWC layer after a partner application is
 * submitted — just enough to confirm what was created and its resulting
 * status, without exposing the full application record.
 */
public with sharing class PartnerApplicationResultDTO {
  @AuraEnabled
  public Id applicationId { get; set; }
  @AuraEnabled
  public String applicationNumber { get; set; }
  @AuraEnabled
  public String status { get; set; }
}
