/*
 * DTO carrying one AI provider's config plus its live connection status
 * to the admin provider list UI.
 */
public with sharing class AIProviderStatusDTO {
  @AuraEnabled
  public String developerName;
  @AuraEnabled
  public String providerName;
  @AuraEnabled
  public String providerType;
  @AuraEnabled
  public Boolean active;
  @AuraEnabled
  public String connectionStatus;
  @AuraEnabled
  public Datetime lastTestDate;
  @AuraEnabled
  public String lastTestResult;
}
