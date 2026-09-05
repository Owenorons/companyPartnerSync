@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class DealProtectionMigrationBatch implements Database.Batchable<SObject> {
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

  public void finish(Database.BatchableContext context) {
  }
}
