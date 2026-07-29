[
  {
    "apiName": "Usage_Metric__c",
    "label": "Usage Metric",
    "pluralLabel": "Usage Metrics",
    "sharingModel": "Private",
    "nameFieldType": "AutoNumber",
    "nameFieldLabel": "Metric ID",
    "displayFormat": "UM-{000000}",
    "startingNumber": 1,
    "fields": [
      {
        "apiName": "License_Tier__c",
        "label": "License Tier",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Metric_Date__c",
        "label": "Metric Date",
        "description": "Usage date for the billable activity.",
        "type": "Date",
        "required": true
      },
      {
        "apiName": "Metric_Type__c",
        "label": "Metric Type",
        "description": "Type of billable partner activity being tracked.",
        "type": "Picklist",
        "required": true,
        "values": [
          "AI Request",
          "Deal Submitted",
          "MDF Request",
          "Lead Assigned",
          "Content Download",
          "Notification Sent"
        ]
      },
      {
        "apiName": "Quantity__c",
        "label": "Quantity",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": true,
        "unique": false,
        "externalId": false
      }
    ],
    "fieldPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "License_Tier__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Metric_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Metric_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Quantity__c",
        "readable": true,
        "editable": true
      }
    ],
    "objectPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "objectApiName": "Usage_Metric__c",
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
