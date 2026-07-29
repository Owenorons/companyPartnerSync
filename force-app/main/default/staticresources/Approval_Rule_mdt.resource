[
  {
    "apiName": "Approval_Rule__mdt",
    "label": "Approval Rule",
    "pluralLabel": "Approval Rules",
    "nameFieldType": "Text",
    "nameFieldLabel": "Approval Rule Name",
    "fields": [
      {
        "apiName": "Active__c",
        "label": "Active",
        "description": "Indicates whether the approval rule is active.",
        "type": "Checkbox",
        "defaultValue": "true"
      },
      {
        "apiName": "Approver_Role__c",
        "label": "Approver Role",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Minimum_Amount__c",
        "label": "Minimum Amount",
        "type": "Number",
        "precision": 18,
        "scale": 2,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Object_Name__c",
        "label": "Object Name",
        "description": "Object name that the approval rule applies to.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Rule_Name__c",
        "label": "Rule Name",
        "description": "Business name of the approval rule.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      }
    ],
    "records": [
      {
        "developerName": "MDF_Marketing_Director",
        "label": "MDF > $10,000 - Marketing Director",
        "protected_x": false,
        "values": {
          "Rule_Name__c": "MDF Marketing Director Threshold",
          "Object_Name__c": "MDF_Request__c",
          "Minimum_Amount__c": "10000",
          "Approver_Role__c": "Marketing Director",
          "Active__c": "true"
        }
      },
      {
        "developerName": "MDF_VP_Marketing",
        "label": "MDF > $50,000 - VP Marketing",
        "protected_x": false,
        "values": {
          "Rule_Name__c": "MDF VP Marketing Threshold",
          "Object_Name__c": "MDF_Request__c",
          "Minimum_Amount__c": "50000",
          "Approver_Role__c": "VP Marketing",
          "Active__c": "true"
        }
      },
      {
        "developerName": "Deal_VP_Sales",
        "label": "Deal > $500,000 - VP Sales",
        "protected_x": false,
        "values": {
          "Rule_Name__c": "Deal VP Sales Threshold",
          "Object_Name__c": "Deal_Registration__c",
          "Minimum_Amount__c": "500000",
          "Approver_Role__c": "VP Sales",
          "Active__c": "true"
        }
      }
    ]
  }
]
