/*
 * Admin service backing the AI provider configuration UI: joins the
 * AI_Provider_Config__mdt catalog with per-provider connection status
 * recorded in AI_Configuration__c (see AIConnectionTestService).
 */
public with sharing class AIProviderAdminService {
  public static List<AIProviderStatusDTO> getProviders() {
    PartnerPermissionService.assertCanConfigureAI();

    Map<String, AI_Configuration__c> statusByProvider = AIProviderSelector.selectStatusByProvider();

    List<AIProviderStatusDTO> results = new List<AIProviderStatusDTO>();

    List<AI_Provider_Config__mdt> providers = AIProviderSelector.selectAllProviders();

    for (AI_Provider_Config__mdt provider : providers) {
      AIProviderStatusDTO dto = new AIProviderStatusDTO();
      dto.developerName = provider.DeveloperName;
      dto.providerName = provider.Provider_Name__c;
      dto.providerType = provider.Provider_Type__c;
      dto.active = provider.Active__c;

      AI_Configuration__c status = statusByProvider.get(provider.DeveloperName);

      if (status != null) {
        dto.connectionStatus = status.Connection_Status__c;
        dto.lastTestDate = status.Last_Test_Date__c;
        dto.lastTestResult = status.Last_Test_Result__c;
      } else {
        dto.connectionStatus = 'Not Tested';
      }

      results.add(dto);
    }

    return results;
  }
}
