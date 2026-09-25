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
}
