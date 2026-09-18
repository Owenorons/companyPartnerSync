/**
 * DTO carrying one AI provider's config plus its live connection status
 * to the admin provider list UI.
 */
public with sharing class AIProviderStatusDTO {
  /**
   * DeveloperName of the AI_Provider_Config__mdt record.
   */
  @AuraEnabled
  public String developerName { get; set; }
  /**
   * Display name of the provider.
   */
  @AuraEnabled
  public String providerName { get; set; }
  /**
   * Provider type (e.g. OpenAI, AzureOpenAI).
   */
  @AuraEnabled
  public String providerType { get; set; }
  /**
   * Whether the provider is configured as active.
   */
  @AuraEnabled
  public Boolean active { get; set; }
  /**
   * Most recently recorded connection status (e.g. Connected, Failed, Not Tested).
   */
  @AuraEnabled
  public String connectionStatus { get; set; }
  /**
   * Date/time the connection was last tested.
   */
  @AuraEnabled
  public Datetime lastTestDate { get; set; }
  /**
   * Outcome message from the last connection test.
   */
  @AuraEnabled
  public String lastTestResult { get; set; }
}
