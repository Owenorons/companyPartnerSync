/**
 * Aura controller surface for Sprint 45's operations console: dead-letter
 * queue visibility/redrive plus AI interaction/recommendation health -
 * closing both the "nothing ever reads Event_DLQ__c" gap and the
 * long-standing "psAiGovernanceConsole has no page" gap in one internal
 * screen. Pure pass-through/exception-translation layer; the real retry/
 * acknowledge logic lives in EventDLQService, matching every other
 * controller in this codebase.
 */
public with sharing class PartnerSyncOperationsConsoleController {
  private static final Integer MAX_DEAD_LETTER_ROWS = 50;

  /**
   * Loads the operations health summary: dead-letter counts by status (plus
   * the most recent rows needing attention) and AI interaction/
   * recommendation health counts.
   *
   * @return The operations health summary.
   */
  @AuraEnabled(cacheable=true)
  public static OperationsHealthDTO getOperationsHealth() {
    try {
      PartnerAccessService.assertInternalUser();

      OperationsHealthDTO result = new OperationsHealthDTO();
      result.newDeadLetterCount = [
        SELECT COUNT()
        FROM Event_DLQ__c
        WHERE Status__c = 'New'
        WITH SYSTEM_MODE
      ];
      result.failedDeadLetterCount = [
        SELECT COUNT()
        FROM Event_DLQ__c
        WHERE Status__c = 'Failed'
        WITH SYSTEM_MODE
      ];
      result.retriedDeadLetterCount = [
        SELECT COUNT()
        FROM Event_DLQ__c
        WHERE Status__c = 'Retried'
        WITH SYSTEM_MODE
      ];

      for (Event_DLQ__c row : [
        SELECT
          Event_Type__c,
          Status__c,
          Retry_Count__c,
          Last_Retry_On__c,
          Error_Message__c,
          CreatedDate
        FROM Event_DLQ__c
        WHERE Status__c IN ('New', 'Failed')
        WITH SYSTEM_MODE
        ORDER BY CreatedDate DESC
        LIMIT :MAX_DEAD_LETTER_ROWS
      ]) {
        result.deadLetters.add(toDeadLetterDTO(row));
      }

      result.aiFailedInteractionCount = [
        SELECT COUNT()
        FROM AI_Interaction__c
        WHERE Status__c = 'Failed'
        WITH SYSTEM_MODE
      ];
      result.aiBlockedInteractionCount = [
        SELECT COUNT()
        FROM AI_Interaction__c
        WHERE Status__c IN ('Blocked-Policy', 'Blocked-Quota')
        WITH SYSTEM_MODE
      ];
      result.aiProposedRecommendationCount = [
        SELECT COUNT()
        FROM AI_Recommendation__c
        WHERE Status__c = 'Proposed'
        WITH SYSTEM_MODE
      ];
      result.aiFailedRecommendationCount = [
        SELECT COUNT()
        FROM AI_Recommendation__c
        WHERE Status__c = 'Failed'
        WITH SYSTEM_MODE
      ];

      return result;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerSyncOperationsConsoleController',
        'Unable to load the operations health summary.',
        'Unable to load the operations health summary.',
        ex
      );
    }
  }

  /**
   * Redrives a single dead-lettered event.
   *
   * @param dlqId Id of the Event_DLQ__c row to retry.
   */
  @AuraEnabled
  public static void retryDeadLetter(Id dlqId) {
    try {
      EventDLQService.retry(dlqId);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerSyncOperationsConsoleController',
        'Unable to retry the event.',
        'Unable to retry the event.',
        ex
      );
    }
  }

  /**
   * Marks a dead-lettered event Resolved without retrying it.
   *
   * @param dlqId Id of the Event_DLQ__c row to acknowledge.
   */
  @AuraEnabled
  public static void acknowledgeDeadLetter(Id dlqId) {
    try {
      EventDLQService.acknowledge(dlqId);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerSyncOperationsConsoleController',
        'Unable to acknowledge the event.',
        'Unable to acknowledge the event.',
        ex
      );
    }
  }

  private static DeadLetterRowDTO toDeadLetterDTO(Event_DLQ__c row) {
    DeadLetterRowDTO dto = new DeadLetterRowDTO();
    dto.dlqId = row.Id;
    dto.eventType = row.Event_Type__c;
    dto.status = row.Status__c;
    dto.retryCount = row.Retry_Count__c == null
      ? 0
      : Integer.valueOf(row.Retry_Count__c);
    dto.lastRetryOn = row.Last_Retry_On__c;
    dto.errorMessage = row.Error_Message__c;
    dto.createdOn = row.CreatedDate;
    return dto;
  }
}
