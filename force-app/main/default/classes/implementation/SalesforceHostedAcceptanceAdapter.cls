/**
 * The only ImplementationAcceptanceAdapter mode this codebase implements
 * today: a direct, Salesforce-hosted acknowledgment (an internal user or
 * the customer contact recording acceptance through the standard UI),
 * with Acceptance_Method__c = 'Salesforce Hosted'.
 */
public class SalesforceHostedAcceptanceAdapter implements ImplementationAcceptanceAdapter {
  public void applyAcceptance(
    Implementation_Acceptance__c acceptance,
    String acceptedByName,
    String acceptedByEmail
  ) {
    acceptance.Status__c = 'Accepted';
    acceptance.Accepted_On__c = System.now();
    acceptance.Accepted_By_Name__c = acceptedByName;
    acceptance.Accepted_By_Email__c = acceptedByEmail;
    acceptance.Acceptance_Method__c = 'Salesforce Hosted';
  }
}
