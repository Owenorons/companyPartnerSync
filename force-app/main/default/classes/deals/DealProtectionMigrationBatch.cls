/**
 * One-time migration batch that backfills Deal_Protection_Grant__c/Deal_Protection_Action__c
 * records for legacy approved deal registrations that have a Protection_End_Date__c but no
 * current protection grant yet, so they line up with the newer protection-grant model.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class DealProtectionMigrationBatch implements Database.Batchable<SObject> {
  /**
   * Builds the query locator for approved deal registrations with a protection end date.
   *
   * @param context Batch execution context (unused).
   * @return A query locator over approved deal registrations with Protection_End_Date__c set.
   */
  public Database.QueryLocator start(Database.BatchableContext context) {
    return Database.getQueryLocator(
      [
        SELECT Id, Protection_Start_Date__c, Protection_End_Date__c
        FROM Deal_Registration__c
        WHERE
          Status__c IN ('Approved', 'Approved with Conditions')
          AND Protection_End_Date__c != NULL
      ]
    );
  }

  /**
   * For each deal in scope that doesn't already have a current protection grant, inserts a
   * Deal_Protection_Grant__c (backdating the start date using the tenant's configured expiry
   * window when Protection_Start_Date__c isn't set) plus a matching migration action record.
   *
   * @param context Batch execution context (unused).
   * @param scope Batch of approved deal registrations to migrate.
   */
  public void execute(
    Database.BatchableContext context,
    List<Deal_Registration__c> scope
  ) {
    Set<Id> dealIds = new Map<Id, Deal_Registration__c>(scope).keySet();
    Set<Id> alreadyMigrated = new Set<Id>();
    for (Deal_Protection_Grant__c grant : [
      SELECT Deal__c
      FROM Deal_Protection_Grant__c
      WHERE Deal__c IN :dealIds AND Current__c = TRUE
    ])
      alreadyMigrated.add(grant.Deal__c);
    List<Deal_Protection_Grant__c> grants = new List<Deal_Protection_Grant__c>();
    for (Deal_Registration__c deal : scope) {
      if (alreadyMigrated.contains(deal.Id))
        continue;
      Date startDate = deal.Protection_Start_Date__c == null
        ? deal.Protection_End_Date__c.addDays(
            -TenantConfigService.getDealExpiryDays()
          )
        : deal.Protection_Start_Date__c;
      grants.add(
        new Deal_Protection_Grant__c(
          Deal__c = deal.Id,
          Current__c = true,
          Current_Grant_Key__c = String.valueOf(deal.Id),
          Status__c = 'Active',
          Start_Date__c = startDate,
          End_Date__c = deal.Protection_End_Date__c,
          Version_Number__c = 0,
          Extension_Count__c = 0
        )
      );
    }
    if (!grants.isEmpty())
      Database.insert(grants, AccessLevel.SYSTEM_MODE);
    List<Deal_Protection_Action__c> actions = new List<Deal_Protection_Action__c>();
    for (Deal_Protection_Grant__c grant : grants)
      actions.add(
        new Deal_Protection_Action__c(
          Deal__c = grant.Deal__c,
          Grant__c = grant.Id,
          Command_Key__c = 'migration-protection-' + grant.Deal__c,
          Action__c = 'Migrate Legacy Protection',
          Occurred_On__c = System.now()
        )
      );
    if (!actions.isEmpty())
      Database.insert(actions, AccessLevel.SYSTEM_MODE);
  }

  /**
   * No post-processing is required after this batch runs.
   *
   * @param context Batch execution context (unused).
   */
  public void finish(Database.BatchableContext context) {
  }
}
