/** Backfills the onboarding aggregate for applications created before v2. */
public without sharing class PartnerOnboardingMigrationBatch implements Database.Batchable<SObject> {
  /**
   * Queries every already-decided (Approved or Rejected) partner application
   * that still has no onboarding aggregate to backfill. Excluding
   * applications that already have one makes this batch safe to re-run:
   * without this filter, re-running it would re-initialise (and silently
   * regress) any onboarding that has since progressed past its initial state.
   *
   * @param context The batch execution context provided by the platform.
   * @return A query locator over the in-scope Partner_Application__c records.
   */
  public Database.QueryLocator start(Database.BatchableContext context) {
    return Database.getQueryLocator(
      [
        SELECT Id, Application_Status__c
        FROM Partner_Application__c
        WHERE
          Application_Status__c IN ('Approved', 'Rejected')
          AND Id NOT IN (
            SELECT Application__c
            FROM Partner_Onboarding__c
            WHERE Application__c != NULL
          )
      ]
    );
  }

  /**
   * Initialises the onboarding aggregate and lifecycle history for each
   * application in the batch scope, matching its existing decision outcome.
   *
   * @param context The batch execution context provided by the platform.
   * @param applications The Partner_Application__c records in this batch chunk.
   */
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

  /**
   * No-op completion hook required by Database.Batchable; this job has no
   * post-processing to perform.
   *
   * @param context The batch execution context provided by the platform.
   */
  public void finish(Database.BatchableContext context) {
  }
}
