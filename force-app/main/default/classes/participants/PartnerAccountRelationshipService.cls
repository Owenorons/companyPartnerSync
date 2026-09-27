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

  /**
   * Checks whether a relationship's territory scope permits collaboration
   * on a deal in the given country. An unset Territory__c means no
   * territory restriction. A restricted relationship with no deal country
   * to check against fails closed (blocked) rather than silently passing -
   * this codebase's established pattern for "can't verify eligibility, so
   * don't allow it" elsewhere (e.g. protection-blocking conditions).
   *
   * Deal_Registration__c has no structured Territory__c/Region__c of its
   * own to compare against - Territory__c is checked against
   * Identity_Country__c, the closest field this org actually has, matching
   * the same limitation already documented for Lead_Distribution_Rule__mdt's
   * Region__c matching. Product_Family__c has no deal-side equivalent at
   * all and is not checked here - see docs/deal-participant-management-review.md.
   *
   * @param relationship The active Partner_Account_Relationship__c to check.
   * @param dealCountry The deal's Identity_Country__c value.
   * @return True if the relationship's territory scope permits this deal's country.
   */
  public static Boolean allowsTerritory(
    Partner_Account_Relationship__c relationship,
    String dealCountry
  ) {
    if (relationship == null || String.isBlank(relationship.Territory__c)) {
      return true;
    }

    if (String.isBlank(dealCountry)) {
      return false;
    }

    return relationship.Territory__c.trim()
      .equalsIgnoreCase(dealCountry.trim());
  }
}
