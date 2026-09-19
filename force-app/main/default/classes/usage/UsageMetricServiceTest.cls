@IsTest
private class UsageMetricServiceTest {
  @IsTest
  static void logPersistsMetricWithSuppliedTypeAndAccount() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Metrics');
    insert partner;
    TenantConfigService.setConfigForTest(
      new Tenant_Config__mdt(Edition__c = 'Gold')
    );

    UsageMetricService.log(
      partner.Id,
      UsageMetricService.METRIC_TYPE_DEAL_SUBMITTED
    );

    Usage_Metric__c metric = [
      SELECT
        Partner_Account__c,
        Metric_Type__c,
        Quantity__c,
        Metric_Date__c,
        License_Tier__c
      FROM Usage_Metric__c
      LIMIT 1
    ];
    Assert.areEqual(partner.Id, metric.Partner_Account__c);
    Assert.areEqual('Deal Submitted', metric.Metric_Type__c);
    Assert.areEqual(1, metric.Quantity__c);
    Assert.areEqual(Date.today(), metric.Metric_Date__c);
    Assert.areEqual('Gold', metric.License_Tier__c);

    TenantConfigService.clearCacheForTest();
  }

  @IsTest
  static void logAllowsNullPartnerAccountForNotificationSent() {
    UsageMetricService.log(
      null,
      UsageMetricService.METRIC_TYPE_NOTIFICATION_SENT
    );

    List<Usage_Metric__c> metrics = [
      SELECT Partner_Account__c, Metric_Type__c
      FROM Usage_Metric__c
    ];
    Assert.areEqual(1, metrics.size());
    Assert.isNull(metrics[0].Partner_Account__c);
    Assert.areEqual('Notification Sent', metrics[0].Metric_Type__c);
  }

  @IsTest
  static void logSwallowsFailureAndNeverThrows() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Metrics Fail');
    insert partner;

    try {
      // Metric_Type__c is required=true; a null value deterministically
      // forces a DML failure without depending on picklist restriction.
      UsageMetricService.log(partner.Id, null);
    } catch (Exception unexpected) {
      Assert.fail('log() must never let a DML failure escape to its caller.');
    }

    Assert.areEqual(0, [SELECT COUNT() FROM Usage_Metric__c]);
  }

  @IsTest
  static void logSucceedsForPartnerUserWithNoDirectObjectAccess() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Metrics Partner'
    );
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;
    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    System.runAs(partnerUser) {
      Assert.isFalse(
        Schema.sObjectType.Usage_Metric__c.isCreateable(),
        'This test only proves something if the partner user truly lacks direct create access.'
      );
      UsageMetricService.log(
        partner.Id,
        UsageMetricService.METRIC_TYPE_MDF_REQUEST
      );
    }

    Assert.areEqual(1, [SELECT COUNT() FROM Usage_Metric__c]);
  }
}
