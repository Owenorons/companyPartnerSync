/* Human-governance boundary for model output. Draft insights are never
 * partner-visible; an authorized reviewer must explicitly accept or dismiss
 * them, optionally correcting the recommendation before acceptance. */
public with sharing class AIInsightGovernanceService {
  public static List<AIInsightDTO> getPendingReview() {
    PartnerPermissionService.assertCanReviewAIInsights();
    List<AIInsightDTO> results = new List<AIInsightDTO>();
    for (AI_Insight__c row : [
      SELECT
        Id,
        Partner_Account__c,
        Feature_Name__c,
        Provider__c,
        Confidence__c,
        Insight_Text__c,
        Recommendation__c,
        Status__c,
        CreatedDate
      FROM AI_Insight__c
      WHERE Status__c IN ('Draft', 'Reviewed')
      WITH USER_MODE
      ORDER BY CreatedDate ASC
      LIMIT 200
    ]) {
      results.add(AIInsightDomain.toDTO(row));
    }
    return results;
  }

  public static AIInsightDTO decide(
    Id insightId,
    String decision,
    String recommendation
  ) {
    PartnerPermissionService.assertCanReviewAIInsights();
    if (
      insightId == null || (decision != 'Accepted' && decision != 'Dismissed')
    ) {
      throw new PartnerSyncHandledException(
        'A valid AI review decision is required.'
      );
    }
    AI_Insight__c insight = [
      SELECT
        Id,
        Partner_Account__c,
        Feature_Name__c,
        Provider__c,
        Confidence__c,
        Insight_Text__c,
        Recommendation__c,
        Status__c,
        CreatedDate
      FROM AI_Insight__c
      WHERE Id = :insightId
      WITH USER_MODE
      LIMIT 1
      FOR UPDATE
    ];
    if (insight.Status__c != 'Draft' && insight.Status__c != 'Reviewed') {
      throw new PartnerSyncHandledException(
        'This AI insight has already been decided.'
      );
    }
    if (decision == 'Accepted') {
      String finalRecommendation = String.isBlank(recommendation)
        ? insight.Recommendation__c
        : recommendation.trim();
      if (
        String.isBlank(insight.Insight_Text__c) ||
        String.isBlank(finalRecommendation)
      ) {
        throw new PartnerSyncHandledException(
          'A summary and recommendation are required before acceptance.'
        );
      }
      insight.Recommendation__c = finalRecommendation.left(32768);
    }
    insight.Status__c = decision;
    SecurityUtil.assertUpdateable(AI_Insight__c.SObjectType);
    update SecurityUtil.stripForUpdate(new List<SObject>{ insight });

    AuditLogRequestDTO audit = AuditFactory.createSuccess(
      'AI_Insight__c',
      insight.Id,
      decision == 'Accepted' ? 'Accept AI Insight' : 'Dismiss AI Insight'
    );
    audit.partnerAccountId = insight.Partner_Account__c;
    AuditService.log(audit);
    return AIInsightDomain.toDTO(insight);
  }
}
