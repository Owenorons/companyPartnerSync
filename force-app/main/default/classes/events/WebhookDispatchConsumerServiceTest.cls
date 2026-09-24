@IsTest
private class WebhookDispatchConsumerServiceTest {
  private static Webhook_Endpoint__mdt endpoint(String filter) {
    return new Webhook_Endpoint__mdt(
      DeveloperName = 'Test_Endpoint',
      URL__c = 'https://webhook.example.test/partnersync',
      Event_Filter__c = filter,
      Retry_Count__c = 2,
      Timeout_Seconds__c = 15
    );
  }

  private static PartnerSync_Event__e testEvent() {
    return new PartnerSync_Event__e(
      Event_Type__c = 'DealSubmitted',
      Object_Name__c = 'Deal_Registration__c',
      Summary__c = 'Deal registration submitted for review.',
      Occurred_On__c = System.now()
    );
  }

  @IsTest
  static void dispatchIsANoOpWhenWebhooksDisabled() {
    WebhookDispatchConsumerService.testEndpoints = new List<Webhook_Endpoint__mdt>{
      endpoint('All')
    };

    Test.startTest();
    WebhookDispatchConsumerService.dispatchBusinessEvent(testEvent());
    Test.stopTest();

    Assert.areEqual(
      0,
      [SELECT COUNT() FROM Webhook_Delivery_Attempt__c],
      'Webhook dispatch defaults to disabled until Tenant_Config__mdt.Enable_Webhooks__c is turned on.'
    );
  }

  @IsTest
  static void dispatchSkipsEndpointNotMatchingFilter() {
    TenantConfigService.setConfigForTest(
      new Tenant_Config__mdt(Enable_Webhooks__c = true)
    );
    WebhookDispatchConsumerService.testEndpoints = new List<Webhook_Endpoint__mdt>{
      endpoint('SomeOtherEvent')
    };

    Test.startTest();
    WebhookDispatchConsumerService.dispatchBusinessEvent(testEvent());
    Test.stopTest();

    Assert.areEqual(
      0,
      [SELECT COUNT() FROM Webhook_Delivery_Attempt__c],
      'An endpoint whose filter does not match the event type should not be delivered to.'
    );
  }

  @IsTest
  static void dispatchLogsSucceededAttemptForMatchingActiveEndpoint() {
    TenantConfigService.setConfigForTest(
      new Tenant_Config__mdt(Enable_Webhooks__c = true)
    );
    WebhookDispatchConsumerService.testEndpoints = new List<Webhook_Endpoint__mdt>{
      endpoint('All')
    };
    Test.setMock(HttpCalloutMock.class, new WebhookCalloutMock(200, '{}'));

    Test.startTest();
    WebhookDispatchConsumerService.dispatchBusinessEvent(testEvent());
    Test.stopTest();

    Webhook_Delivery_Attempt__c attempt = [
      SELECT Status__c, Response_Code__c, Attempt_Number__c, Endpoint__c
      FROM Webhook_Delivery_Attempt__c
      LIMIT 1
    ];
    Assert.areEqual('Succeeded', attempt.Status__c);
    Assert.areEqual(200, attempt.Response_Code__c);
    Assert.areEqual(1, attempt.Attempt_Number__c);
    Assert.areEqual('Test_Endpoint', attempt.Endpoint__c);
  }

  @IsTest
  static void dispatchLogsFailedAttemptOnNonSuccessResponse() {
    TenantConfigService.setConfigForTest(
      new Tenant_Config__mdt(Enable_Webhooks__c = true)
    );
    WebhookDispatchConsumerService.testEndpoints = new List<Webhook_Endpoint__mdt>{
      endpoint('DealSubmitted')
    };
    Test.setMock(
      HttpCalloutMock.class,
      new WebhookCalloutMock(500, 'Internal Server Error')
    );

    Test.startTest();
    WebhookDispatchConsumerService.dispatchBusinessEvent(testEvent());
    Test.stopTest();

    Webhook_Delivery_Attempt__c attempt = [
      SELECT Status__c, Response_Code__c, Error_Detail__c
      FROM Webhook_Delivery_Attempt__c
      LIMIT 1
    ];
    Assert.areEqual('Failed', attempt.Status__c);
    Assert.areEqual(500, attempt.Response_Code__c);
    Assert.isTrue(attempt.Error_Detail__c.contains('500'));
  }
}
