[
  {
    "apiName": "Audit_Log__c",
    "label": "Audit Log",
    "pluralLabel": "Audit Logs",
    "sharingModel": "Private",
    "nameFieldType": "AutoNumber",
    "nameFieldLabel": "Audit Log Number",
    "displayFormat": "AL-{000000}",
    "fields": [
      {
        "apiName": "Action__c",
        "label": "Action",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Audit_Timestamp__c",
        "label": "Audit Timestamp",
        "type": "DateTime",
        "required": false
      },
      {
        "apiName": "Customer_Account__c",
        "label": "Customer Account",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Account",
        "relationshipName": "Customer_Audit_Logs"
      },
      {
        "apiName": "Metadata_JSON__c",
        "label": "Metadata JSON",
        "type": "LongTextArea",
        "length": 32768,
        "visibleLines": 5
      },
      {
        "apiName": "New_Value_JSON__c",
        "label": "New Value JSON",
        "type": "LongTextArea",
        "length": 32768,
        "visibleLines": 5
      },
      {
        "apiName": "Object_Name__c",
        "label": "Object Name",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Old_Value_JSON__c",
        "label": "Old Value JSON",
        "type": "LongTextArea",
        "length": 32768,
        "visibleLines": 5
      },
      {
        "apiName": "Partner_Account__c",
        "label": "Partner Account",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Account",
        "relationshipName": "Audit_Logs"
      },
      {
        "apiName": "Partner_Contact__c",
        "label": "Partner Contact",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Contact",
        "relationshipName": "Audit_Logs"
      },
      {
        "apiName": "Performed_By_Name__c",
        "label": "Performed By Name",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Performed_By_Type__c",
        "label": "Performed By Type",
        "type": "Picklist",
        "required": false,
        "values": ["Internal", "Partner"]
      },
      {
        "apiName": "Performed_By__c",
        "label": "Performed By",
        "type": "Lookup",
        "required": false,
        "referenceTo": "User",
        "relationshipName": "Performed_Audit_Logs"
      },
      {
        "apiName": "Record_Id__c",
        "label": "Record Id",
        "type": "Text",
        "length": 18,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Record_Name__c",
        "label": "Record Name",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Severity__c",
        "label": "Severity",
        "type": "Picklist",
        "required": false,
        "values": ["Info", "Warn", "Error"]
      },
      {
        "apiName": "Status__c",
        "label": "Status",
        "type": "Picklist",
        "required": false,
        "values": ["Success", "Failed"]
      }
    ],
    "objectPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "objectApiName": "Audit_Log__c",
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
        "field": "Action__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Audit_Timestamp__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Customer_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Metadata_JSON__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "New_Value_JSON__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Object_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Old_Value_JSON__c",
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
        "field": "Partner_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Performed_By_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Performed_By_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Performed_By__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Record_Id__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Record_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Severity__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Status__c",
        "readable": true,
        "editable": true
      }
    ],
    "defaultFieldPermissionSet": "PartnerSync_Internal_Admin",
    "defaultFieldReadable": true,
    "defaultFieldEditable": true
  }
]
