/**
 * Input context for conflict analysis: the deal being analysed, its derived
 * customer identity, and its current validation findings.
 */
public class DealConflictContext {
  public Deal_Registration__c deal;
  public DealCustomerIdentity identity;
  public List<DealValidationFinding> validationFindings;
}
