/**
 * Normalizes a source-specific revenue import into an unsaved,
 * fully-populated Deal_Revenue__c candidate. Implementations never insert
 * or resolve the Deal themselves - RevenueCommandService.importRevenue()
 * owns idempotency checking, Deal resolution, and the actual insert, so
 * every source goes through the same governed pipeline (doc Sprint 41
 * §41.14). Mirrors ImplementationAcceptanceAdapter's shape.
 */
public interface RevenueSourceAdapter {
  /**
   * Builds an unsaved Deal_Revenue__c candidate from the given request.
   *
   * @param request The normalized import request.
   * @return An unsaved Deal_Revenue__c ready for RevenueCommandService to resolve and insert.
   */
  Deal_Revenue__c buildCandidate(RevenueImportRequest request);
}
