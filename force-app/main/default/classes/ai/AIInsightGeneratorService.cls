/*
 * Orchestrates on-demand AI insight generation: checks the tenant AI
 * feature flag, resolves a provider through AIProviderRouter, renders the
 * feature's prompt template, and persists the result as an AI_Insight__c.
 */
public with sharing class AIInsightGeneratorService {
  public static AI_Insight__c generate(AIInsightRequestDTO request) {
    if (!TenantConfigService.isAiEnabled()) {
      throw new PartnerSyncHandledException('AI insights are disabled.');
    }

    if (request == null || String.isBlank(request.insightType)) {
      throw new PartnerSyncHandledException('Insight type is required.');
    }

    AIProvider provider = AIProviderRouter.getProvider(request.insightType);

    AIProviderRequestDTO providerRequest = new AIProviderRequestDTO();
    providerRequest.featureName = request.insightType;
    providerRequest.prompt = buildPrompt(request);
    providerRequest.contextData = request.contextData;

    AIProviderResponseDTO providerResponse = provider.generate(providerRequest);

    AI_Insight__c insight = buildInsight(request, providerResponse);

    SecurityUtil.assertCreateable(AI_Insight__c.SObjectType);
    insert SecurityUtil.stripForCreate(new List<SObject>{ insight });

    AuditLogRequestDTO audit = AuditFactory.createSuccess(
      'AI_Insight__c',
      insight.Id,
      'Generate'
    );
    audit.partnerAccountId = request.partnerAccountId;
    AuditService.log(audit);

    return insight;
  }

  private static String buildPrompt(AIInsightRequestDTO request) {
    AI_Feature_Config__mdt feature = AI_Feature_Config__mdt.getInstance(
      request.insightType
    );

    String template = feature == null ||
      String.isBlank(feature.Prompt_Template__c)
      ? 'Analyze the following data and provide a recommendation: {context}'
      : feature.Prompt_Template__c;

    String contextJson = request.contextData == null
      ? '{}'
      : JSON.serialize(request.contextData);

    return template.replace('{context}', contextJson);
  }

  private static AI_Insight__c buildInsight(
    AIInsightRequestDTO request,
    AIProviderResponseDTO response
  ) {
    // Persisted even on provider failure, with Status__c = 'Draft' and the
    // error message in Insight_Text__c, so a failed generation is visible
    // to admins for follow-up instead of silently disappearing.
    AI_Insight__c insight = new AI_Insight__c();
    insight.Partner_Account__c = request.partnerAccountId;
    insight.Feature_Name__c = request.insightType;
    insight.Provider__c = response.providerName;
    insight.Confidence__c = response.confidence;
    insight.Status__c = response.success ? 'Generated' : 'Draft';
    insight.Insight_Text__c = response.success
      ? response.responseText
      : 'AI provider unavailable: ' + response.errorMessage;

    return insight;
  }
}
