[
  {
    "apiName": "Lead_Distribution_Rule__mdt",
    "label": "Lead Distribution Rule",
    "pluralLabel": "Lead Distribution Rules",
    "nameFieldType": "Text",
    "nameFieldLabel": "Lead Distribution Rule Name",
    "fields": [
      {
        "apiName": "Active__c",
        "label": "Active",
        "type": "Checkbox",
        "defaultValue": "true"
      },
      {
        "apiName": "Assign_To_User_Id__c",
        "label": "Assign To User Id",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Assignment_Method__c",
        "label": "Assignment Method",
        "type": "Picklist",
        "required": false,
        "values": ["Round Robin", "Fixed Owner", "Capacity Based"]
      },
      {
        "apiName": "Capacity_Max__c",
        "label": "Capacity Max",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Capacity_Min__c",
        "label": "Capacity Min",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Country__c",
        "label": "Country",
        "description": "Country matched by the lead distribution rule.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Industry__c",
        "label": "Industry",
        "description": "Industry matched by the lead distribution rule.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Partner_Account_Key__c",
        "label": "Partner Account Key",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Partner_Tier__c",
        "label": "Partner Tier",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Partner_Type__c",
        "label": "Partner Type",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Priority__c",
        "label": "Priority",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Region__c",
        "label": "Region",
        "description": "Region matched by the lead distribution rule.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Rule_Name__c",
        "label": "Rule Name",
        "description": "Business name of the lead distribution rule.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Distribution_Method__c",
        "label": "Distribution Method",
        "description": "Top-level routing strategy this rule applies.",
        "type": "Picklist",
        "required": false,
        "values": [
          "Territory",
          "Product Specialization",
          "Partner Tier",
          "Round Robin",
          "AI Recommendation"
        ]
      }
    ],
    "records": [
      {
        "developerName": "Territory",
        "label": "Territory",
        "protected_x": false,
        "values": {
          "Rule_Name__c": "Territory",
          "Priority__c": "1",
          "Distribution_Method__c": "Territory",
          "Active__c": "true"
        }
      },
      {
        "developerName": "Product",
        "label": "Product",
        "protected_x": false,
        "values": {
          "Priority__c": "2",
          "Distribution_Method__c": "Product Specialization"
        }
      },
      {
        "developerName": "PartnerTier",
        "label": "Partner Tier",
        "protected_x": false,
        "values": {
          "Priority__c": "3",
          "Distribution_Method__c": "Partner Tier"
        }
      },
      {
        "developerName": "RoundRobin",
        "label": "Round Robin",
        "protected_x": false,
        "values": {
          "Priority__c": "4",
          "Distribution_Method__c": "Round Robin"
        }
      },
      {
        "developerName": "AIRecommendation",
        "label": "AI Recommendation",
        "protected_x": false,
        "values": {
          "Priority__c": "5",
          "Distribution_Method__c": "AI Recommendation"
        }
      }
    ]
  }
]
