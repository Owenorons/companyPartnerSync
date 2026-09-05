@IsTest
private class PartnerOnboardingLifecycleServiceTest {
  private static Partner_Application__c application(String status) {
    Partner_Application__c record = new Partner_Application__c(
      Name = 'Lifecycle Foundation',
      Company_Name__c = 'Lifecycle Foundation',
      Business_Email__c = 'foundation@example.com',
      Application_Status__c = status
    );
    insert record;
    return record;
  }

  @IsTest
  static void approvalCreatesBlockedOnboardingTaskAndEventIdempotently() {
    Partner_Application__c record = application('Approved');

    Test.startTest();
    PartnerOnboardingLifecycleService.initialise(record, 'Approved');
    PartnerOnboardingLifecycleService.initialise(record, 'Approved');
    Test.stopTest();

    Partner_Onboarding__c onboarding = [
      SELECT Status__c, Current_Stage__c, Activation_Gate_Status__c
      FROM Partner_Onboarding__c
      WHERE Application__c = :record.Id
    ];
    System.assertEquals('Onboarding', onboarding.Status__c);
    System.assertEquals('Partner Enablement', onboarding.Current_Stage__c);
    System.assertEquals('Blocked', onboarding.Activation_Gate_Status__c);
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM Partner_Onboarding_Task__c
        WHERE Onboarding__c = :onboarding.Id
      ]
    );
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM Partner_Lifecycle_Event__c
        WHERE Onboarding__c = :onboarding.Id
      ]
    );
  }

  @IsTest
  static void rejectionClosesOnboardingWithoutEnablementTask() {
    Partner_Application__c record = application('Rejected');
    PartnerOnboardingLifecycleService.initialise(record, 'Rejected');

    Partner_Onboarding__c onboarding = [
      SELECT Status__c, Current_Stage__c
      FROM Partner_Onboarding__c
      WHERE Application__c = :record.Id
    ];
    System.assertEquals('Closed', onboarding.Status__c);
    System.assertEquals('Closed', onboarding.Current_Stage__c);
    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM Partner_Onboarding_Task__c
        WHERE Onboarding__c = :onboarding.Id
      ]
    );
  }

  @IsTest
  static void batchBackfillsExistingDecisions() {
    Partner_Application__c approved = application('Approved');
    Partner_Application__c rejected = application('Rejected');

    Test.startTest();
    Database.executeBatch(new PartnerOnboardingMigrationBatch(), 50);
    Test.stopTest();

    Set<Id> applicationIds = new Set<Id>{ approved.Id, rejected.Id };
    System.assertEquals(
      2,
      [
        SELECT COUNT()
        FROM Partner_Onboarding__c
        WHERE Application__c IN :applicationIds
      ]
    );
  }
}
