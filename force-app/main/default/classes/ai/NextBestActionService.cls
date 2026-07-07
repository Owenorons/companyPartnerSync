public with sharing class NextBestActionService {
  public static List<NextBestActionDTO> getMyActions() {
    if (!TenantConfigService.isAiEnabled()) {
      throw new PartnerSyncHandledException('AI recommendations are disabled.');
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();
    List<NextBestActionDTO> actions = new List<NextBestActionDTO>();

    for (
      AI_Insight__c insight : AIInsightSelector.selectPartnerInsights(
        partnerAccountId
      )
    ) {
      if (String.isBlank(insight.Recommendation__c)) {
        continue;
      }

      NextBestActionDTO action = new NextBestActionDTO();
      action.actionId = insight.Id;
      action.title = buildTitle(insight.Feature_Name__c);
      action.recommendation = insight.Recommendation__c;
      action.reason = insight.Insight_Text__c;
      action.sourceSignal = insight.Feature_Name__c;
      action.confidence = insight.Confidence__c;
      action.priority = getPriority(insight.Confidence__c);
      actions.add(action);

      if (actions.size() == 5) {
        break;
      }
    }

    return actions;
  }

  private static String buildTitle(String featureName) {
    if (String.isBlank(featureName)) {
      return 'Recommended action';
    }

    return featureName + ' recommendation';
  }

  private static String getPriority(Decimal confidence) {
    if (confidence == null) {
      return 'Medium';
    }

    if (confidence >= 80) {
      return 'High';
    }

    if (confidence >= 50) {
      return 'Medium';
    }

    return 'Low';
  }
}
