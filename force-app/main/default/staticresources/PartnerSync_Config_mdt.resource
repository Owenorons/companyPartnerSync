[
  {
    "apiName": "PartnerSync_Config__mdt",
    "label": "PartnerSync Config",
    "pluralLabel": "PartnerSync Configs",
    "nameFieldType": "Text",
    "nameFieldLabel": "PartnerSync Config Name",
    "fields": [
      {
        "apiName": "Default_Deal_Expiry_Days__c",
        "label": "Default Deal Expiry Days",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Default_Lead_Response_Days__c",
        "label": "Default Lead Response Days",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Enable_Content_Hub__c",
        "label": "Enable Content Hub",
        "type": "Checkbox",
        "defaultValue": "true"
      },
      {
        "apiName": "Enable_Deal_Registration__c",
        "label": "Enable Deal Registration",
        "type": "Checkbox",
        "defaultValue": "true"
      },
      {
        "apiName": "Enable_Gamification__c",
        "label": "Enable Gamification",
        "type": "Checkbox",
        "defaultValue": "true"
      },
      {
        "apiName": "Enable_MDF__c",
        "label": "Enable MDF",
        "description": "Indicates whether MDF functionality is enabled.",
        "type": "Checkbox",
        "defaultValue": "true"
      },
      {
        "apiName": "Enable_Partner_Analytics__c",
        "label": "Enable Partner Analytics",
        "type": "Checkbox",
        "defaultValue": "true"
      },
      {
        "apiName": "Enable_Partner_Onboarding__c",
        "label": "Enable Partner Onboarding",
        "type": "Checkbox",
        "defaultValue": "true"
      },
      {
        "apiName": "Max_Open_Deals_Per_Partner__c",
        "label": "Max Open Deals Per Partner",
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
        "label": "Default",
        "protected_x": false,
        "values": {
          "Enable_Partner_Onboarding__c": "true",
          "Enable_Deal_Registration__c": "false",
          "Enable_MDF__c": "false",
          "Enable_Content_Hub__c": "false",
          "Enable_Gamification__c": "false",
          "Enable_Partner_Analytics__c": "false",
          "Default_Deal_Expiry_Days__c": "30",
          "Default_Lead_Response_Days__c": "5",
          "Max_Open_Deals_Per_Partner__c": "50"
        }
      }
    ]
  }
]
