[
  {
    "apiName": "Approval_Routing_Config__mdt",
    "label": "Approval Routing Config",
    "pluralLabel": "Approval Routing Configs",
    "nameFieldType": "Text",
    "nameFieldLabel": "Approval Routing Config Name",
    "fields": [
      {
        "apiName": "Object__c",
        "label": "Object",
        "description": "API name of the object this routing rule applies to.",
        "type": "Picklist",
        "required": false,
        "values": ["MDF_Request__c", "Deal_Registration__c"]
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
        "apiName": "Maximum_Amount__c",
        "label": "Maximum Amount",
        "type": "Number",
        "precision": 18,
        "scale": 2,
        "required": false,
        "unique": false,
        "externalId": false
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
        "apiName": "Active__c",
        "label": "Active",
        "type": "Checkbox",
        "defaultValue": "true"
      }
    ],
    "records": [
      {
        "developerName": "MDF_Manager",
        "label": "MDF - Marketing Manager",
        "protected_x": false,
        "values": {
          "Object__c": "MDF_Request__c",
          "Minimum_Amount__c": "0",
          "Maximum_Amount__c": "5000",
          "Approver_Role__c": "Marketing Manager",
          "Active__c": "true"
        }
      },
      {
        "developerName": "MDF_Director",
        "label": "MDF - Marketing Director",
        "protected_x": false,
        "values": {
          "Object__c": "MDF_Request__c",
          "Minimum_Amount__c": "5001",
          "Maximum_Amount__c": "20000",
          "Approver_Role__c": "Marketing Director",
          "Active__c": "true"
        }
      },
      {
        "developerName": "MDF_VP",
        "label": "MDF - VP Marketing",
        "protected_x": false,
        "values": {
          "Object__c": "MDF_Request__c",
          "Minimum_Amount__c": "20001",
          "Approver_Role__c": "VP Marketing",
          "Active__c": "true"
        }
      },
      {
        "developerName": "Deal_ChannelManager",
        "label": "Deal - Channel Manager",
        "protected_x": false,
        "values": {
          "Object__c": "Deal_Registration__c",
          "Minimum_Amount__c": "0",
          "Maximum_Amount__c": "100000",
          "Approver_Role__c": "Channel Manager",
          "Active__c": "true"
        }
      },
      {
        "developerName": "Deal_RegionalDirector",
        "label": "Deal - Regional Director",
        "protected_x": false,
        "values": {
          "Object__c": "Deal_Registration__c",
          "Minimum_Amount__c": "100001",
          "Maximum_Amount__c": "500000",
          "Approver_Role__c": "Regional Director",
          "Active__c": "true"
        }
      },
      {
        "developerName": "Deal_VP",
        "label": "Deal - VP Sales",
        "protected_x": false,
        "values": {
          "Object__c": "Deal_Registration__c",
          "Minimum_Amount__c": "500001",
          "Approver_Role__c": "VP Sales",
          "Active__c": "true"
        }
      }
    ]
  }
]
