/**
 * Projects a deal's canonical Stage__c from its current primary
 * Deal_Opportunity__c's Opportunity.StageName, via Deal_Sales_Stage_Map__mdt
 * (Sprint 39 §39.16-39.18) - never assumes standard Salesforce stage labels,
 * since a customer's own Opportunity automation may use entirely custom
 * stage names. Called from DealOpportunityCommandService's link/create
 * commands and from DealOpportunityReconciliationBatch.
 */
public without sharing class DealSalesStageProjectionService {
  /**
   * Recomputes and, if changed, persists a deal's canonical Stage__c from
   * its current primary Opportunity's StageName.
   *
   * @param dealId Id of the deal to project.
   */
  public static void recompute(Id dealId) {
    Deal_Opportunity__c primary = DealOpportunitySelector.selectCurrentPrimary(
      dealId
    );
    if (primary == null || primary.Opportunity__r?.StageName == null) {
      return;
    }

    String canonicalStage = resolveCanonicalStage(
      primary.Opportunity__r.StageName
    );

    List<Deal_Registration__c> deals = [
      SELECT Id, Stage__c
      FROM Deal_Registration__c
      WHERE Id = :dealId
      WITH SYSTEM_MODE
    ];
    if (deals.isEmpty() || deals[0].Stage__c == canonicalStage) {
      return;
    }

    Database.update(
      new Deal_Registration__c(Id = dealId, Stage__c = canonicalStage),
      AccessLevel.SYSTEM_MODE
    );
  }

  /**
   * Resolves the canonical stage for a live Opportunity.StageName value,
   * exact-matching against Deal_Sales_Stage_Map__mdt and falling back to
   * the wildcard Default record when unmapped.
   *
   * @param opportunityStageName The Opportunity's live StageName.
   * @return The matching canonical stage, or the Default record's fallback.
   */
  public static String resolveCanonicalStage(String opportunityStageName) {
    Deal_Sales_Stage_Map__mdt mapping = resolveMapping(opportunityStageName);
    return mapping?.Canonical_Stage__c;
  }

  /**
   * Resolves the full mapping row for a live Opportunity.StageName value,
   * for callers (e.g. the reconciliation batch) that also need Is_Won__c/
   * Is_Closed__c.
   *
   * @param opportunityStageName The Opportunity's live StageName.
   * @return The matching mapping row, or the Default record's fallback.
   */
  public static Deal_Sales_Stage_Map__mdt resolveMapping(
    String opportunityStageName
  ) {
    Deal_Sales_Stage_Map__mdt exactMatch;
    Deal_Sales_Stage_Map__mdt fallback;
    // Deal_Sales_Stage_Map__mdt.getAll() reads from the platform's custom
    // metadata cache, not a SOQL query - safe to call once per row in a
    // bulk/batch context without counting against the 100-SOQL-per-
    // transaction limit, unlike every other CMDT resolver in this codebase
    // (which query CMDT via SOQL because they're only ever called from
    // single-record command paths, not batch loops).
    for (
      Deal_Sales_Stage_Map__mdt candidate : Deal_Sales_Stage_Map__mdt.getAll()
        .values()
    ) {
      if (candidate.Active__c != true) {
        continue;
      }
      if (candidate.Opportunity_Stage_Name__c == opportunityStageName) {
        exactMatch = candidate;
        break;
      }
      if (candidate.Opportunity_Stage_Name__c == null && fallback == null) {
        fallback = candidate;
      }
    }
    return exactMatch != null ? exactMatch : fallback;
  }
}
