@IsTest
private class PartnerSyncPostInstallTest {
  @IsTest
  static void administratorSchedulesOperationalAutomationThroughFacade() {
    User administrator = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      administrator.Id,
      'PartnerSync_Internal_Admin'
    );

    System.runAs(administrator) {
      Test.startTest();
      PartnerSyncPostInstall.scheduleOperationalAutomation();
      Test.stopTest();

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
}
