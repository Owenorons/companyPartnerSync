public with sharing class PartnerApplicationResultDTO {
  @AuraEnabled
  public Id applicationId;
  @AuraEnabled
  public String applicationNumber;
  @AuraEnabled
  public String status;
}
