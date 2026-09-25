/**
 * Gates whether two partner accounts may collaborate on a deal, per the
 * architecture doc's PartnerAccountRelationshipService (Sprint 38 §38.13):
 * a co-sell relationship must be explicitly recorded, not inferred from
 * Account hierarchy alone.
 */
public without sharing class PartnerAccountRelationshipService {
  /**
   * Indicates whether an active, co-sell-permitting relationship exists
   * between two partner accounts, in either direction.
   *
   * @param sourceAccountId Id of the deal's originating partner account.
   * @param targetAccountId Id of the account being invited to co-sell.
   * @return True if an active relationship with Allows_CoSell__c=true exists.
   */
  public static Boolean allowsCoSell(Id sourceAccountId, Id targetAccountId) {
    Partner_Account_Relationship__c relationship = PartnerAccountRelationshipSelector.selectActive(
      sourceAccountId,
      targetAccountId
    );

    return relationship != null && relationship.Allows_CoSell__c == true;
  }

  /**
   * Requires an active, co-sell-permitting relationship between two partner
   * accounts, throwing a specific, partner-safe reason if none exists.
   *
   * @param sourceAccountId Id of the deal's originating partner account.
   * @param targetAccountId Id of the account being invited to co-sell.
   * @return The active relationship record.
   */
  public static Partner_Account_Relationship__c requireActiveRelationship(
    Id sourceAccountId,
    Id targetAccountId
  ) {
    Partner_Account_Relationship__c relationship = PartnerAccountRelationshipSelector.selectActive(
      sourceAccountId,
      targetAccountId
    );

    if (relationship == null) {
      throw new PartnerSyncHandledException(
        'No active partner relationship permits this collaboration.'
      );
    }

    if (relationship.Allows_CoSell__c != true) {
      throw new PartnerSyncHandledException(
        'The partner relationship does not permit co-sell collaboration.'
      );
    }

    return relationship;
  }
}
