/**
 * Scheduled/batch job that identifies renewals from Active
 * Customer_Commercial_Entitlement__c rows entering their policy's renewal
 * planning window (doc section 42.20), inserting Partner_Renewal__c rows
 * at Status__c = 'Identified'. Genuinely bulk-safe from day one: the query
 * locator scopes to the widest configured window across every active
 * policy, and the per-entitlement policy lookup inside execute() is a
 * single Map lookup against one query resolved once in start() - never a
 * SOQL call per row. Idempotent: an entitlement that already has a
 * non-terminal renewal is skipped, so repeated runs don't duplicate.
 */
public with sharing class RenewalIdentificationBatch implements Database.Batchable<SObject>, Schedulable {
  private Map<String, Renewal_Policy__mdt> policiesByFamily;

  /**
   * Builds the query locator for Active entitlements entering the widest
   * configured renewal planning window.
   *
   * @param context Batch execution context (unused).
   * @return A query locator over Active entitlements approaching expiry.
   */
  public Database.QueryLocator start(Database.BatchableContext context) {
    policiesByFamily = RenewalPolicyResolver.resolveAllActiveByProductFamily();
    Integer widestWindow = 0;
    for (Renewal_Policy__mdt policy : policiesByFamily.values()) {
      Integer window = policy.Planning_Window_Days__c == null
        ? 0
        : Integer.valueOf(policy.Planning_Window_Days__c);
      if (window > widestWindow) {
        widestWindow = window;
      }
    }
    if (widestWindow == 0) {
      widestWindow = 180;
    }

    Date today = System.today();
    Date windowEnd = today.addDays(widestWindow);
    return Database.getQueryLocator(
      [
        SELECT
          Id,
          Customer_Account__c,
          Customer_Success_Engagement__c,
          Originating_Deal__c,
          Product_Family__c,
          Effective_End_On__c
        FROM Customer_Commercial_Entitlement__c
        WHERE
          Status__c = 'Active'
          AND Effective_End_On__c != NULL
          AND Effective_End_On__c >= :today
          AND Effective_End_On__c <= :windowEnd
      ]
    );
  }

  /**
   * Identifies a renewal for each entitlement actually within its own
   * policy's window, skipping entitlements that already have a
   * non-terminal renewal (idempotency) and those merely caught by the
   * query locator's widest-window scope but not yet within their own
   * narrower window.
   *
   * @param context Batch execution context (unused).
   * @param scope Batch of Active entitlements approaching expiry.
   */
  public void execute(
    Database.BatchableContext context,
    List<Customer_Commercial_Entitlement__c> scope
  ) {
    if (policiesByFamily == null) {
      policiesByFamily = RenewalPolicyResolver.resolveAllActiveByProductFamily();
    }
    Date today = System.today();
    Set<Id> entitlementIds = new Set<Id>();
    for (Customer_Commercial_Entitlement__c entitlement : scope) {
      entitlementIds.add(entitlement.Id);
    }
    Set<Id> alreadyOpen = RenewalSelector.selectEntitlementIdsWithOpenRenewal(
      entitlementIds
    );

    Set<Id> engagementIds = new Set<Id>();
    for (Customer_Commercial_Entitlement__c entitlement : scope) {
      if (entitlement.Customer_Success_Engagement__c != null) {
        engagementIds.add(entitlement.Customer_Success_Engagement__c);
      }
    }
    Map<Id, Customer_Success_Engagement__c> engagementsById = new Map<Id, Customer_Success_Engagement__c>(
      [
        SELECT Primary_Partner__c
        FROM Customer_Success_Engagement__c
        WHERE Id IN :engagementIds
        WITH SYSTEM_MODE
      ]
    );

    List<Partner_Renewal__c> renewalsToInsert = new List<Partner_Renewal__c>();

    for (Customer_Commercial_Entitlement__c entitlement : scope) {
      try {
        if (alreadyOpen.contains(entitlement.Id)) {
          continue;
        }
        Renewal_Policy__mdt policy = RenewalPolicyResolver.pickFromMap(
          policiesByFamily,
          entitlement.Product_Family__c
        );
        if (policy == null) {
          continue;
        }
        Integer window = policy.Planning_Window_Days__c == null
          ? 180
          : Integer.valueOf(policy.Planning_Window_Days__c);
        if (today.addDays(window) < entitlement.Effective_End_On__c) {
          continue;
        }

        Customer_Success_Engagement__c engagement = engagementsById.get(
          entitlement.Customer_Success_Engagement__c
        );
        Partner_Renewal__c renewal = new Partner_Renewal__c(
          Customer_Success_Engagement__c = entitlement.Customer_Success_Engagement__c,
          Customer_Account__c = entitlement.Customer_Account__c,
          Original_Deal__c = entitlement.Originating_Deal__c,
          Primary_Partner__c = engagement?.Primary_Partner__c,
          Commercial_Entitlement__c = entitlement.Id,
          Status__c = policy.Require_Partner_Confirmation__c == true
            ? 'Partner Confirmation Required'
            : 'Identified',
          Renewal_Health__c = 'On Track',
          Planning_Window_Start_On__c = today,
          Target_Decision_On__c = entitlement.Effective_End_On__c,
          Version_Number__c = 0
        );
        renewalsToInsert.add(renewal);
      } catch (Exception ex) {
        LoggingService.error(
          'RenewalIdentificationBatch',
          'Failed to identify a renewal for entitlement ' + entitlement.Id,
          ex
        );
      }
    }

    if (!renewalsToInsert.isEmpty()) {
      Database.insert(renewalsToInsert, false, AccessLevel.SYSTEM_MODE);

      List<Customer_Success_Engagement__c> engagementUpdates = new List<Customer_Success_Engagement__c>();
      for (Partner_Renewal__c inserted : renewalsToInsert) {
        if (
          inserted.Id != null &&
          inserted.Customer_Success_Engagement__c != null
        ) {
          engagementUpdates.add(
            new Customer_Success_Engagement__c(
              Id = inserted.Customer_Success_Engagement__c,
              Current_Renewal__c = inserted.Id
            )
          );
        }
      }
      if (!engagementUpdates.isEmpty()) {
        Database.update(engagementUpdates, false, AccessLevel.SYSTEM_MODE);
      }
    }
  }

  /**
   * No post-processing is required after this batch runs.
   *
   * @param context Batch execution context (unused).
   */
  public void finish(Database.BatchableContext context) {
  }

  /**
   * Scheduled entry point: launches this class as a batch job. Chunk size
   * 200 is safe here since execute() does a bounded, small number of SOQL
   * calls per row (one idempotency count query) plus zero per-row policy
   * SOQL (resolved once in start() and reused via Map lookup) - a genuine
   * bulk design from day one, not a retrofit.
   *
   * @param context Scheduled execution context (unused).
   */
  public void execute(SchedulableContext context) {
    Database.executeBatch(new RenewalIdentificationBatch(), 200);
  }
}
