/**
 * Cross-cutting operational health summary (dead letters + AI governance
 * health), for PartnerSyncOperationsConsoleController. Closes the
 * long-standing gap that AI interaction/recommendation health had no
 * internal page of its own.
 */
public class OperationsHealthDTO {
  @AuraEnabled
  public Integer newDeadLetterCount;
  @AuraEnabled
  public Integer failedDeadLetterCount;
  @AuraEnabled
  public Integer retriedDeadLetterCount;
  @AuraEnabled
  public List<DeadLetterRowDTO> deadLetters;
  @AuraEnabled
  public Integer aiFailedInteractionCount;
  @AuraEnabled
  public Integer aiBlockedInteractionCount;
  @AuraEnabled
  public Integer aiProposedRecommendationCount;
  @AuraEnabled
  public Integer aiFailedRecommendationCount;

  public OperationsHealthDTO() {
    deadLetters = new List<DeadLetterRowDTO>();
  }
}
