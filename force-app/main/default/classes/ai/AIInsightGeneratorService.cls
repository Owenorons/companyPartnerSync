/**
 * Entry point for generating an AI insight. Generation is asynchronous:
 * quota reservation and enqueue commit before the provider callout. The
 * returned Id identifies the AsyncApexJob.
 */
public with sharing class AIInsightGeneratorService {
  /**
   * Enqueues asynchronous AI insight generation for a request.
   *
   * @param request The insight generation request.
   * @return Id of the queued AsyncApexJob.
   */
  public static Id generate(AIInsightRequestDTO request) {
    return AIInsightGenerationQueueable.enqueue(request);
  }

  /**
   * Validates that AI insight generation is permitted and well-formed for
   * a request: caller permission, tenant AI enablement, request contents,
   * and insight create access.
   *
   * @param request The insight generation request to validate.
   */
  public static void validate(AIInsightRequestDTO request) {
    PartnerPermissionService.assertCanGenerateAIInsights();
    if (!TenantConfigService.isAiEnabled()) {
      throw new PartnerSyncHandledException('AI insights are disabled.');
    }
    validateRequest(request);
    SecurityUtil.assertCreateable(AI_Insight__c.SObjectType);
  }

  private static void validateRequest(AIInsightRequestDTO request) {
    if (request == null || String.isBlank(request.insightType)) {
      throw new PartnerSyncHandledException('Insight type is required.');
    }
    if (request.partnerAccountId == null) {
      throw new PartnerSyncHandledException('Partner account is required.');
    }
    if (
      [SELECT COUNT() FROM Account WHERE Id = :request.partnerAccountId] != 1
    ) {
      throw new PartnerSyncHandledException('Partner account not found.');
    }
    AI_Feature_Config__mdt feature = AI_Feature_Config__mdt.getInstance(
      request.insightType
    );
    if (feature == null || !feature.Enabled__c) {
      throw new PartnerSyncHandledException(
        'The requested AI feature is not enabled.'
      );
    }
    sanitizeContext(request.contextData);
  }

  private static void sanitizeContext(Map<String, Object> contextData) {
    if (contextData == null) {
      return;
    }
    if (
      contextData.size() > 30 ||
      JSON.serialize(contextData).length() > 12000
    ) {
      throw new PartnerSyncHandledException('AI context is too large.');
    }
    for (String key : contextData.keySet()) {
      Object value = contextData.get(key);
      if (
        String.isBlank(key) ||
        key.length() > 80 ||
        value instanceof Map<String, Object> ||
        value instanceof List<Object>
      ) {
        throw new PartnerSyncHandledException(
          'AI context contains an unsupported value.'
        );
      }
      if (value != null && String.valueOf(value).length() > 2000) {
        throw new PartnerSyncHandledException('AI context value is too large.');
      }
    }
  }
}
