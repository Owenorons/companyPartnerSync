[
  {
    "apiName": "Badge_Rule_Config__mdt",
    "label": "Badge Rule Config",
    "pluralLabel": "Badge Rule Configs",
    "nameFieldType": "Text",
    "nameFieldLabel": "Badge Rule Config Name",
    "fields": [
      {
        "apiName": "Active__c",
        "label": "Active",
        "description": "Indicates whether the badge rule is active.",
        "type": "Checkbox",
        "defaultValue": "true"
      },
      {
        "apiName": "Badge_Code__c",
        "label": "Badge Code",
        "description": "Badge code awarded by the gamification rule.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Badge_Name__c",
        "label": "Badge Name",
        "description": "Badge name awarded by the gamification rule.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Metric_Name__c",
        "label": "Metric Name",
        "description": "Metric evaluated by the badge rule.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Operator__c",
        "label": "Operator",
        "description": "Comparison operator used by the badge rule.",
        "type": "Picklist",
        "required": false,
        "values": [
          "Equals",
          "Greater Than",
          "Greater Or Equal",
          "Less Than",
          "Less Or Equal"
        ]
      },
      {
        "apiName": "Threshold__c",
        "label": "Threshold",
        "description": "Threshold value required to earn the badge.",
        "type": "Number",
        "precision": 18,
        "scale": 2,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Minimum_Score__c",
        "label": "Minimum Score",
        "description": "Minimum partner performance score required for this tier badge.",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Icon__c",
        "label": "Icon",
        "description": "Icon representing this badge.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      }
    ],
    "records": [
      {
        "developerName": "Bronze",
        "label": "Bronze",
        "protected_x": false,
        "values": {
          "Badge_Name__c": "Bronze",
          "Minimum_Score__c": "0",
          "Icon__c": "bronze",
          "Active__c": "true"
        }
      },
      {
        "developerName": "Silver",
        "label": "Silver",
        "protected_x": false,
        "values": {
          "Badge_Name__c": "Silver",
          "Minimum_Score__c": "40"
        }
      },
      {
        "developerName": "Gold",
        "label": "Gold",
        "protected_x": false,
        "values": {
          "Badge_Name__c": "Gold",
          "Minimum_Score__c": "60"
        }
      },
      {
        "developerName": "Platinum",
        "label": "Platinum",
        "protected_x": false,
        "values": {
          "Badge_Name__c": "Platinum",
          "Minimum_Score__c": "80"
        }
      },
      {
        "developerName": "Elite",
        "label": "Elite",
        "protected_x": false,
        "values": {
          "Badge_Name__c": "Elite",
          "Minimum_Score__c": "95"
        }
      }
    ]
  }
]
