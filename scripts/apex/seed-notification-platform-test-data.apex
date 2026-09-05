// Repeatable notification-platform test data for a namespaced scratch org.
// Publishes the six mapped business events to active partner accounts and one
// intentional no-recipient event to validate dead-letter handling.

List<User> partnerUsers = [
  SELECT Id, ContactId, Contact.AccountId, Contact.Account.Name
  FROM User
  WHERE IsActive = TRUE AND ContactId != NULL AND Contact.AccountId != NULL
  ORDER BY Contact.Account.Name
  LIMIT 20
];

if (partnerUsers.isEmpty()) {
  throw new IllegalArgumentException(
    'No active contact-backed partner user is available for notification seeding.'
  );
}

Map<Id, User> oneUserByAccount = new Map<Id, User>();
for (User partnerUser : partnerUsers)
  if (!oneUserByAccount.containsKey(partnerUser.Contact.AccountId))
    oneUserByAccount.put(partnerUser.Contact.AccountId, partnerUser);

List<String> eventTypes = new List<String>{
  'DealSubmitted',
  'DealApproved',
  'MDFSubmitted',
  'MDFApproved',
  'LeadAccepted',
  'LeadConverted'
};
List<Id> partnerAccountIds = new List<Id>(oneUserByAccount.keySet());
String runKey = Datetime.now().formatGmt('yyyyMMdd-HHmmss');
List<psync__PartnerSync_Event__e> events = new List<psync__PartnerSync_Event__e>();

for (Integer index = 0; index < eventTypes.size(); index++) {
  Id partnerAccountId = partnerAccountIds[Math.mod(index, partnerAccountIds.size())];
  String eventType = eventTypes[index];
  String eventId = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
  events.add(
    new psync__PartnerSync_Event__e(
      psync__Event_Type__c = eventType,
      psync__Record_Id__c = String.valueOf(partnerAccountId),
      psync__Object_Name__c = 'Account',
      psync__Partner_Account_Id__c = String.valueOf(partnerAccountId),
      psync__Summary__c = 'Notification platform seed ' + runKey + ': ' + eventType,
      psync__Severity__c = index == 1 || index == 3 ? 'High' : 'Info',
      psync__Occurred_On__c = System.now(),
      psync__Event_Id__c = eventId,
      psync__Event_Version__c = '2.0',
      psync__Correlation_Id__c = 'Seed-' + runKey,
      psync__Idempotency_Key__c = 'Seed:' + runKey + ':' + eventType
    )
  );
}

Account noRecipientAccount = new Account(
  Name = 'Notification Seed - No Recipient - ' + runKey
);
insert noRecipientAccount;
String noRecipientEventId = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
events.add(
  new psync__PartnerSync_Event__e(
    psync__Event_Type__c = 'DealApproved',
    psync__Record_Id__c = String.valueOf(noRecipientAccount.Id),
    psync__Object_Name__c = 'Account',
    psync__Partner_Account_Id__c = String.valueOf(noRecipientAccount.Id),
    psync__Summary__c = 'Intentional no-recipient DLQ seed ' + runKey,
    psync__Severity__c = 'High',
    psync__Occurred_On__c = System.now(),
    psync__Event_Id__c = noRecipientEventId,
    psync__Event_Version__c = '2.0',
    psync__Correlation_Id__c = 'Seed-' + runKey,
    psync__Idempotency_Key__c = 'Seed:' + runKey + ':NoRecipient'
  )
);

List<Database.SaveResult> results = EventBus.publish(events);
Integer accepted = 0;
List<String> failures = new List<String>();
for (Integer index = 0; index < results.size(); index++) {
  if (results[index].isSuccess()) {
    accepted++;
  } else {
    for (Database.Error error : results[index].getErrors())
      failures.add(
        (eventTypes.size() > index ? eventTypes[index] : 'NoRecipient') +
        ': ' +
        error.getMessage()
      );
  }
}

System.debug(
  LoggingLevel.INFO,
  'NOTIFICATION_SEED run=' + runKey +
  ' partnerAccounts=' + partnerAccountIds.size() +
  ' eventsAccepted=' + accepted +
  ' failures=' + JSON.serialize(failures) +
  ' noRecipientAccount=' + noRecipientAccount.Id
);
