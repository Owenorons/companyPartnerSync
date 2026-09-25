/**
 * Consumer for 'ApprovalPlanReturned' events (see
 * ApprovalCommandService.coordinate()), one of the four
 * PartnerSyncEventHandler dispatches. Reacts to a mid-chain approval step
 * being sent back for correction by recovering the target record to a
 * state its owner can act on. Object-agnostic dispatch, per-object
 * reaction: today only MDF_Request__c has one wired up.
 *
 * Deal_Registration__c has the identical gap (a Returned chain step leaves
 * its Approval_Plan__c permanently stuck, same as MDF would without this
 * consumer) but is deliberately not handled here - MDF is a flat service
 * with direct SYSTEM_MODE DML, so reacting is a simple status update.
 * Deal's reaction would need to go through DealCommandService's
 * permission-gated state machine, which an automated event consumer can't
 * safely drive the same way an interactive user action does. That's a
 * separate piece of work, not a silent gap - see
 * docs/prm-gap-remediation-build-plan.md Phase 9d.
 */
public without sharing class ApprovalReturnConsumerService {
  /**
   * Reacts to a single 'ApprovalPlanReturned' event, if its target object has a wired-up
   * reaction. Events for objects with no reaction are silently, deliberately ignored - not a
   * failure, since not every approval-routed object needs (or currently has) a recovery path.
   *
   * @param eventRecord The published 'ApprovalPlanReturned' event to react to.
   */
  public static void handleReturnedPlan(PartnerSync_Event__e eventRecord) {
    if (eventRecord.Event_Type__c != 'ApprovalPlanReturned') {
      return;
    }

    if (eventRecord.Object_Name__c == 'MDF_Request__c') {
      recoverMdfRequest(eventRecord);
    }
  }

  private static void recoverMdfRequest(PartnerSync_Event__e eventRecord) {
    if (String.isBlank(eventRecord.Record_Id__c)) {
      return;
    }

    Database.update(
      new MDF_Request__c(
        Id = (Id) eventRecord.Record_Id__c,
        Status__c = 'Needs Information',
        Return_Reason__c = eventRecord.Summary__c
      ),
      AccessLevel.SYSTEM_MODE
    );
  }
}
