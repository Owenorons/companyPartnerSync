/*
 * Covers ExecutiveCommandCenterController: an internal user with the
 * executive analytics permission sees the snapshot/metric
 * definitions/trend/export, a user without it is rejected from every
 * method, and the CSV export contains a real row derived from the
 * snapshot's actual field values.
 */
@IsTest
private class ExecutiveCommandCenterControllerTest {
  @IsTest
  static void executiveUserSeesSnapshotDefinitionsAndTrend() {
    createFixture();
    User executiveUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      executiveUser.Id,
      'PartnerSync_Executive_User'
    );

    System.runAs(executiveUser) {
      ExecutiveSnapshotDTO latest = ExecutiveCommandCenterController.getLatestSnapshot();
      Assert.isNotNull(latest);
      Assert.areEqual(2, latest.activePartnerCount);

      List<Metric_Definition__mdt> definitions = ExecutiveCommandCenterController.getMetricDefinitions();
      Assert.isTrue(definitions.size() > 0);

      List<ExecutiveSnapshotDTO> trend = ExecutiveCommandCenterController.getTrend(
        30
      );
      Assert.areEqual(1, trend.size());
    }
  }

  @IsTest
  static void nonExecutiveUserIsRejectedFromEveryMethod() {
    createFixture();
    User plainUser = TestUserFactory.createInternalUser();

    System.runAs(plainUser) {
      try {
        ExecutiveCommandCenterController.getLatestSnapshot();
        Assert.fail('Expected a non-executive user to be rejected.');
      } catch (AuraHandledException expected) {
        Assert.isTrue(true);
      }
      try {
        ExecutiveCommandCenterController.getMetricDefinitions();
        Assert.fail('Expected a non-executive user to be rejected.');
      } catch (AuraHandledException expected) {
        Assert.isTrue(true);
      }
      try {
        ExecutiveCommandCenterController.getTrend(30);
        Assert.fail('Expected a non-executive user to be rejected.');
      } catch (AuraHandledException expected) {
        Assert.isTrue(true);
      }
      try {
        ExecutiveCommandCenterController.exportSnapshotCsv();
        Assert.fail('Expected a non-executive user to be rejected.');
      } catch (AuraHandledException expected) {
        Assert.isTrue(true);
      }
    }
  }

  @IsTest
  static void exportCsvContainsARealRowFromTheSnapshotsActualValues() {
    createFixture();
    User executiveUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      executiveUser.Id,
      'PartnerSync_Executive_User'
    );

    System.runAs(executiveUser) {
      String csv = ExecutiveCommandCenterController.exportSnapshotCsv();
      List<String> lines = csv.split('\n');
      Assert.areEqual(2, lines.size());
      Assert.isTrue(lines[0].contains('Open Deals'));
      Assert.isTrue(lines[1].contains('3'));
    }
  }

  private static void createFixture() {
    Account partnerOne = PartnerSyncTestDataFactory.partnerAccount(
      'Executive Controller Partner One'
    );
    Account partnerTwo = PartnerSyncTestDataFactory.partnerAccount(
      'Executive Controller Partner Two'
    );
    insert new List<Account>{ partnerOne, partnerTwo };

    insert new Partner_Portfolio_Snapshot__c(
      Partner_Account__c = partnerOne.Id,
      Snapshot_Date__c = Date.today(),
      Health_Score__c = 80,
      Open_Deal_Count__c = 2
    );
    insert new Partner_Portfolio_Snapshot__c(
      Partner_Account__c = partnerTwo.Id,
      Snapshot_Date__c = Date.today(),
      Health_Score__c = 60,
      Open_Deal_Count__c = 1
    );

    ExecutiveSnapshotBatch.compute();
  }
}
