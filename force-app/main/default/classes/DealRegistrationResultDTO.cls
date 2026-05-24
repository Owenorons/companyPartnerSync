public with sharing class DealRegistrationResultDTO {
  @AuraEnabled
  public Id dealRegistrationId;
  @AuraEnabled
  public String dealRegistrationNumber;
  @AuraEnabled
  public String status;
  @AuraEnabled
  public String conflictStatus;
}
