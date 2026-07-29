[
  {
    "apiName": "Feature_Flag__mdt",
    "label": "Feature Flag",
    "pluralLabel": "Feature Flags",
    "nameFieldType": "Text",
    "nameFieldLabel": "Feature Flag Name",
    "fields": [
      {
        "apiName": "Description__c",
        "label": "Description",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Enabled__c",
        "label": "Enabled",
        "description": "Indicates whether the feature flag is enabled.",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Feature_Name__c",
        "label": "Feature Name",
        "description": "Name of the feature controlled by this flag.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "License_Tier__c",
        "label": "License Tier",
        "description": "License tier associated with the feature flag.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      }
    ],
    "records": [
      {
        "developerName": "AI",
        "label": "AI",
        "protected_x": false,
        "values": { "Feature_Name__c": "AI", "Enabled__c": "true" }
      },
      {
        "developerName": "MDF",
        "label": "MDF",
        "protected_x": false,
        "values": { "Feature_Name__c": "MDF", "Enabled__c": "true" }
      },
      {
        "developerName": "Analytics",
        "label": "Analytics",
        "protected_x": false,
        "values": { "Feature_Name__c": "Analytics", "Enabled__c": "true" }
      },
      {
        "developerName": "Notifications",
        "label": "Notifications",
        "protected_x": false,
        "values": { "Feature_Name__c": "Notifications", "Enabled__c": "true" }
      },
      {
        "developerName": "Content_Hub",
        "label": "Content Hub",
        "protected_x": false,
        "values": { "Feature_Name__c": "Content Hub", "Enabled__c": "true" }
      },
      {
        "developerName": "Leaderboards",
        "label": "Leaderboards",
        "protected_x": false,
        "values": { "Feature_Name__c": "Leaderboards", "Enabled__c": "true" }
      },
      {
        "developerName": "Webhooks",
        "label": "Webhooks",
        "protected_x": false,
        "values": { "Feature_Name__c": "Webhooks", "Enabled__c": "true" }
      },
      {
        "developerName": "Agentforce",
        "label": "Agentforce",
        "protected_x": false,
        "values": { "Feature_Name__c": "Agentforce", "Enabled__c": "true" }
      }
    ]
  }
]
