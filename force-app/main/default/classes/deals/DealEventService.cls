/**
 * Creates the Deal_Event__c audit/history record for a completed lifecycle command, along with
 * a matching Deal_Event_Outbox__c row that queues it for downstream publication.
 */
public without sharing class DealEventService {
  /**
   * Pairing of the event record just created and its corresponding outbox row.
   */
  public class EventCreationResult {
    public Deal_Event__c eventRecord;
    public Deal_Event_Outbox__c outboxRecord;
  }

  /**
   * Builds and inserts a Deal_Event__c from the given command context (including a JSON payload
   * merging standard transition fields with any context-supplied payload), plus a pending
   * Deal_Event_Outbox__c row for it.
   *
   * @param context The command execution context describing the transition that occurred.
   * @return The inserted event and outbox records.
   */
  public static EventCreationResult createEvent(DealCommandContext context) {
    Map<String, Object> safePayload = new Map<String, Object>{
      'aggregateType' => context.command.aggregateType,
      'aggregateId' => String.valueOf(context.command.aggregateId),
      'commandType' => context.command.commandType,
      'previousState' => context.previousState,
      'newState' => context.newState,
      'version' => context.newVersion
    };
    if (context.eventPayload != null) {
      safePayload.putAll(context.eventPayload);
    }

    Deal_Event__c eventRecord = new Deal_Event__c(
      Deal__c = context.command.dealId,
      Aggregate_Type__c = context.command.aggregateType,
      Aggregate_Id__c = String.valueOf(context.command.aggregateId),
      Event_Type__c = context.eventType,
      Lifecycle_Dimension__c = context.command.lifecycleDimension,
      Previous_State__c = context.previousState,
      New_State__c = context.newState,
      Action__c = context.command.commandType,
      Actor_User__c = UserInfo.getUserId(),
      Source__c = context.command.source,
      Command_Key__c = context.command.commandKey,
      Correlation_Id__c = context.command.correlationId,
      Causation_Id__c = context.command.causationId,
      Occurred_On__c = System.now(),
      Summary__c = context.command.commandType +
        ': ' +
        context.previousState +
        ' to ' +
        context.newState,
      Payload__c = JSON.serialize(safePayload),
      Partner_Visible__c = context.transition.partnerVisible == true
    );
    Database.insert(eventRecord, AccessLevel.SYSTEM_MODE);

    Deal_Event_Outbox__c outbox = new Deal_Event_Outbox__c(
      Event__c = eventRecord.Id,
      Status__c = 'Pending',
      Attempt_Count__c = 0,
      Next_Attempt_On__c = System.now()
    );
    Database.insert(outbox, AccessLevel.SYSTEM_MODE);

    EventCreationResult result = new EventCreationResult();
    result.eventRecord = eventRecord;
    result.outboxRecord = outbox;
    return result;
  }
}
