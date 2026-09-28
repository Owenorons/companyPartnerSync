/**
 * Aura controller surface for Sprint 43: the internal-only portfolio
 * intelligence panel queue view and AI feedback submission. Pure
 * pass-through/exception-translation layer, mirroring
 * CustomerSuccessController's shape - no business logic here.
 */
public with sharing class PortfolioIntelligenceController {
  /**
   * Loads the most recent portfolio snapshot for each partner, for the
   * Customer Success Workbench's portfolio panel.
   *
   * @return Up to 200 of the most recently computed snapshots, one per partner.
   */
  @AuraEnabled(cacheable=true)
  public static List<Partner_Portfolio_Snapshot__c> getAllSnapshots() {
    try {
      if (
        !PartnerAccessService.isInternalUser() ||
        !DealLifecyclePermissionService.hasPermission(
          'PartnerSync_View_Portfolio_Intelligence'
        )
      ) {
        throw new PartnerSyncHandledException(
          'Current user lacks authority to view portfolio intelligence.'
        );
      }
      return [
        SELECT
          Partner_Account__c,
          Partner_Account__r.Name,
          Snapshot_Date__c,
          Health_Score__c,
          Health_Label__c,
          At_Risk_Deal_Count__c,
          At_Risk_Engagement_Count__c,
          Upcoming_Renewal_Count__c,
          Renewal_Value_At_Risk__c,
          Narrative__c
        FROM Partner_Portfolio_Snapshot__c
        WHERE Snapshot_Date__c = TODAY
        WITH SYSTEM_MODE
        ORDER BY Health_Score__c ASC NULLS LAST
        LIMIT 200
      ];
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PortfolioIntelligenceController',
        'Unable to load portfolio snapshots.',
        'Unable to load portfolio snapshots.',
        ex
      );
    }
  }

  /**
   * Loads open AI recommendations, for the portfolio panel's action queue.
   *
   * @return Up to 200 Proposed recommendations.
   */
  @AuraEnabled(cacheable=true)
  public static List<AI_Recommendation__c> getProposedRecommendations() {
    try {
      PartnerAccessService.assertInternalUser();
      return [
        SELECT
          Related_Object__c,
          Related_Record_Id__c,
          Partner_Account__r.Name,
          Recommended_Action_Key__c,
          Recommendation_Text__c,
          Confidence__c
        FROM AI_Recommendation__c
        WHERE Status__c = 'Proposed'
        WITH SYSTEM_MODE
        ORDER BY CreatedDate ASC
        LIMIT 200
      ];
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PortfolioIntelligenceController',
        'Unable to load proposed recommendations.',
        'Unable to load proposed recommendations.',
        ex
      );
    }
  }

  /**
   * Executes a proposed AI recommendation.
   *
   * @param recommendationId Id of the Proposed recommendation to execute.
   * @param reason Optional reason to pass through to the underlying command.
   * @return The updated recommendation.
   */
  @AuraEnabled
  public static AI_Recommendation__c executeRecommendation(
    Id recommendationId,
    String reason
  ) {
    try {
      return AgentActionGatewayService.executeAction(recommendationId, reason);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PortfolioIntelligenceController',
        'Unable to execute the recommendation.',
        'Unable to execute the recommendation.',
        ex
      );
    }
  }

  /**
   * Submits feedback on a recommendation. A partner caller may only
   * target a recommendation for their own partner account.
   *
   * @param recommendationId Id of the AI_Recommendation__c this feedback concerns.
   * @param rating 'Helpful' or 'Not Helpful'.
   * @param reason Optional free-text reason.
   * @return The inserted feedback record.
   */
  @AuraEnabled
  public static AI_Feedback__c submitFeedback(
    Id recommendationId,
    String rating,
    String reason
  ) {
    try {
      if (!PartnerAccessService.isInternalUser()) {
        if (
          !DealLifecyclePermissionService.hasPermission(
            'PartnerSync_Submit_AI_Feedback'
          )
        ) {
          throw new PartnerSyncHandledException(
            'Current user lacks authority to submit AI feedback.'
          );
        }
        List<AI_Recommendation__c> rows = [
          SELECT Partner_Account__c
          FROM AI_Recommendation__c
          WHERE Id = :recommendationId
          WITH SYSTEM_MODE
        ];
        if (
          rows.isEmpty() ||
          rows[0].Partner_Account__c !=
          PartnerAccessService.getCurrentPartnerAccountId()
        ) {
          throw new PartnerSyncHandledException(
            'Recommendation not accessible.'
          );
        }
      }
      return AIFeedbackService.submit(recommendationId, null, rating, reason);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PortfolioIntelligenceController',
        'Unable to submit feedback.',
        'Unable to submit feedback.',
        ex
      );
    }
  }
}
