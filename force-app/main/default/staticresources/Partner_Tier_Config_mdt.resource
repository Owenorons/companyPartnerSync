[
  {
    "apiName": "Partner_Tier_Config__mdt",
    "label": "Partner Tier Config",
    "pluralLabel": "Partner Tier Configs",
    "nameFieldType": "Text",
    "nameFieldLabel": "Partner Tier Config Name",
    "fields": [
      {
        "apiName": "Analytics_Access_Level__c",
        "label": "Analytics Access Level",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Badge_Eligibility__c",
        "label": "Badge Eligibility",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Can_Access_Premium_Content__c",
        "label": "Can Access Premium Content",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Deal_Protection_Days__c",
        "label": "Deal Protection Days",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Max_MDF_Budget__c",
        "label": "Max MDF Budget",
        "type": "Number",
        "precision": 18,
        "scale": 2,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Tier_Name__c",
        "label": "Tier Name",
        "description": "Partner tier governed by the configuration.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Minimum_Score__c",
        "label": "Minimum Score",
        "description": "Minimum partner performance score required to reach this tier.",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Lead_Priority__c",
        "label": "Lead Priority",
        "description": "Lead distribution priority for this tier (lower is higher priority).",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "MDF_Multiplier__c",
        "label": "MDF Multiplier",
        "description": "Multiplier applied to MDF budget calculations for this tier.",
        "type": "Number",
        "precision": 5,
        "scale": 2,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Max_Open_MDF__c",
        "label": "Max Open MDF",
        "description": "Maximum concurrently open MDF requests allowed for this tier.",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Certification_Required__c",
        "label": "Certification Required",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Enable_CoSell__c",
        "label": "Enable Co-Sell",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Portal_Branding_Level__c",
        "label": "Portal Branding Level",
        "type": "Picklist",
        "required": false,
        "values": ["Standard", "Premium"]
      }
    ],
    "records": [
      {
        "developerName": "Registered",
        "label": "Registered",
        "protected_x": false,
        "values": {
          "Tier_Name__c": "Registered",
          "Minimum_Score__c": "0",
          "Lead_Priority__c": "5",
          "MDF_Multiplier__c": "1.00"
        }
      },
      {
        "developerName": "Silver",
        "label": "Silver",
        "protected_x": false,
        "values": {
          "Tier_Name__c": "Silver",
          "Minimum_Score__c": "40",
          "Lead_Priority__c": "4",
          "MDF_Multiplier__c": "1.10"
        }
      },
      {
        "developerName": "Gold",
        "label": "Gold",
        "protected_x": false,
        "values": {
          "Tier_Name__c": "Gold",
          "Minimum_Score__c": "60",
          "Lead_Priority__c": "3",
          "MDF_Multiplier__c": "1.25"
        }
      },
      {
        "developerName": "Platinum",
        "label": "Platinum",
        "protected_x": false,
        "values": {
          "Tier_Name__c": "Platinum",
          "Minimum_Score__c": "80",
          "Lead_Priority__c": "2",
          "MDF_Multiplier__c": "1.50"
        }
      },
      {
        "developerName": "Elite",
        "label": "Elite",
        "protected_x": false,
        "values": {
          "Tier_Name__c": "Elite",
          "Minimum_Score__c": "95",
          "Lead_Priority__c": "1",
          "MDF_Multiplier__c": "2.00"
        }
      }
    ]
  }
]
