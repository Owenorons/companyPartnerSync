/**
 * Aura-enabled entry point for the partner portal's AI surfaces (insight
 * list, next best actions). AIInsightController is the equivalent
 * surface for internal/admin users.
 */
public with sharing class PartnerAIController {
  /**
   * Lists the running partner user's accepted AI insights.
   *
   * @return AI insights for the running user's partner account.
   */
  @AuraEnabled(cacheable=true)
  public static List<AIInsightDTO> getMyInsights() {
    try {
      return AIInsightService.getMyInsights();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerAIController',
        'Unable to load AI insights.',
        'Unable to load AI insights.',
        ex
      );
    }
  }

  /**
   * Lists the running partner user's next-best-action recommendations.
   *
   * @return Next best action DTOs derived from the running user's AI insights.
   */
  @AuraEnabled(cacheable=true)
  public static List<NextBestActionDTO> getMyNextBestActions() {
    try {
      return NextBestActionService.getMyActions();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerAIController',
        'Unable to load next best actions.',
        'Unable to load next best actions.',
        ex
      );
    }
  }

  /**
   * Lists the active AI feature types a partner may request an insight
   * for.
   *
   * @return Active insight type label/value pairs.
   */
  @AuraEnabled(cacheable=true)
  public static List<AIInsightTypeDTO> getInsightTypes() {
    try {
      List<AIInsightTypeDTO> results = new List<AIInsightTypeDTO>();
      for (
        AI_Feature_Config__mdt feature : AIInsightSelector.selectActiveFeatureTypes()
      ) {
        results.add(AIInsightDomain.toTypeDTO(feature));
      }
      return results;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerAIController',
        'Unable to load AI insight types.',
        'Unable to load AI insight types.',
        ex
      );
    }
  }

  /**
   * Submits an AI insight request for the running partner's own account.
   * Generation itself is internal-only; this lands in the governance
   * console's pending-requests queue for a reviewer to action.
   *
   * @param insightType DeveloperName of the requested AI_Feature_Config__mdt.
   * @param notes The partner's free-text context for the request.
   */
  @AuraEnabled
  public static void submitInsightRequest(String insightType, String notes) {
    try {
      AIInsightRequestService.submitRequest(insightType, notes);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerAIController',
        'Unable to submit AI insight request.',
        'Unable to submit AI insight request.',
        ex
      );
    }
  }

  /**
   * Lists the running partner user's own AI insight requests.
   *
   * @return The caller's own requests as list DTOs.
   */
  @AuraEnabled(cacheable=true)
  public static List<AIInsightRequestListDTO> getMyInsightRequests() {
    try {
      List<AIInsightRequestListDTO> results = new List<AIInsightRequestListDTO>();
      for (
        AI_Insight_Request__c request : AIInsightRequestService.getMyRequests()
      ) {
        AI_Feature_Config__mdt feature = AI_Feature_Config__mdt.getInstance(
          request.Insight_Type__c
        );
        results.add(
          AIInsightDomain.toRequestDTO(
            request,
            feature == null ? request.Insight_Type__c : feature.Feature_Name__c
          )
        );
      }
      return results;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerAIController',
        'Unable to load AI insight requests.',
        'Unable to load AI insight requests.',
        ex
      );
    }
  }
}
