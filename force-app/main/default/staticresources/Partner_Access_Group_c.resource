[
  {
    "apiName": "Partner_Access_Group__c",
    "label": "Partner Access Group",
    "pluralLabel": "Partner Access Groups",
    "sharingModel": "Private",
    "nameFieldType": "AutoNumber",
    "nameFieldLabel": "Partner Access Group Number",
    "displayFormat": "PAG-{000000}",
    "startingNumber": 1,
    "fields": [
      {
        "apiName": "Active__c",
        "label": "Active",
        "description": "Active mapping.",
        "type": "Checkbox",
        "defaultValue": "true"
      },
      {
        "apiName": "Group_Id__c",
        "label": "Group Id",
        "description": "Salesforce Group Id.",
        "type": "Text",
        "length": 18,
        "required": true,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Partner_Account__c",
        "label": "Partner Account",
        "description": "Partner account.",
        "type": "Lookup",
        "required": true,
        "referenceTo": "Account",
        "relationshipName": "Partner_Access_Groups"
      }
    ],
    "fieldPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Active__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Group_Id__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Partner_Account__c",
        "readable": true,
        "editable": true
      }
    ],
    "objectPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "objectApiName": "Partner_Access_Group__c",
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
