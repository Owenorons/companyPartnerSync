[
  {
    "apiName": "Partner_Performance__c",
    "label": "Partner Performance",
    "pluralLabel": "Partner Performance Snapshots",
    "sharingModel": "Private",
    "defaultFieldPermissionSet": "PartnerSync_Internal_Admin",
    "defaultFieldReadable": true,
    "defaultFieldEditable": true,
    "nameFieldType": "Text",
    "nameFieldLabel": "Partner Performance Name",
    "fields": [
      {
        "apiName": "Content_Downloads__c",
        "label": "Content Downloads",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Leaderboard_Rank__c",
        "label": "Leaderboard Rank",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Leads_Accepted__c",
        "label": "Leads Accepted",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Leads_Assigned__c",
        "label": "Leads Assigned",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Leads_Converted__c",
        "label": "Leads Converted",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "MDF_Approved__c",
        "label": "MDF Approved",
        "type": "Currency",
        "precision": 18,
        "scale": 2,
        "required": false
      },
      {
        "apiName": "MDF_Claimed__c",
        "label": "MDF Claimed",
        "type": "Currency",
        "precision": 18,
        "scale": 2,
        "required": false
      },
      {
        "apiName": "Opportunities_Created__c",
        "label": "Opportunities Created",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Opportunities_Won__c",
        "label": "Opportunities Won",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Partner_Account__c",
        "label": "Partner Account",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Account",
        "relationshipName": "Partner_Performance_Snapshots"
      },
      {
        "apiName": "Partner_Score__c",
        "label": "Partner Score",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Pipeline_Value__c",
        "label": "Pipeline Value",
        "type": "Currency",
        "precision": 18,
        "scale": 2,
        "required": false
      },
      {
        "apiName": "Reporting_Period_End__c",
        "label": "Reporting Period End",
        "description": "End date for the reporting period.",
        "type": "Date",
        "required": false
      },
      {
        "apiName": "Reporting_Period_Start__c",
        "label": "Reporting Period Start",
        "description": "Start date for the reporting period.",
        "type": "Date",
        "required": false
      },
      {
        "apiName": "Won_Value__c",
        "label": "Won Value",
        "type": "Currency",
        "precision": 18,
        "scale": 2,
        "required": false
      }
    ],
    "objectPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "objectApiName": "Partner_Performance__c",
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
        "field": "Content_Downloads__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Leaderboard_Rank__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Leads_Accepted__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Leads_Assigned__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Leads_Converted__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "MDF_Approved__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "MDF_Claimed__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Opportunities_Created__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Opportunities_Won__c",
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
        "field": "Partner_Score__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Pipeline_Value__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Reporting_Period_End__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Reporting_Period_Start__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Won_Value__c",
        "readable": true,
        "editable": true
      }
    ]
  }
]
