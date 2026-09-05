/*
 * Aura-enabled entry point for the partner portal's AI surfaces (insight
 * list, next best actions). AIInsightController is the equivalent
 * surface for internal/admin users.
 */
public with sharing class PartnerAIController {
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
