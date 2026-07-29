[
  {
    "apiName": "Partner_Record_Share__c",
    "label": "Partner Record Share",
    "pluralLabel": "Partner Record Shares",
    "sharingModel": "Private",
    "nameFieldType": "AutoNumber",
    "nameFieldLabel": "Partner Record Share Number",
    "displayFormat": "PRS-{000000}",
    "startingNumber": 1,
    "fields": [
      {
        "apiName": "Access_Level__c",
        "label": "Access Level",
        "description": "Business access level.",
        "type": "Picklist",
        "required": true,
        "values": ["Read", "Edit", "Review", "Approve"]
      },
      {
        "apiName": "Active__c",
        "label": "Active",
        "description": "Whether the share is active.",
        "type": "Checkbox",
        "defaultValue": "true"
      },
      {
        "apiName": "Expiry_Date__c",
        "label": "Expiry Date",
        "description": "Optional access expiry.",
        "type": "Date",
        "required": false
      },
      {
        "apiName": "Granted_By__c",
        "label": "Granted By",
        "description": "User who granted access.",
        "type": "Lookup",
        "required": false,
        "referenceTo": "User",
        "relationshipName": "Granted_Partner_Record_Shares"
      },
      {
        "apiName": "Granted_On__c",
        "label": "Granted On",
        "description": "Date access was granted.",
        "type": "DateTime",
        "required": false
      },
      {
        "apiName": "Partner_Account__c",
        "label": "Partner Account",
        "description": "Partner account receiving access.",
        "type": "Lookup",
        "required": true,
        "referenceTo": "Account",
        "relationshipName": "Partner_Record_Shares"
      },
      {
        "apiName": "Revoked_On__c",
        "label": "Revoked On",
        "description": "Date access was revoked.",
        "type": "DateTime",
        "required": false
      },
      {
        "apiName": "Share_Reason__c",
        "label": "Share Reason",
        "description": "Reason access was granted.",
        "type": "Picklist",
        "required": true,
        "values": [
          "Co-Sell",
          "Distributor",
          "Regional Manager",
          "Escalation",
          "Deal Conflict Review",
          "MDF Review",
          "Multi-Account Access"
        ]
      },
      {
        "apiName": "Target_Object__c",
        "label": "Target Object",
        "description": "Object type.",
        "type": "Picklist",
        "required": true,
        "values": [
          "Deal Registration",
          "MDF Request",
          "Opportunity",
          "AI Insight",
          "Partner Performance Snapshot"
        ]
      },
      {
        "apiName": "Target_Record_Id__c",
        "label": "Target Record Id",
        "description": "Record being shared.",
        "type": "Text",
        "length": 18,
        "required": true,
        "unique": false,
        "externalId": false
      }
    ],
    "fieldPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Access_Level__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Active__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Expiry_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Granted_By__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Granted_On__c",
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
        "field": "Revoked_On__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Share_Reason__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Target_Object__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Target_Record_Id__c",
        "readable": true,
        "editable": true
      }
    ],
    "objectPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "objectApiName": "Partner_Record_Share__c",
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
