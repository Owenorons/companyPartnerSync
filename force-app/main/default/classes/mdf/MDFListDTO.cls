/*
 * DTO for a single MDF request row, used by both the partner's "my
 * requests" list and the internal review queue.
 */
public with sharing class MDFListDTO {
  @AuraEnabled
  public Id requestId;

  @AuraEnabled
  public String requestNumber;

  @AuraEnabled
  public String partnerName;

  @AuraEnabled
  public String campaignName;

  @AuraEnabled
  public String requestType;

  @AuraEnabled
  public Decimal requestedAmount;

  @AuraEnabled
  public Decimal approvedAmount;

  @AuraEnabled
  public String status;

  @AuraEnabled
  public Date startDate;

  @AuraEnabled
  public Date endDate;
}
