/**
 * Records feedback on an AI recommendation or legacy insight. Thin insert,
 * no state machine.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class AIFeedbackService {
  /**
   * Submits feedback on exactly one of a recommendation or an insight.
   *
   * @param recommendationId Id of the AI_Recommendation__c this feedback concerns, or null.
   * @param insightId Id of the AI_Insight__c this feedback concerns, or null.
   * @param rating 'Helpful' or 'Not Helpful'.
   * @param reason Optional free-text reason.
   * @return The inserted feedback record.
   */
  public static AI_Feedback__c submit(
    Id recommendationId,
    Id insightId,
    String rating,
    String reason
  ) {
    if (recommendationId == null && insightId == null) {
      throw new PartnerSyncHandledException(
        'Feedback must target a recommendation or an insight.'
      );
    }
    if (recommendationId != null && insightId != null) {
      throw new PartnerSyncHandledException(
        'Feedback may target only one of a recommendation or an insight, not both.'
      );
    }
    if (String.isBlank(rating)) {
      throw new PartnerSyncHandledException('A rating is required.');
    }

    AI_Feedback__c feedback = new AI_Feedback__c(
      Recommendation__c = recommendationId,
      Insight__c = insightId,
      Rating__c = rating,
      Reason__c = reason,
      Submitted_By__c = UserInfo.getUserId()
    );
    Database.insert(feedback, AccessLevel.SYSTEM_MODE);
    return feedback;
  }
}
