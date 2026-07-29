/*
 * Aura-enabled entry point for the internal-user AI insight admin UI:
 * generating an insight on demand, listing configured providers, and
 * testing a provider's connection. Restricted to internal users;
 * PartnerAIController is the equivalent surface for partner users.
 */
public with sharing class AIInsightController {
  @AuraEnabled
  public static AIInsightDTO generateInsight(AIInsightRequestDTO request) {
    try {
      PartnerAccessService.assertInternalUser();

      AI_Insight__c insight = AIInsightGeneratorService.generate(request);

      return AIInsightDomain.toDTO(insight);
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'AIInsightController',
        'Unable to generate AI insight.',
        ex
      );
      throw new AuraHandledException('Unable to generate AI insight.');
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<AIProviderStatusDTO> getProviders() {
    try {
      return AIProviderAdminService.getProviders();
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'AIInsightController',
        'Unable to load AI providers.',
        ex
      );
      throw new AuraHandledException('Unable to load AI providers.');
    }
  }

  @AuraEnabled
  public static String testProviderConnection(String providerDeveloperName) {
    try {
      PartnerAccessService.assertInternalUser();

      AIProviderResponseDTO response = AIConnectionTestService.testConnection(
        providerDeveloperName
      );

      if (!response.success) {
        throw new PartnerSyncHandledException(response.errorMessage);
      }

      return 'Connection successful.';
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'AIInsightController',
        'Unable to test AI provider connection.',
        ex
      );
      throw new AuraHandledException('Unable to test AI provider connection.');
    }
  }
}
