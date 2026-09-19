/**
 * Command handler that performs the administrative initialisation of a deal's
 * lifecycle, moving it into the Registration phase.
 */
public with sharing class InitializeDealLifecycleCommandHandler implements DealCommandHandler {
  /**
   * Validates that the command can be applied to the given context.
   *
   * @param context The command execution context, including the target deal.
   */
  public void validate(DealCommandContext context) {
    if (context.deal.Id == null) {
      throw new DealLifecycleException('An existing deal is required.');
    }
  }

  /**
   * Initialises the deal's lifecycle fields and records the initialization
   * event on the command context.
   *
   * @param context The command execution context to mutate.
   */
  public void execute(DealCommandContext context) {
    context.deal.Lifecycle_Phase__c = 'Registration';
    context.deal.Current_Action_Required__c = 'Submit';
    context.deal.Lifecycle_Health__c = 'Healthy';
    context.eventType = 'DealLifecycleInitialized';
    context.eventPayload.put('initialization', 'Administrative');
  }
}
