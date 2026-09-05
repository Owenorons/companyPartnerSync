/** Persists the immediate EventBus acceptance result for operational review. */
public without sharing class EventPublicationService {
  @SuppressWarnings('PMD.ApexCRUDViolation')
  public static void record(
    String eventName,
    String eventType,
    String eventId,
    String eventVersion,
    String correlationId,
    String idempotencyKey,
    Database.SaveResult result
  ) {
    try {
      String errorDetail;
      if (!result.isSuccess()) {
        List<String> errors = new List<String>();
        for (Database.Error error : result.getErrors())
          errors.add(error.getStatusCode() + ': ' + error.getMessage());
        errorDetail = String.join(errors, ' | ');
      }
      insert new Event_Publication__c(
        Event_Name__c = abbreviate(eventName, 100),
        Event_Type__c = abbreviate(eventType, 100),
        Event_Id__c = eventId,
        Event_Version__c = eventVersion,
        Correlation_Id__c = correlationId,
        Idempotency_Key__c = idempotencyKey,
        Status__c = result.isSuccess() ? 'Accepted' : 'Failed',
        Replay_Id__c = result.isSuccess()
          ? String.valueOf(result.getId())
          : null,
        Error_Detail__c = errorDetail,
        Published_On__c = System.now()
      );
    } catch (Exception ex) {
      LoggingService.error(
        'EventPublicationService',
        'Unable to persist the platform-event publication result.',
        ex
      );
    }
  }

  private static String abbreviate(String value, Integer maximumLength) {
    return value != null &&
      value.length() > maximumLength
      ? value.substring(0, maximumLength)
      : value;
  }
}
