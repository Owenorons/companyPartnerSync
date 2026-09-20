@IsTest
private class PartnerProvisioningQueueableTest {
  private static Partner_Application__c createQueuedApplication(
    Datetime startedOn,
    String jobId
  ) {
    Partner_Application__c application = new Partner_Application__c(
      Name = 'Provisioning Recovery Test',
      Company_Name__c = 'Provisioning Recovery Test',
      Business_Email__c = 'provisioning-recovery@example.com',
      Application_Status__c = 'Approved',
      Decision__c = 'Approved',
      Provisioning_Status__c = 'Queued',
      Provisioning_Started_On__c = startedOn,
      Provisioning_Job_Id__c = jobId
    );
    insert application;
    return application;
  }

  @IsTest
  static void statusQueueableRecordsSuccessfulProvisioning() {
    User provisionedUser = TestUserFactory.createInternalUser();
    Partner_Application__c application = createQueuedApplication(
      System.now(),
      '707000000000001AAA'
    );

    new PartnerProvisioningStatusQueueable(
        application.Id,
        provisionedUser.Id,
        null,
        '707000000000001AAA'
      )
      .execute(null);

    Partner_Application__c updated = selectProvisioningState(application.Id);
    System.assertEquals('Complete', updated.Provisioning_Status__c);
    System.assertEquals(provisionedUser.Id, updated.Provisioned_User__c);
    System.assertNotEquals(null, updated.Provisioned_On__c);
    System.assertEquals(null, updated.Provisioning_Error__c);
    System.assertEquals(null, updated.Provisioning_Job_Id__c);
  }

  @IsTest
  static void statusQueueableRecordsAndTruncatesFailure() {
    Partner_Application__c application = createQueuedApplication(
      System.now(),
      '707000000000002AAA'
    );
    String longError = ''.leftPad(33000, 'x');

    new PartnerProvisioningStatusQueueable(
        application.Id,
        null,
        longError,
        '707000000000002AAA'
      )
      .execute(null);

    Partner_Application__c updated = selectProvisioningState(application.Id);
    System.assertEquals('Failed', updated.Provisioning_Status__c);
    System.assertEquals(32768, updated.Provisioning_Error__c.length());
    System.assertEquals(null, updated.Provisioning_Job_Id__c);
  }

  @IsTest
  static void staleStatusJobCannotOverwriteCurrentRequest() {
    Partner_Application__c application = createQueuedApplication(
      System.now(),
      '707000000000003AAA'
    );

    new PartnerProvisioningStatusQueueable(
        application.Id,
        null,
        'Old request failed.',
        '707000000000004AAA'
      )
      .execute(null);

    Partner_Application__c unchanged = selectProvisioningState(application.Id);
    System.assertEquals('Queued', unchanged.Provisioning_Status__c);
    System.assertEquals('707000000000003AAA', unchanged.Provisioning_Job_Id__c);
    System.assertEquals(null, unchanged.Provisioning_Error__c);
  }

  @IsTest
  static void reconcilerFailsQueuedRequestOlderThanTwentyFourHours() {
    Partner_Application__c stale = createQueuedApplication(
      System.now().addHours(-25),
      null
    );

    new PartnerProvisioningReconciler().execute(null);

    Partner_Application__c updated = selectProvisioningState(stale.Id);
    System.assertEquals('Failed', updated.Provisioning_Status__c);
    System.assert(updated.Provisioning_Error__c.contains('Retry provisioning'));
    System.assertEquals(null, updated.Provisioning_Job_Id__c);
  }

  @IsTest
  static void reconcilerLeavesRecentQueuedRequestAlone() {
    Partner_Application__c recent = createQueuedApplication(
      System.now().addHours(-23),
      null
    );

    new PartnerProvisioningReconciler().execute(null);

    Partner_Application__c unchanged = selectProvisioningState(recent.Id);
    System.assertEquals('Queued', unchanged.Provisioning_Status__c);
    System.assertEquals(null, unchanged.Provisioning_Error__c);
  }

  @IsTest
  static void reconcilerAbortsAStaleRunningJob() {
    Test.startTest();
    Id queuedJobId = Database.executeBatch(
      new ProvisioningNoOpBatchTestHelper(),
      1
    );
    Partner_Application__c stale = createQueuedApplication(
      System.now().addHours(-25),
      String.valueOf(queuedJobId)
    );
    new PartnerProvisioningReconciler().execute(null);
    Partner_Application__c updated = selectProvisioningState(stale.Id);
    Assert.areEqual('Failed', updated.Provisioning_Status__c);
    Assert.isTrue(updated.Provisioning_Error__c.contains('Retry provisioning'));
    Test.stopTest();
  }

  private static Partner_Application__c selectProvisioningState(
    Id applicationId
  ) {
    return [
      SELECT
        Provisioning_Status__c,
        Provisioning_Error__c,
        Provisioning_Job_Id__c,
        Provisioned_User__c,
        Provisioned_On__c
      FROM Partner_Application__c
      WHERE Id = :applicationId
    ];
  }
}
