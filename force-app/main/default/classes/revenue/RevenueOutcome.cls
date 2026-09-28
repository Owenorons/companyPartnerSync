/**
 * Committed outcome of RevenueCommandService.importRevenue() - mirrors
 * DealParticipantOutcome/ImplementationHandoffOutcome's framing (a
 * business-expected non-match returns a typed outcome instead of
 * throwing).
 */
public class RevenueOutcome {
  public static final String MATCHED = 'Matched';
  public static final String RECONCILIATION_REQUIRED = 'ReconciliationRequired';
  public static final String DUPLICATE_IGNORED = 'DuplicateIgnored';

  public String outcome;
  public Deal_Revenue__c revenue;
  public Revenue_Reconciliation__c reconciliation;
  public String message;

  public RevenueOutcome(
    String outcome,
    Deal_Revenue__c revenue,
    Revenue_Reconciliation__c reconciliation,
    String message
  ) {
    this.outcome = outcome;
    this.revenue = revenue;
    this.reconciliation = reconciliation;
    this.message = message;
  }
}
