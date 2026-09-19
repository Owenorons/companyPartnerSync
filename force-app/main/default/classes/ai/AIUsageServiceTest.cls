@IsTest
private class AIUsageServiceTest {
  @IsTest
  static void pendingJobsConsumeQuotaBeforeAnyInsightExists() {
    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(adminUser.Id, 'PartnerSync_AI_Admin');
    System.runAs(adminUser) {
      Account partner = PartnerSyncTestDataFactory.partnerAccount('Quota');
      insert partner;
      enableAI(1);
      AIInsightGenerationQueueable.skipExecutionForTest = true;
      Test.startTest();
      Id jobId = AIInsightController.enqueueInsight(request(partner.Id));
      Assert.isNotNull(jobId);
      Assert.areEqual(0, [SELECT COUNT() FROM AI_Insight__c]);
      Assert.areEqual(
        1,
        [SELECT Reserved_Count__c FROM AI_Usage_Day__c LIMIT 1]
        .Reserved_Count__c
      );
      try {
        AIInsightGeneratorService.generate(request(partner.Id));
        Assert.fail('A pending job must consume the last slot.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('daily AI request limit'));
      }
      Assert.areEqual(1, Limits.getQueueableJobs());
      Test.stopTest();
      TenantConfigService.clearCacheForTest();
    }
  }

  @IsTest
  static void rejectedInputDoesNotReserveQuota() {
    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(adminUser.Id, 'PartnerSync_AI_Admin');
    System.runAs(adminUser) {
      enableAI(1);
      try {
        AIInsightGeneratorService.generate(null);
        Assert.fail('Invalid requests must fail before reservation.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('Insight type'));
      }
      Assert.areEqual(0, [SELECT COUNT() FROM AI_Usage_Day__c]);
      Assert.areEqual(0, Limits.getQueueableJobs());
      TenantConfigService.clearCacheForTest();
    }
  }

  @IsTest
  static void firstReservationIncludesExistingInsightsAndUsesANewUtcDay() {
    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(adminUser.Id, 'PartnerSync_AI_Admin');
    System.runAs(adminUser) {
      enableAI(2);
      Account partner = PartnerSyncTestDataFactory.partnerAccount(
        'Legacy usage'
      );
      insert partner;
      insert new AI_Insight__c(
        Partner_Account__c = partner.Id,
        Status__c = 'Draft'
      );
      insert new AI_Usage_Day__c(
        Day_Key__c = String.valueOf(System.now().dateGMT().addDays(-1)),
        Reserved_Count__c = 999
      );
      Date today = AIUsageService.reserve();
      Assert.areEqual(System.now().dateGMT(), today);
      String key = String.valueOf(today);
      Assert.areEqual(
        2,
        [SELECT Reserved_Count__c FROM AI_Usage_Day__c WHERE Day_Key__c = :key]
        .Reserved_Count__c
      );
      try {
        AIUsageService.reserve();
        Assert.fail('Existing insights plus pending work must count.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('daily AI request limit'));
      }
      TenantConfigService.clearCacheForTest();
    }
  }

  @IsTest
  static void uniqueDayKeyPreventsTwoFirstRequestCounters() {
    String key = String.valueOf(System.now().dateGMT());
    insert new AI_Usage_Day__c(Day_Key__c = key, Reserved_Count__c = 1);
    Database.SaveResult duplicate = Database.insert(
      new AI_Usage_Day__c(Day_Key__c = key, Reserved_Count__c = 1),
      false
    );
    Assert.isFalse(duplicate.isSuccess());
    Assert.areEqual(
      StatusCode.DUPLICATE_VALUE,
      duplicate.getErrors()[0].getStatusCode()
    );
  }

  @IsTest
  static void expiredReservationCannotCallProvider() {
    Test.startTest();
    try {
      new AIInsightGenerationQueueable(
          new AIInsightRequestDTO(),
          System.now().dateGMT().addDays(-1)
        )
        .execute(null);
      Assert.fail('A job delayed into the next UTC day must expire.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains('reservation expired'));
    }
    Assert.areEqual(0, Limits.getCallouts());
    Test.stopTest();
  }

  @IsTest
  static void reservationRollsBackWithItsTransaction() {
    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(adminUser.Id, 'PartnerSync_AI_Admin');
    System.runAs(adminUser) {
      enableAI(1);
      Savepoint beforeReservation = Database.setSavepoint();
      AIUsageService.reserve();
      Database.rollback(beforeReservation);
      Assert.areEqual(0, [SELECT COUNT() FROM AI_Usage_Day__c]);
      AIUsageService.reserve();
      Assert.areEqual(
        1,
        [SELECT Reserved_Count__c FROM AI_Usage_Day__c LIMIT 1]
        .Reserved_Count__c
      );
      TenantConfigService.clearCacheForTest();
    }
  }

  @IsTest
  static void parseLimitTreatsZeroAsABlockingLimitAndNegativeAsUnlimited() {
    // Exercises the actual metadata-string parsing (unlike the other tests
    // here, which use testDailyLimit to bypass it) since Apex tests cannot
    // insert a Tenant_Config__mdt record to drive this through getDailyLimit().
    Assert.areEqual(
      0,
      AIUsageService.parseLimit('0'),
      'A configured limit of zero must block every request, not be treated as unlimited.'
    );
    Assert.areEqual(
      500,
      AIUsageService.parseLimit('500'),
      'A positive configured limit must parse to its numeric value.'
    );
    Assert.isNull(
      AIUsageService.parseLimit('-1'),
      'A negative value is not a valid limit and must retain unlimited behavior.'
    );
    Assert.isNull(
      AIUsageService.parseLimit('not-a-number'),
      'A nonnumeric value must retain unlimited behavior rather than fail closed.'
    );
  }

  private static void enableAI(Integer dailyLimit) {
    TenantConfigService.setConfigForTest(
      new Tenant_Config__mdt(Enable_AI__c = true)
    );
    AIUsageService.testDailyLimit = dailyLimit;
  }

  private static AIInsightRequestDTO request(Id accountId) {
    AIInsightRequestDTO value = new AIInsightRequestDTO();
    value.partnerAccountId = accountId;
    value.insightType = 'LeadFitScoring';
    return value;
  }
}
