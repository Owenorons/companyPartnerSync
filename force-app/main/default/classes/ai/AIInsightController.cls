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
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'AIInsightController',
        'Unable to generate AI insight.',
        'Unable to generate AI insight.',
        ex
      );
    }
  }

  @AuraEnabled
  public static Id enqueueInsight(AIInsightRequestDTO request) {
    try {
      PartnerPermissionService.assertCanGenerateAIInsights();
      return System.enqueueJob(new AIInsightGenerationQueueable(request));
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'AIInsightController',
        'Unable to queue AI insight generation.',
        'Unable to queue AI insight generation.',
        ex
      );
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<AIInsightDTO> getPendingReview() {
    try {
      return AIInsightGovernanceService.getPendingReview();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'AIInsightController',
        'Unable to load AI insights for review.',
        'Unable to load AI insights for review.',
        ex
      );
    }
  }

  @AuraEnabled
  public static AIInsightDTO reviewInsight(
    Id insightId,
    String decision,
    String recommendation
  ) {
    try {
      return AIInsightGovernanceService.decide(
        insightId,
        decision,
        recommendation
      );
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'AIInsightController',
        'Unable to review AI insight.',
        'Unable to review AI insight.',
        ex
      );
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<AIProviderStatusDTO> getProviders() {
    try {
      return AIProviderAdminService.getProviders();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'AIInsightController',
        'Unable to load AI providers.',
        'Unable to load AI providers.',
        ex
      );
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
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'AIInsightController',
        'Unable to test AI provider connection.',
        'Unable to test AI provider connection.',
        ex
      );
    }
  }
}
