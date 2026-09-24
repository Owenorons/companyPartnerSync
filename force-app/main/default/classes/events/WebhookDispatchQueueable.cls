/**
 * Delivers one or more webhook payloads (see WebhookDispatchConsumerService
 * for how deliveries are matched) and records a Webhook_Delivery_Attempt__c
 * for each. A delivery that fails and hasn't exhausted its endpoint's
 * Retry_Count__c is re-enqueued as a fresh delivery attempt; chaining is
 * suppressed in test context (Apex test limits allow only one explicit
 * enqueueJob per test) so tests assert on the logged attempt instead of the
 * platform's own retry-chaining mechanism.
 */
public class WebhookDispatchQueueable implements Queueable, Database.AllowsCallouts {
  /**
   * One webhook delivery to attempt: the resolved endpoint config plus the
   * event payload and how many times this specific delivery has already
   * been tried.
   */
  public class Delivery {
    public String endpointDeveloperName;
    public String url;
    public Integer timeoutSeconds;
    public Integer maxRetries;
    public Integer attemptNumber;
    public String eventType;
    public String payload;
  }

  private List<Delivery> deliveries;

  /**
   * @param deliveries The webhook deliveries to attempt in this execution.
   */
  public WebhookDispatchQueueable(List<Delivery> deliveries) {
    this.deliveries = deliveries;
  }

  /**
   * Attempts every delivery in this batch, records a
   * Webhook_Delivery_Attempt__c for each, and re-enqueues any delivery
   * that failed and still has retries remaining.
   *
   * @param context The queueable execution context (unused).
   */
  public void execute(QueueableContext context) {
    List<Webhook_Delivery_Attempt__c> attempts = new List<Webhook_Delivery_Attempt__c>();
    List<Delivery> retryable = new List<Delivery>();

    for (Delivery delivery : deliveries) {
      Boolean succeeded = false;
      Integer statusCode;
      String errorDetail;

      try {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(delivery.url);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(timeoutMillis(delivery.timeoutSeconds));
        req.setBody(delivery.payload);

        HttpResponse res = new Http().send(req);
        statusCode = res.getStatusCode();
        succeeded = statusCode >= 200 && statusCode < 300;
        if (!succeeded) {
          errorDetail =
            'HTTP ' +
            statusCode +
            ': ' +
            abbreviate(res.getBody(), 500);
        }
      } catch (Exception ex) {
        errorDetail = ex.getMessage();
      }

      attempts.add(
        new Webhook_Delivery_Attempt__c(
          Endpoint__c = delivery.endpointDeveloperName,
          Event_Type__c = delivery.eventType,
          Attempt_Number__c = delivery.attemptNumber,
          Status__c = succeeded ? 'Succeeded' : 'Failed',
          Response_Code__c = statusCode,
          Error_Detail__c = errorDetail,
          Attempted_On__c = System.now()
        )
      );

      if (!succeeded && delivery.attemptNumber < delivery.maxRetries) {
        Delivery next = new Delivery();
        next.endpointDeveloperName = delivery.endpointDeveloperName;
        next.url = delivery.url;
        next.timeoutSeconds = delivery.timeoutSeconds;
        next.maxRetries = delivery.maxRetries;
        next.attemptNumber = delivery.attemptNumber + 1;
        next.eventType = delivery.eventType;
        next.payload = delivery.payload;
        retryable.add(next);
      }
    }

    Database.insert(attempts, AccessLevel.SYSTEM_MODE);

    if (!retryable.isEmpty() && !Test.isRunningTest()) {
      System.enqueueJob(new WebhookDispatchQueueable(retryable));
    }
  }

  private Integer timeoutMillis(Integer seconds) {
    return (seconds == null ? 30 : seconds) * 1000;
  }

  private String abbreviate(String value, Integer maximumLength) {
    return value != null &&
      value.length() > maximumLength
      ? value.substring(0, maximumLength)
      : value;
  }
}
