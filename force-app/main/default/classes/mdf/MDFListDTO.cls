/*
 * DTO for a single MDF request row, used by both the partner's "my
 * requests" list and the internal review queue.
 */
public with sharing class MDFListDTO {
  @AuraEnabled
  public Id requestId { get; set; }

  @AuraEnabled
  public String requestNumber { get; set; }

  @AuraEnabled
  public String partnerName { get; set; }

  @AuraEnabled
  public String campaignName { get; set; }

  @AuraEnabled
  public String requestType { get; set; }

  @AuraEnabled
  public Decimal requestedAmount { get; set; }

  @AuraEnabled
  public Decimal approvedAmount { get; set; }

  @AuraEnabled
  public String status { get; set; }

  @AuraEnabled
  public Date startDate { get; set; }

  @AuraEnabled
  public Date endDate { get; set; }
}
