/*
 * Second of the two consumers PartnerSyncEventHandler dispatches a
 * PartnerSync_Event__e to (see AuditEventConsumerService for the other).
 * Translates a raw Event_Type__c into user-facing notification copy via the
 * lookup maps below; an event type missing from TITLE_BY_EVENT_TYPE is
 * silently skipped, since not every business event warrants a partner
 * notification.
 */
public with sharing class NotificationEventConsumerService {
  private static final Map<String, String> TITLE_BY_EVENT_TYPE = new Map<String, String>{
    'DealSubmitted' => 'Deal Submitted',
    'DealApproved' => 'Deal Approved',
    'MDFSubmitted' => 'MDF Request Submitted',
    'MDFApproved' => 'MDF Request Approved',
    'LeadAccepted' => 'Lead Accepted',
    'LeadConverted' => 'Lead Converted'
  };

  private static final Map<String, String> MESSAGE_BY_EVENT_TYPE = new Map<String, String>{
    'DealSubmitted' => 'A new deal registration has been submitted for review.',
    'DealApproved' => 'Your deal registration has been approved.',
    'MDFSubmitted' => 'A new MDF request has been submitted for review.',
    'MDFApproved' => 'Your MDF request has been approved.',
    'LeadAccepted' => 'A partner has accepted an assigned lead.',
    'LeadConverted' => 'A lead has been converted to a deal registration.'
  };

  private static final Map<String, String> NOTIFICATION_TYPE_BY_EVENT_TYPE = new Map<String, String>{
    'DealSubmitted' => 'Deal',
    'DealApproved' => 'Deal',
    'MDFSubmitted' => 'MDF',
    'MDFApproved' => 'MDF',
    'LeadAccepted' => 'Lead',
    'LeadConverted' => 'Lead'
  };

  public static void notifyBusinessEvent(PartnerSync_Event__e eventRecord) {
    String title = TITLE_BY_EVENT_TYPE.get(eventRecord.Event_Type__c);

    if (title == null) {
      return;
    }

    NotificationRequestDTO request = new NotificationRequestDTO();
    request.partnerAccountId = idOrNull(eventRecord.Partner_Account_Id__c);
    request.notificationType = NOTIFICATION_TYPE_BY_EVENT_TYPE.get(
      eventRecord.Event_Type__c
    );
    request.title = title;
    request.message = MESSAGE_BY_EVENT_TYPE.get(eventRecord.Event_Type__c);
    request.relatedObject = eventRecord.Object_Name__c;
    request.relatedRecordId = idOrNull(eventRecord.Record_Id__c);

    NotificationService.create(request);
  }

  private static Id idOrNull(String value) {
    return String.isBlank(value) ? null : (Id) value;
  }
}
