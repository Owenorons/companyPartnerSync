[
  {
    "apiName": "Business_SLA_Config__mdt",
    "label": "Business SLA Config",
    "pluralLabel": "Business SLA Configs",
    "nameFieldType": "Text",
    "nameFieldLabel": "Business SLA Config Name",
    "fields": [
      {
        "apiName": "Active__c",
        "label": "Active",
        "type": "Checkbox",
        "defaultValue": "true"
      },
      {
        "apiName": "Business_Hours_Name__c",
        "label": "Business Hours Name",
        "description": "Business hours name used to calculate SLA timing.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "SLA_Name__c",
        "label": "SLA Name",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Lead_Response_Hours__c",
        "label": "Lead Response Hours",
        "description": "Hours allowed for a partner to respond to an assigned lead.",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Deal_Review_Hours__c",
        "label": "Deal Review Hours",
        "description": "Hours allowed for internal review of a deal registration.",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "MDF_Review_Hours__c",
        "label": "MDF Review Hours",
        "description": "Hours allowed for internal review of an MDF request.",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Proof_Review_Hours__c",
        "label": "Proof Review Hours",
        "description": "Hours allowed for internal review of MDF proof of performance.",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      }
    ],
    "records": [
      {
        "developerName": "Default",
        "label": "Standard SLA",
        "protected_x": false,
        "values": {
          "SLA_Name__c": "Standard SLA",
          "Business_Hours_Name__c": "Default",
          "Lead_Response_Hours__c": "48",
          "Deal_Review_Hours__c": "72",
          "MDF_Review_Hours__c": "120",
          "Proof_Review_Hours__c": "72",
          "Active__c": "true"
        }
      },
      {
        "developerName": "Enterprise",
        "label": "Premium SLA",
        "protected_x": false,
        "values": {
          "SLA_Name__c": "Premium SLA",
          "Lead_Response_Hours__c": "24",
          "Deal_Review_Hours__c": "48",
          "MDF_Review_Hours__c": "72"
        }
      }
    ]
  }
]
