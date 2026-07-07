public with sharing class PartnerAIController {
  @AuraEnabled(cacheable=true)
  public static List<AIInsightDTO> getMyInsights() {
    try {
      return AIInsightService.getMyInsights();
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'PartnerAIController',
        'Unable to load AI insights.',
        ex
      );

      throw new AuraHandledException('Unable to load AI insights.');
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<NextBestActionDTO> getMyNextBestActions() {
    try {
      return NextBestActionService.getMyActions();
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'PartnerAIController',
        'Unable to load next best actions.',
        ex
      );

      throw new AuraHandledException('Unable to load next best actions.');
    }
  }
}
