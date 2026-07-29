[
  {
    "apiName": "Partner_Activity__c",
    "label": "Partner Activity",
    "pluralLabel": "Partner Activities",
    "sharingModel": "Private",
    "defaultFieldPermissionSet": "PartnerSync_Internal_Admin",
    "defaultFieldReadable": true,
    "defaultFieldEditable": true,
    "nameFieldType": "Text",
    "nameFieldLabel": "Partner Activity Name",
    "fields": [
      {
        "apiName": "Activity_DateTime__c",
        "label": "Activity DateTime",
        "description": "Date and time when the partner activity occurred.",
        "type": "DateTime",
        "required": false
      },
      {
        "apiName": "Activity_Message__c",
        "label": "Activity Message",
        "description": "Message describing the partner activity.",
        "type": "LongTextArea",
        "length": 32768,
        "visibleLines": 5
      },
      {
        "apiName": "Activity_Type__c",
        "label": "Activity Type",
        "description": "Type of partner activity captured in the stream.",
        "type": "Picklist",
        "required": false,
        "values": ["Deal", "MDF", "Lead", "Content", "Notification", "System"]
      },
      {
        "apiName": "Partner_Account__c",
        "label": "Partner Account",
        "description": "Partner account associated with the activity.",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Account",
        "relationshipName": "Partner_Activities"
      },
      {
        "apiName": "Performed_By_User__c",
        "label": "Performed By User",
        "description": "User who performed the partner activity.",
        "type": "Lookup",
        "required": false,
        "referenceTo": "User",
        "relationshipName": "Performed_Partner_Activities"
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
        "type": "Text",
        "length": 18,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Visibility__c",
        "label": "Visibility",
        "description": "Visibility scope for the partner activity.",
        "type": "Picklist",
        "required": false,
        "values": ["Internal Only", "Partner Visible"]
      }
    ],
    "objectPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "objectApiName": "Partner_Activity__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "modifyAllRecords": false
      }
    ],
    "fieldPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Activity_DateTime__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Activity_Message__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Activity_Type__c",
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
        "field": "Performed_By_User__c",
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
        "field": "Visibility__c",
        "readable": true,
        "editable": true
      }
    ]
  }
]
