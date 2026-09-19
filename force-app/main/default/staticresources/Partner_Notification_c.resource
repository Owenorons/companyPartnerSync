[
  {
    "apiName": "Partner_Notification__c",
    "label": "Partner Notification",
    "pluralLabel": "Partner Notifications",
    "sharingModel": "Private",
    "nameFieldType": "AutoNumber",
    "nameFieldLabel": "Partner Notification Number",
    "displayFormat": "PN-{000000}",
    "startingNumber": 1,
    "fields": [
      {
        "apiName": "Action_Label__c",
        "label": "Action Label",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Action_URL__c",
        "label": "Action URL",
        "type": "Url",
        "required": false
      },
      {
        "apiName": "Dismissed__c",
        "label": "Dismissed",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Is_Read__c",
        "label": "Is Read",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Message__c",
        "label": "Message",
        "type": "LongTextArea",
        "length": 32768,
        "visibleLines": 5
      },
      {
        "apiName": "Notification_Type__c",
        "label": "Notification Type",
        "description": "Business category for the notification.",
        "type": "Picklist",
        "required": false,
        "values": ["Deal", "MDF", "Lead", "AI", "System", "Content"]
      },
      {
        "apiName": "Partner_Account__c",
        "label": "Partner Account",
        "description": "Partner account associated with the notification.",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Account",
        "relationshipName": "Partner_Notifications"
      },
      {
        "apiName": "Priority__c",
        "label": "Priority",
        "type": "Picklist",
        "required": false,
        "values": ["Low", "Normal", "High"]
      },
      {
        "apiName": "Read_On__c",
        "label": "Read On",
        "type": "DateTime",
        "required": false
      },
      {
        "apiName": "Recipient_Contact__c",
        "label": "Recipient Contact",
        "description": "Recipient Contact",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Contact",
        "relationshipName": "Partner_Notifications",
        "relationshipLabel": "Partner Notifications"
      },
      {
        "apiName": "Recipient_User__c",
        "label": "Recipient User",
        "type": "Lookup",
        "required": false,
        "referenceTo": "User",
        "relationshipName": "Partner_Notifications"
      },
      {
        "apiName": "Related_Object__c",
        "label": "Related Object",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Related_Record_Id__c",
        "label": "Related Record Id",
        "description": "Salesforce record Id related to the notification.",
        "type": "Text",
        "length": 18,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Title__c",
        "label": "Title",
        "description": "Short title displayed for the notification.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      }
    ],
    "fieldPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Action_Label__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Action_URL__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Dismissed__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Is_Read__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Message__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Notification_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Priority__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Read_On__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Recipient_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Recipient_User__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Related_Object__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Related_Record_Id__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Title__c",
        "readable": true,
        "editable": true
      }
    ],
    "objectPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "objectApiName": "Partner_Notification__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "modifyAllRecords": false
      }
    ],
    "defaultFieldPermissionSet": "PartnerSync_Internal_Admin",
    "defaultFieldReadable": true,
    "defaultFieldEditable": true
  }
]
