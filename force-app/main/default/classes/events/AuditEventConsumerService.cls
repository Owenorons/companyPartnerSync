/*
 * One of two consumers PartnerSyncEventHandler fans a PartnerSync_Event__e
 * out to (the other being NotificationEventConsumerService). Event types not
 * present in AUDIT_ACTION_BY_EVENT_TYPE are deliberately ignored rather than
 * erroring, since not every business event that fires this platform event
 * needs an audit trail entry.
 */
public with sharing class AuditEventConsumerService {
  private static final Map<String, String> AUDIT_ACTION_BY_EVENT_TYPE = new Map<String, String>{
    'DealSubmitted' => 'Submit',
    'DealApproved' => 'Approve',
    'LeadAccepted' => 'Accept',
    'LeadConverted' => 'Convert'
  };

  public static void logBusinessEvent(PartnerSync_Event__e eventRecord) {
    String action = AUDIT_ACTION_BY_EVENT_TYPE.get(eventRecord.Event_Type__c);

    if (action == null) {
      return;
    }

    AuditLogRequestDTO audit = AuditFactory.createSuccess(
      eventRecord.Object_Name__c,
      idOrNull(eventRecord.Record_Id__c),
      action
    );

    audit.partnerAccountId = idOrNull(eventRecord.Partner_Account_Id__c);

    AuditService.log(audit);
  }

  private static Id idOrNull(String value) {
    return String.isBlank(value) ? null : (Id) value;
  }
}
