/**
 * Normalizes a source-specific entitlement recording into an unsaved,
 * fully-populated Customer_Commercial_Entitlement__c candidate.
 * Implementations never insert themselves -
 * CommercialEntitlementCommandService owns the actual insert, so every
 * source goes through the same governed pipeline. Mirrors
 * RevenueSourceAdapter's shape (doc Sprint 42 point 10 - no CRM/
 * subscription/billing integration exists in this org today, same
 * situation RevenueSourceAdapter was in for Sprint 41).
 */
public interface CommercialEntitlementAdapter {
  /**
   * Builds an unsaved, Active Customer_Commercial_Entitlement__c candidate
   * from the given command.
   *
   * @param command The entitlement details to record.
   * @return An unsaved Customer_Commercial_Entitlement__c ready for the command service to insert.
   */
  Customer_Commercial_Entitlement__c buildCandidate(
    CommercialEntitlementCommand command
  );
}
