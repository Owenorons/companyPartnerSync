/** Backfills the onboarding aggregate for applications created before v2. */
public without sharing class PartnerOnboardingMigrationBatch implements Database.Batchable<SObject> {
  public Database.QueryLocator start(Database.BatchableContext context) {
    return Database.getQueryLocator(
      [
        SELECT Id, Application_Status__c
        FROM Partner_Application__c
        WHERE Application_Status__c IN ('Approved', 'Rejected')
      ]
    );
  }

  public void execute(
    Database.BatchableContext context,
    List<Partner_Application__c> applications
  ) {
    for (Partner_Application__c application : applications) {
      PartnerOnboardingLifecycleService.initialise(
        application,
        application.Application_Status__c
      );
    }
  }

  public void finish(Database.BatchableContext context) {
  }
}
