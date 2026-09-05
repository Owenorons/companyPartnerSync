public with sharing class InitializeDealLifecycleCommandHandler implements DealCommandHandler {
  public void validate(DealCommandContext context) {
    if (context.deal.Id == null) {
      throw new DealLifecycleException('An existing deal is required.');
    }
  }

  public void execute(DealCommandContext context) {
    context.deal.Lifecycle_Phase__c = 'Registration';
    context.deal.Current_Action_Required__c = 'Submit';
    context.deal.Lifecycle_Health__c = 'Healthy';
    context.eventType = 'DealLifecycleInitialized';
    context.eventPayload.put('initialization', 'Administrative');
  }
}
