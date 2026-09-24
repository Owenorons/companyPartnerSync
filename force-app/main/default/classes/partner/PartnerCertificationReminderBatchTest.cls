/*
 * End-to-end coverage for PartnerCertificationReminderBatch: a Completed
 * training assignment past Expires_On__c is expired and fires
 * CertificationExpired, one expiring in exactly 30 days fires
 * CertificationExpiringSoon without changing status, assignments outside
 * the window are left alone, a post-onboarding (Onboarding__c null)
 * assignment is picked up via its own Partner_Account__c, and the batch can
 * be scheduled at all.
 */
@IsTest
private class PartnerCertificationReminderBatchTest {
  @IsTest
  static void batchExpiresCompletedAssignmentsPastExpiry() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;
    Partner_Training_Assignment__c assignment = new Partner_Training_Assignment__c(
      Assignment_Key__c = partner.Id + ':security-cert',
      Training_Key__c = 'security-cert',
      Partner_Account__c = partner.Id,
      Status__c = 'Completed',
      Expires_On__c = Date.today().addDays(-1)
    );
    insert assignment;

    Test.startTest();
    Database.executeBatch(new PartnerCertificationReminderBatch(), 100);
    Test.stopTest();

    Partner_Training_Assignment__c updated = [
      SELECT Status__c
      FROM Partner_Training_Assignment__c
      WHERE Id = :assignment.Id
    ];
    Assert.areEqual(
      'Expired',
      updated.Status__c,
      'Completed assignment past expiry should be expired by the batch.'
    );
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Event_Publication__c
        WHERE Event_Type__c = 'CertificationExpired'
      ],
      'Expiring the assignment should fire a CertificationExpired event.'
    );
  }

  @IsTest
  static void batchFiresReminderExactlyThirtyDaysOutWithoutChangingStatus() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;
    Partner_Training_Assignment__c assignment = new Partner_Training_Assignment__c(
      Assignment_Key__c = partner.Id + ':security-cert',
      Training_Key__c = 'security-cert',
      Partner_Account__c = partner.Id,
      Status__c = 'Completed',
      Expires_On__c = Date.today().addDays(30)
    );
    insert assignment;

    Test.startTest();
    Database.executeBatch(new PartnerCertificationReminderBatch(), 100);
    Test.stopTest();

    Partner_Training_Assignment__c updated = [
      SELECT Status__c
      FROM Partner_Training_Assignment__c
      WHERE Id = :assignment.Id
    ];
    Assert.areEqual(
      'Completed',
      updated.Status__c,
      'An assignment 30 days from expiry should not change status.'
    );
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Event_Publication__c
        WHERE Event_Type__c = 'CertificationExpiringSoon'
      ],
      'An assignment 30 days from expiry should fire a reminder event.'
    );
  }

  @IsTest
  static void batchLeavesAssignmentsOutsideTheWindowAlone() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;
    Partner_Training_Assignment__c farOut = new Partner_Training_Assignment__c(
      Assignment_Key__c = partner.Id + ':far-out-cert',
      Training_Key__c = 'far-out-cert',
      Partner_Account__c = partner.Id,
      Status__c = 'Completed',
      Expires_On__c = Date.today().addDays(45)
    );
    Partner_Training_Assignment__c alreadyExpired = new Partner_Training_Assignment__c(
      Assignment_Key__c = partner.Id + ':already-expired-cert',
      Training_Key__c = 'already-expired-cert',
      Partner_Account__c = partner.Id,
      Status__c = 'Expired',
      Expires_On__c = Date.today().addDays(-10)
    );
    insert new List<Partner_Training_Assignment__c>{ farOut, alreadyExpired };

    Test.startTest();
    Database.executeBatch(new PartnerCertificationReminderBatch(), 100);
    Test.stopTest();

    Map<Id, Partner_Training_Assignment__c> updated = new Map<Id, Partner_Training_Assignment__c>(
      [
        SELECT Status__c
        FROM Partner_Training_Assignment__c
        WHERE Id IN (:farOut.Id, :alreadyExpired.Id)
      ]
    );
    Assert.areEqual('Completed', updated.get(farOut.Id).Status__c);
    Assert.areEqual('Expired', updated.get(alreadyExpired.Id).Status__c);
  }

  @IsTest
  static void batchResolvesPartnerAccountForOnboardingScopedAssignment() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;
    Partner_Application__c application = new Partner_Application__c(
      Name = 'Onboarding Cert Partner',
      Company_Name__c = 'Onboarding Cert Partner',
      Business_Email__c = 'onboardingcert@example.test',
      Application_Status__c = 'Approved',
      Country__c = 'Australia',
      Partner_Type__c = 'Reseller',
      Requested_Tier__c = 'Gold'
    );
    insert application;
    Partner_Onboarding__c onboarding = new Partner_Onboarding__c(
      Application__c = application.Id,
      Onboarding_Key__c = String.valueOf(application.Id),
      Partner_Account__c = partner.Id,
      Status__c = 'Active',
      Current_Stage__c = 'Active',
      Activation_Gate_Status__c = 'Ready',
      Version_Number__c = 1
    );
    insert onboarding;
    Partner_Training_Assignment__c assignment = new Partner_Training_Assignment__c(
      Assignment_Key__c = onboarding.Id + ':onboarding-cert',
      Training_Key__c = 'onboarding-cert',
      Onboarding__c = onboarding.Id,
      Status__c = 'Completed',
      Expires_On__c = Date.today().addDays(-1)
    );
    insert assignment;

    Test.startTest();
    Database.executeBatch(new PartnerCertificationReminderBatch(), 100);
    Test.stopTest();

    Assert.areEqual(
      'Expired',
      [
        SELECT Status__c
        FROM Partner_Training_Assignment__c
        WHERE Id = :assignment.Id
      ]
      .Status__c
    );
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Event_Publication__c
        WHERE Event_Type__c = 'CertificationExpired'
      ],
      'An onboarding-scoped assignment should still resolve a partner account and fire the event.'
    );
  }

  @IsTest
  static void schedulableQueuesBatch() {
    new PartnerCertificationReminderBatch().execute((SchedulableContext) null);
  }

  @IsTest
  static void scheduledRunKicksOffBatch() {
    Test.startTest();
    String jobId = System.schedule(
      'PartnerCertificationReminderBatch Test',
      '0 0 1 * * ?',
      new PartnerCertificationReminderBatch()
    );
    Test.stopTest();

    Assert.isNotNull(
      jobId,
      'Scheduling the certification reminder batch should return a job id.'
    );
  }
}
