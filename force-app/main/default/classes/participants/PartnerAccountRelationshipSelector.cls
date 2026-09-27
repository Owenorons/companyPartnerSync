/**
 * Selector layer for Partner_Account_Relationship__c.
 */
public without sharing class PartnerAccountRelationshipSelector {
  /**
   * Queries the active relationship between two accounts, in either
   * direction, if one exists.
   *
   * @param sourceAccountId Id of the deal's originating partner account.
   * @param targetAccountId Id of the account being checked for a co-sell relationship.
   * @return The active relationship record, or null if none exists.
   */
  public static Partner_Account_Relationship__c selectActive(
    Id sourceAccountId,
    Id targetAccountId
  ) {
    List<Partner_Account_Relationship__c> rows = [
      SELECT
        Id,
        Source_Account__c,
        Target_Account__c,
        Relationship_Type__c,
        Status__c,
        Allows_CoSell__c,
        Territory__c,
        Product_Family__c,
        Effective_From__c,
        Effective_To__c
      FROM Partner_Account_Relationship__c
      WHERE
        Status__c = 'Active'
        AND ((Source_Account__c = :sourceAccountId
        AND Target_Account__c = :targetAccountId)
        OR (Source_Account__c = :targetAccountId
        AND Target_Account__c = :sourceAccountId))
      WITH SYSTEM_MODE
      LIMIT 1
    ];

    return rows.isEmpty() ? null : rows[0];
  }

  /**
   * Queries Suspended or Expired relationships, for the internal Co-Sell
   * Workbench's "Relationship Exceptions" view - relationships that may
   * need administrative attention.
   *
   * @return Up to 200 Suspended/Expired relationships, most recently changed first.
   */
  public static List<Partner_Account_Relationship__c> selectExceptions() {
    return [
      SELECT
        Id,
        Source_Account__c,
        Source_Account__r.Name,
        Target_Account__c,
        Target_Account__r.Name,
        Status__c,
        Effective_To__c
      FROM Partner_Account_Relationship__c
      WHERE Status__c IN ('Suspended', 'Expired')
      WITH SYSTEM_MODE
      ORDER BY LastModifiedDate DESC
      LIMIT 200
    ];
  }
}
