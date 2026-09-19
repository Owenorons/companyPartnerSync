/**
 * Human-governance boundary for model output. Draft insights are never
 * partner-visible; an authorized reviewer must explicitly accept or dismiss
 * them, optionally correcting the recommendation before acceptance.
 */
public with sharing class AIInsightGovernanceService {
  /**
   * Lists AI insights awaiting human review, asserting reviewer permission first.
   *
   * @return AI insights in Draft or Reviewed status, oldest first, limited to 200.
   */
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

  /**
   * Records a reviewer's accept/dismiss decision on a draft or reviewed AI
   * insight, asserting reviewer permission, locking the row, and
   * validating the transition and (on acceptance) that a summary and
   * recommendation are present.
   *
   * @param insightId Id of the AI_Insight__c to decide.
   * @param decision The review decision, 'Accepted' or 'Dismissed'.
   * @param recommendation Optional replacement recommendation text to apply on acceptance; falls back to the insight's existing recommendation when blank.
   * @return The updated insight as a DTO.
   */
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
    persistDecision(insight, decision);

    AuditLogRequestDTO audit = AuditFactory.createSuccess(
      'AI_Insight__c',
      insight.Id,
      decision == 'Accepted' ? 'Accept AI Insight' : 'Dismiss AI Insight'
    );
    audit.partnerAccountId = insight.Partner_Account__c;
    AuditService.log(audit);
    return AIInsightDomain.toDTO(insight);
  }

  // Deliberate, privileged FLS bypass: Status__c and Recommendation__c are
  // editable=false in every permission set (including PartnerSync_AI_Admin),
  // by design, so only this reviewer-permission-gated write path can change
  // them. The recommendation text is reviewer-supplied, not system-computed,
  // so this write is authorized by assertCanReviewAIInsights() and the row
  // lock/transition validation above it, not by any claim that the data is
  // trusted. Plain DML always bypasses FLS; `with sharing` only enforces
  // record-level visibility, not field-level security, so it does not make
  // this write safe on its own.
  @SuppressWarnings('PMD.ApexCRUDViolation')
  private static void persistDecision(AI_Insight__c insight, String decision) {
    AI_Insight__c changes = new AI_Insight__c(
      Id = insight.Id,
      Status__c = decision
    );
    if (decision == 'Accepted')
      changes.Recommendation__c = insight.Recommendation__c;
    update changes;
  }
}
