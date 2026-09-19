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
}
