/**
 * Request payload for a Deal_Implementation__c lifecycle command, covering
 * both the Create inputs (used only by the 'Create' action, system-
 * triggered from DealOpportunityReconciliationBatch.handleClosedWon) and
 * the decision inputs shared by every other action.
 */
public class ImplementationCommand {
  public Id implementationId;
  public Id dealId;
  public String action;
  public Integer expectedVersion;
  public String reason;
  public Map<String, Object> parameters;

  public ImplementationCommand() {
    parameters = new Map<String, Object>();
  }

  /**
   * Validates that the command has the fields its action requires,
   * throwing a PartnerSyncHandledException otherwise.
   */
  public void validate() {
    if (String.isBlank(action)) {
      throw new PartnerSyncHandledException(
        'An implementation command action is required.'
      );
    }
    if (action == 'Create') {
      if (dealId == null) {
        throw new PartnerSyncHandledException(
          'A deal is required to create an implementation.'
        );
      }
      return;
    }
    if (implementationId == null) {
      throw new PartnerSyncHandledException(
        'An implementation is required for this command.'
      );
    }
  }
}
