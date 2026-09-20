@IsTest
private class PartnerOnboardingMigrationBatchTest {
  @IsTest
  static void backfillsOnboardingForApplicationsMissingOne() {
    Partner_Application__c application = decidedApplication('Approved');

    Test.startTest();
    Database.executeBatch(new PartnerOnboardingMigrationBatch(), 100);
    Test.stopTest();

    Partner_Onboarding__c onboarding = [
      SELECT Status__c, Current_Stage__c, Version_Number__c
      FROM Partner_Onboarding__c
      WHERE Application__c = :application.Id
    ];
    Assert.areEqual('Onboarding', onboarding.Status__c);
    Assert.areEqual('Partner Enablement', onboarding.Current_Stage__c);
    Assert.areEqual(1, onboarding.Version_Number__c);
  }

  @IsTest
  static void reRunningBatchDoesNotRegressAProgressedOnboarding() {
    Partner_Application__c application = decidedApplication('Approved');
    Partner_Onboarding__c progressed = new Partner_Onboarding__c(
      Application__c = application.Id,
      Onboarding_Key__c = String.valueOf(application.Id),
      Status__c = 'Active',
      Current_Stage__c = 'Active',
      Activation_Gate_Status__c = 'Ready',
      Version_Number__c = 5
    );
    insert progressed;

    Test.startTest();
    Database.executeBatch(new PartnerOnboardingMigrationBatch(), 100);
    Test.stopTest();

    Partner_Onboarding__c unchanged = [
      SELECT Status__c, Current_Stage__c, Version_Number__c
      FROM Partner_Onboarding__c
      WHERE Application__c = :application.Id
    ];
    Assert.areEqual(
      'Active',
      unchanged.Status__c,
      'A re-run must not regress an onboarding that has already progressed.'
    );
    Assert.areEqual(5, unchanged.Version_Number__c);
  }

  private static Partner_Application__c decidedApplication(String status) {
    Partner_Application__c application = new Partner_Application__c(
      Name = 'Migration Test Partner',
      Company_Name__c = 'Migration Test Partner',
      Business_Email__c = 'migration-' +
        System.now().getTime() +
        '@example.test',
      Application_Status__c = status,
      Country__c = 'Australia',
      Partner_Type__c = 'Reseller',
      Requested_Tier__c = 'Gold'
    );
    insert application;
    return application;
  }
}
