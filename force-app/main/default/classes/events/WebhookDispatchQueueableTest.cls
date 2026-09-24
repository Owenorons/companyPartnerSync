@IsTest
private class WebhookDispatchQueueableTest {
  private static WebhookDispatchQueueable.Delivery delivery(
    Integer attemptNumber,
    Integer maxRetries
  ) {
    WebhookDispatchQueueable.Delivery delivery = new WebhookDispatchQueueable.Delivery();
    delivery.endpointDeveloperName = 'Test_Endpoint';
    delivery.url = 'https://webhook.example.test/partnersync';
    delivery.timeoutSeconds = 10;
    delivery.maxRetries = maxRetries;
    delivery.attemptNumber = attemptNumber;
    delivery.eventType = 'DealSubmitted';
    delivery.payload = '{"eventType":"DealSubmitted"}';
    return delivery;
  }

  @IsTest
  static void exhaustedRetriesStillLogTheFinalFailedAttempt() {
    Test.setMock(
      HttpCalloutMock.class,
      new WebhookCalloutMock(503, 'Service Unavailable')
    );

    // maxRetries == attemptNumber: this is already the last allowed try,
    // so no further retry should be scheduled after it fails.
    Test.startTest();
    new WebhookDispatchQueueable(
        new List<WebhookDispatchQueueable.Delivery>{ delivery(2, 2) }
      )
      .execute(null);
    Test.stopTest();

    Webhook_Delivery_Attempt__c attempt = [
      SELECT Status__c, Attempt_Number__c, Response_Code__c
      FROM Webhook_Delivery_Attempt__c
      LIMIT 1
    ];
    Assert.areEqual('Failed', attempt.Status__c);
    Assert.areEqual(2, attempt.Attempt_Number__c);
    Assert.areEqual(503, attempt.Response_Code__c);
  }

  @IsTest
  static void calloutExceptionIsRecordedAsAFailedAttempt() {
    Test.setMock(HttpCalloutMock.class, new ThrowingCalloutMock());

    Test.startTest();
    new WebhookDispatchQueueable(
        new List<WebhookDispatchQueueable.Delivery>{ delivery(1, 0) }
      )
      .execute(null);
    Test.stopTest();

    Webhook_Delivery_Attempt__c attempt = [
      SELECT Status__c, Error_Detail__c, Response_Code__c
      FROM Webhook_Delivery_Attempt__c
      LIMIT 1
    ];
    Assert.areEqual('Failed', attempt.Status__c);
    Assert.isNull(attempt.Response_Code__c);
    Assert.isTrue(attempt.Error_Detail__c.contains('Simulated outage'));
  }

  private class ThrowingCalloutMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest request) {
      throw new CalloutException('Simulated outage');
    }
  }
}
