[
  {
    "apiName": "PartnerSync_License_Tier__mdt",
    "label": "PartnerSync License Tier",
    "pluralLabel": "PartnerSync License Tiers",
    "nameFieldType": "Text",
    "nameFieldLabel": "License Tier Name",
    "fields": [
      {
        "apiName": "Active__c",
        "label": "Active",
        "type": "Checkbox",
        "defaultValue": "true"
      },
      {
        "apiName": "Enable_AI__c",
        "label": "Enable AI",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Enable_Analytics__c",
        "label": "Enable Analytics",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Enable_MDF__c",
        "label": "Enable MDF",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Enable_Webhooks__c",
        "label": "Enable Webhooks",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Max_AI_Requests__c",
        "label": "Max AI Requests",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Max_Deals_Per_Month__c",
        "label": "Max Deals Per Month",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Max_MDF_Requests__c",
        "label": "Max MDF Requests",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Max_Partners__c",
        "label": "Max Partners",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Tier_Name__c",
        "label": "Tier Name",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      }
    ],
    "records": [
      {
        "developerName": "Trial",
        "label": "Trial",
        "protected_x": false,
        "values": { "Tier_Name__c": "Trial", "Active__c": "true" }
      },
      {
        "developerName": "Starter",
        "label": "Starter",
        "protected_x": false,
        "values": { "Tier_Name__c": "Starter", "Active__c": "true" }
      },
      {
        "developerName": "Professional",
        "label": "Professional",
        "protected_x": false,
        "values": { "Tier_Name__c": "Professional", "Active__c": "true" }
      },
      {
        "developerName": "Enterprise",
        "label": "Enterprise",
        "protected_x": false,
        "values": { "Tier_Name__c": "Enterprise", "Active__c": "true" }
      }
    ]
  }
]
