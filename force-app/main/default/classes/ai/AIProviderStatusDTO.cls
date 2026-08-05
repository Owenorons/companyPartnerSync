/*
 * DTO carrying one AI provider's config plus its live connection status
 * to the admin provider list UI.
 */
public with sharing class AIProviderStatusDTO {
  @AuraEnabled
  public String developerName { get; set; }
  @AuraEnabled
  public String providerName { get; set; }
  @AuraEnabled
  public String providerType { get; set; }
  @AuraEnabled
  public Boolean active { get; set; }
  @AuraEnabled
  public String connectionStatus { get; set; }
  @AuraEnabled
  public Datetime lastTestDate { get; set; }
  @AuraEnabled
  public String lastTestResult { get; set; }
}
