@IsTest
private class PartnerSyncSetupControllerTest {
  @IsTest
  static void returnsReadinessReportForPartnerSyncAdministrator() {
    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      adminUser.Id,
      'PartnerSync_Internal_Admin'
    );

    System.runAs(adminUser) {
      Test.startTest();
      PartnerSyncSetupController.ReadinessReport report = PartnerSyncSetupController.getReadiness();
      Test.stopTest();

      Assert.areEqual(10, report.totalCount);
      Assert.isTrue(report.readyCount > 0);
      Assert.isNotNull(report.generatedAt);
      Assert.isNotNull(report.coreReady);
      Assert.isNotNull(report.portalReady);

      Set<String> checkKeys = new Set<String>();
      for (
        PartnerSyncSetupController.ReadinessCheck readinessCheck : report.checks
      ) {
        checkKeys.add(readinessCheck.key);
        Assert.isNotNull(readinessCheck.label);
        Assert.isNotNull(readinessCheck.status);
        Assert.isNotNull(readinessCheck.detail);
        Assert.isNotNull(readinessCheck.action);
      }
      Assert.isTrue(checkKeys.contains('core-metadata'));
      Assert.isTrue(checkKeys.contains('experience-cloud'));
      Assert.isTrue(checkKeys.contains('scheduled-automation'));
      Assert.isTrue(checkKeys.contains('dead-letter-backlog'));
      Assert.isTrue(checkKeys.contains('ai-usage-health'));
      Assert.isTrue(checkKeys.contains('analytics-freshness'));
    }
  }

  @IsTest
  static void rejectsInternalUserWithoutSetupPermission() {
    User internalUser = TestUserFactory.createInternalUser();

    System.runAs(internalUser) {
      try {
        PartnerSyncSetupController.getReadiness();
        Assert.fail('Expected setup access to be denied.');
      } catch (PartnerSyncHandledException expectedError) {
        Assert.isTrue(expectedError.getMessage().contains('Internal Admin'));
      }
    }
  }

  @IsTest
  static void configuresOperationalAutomationIdempotently() {
    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      adminUser.Id,
      'PartnerSync_Internal_Admin'
    );
    System.runAs(adminUser) {
      PartnerSyncSetupController.ReadinessReport configured = PartnerSyncSetupController.configureOperationalAutomation();
      Assert.areEqual('READY', statusFor(configured, 'scheduled-automation'));
      PartnerSyncSetupController.ReadinessReport repeated = PartnerSyncSetupController.configureOperationalAutomation();
      Assert.areEqual('READY', statusFor(repeated, 'scheduled-automation'));
      Assert.areEqual(
        5,
        [
          SELECT COUNT()
          FROM CronTrigger
          WHERE CronJobDetail.Name LIKE 'PartnerSync%'
        ]
      );
    }
  }

  @IsTest
  static void reportsOptionalAndMissingConfigurationStates() {
    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      adminUser.Id,
      'PartnerSync_Internal_Admin'
    );
    System.runAs(adminUser) {
      PartnerSyncSetupController.installedPermissionGroupsOverride = new Set<String>();
      PartnerSyncSetupController.onboardingRuleCountOverride = 0;
      PartnerSyncSetupController.liveSiteCountOverride = 1;
      PartnerSyncSetupController.activeAiProviderCountOverride = 1;
      try {
        PartnerSyncSetupController.ReadinessReport report = PartnerSyncSetupController.getReadiness();
        Assert.areEqual(
          'ACTION_REQUIRED',
          statusFor(report, 'permission-groups')
        );
        Assert.areEqual(
          'ACTION_REQUIRED',
          statusFor(report, 'onboarding-policy')
        );
        Assert.areEqual('READY', statusFor(report, 'experience-cloud'));
        Assert.areEqual('READY', statusFor(report, 'ai-configuration'));
      } finally {
        PartnerSyncSetupController.installedPermissionGroupsOverride = null;
        PartnerSyncSetupController.onboardingRuleCountOverride = null;
        PartnerSyncSetupController.liveSiteCountOverride = null;
        PartnerSyncSetupController.activeAiProviderCountOverride = null;
      }
    }
  }

  @IsTest
  static void reportsDeadLetterBacklogAndAiUsageFailuresAsWarnings() {
    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      adminUser.Id,
      'PartnerSync_Internal_Admin'
    );
    System.runAs(adminUser) {
      PartnerSyncSetupController.deadLetterBacklogCountOverride = 2;
      PartnerSyncSetupController.activeAiProviderCountOverride = 1;
      PartnerSyncSetupController.aiInteractionFailureCountOverride = 3;
      try {
        PartnerSyncSetupController.ReadinessReport report = PartnerSyncSetupController.getReadiness();
        Assert.areEqual('WARNING', statusFor(report, 'dead-letter-backlog'));
        Assert.areEqual('WARNING', statusFor(report, 'ai-usage-health'));
      } finally {
        PartnerSyncSetupController.deadLetterBacklogCountOverride = null;
        PartnerSyncSetupController.activeAiProviderCountOverride = null;
        PartnerSyncSetupController.aiInteractionFailureCountOverride = null;
      }
    }
  }

  @IsTest
  static void aiUsageHealthIsReadyWhenNoProviderIsActive() {
    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      adminUser.Id,
      'PartnerSync_Internal_Admin'
    );
    System.runAs(adminUser) {
      PartnerSyncSetupController.activeAiProviderCountOverride = 0;
      try {
        PartnerSyncSetupController.ReadinessReport report = PartnerSyncSetupController.getReadiness();
        Assert.areEqual('READY', statusFor(report, 'ai-usage-health'));
      } finally {
        PartnerSyncSetupController.activeAiProviderCountOverride = null;
      }
    }
  }

  @IsTest
  static void analyticsFreshnessIsWarningWhenNoSnapshotHasBeenComputed() {
    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      adminUser.Id,
      'PartnerSync_Internal_Admin'
    );
    System.runAs(adminUser) {
      PartnerSyncSetupController.ReadinessReport report = PartnerSyncSetupController.getReadiness();
      Assert.areEqual('WARNING', statusFor(report, 'analytics-freshness'));
    }
  }

  @IsTest
  static void analyticsFreshnessIsReadyWhenTheLatestSnapshotIsRecent() {
    insert new Executive_Snapshot__c(
      Snapshot_Date__c = Date.today(),
      Computed_On__c = System.now()
    );

    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      adminUser.Id,
      'PartnerSync_Internal_Admin'
    );
    System.runAs(adminUser) {
      PartnerSyncSetupController.ReadinessReport report = PartnerSyncSetupController.getReadiness();
      Assert.areEqual('READY', statusFor(report, 'analytics-freshness'));
    }
  }

  @IsTest
  static void analyticsFreshnessIsWarningWhenTheLatestSnapshotIsStale() {
    insert new Executive_Snapshot__c(
      Snapshot_Date__c = Date.today().addDays(-3),
      Computed_On__c = System.now().addDays(-3)
    );

    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      adminUser.Id,
      'PartnerSync_Internal_Admin'
    );
    System.runAs(adminUser) {
      PartnerSyncSetupController.ReadinessReport report = PartnerSyncSetupController.getReadiness();
      Assert.areEqual('WARNING', statusFor(report, 'analytics-freshness'));
    }
  }

  private static String statusFor(
    PartnerSyncSetupController.ReadinessReport report,
    String key
  ) {
    for (
      PartnerSyncSetupController.ReadinessCheck readinessCheck : report.checks
    ) {
      if (readinessCheck.key == key)
        return readinessCheck.status;
    }
    return null;
  }
}
