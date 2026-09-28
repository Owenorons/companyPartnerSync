/**
 * Consumer for 'CustomerSuccessHandoffRequested' events (published by
 * ImplementationCommandService.complete()), one of PartnerSyncEventHandler's
 * dispatches. The event's Record_Id__c is the Deal_Registration__c Id, not
 * an Implementation Id (see ImplementationCommandService.publish()'s call
 * shape). This is the first and only consumer of this event - before
 * Sprint 42, a completed implementation reached Customer Success in name
 * only, with no engagement record ever created.
 */
public without sharing class CustomerSuccessEventConsumerService {
  /**
   * Reacts to a single business event, if it's a type this consumer
   * handles. Events of any other type are silently, deliberately ignored -
   * this consumer is fanned out to unconditionally by
   * PartnerSyncEventHandler.process(), the same shape as
   * ApprovalReturnConsumerService.handleReturnedPlan().
   *
   * @param eventRecord The published event to react to.
   */
  public static void handleBusinessEvent(PartnerSync_Event__e eventRecord) {
    if (eventRecord.Event_Type__c != 'CustomerSuccessHandoffRequested') {
      return;
    }
    if (String.isBlank(eventRecord.Record_Id__c)) {
      return;
    }

    CustomerSuccessCommandService.createEngagement(
      (Id) eventRecord.Record_Id__c
    );
  }
}
