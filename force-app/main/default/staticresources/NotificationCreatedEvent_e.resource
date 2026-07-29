[
  {
    "apiName": "NotificationCreatedEvent__e",
    "label": "Notification Created Event",
    "pluralLabel": "Notification Created Events",
    "objectType": "PlatformEvent",
    "eventType": "HighVolume",
    "publishBehavior": "PublishAfterCommit",
    "fields": [
      {
        "apiName": "NotificationId__c",
        "label": "Notification Id",
        "description": "Id of the Partner_Notification__c record that was created.",
        "type": "Text",
        "length": 18,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "RecipientUserId__c",
        "label": "Recipient User Id",
        "description": "Id of the User who should receive this notification. Lets subscribers filter to the current user.",
        "type": "Text",
        "length": 18,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "PartnerAccountId__c",
        "label": "Partner Account Id",
        "description": "Id of the partner account associated with this notification.",
        "type": "Text",
        "length": 18,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Type__c",
        "label": "Type",
        "description": "Notification type, mirrors Partner_Notification__c.Notification_Type__c.",
        "type": "Text",
        "length": 100,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Title__c",
        "label": "Title",
        "description": "Notification title.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Message__c",
        "label": "Message",
        "description": "Notification message body.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "NavigationUrl__c",
        "label": "Navigation Url",
        "description": "Relative URL the client should navigate to when the notification is actioned.",
        "type": "Text",
        "length": 1000,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "EventVersion__c",
        "label": "Event Version",
        "description": "Schema version of this event payload.",
        "type": "Text",
        "length": 20,
        "required": false,
        "unique": false,
        "externalId": false
      }
    ]
  }
]
