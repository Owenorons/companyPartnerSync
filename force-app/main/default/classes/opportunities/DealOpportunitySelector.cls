/**
 * Selector layer for Deal_Opportunity__c, the authoritative Deal <-> Opportunity
 * relationship (Sprint 39 §39.2-39.5). Deal_Registration__c.Opportunity__c
 * remains a backward-compatible projection of the current primary row here,
 * not the source of truth going forward.
 */
public without sharing class DealOpportunitySelector {
  /**
   * Queries every current relationship for a deal, most recently created first.
   *
   * @param dealId Id of the deal.
   * @return The deal's current Deal_Opportunity__c rows.
   */
  public static List<Deal_Opportunity__c> selectForDeal(Id dealId) {
    return [
      SELECT
        Id,
        Deal__c,
        Opportunity__c,
        Opportunity__r.Name,
        Opportunity__r.StageName,
        Opportunity__r.Amount,
        Opportunity__r.CloseDate,
        Opportunity__r.AccountId,
        Opportunity__r.IsClosed,
        Opportunity__r.IsWon,
        Partner_Account__c,
        Relationship_Type__c,
        Primary__c,
        Current__c,
        Version_Number__c
      FROM Deal_Opportunity__c
      WHERE Deal__c = :dealId AND Current__c = TRUE
      WITH SYSTEM_MODE
      ORDER BY CreatedDate DESC
    ];
  }

  /**
   * Queries a deal's current primary relationship, if one exists.
   *
   * @param dealId Id of the deal.
   * @return The deal's current primary Deal_Opportunity__c row, or null.
   */
  public static Deal_Opportunity__c selectCurrentPrimary(Id dealId) {
    List<Deal_Opportunity__c> rows = [
      SELECT
        Id,
        Deal__c,
        Opportunity__c,
        Opportunity__r.StageName,
        Opportunity__r.IsClosed,
        Opportunity__r.IsWon,
        Partner_Account__c,
        Relationship_Type__c,
        Primary__c,
        Current__c,
        Version_Number__c
      FROM Deal_Opportunity__c
      WHERE Deal__c = :dealId AND Current__c = TRUE AND Primary__c = TRUE
      WITH SYSTEM_MODE
      LIMIT 1
    ];

    return rows.isEmpty() ? null : rows[0];
  }

  /**
   * Indicates whether an Opportunity is already claimed by any deal's
   * current relationship - the authoritative "is this Opportunity
   * available" check, replacing Deal_Registration__c.Opportunity__c-only
   * checks like DealRegistrationSelector.hasExistingRegistration.
   *
   * @param opportunityId Id of the Opportunity to check.
   * @return The claiming Deal_Opportunity__c row, or null if unclaimed.
   */
  public static Deal_Opportunity__c selectActiveLinkForOpportunity(
    Id opportunityId
  ) {
    List<Deal_Opportunity__c> rows = [
      SELECT Id, Deal__c, Relationship_Type__c
      FROM Deal_Opportunity__c
      WHERE Opportunity__c = :opportunityId AND Current__c = TRUE
      WITH SYSTEM_MODE
      LIMIT 1
    ];

    return rows.isEmpty() ? null : rows[0];
  }

  /**
   * Locks and reads a single Deal_Opportunity__c by Id, for a command to
   * apply a decision to.
   *
   * @param dealOpportunityId Id of the record to load.
   * @return The locked Deal_Opportunity__c record.
   */
  public static Deal_Opportunity__c selectForUpdate(Id dealOpportunityId) {
    List<Deal_Opportunity__c> rows = [
      SELECT
        Id,
        Deal__c,
        Opportunity__c,
        Partner_Account__c,
        Relationship_Type__c,
        Primary__c,
        Current__c,
        Version_Number__c
      FROM Deal_Opportunity__c
      WHERE Id = :dealOpportunityId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException(
        'Deal opportunity relationship not found.'
      );
    }

    return rows[0];
  }
}
