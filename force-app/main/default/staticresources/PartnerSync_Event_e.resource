[
  {
    "apiName": "PartnerSync_Event__e",
    "label": "PartnerSync Event",
    "pluralLabel": "PartnerSync Events",
    "objectType": "PlatformEvent",
    "eventType": "HighVolume",
    "publishBehavior": "PublishAfterCommit",
    "fields": [
      {
        "apiName": "Event_Type__c",
        "label": "Event Type",
        "description": "Business event type discriminator, e.g. DealSubmitted, MDFApproved.",
        "type": "Text",
        "length": 100,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Record_Id__c",
        "label": "Record Id",
        "description": "Id of the record the event relates to.",
        "type": "Text",
        "length": 18,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Object_Name__c",
        "label": "Object Name",
        "description": "API name of the object the related record belongs to.",
        "type": "Text",
        "length": 100,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Partner_Account_Id__c",
        "label": "Partner Account Id",
        "description": "Id of the partner account associated with this event.",
        "type": "Text",
        "length": 18,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Summary__c",
        "label": "Summary",
        "description": "Short human-readable summary of the event.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Severity__c",
        "label": "Severity",
        "description": "Event severity, e.g. Info, Warning, Error.",
        "type": "Text",
        "length": 50,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Occurred_On__c",
        "label": "Occurred On",
        "description": "Timestamp the underlying business event occurred.",
        "type": "DateTime",
        "required": false
      }
    ]
  }
]
