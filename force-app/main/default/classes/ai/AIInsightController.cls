/**
 * Aura-enabled entry point for the internal-user AI insight admin UI:
 * generating an insight on demand, listing configured providers, and
 * testing a provider's connection. Restricted to internal users;
 * PartnerAIController is the equivalent surface for partner users.
 */
public with sharing class AIInsightController {
  /**
   * Generates an AI insight for an internal user, asserting internal-user
   * access before delegating to AIInsightGeneratorService.
   *
   * @param request The insight generation request.
   * @return Id of the queued AsyncApexJob generating the insight.
   */
  @AuraEnabled
  public static Id generateInsight(AIInsightRequestDTO request) {
    try {
      PartnerAccessService.assertInternalUser();

      return AIInsightGeneratorService.generate(request);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'AIInsightController',
        'Unable to generate AI insight.',
        'Unable to generate AI insight.',
        ex
      );
    }
  }

  /**
   * Queues AI insight generation for a permitted caller, asserting the
   * generate-insights permission before delegating to
   * AIInsightGeneratorService.
   *
   * @param request The insight generation request.
   * @return Id of the queued AsyncApexJob generating the insight.
   */
  @AuraEnabled
  public static Id enqueueInsight(AIInsightRequestDTO request) {
    try {
      PartnerPermissionService.assertCanGenerateAIInsights();
      return AIInsightGeneratorService.generate(request);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'AIInsightController',
        'Unable to queue AI insight generation.',
        'Unable to queue AI insight generation.',
        ex
      );
    }
  }

  /**
   * Lists the active AI feature types available to generate an insight
   * against, for the governance console's generate form.
   *
   * @return Active insight type label/value pairs.
   */
  @AuraEnabled(cacheable=true)
  public static List<AIInsightTypeDTO> getInsightTypes() {
    try {
      PartnerAccessService.assertInternalUser();
      List<AIInsightTypeDTO> results = new List<AIInsightTypeDTO>();
      for (
        AI_Feature_Config__mdt feature : AIInsightSelector.selectActiveFeatureTypes()
      ) {
        results.add(AIInsightDomain.toTypeDTO(feature));
      }
      return results;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'AIInsightController',
        'Unable to load AI insight types.',
        'Unable to load AI insight types.',
        ex
      );
    }
  }

  /**
   * Lists partner-submitted AI insight requests awaiting internal action.
   *
   * @return New AI_Insight_Request__c records as list DTOs.
   */
  @AuraEnabled(cacheable=true)
  public static List<AIInsightRequestListDTO> getPendingRequests() {
    try {
      List<AIInsightRequestListDTO> results = new List<AIInsightRequestListDTO>();
      for (
        AI_Insight_Request__c request : AIInsightRequestService.getPendingRequests()
      ) {
        results.add(
          AIInsightDomain.toRequestDTO(
            request,
            labelFor(request.Insight_Type__c)
          )
        );
      }
      return results;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'AIInsightController',
        'Unable to load AI insight requests.',
        'Unable to load AI insight requests.',
        ex
      );
    }
  }

  /**
   * Marks a partner's request Actioned, for the reviewer to then generate
   * against using the pre-filled partner/type.
   *
   * @param requestId Id of the AI_Insight_Request__c to action.
   * @return The updated request as a list DTO.
   */
  @AuraEnabled
  public static AIInsightRequestListDTO actionRequest(Id requestId) {
    try {
      AI_Insight_Request__c request = AIInsightRequestService.actionRequest(
        requestId
      );
      return AIInsightDomain.toRequestDTO(
        request,
        labelFor(request.Insight_Type__c)
      );
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'AIInsightController',
        'Unable to action AI insight request.',
        'Unable to action AI insight request.',
        ex
      );
    }
  }

  /**
   * Marks a partner's request Dismissed.
   *
   * @param requestId Id of the AI_Insight_Request__c to dismiss.
   */
  @AuraEnabled
  public static void dismissRequest(Id requestId) {
    try {
      AIInsightRequestService.dismissRequest(requestId);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'AIInsightController',
        'Unable to dismiss AI insight request.',
        'Unable to dismiss AI insight request.',
        ex
      );
    }
  }

  private static String labelFor(String insightType) {
    AI_Feature_Config__mdt feature = AI_Feature_Config__mdt.getInstance(
      insightType
    );
    return feature == null ? insightType : feature.Feature_Name__c;
  }

  /**
   * Lists AI insights awaiting human review.
   *
   * @return AI insights in Draft or Reviewed status, oldest first.
   */
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

  /**
   * Records a reviewer's accept/dismiss decision on a draft AI insight,
   * optionally overriding its recommendation text.
   *
   * @param insightId Id of the AI_Insight__c to decide.
   * @param decision The review decision, 'Accepted' or 'Dismissed'.
   * @param recommendation Optional replacement recommendation text to apply on acceptance.
   * @return The updated insight as a DTO.
   */
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

  /**
   * Lists configured AI providers along with their current connection status.
   *
   * @return AI provider status DTOs for the admin provider list UI.
   */
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

  /**
   * Runs a live connection test against a configured AI provider.
   *
   * @param providerDeveloperName DeveloperName of the AI_Provider_Config__mdt to test.
   * @return A success message when the test connection succeeds.
   */
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
