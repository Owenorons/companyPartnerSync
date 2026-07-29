[
  {
    "apiName": "Event_DLQ__c",
    "label": "Event DLQ",
    "pluralLabel": "Event DLQs",
    "sharingModel": "Private",
    "nameFieldType": "AutoNumber",
    "nameFieldLabel": "Event DLQ Number",
    "displayFormat": "DLQ-{000000}",
    "startingNumber": 1,
    "fields": [
      {
        "apiName": "Event_Type__c",
        "label": "Event Type",
        "description": "Type of the event that failed processing.",
        "type": "Text",
        "length": 100,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Payload__c",
        "label": "Payload",
        "description": "Serialized JSON payload of the event that failed processing.",
        "type": "LongTextArea",
        "length": 32768,
        "visibleLines": 5
      },
      {
        "apiName": "Error_Message__c",
        "label": "Error Message",
        "description": "Exception message captured when the event failed processing.",
        "type": "LongTextArea",
        "length": 32768,
        "visibleLines": 5
      },
      {
        "apiName": "Retry_Count__c",
        "label": "Retry Count",
        "description": "Number of times reprocessing has been attempted.",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false,
        "defaultValue": "0"
      },
      {
        "apiName": "Status__c",
        "label": "Status",
        "description": "Processing status of the failed event.",
        "type": "Picklist",
        "required": false,
        "values": ["New", "Retried", "Failed", "Resolved"]
      },
      {
        "apiName": "Last_Retry_On__c",
        "label": "Last Retry On",
        "description": "Timestamp of the most recent reprocessing attempt.",
        "type": "DateTime",
        "required": false
      }
    ],
    "fieldPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Event_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Payload__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Error_Message__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Retry_Count__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Status__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Last_Retry_On__c",
        "readable": true,
        "editable": true
      }
    ],
    "objectPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "objectApiName": "Event_DLQ__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": true,
        "viewAllRecords": true,
        "modifyAllRecords": true
      }
    ]
  }
]
