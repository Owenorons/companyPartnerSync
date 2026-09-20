[
  {
    "apiName": "AI_Provider_Config__mdt",
    "label": "AI Provider Config",
    "pluralLabel": "AI Provider Configs",
    "nameFieldType": "Text",
    "nameFieldLabel": "AI Provider Config Name",
    "fields": [
      {
        "apiName": "Provider_Name__c",
        "label": "Provider Name",
        "description": "Display name for this provider.",
        "type": "Text",
        "length": 100,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Provider_Type__c",
        "label": "Provider Type",
        "description": "Implementation type this record routes to.",
        "type": "Picklist",
        "required": false,
        "values": ["Disabled", "OpenAI", "AzureOpenAI"]
      },
      {
        "apiName": "Active__c",
        "label": "Active",
        "description": "Whether this provider can be routed to. Only Disabled ships active by default.",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Named_Credential__c",
        "label": "Named Credential",
        "description": "Named Credential API name used for the callout endpoint and authentication.",
        "type": "Text",
        "length": 100,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Base_URL__c",
        "label": "Base URL",
        "description": "Path appended to the Named Credential callout endpoint.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Model_Name__c",
        "label": "Model Name",
        "description": "Model identifier to request from the provider.",
        "type": "Text",
        "length": 100,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Api_Version__c",
        "label": "Api Version",
        "description": "Provider API version, e.g. required for Azure OpenAI callouts.",
        "type": "Text",
        "length": 50,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Temperature__c",
        "label": "Temperature",
        "description": "Sampling temperature sent to the provider.",
        "type": "Number",
        "precision": 3,
        "scale": 2,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Max_Tokens__c",
        "label": "Max Tokens",
        "description": "Maximum response tokens requested from the provider.",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Timeout_Seconds__c",
        "label": "Timeout Seconds",
        "description": "Callout timeout in seconds.",
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
        "developerName": "Disabled",
        "label": "Disabled",
        "protected_x": false,
        "values": {
          "Provider_Name__c": "Disabled",
          "Provider_Type__c": "Disabled",
          "Active__c": "true"
        }
      },
      {
        "developerName": "OpenAI",
        "label": "OpenAI",
        "protected_x": false,
        "values": {
          "Provider_Name__c": "OpenAI",
          "Provider_Type__c": "OpenAI",
          "Active__c": "false",
          "Named_Credential__c": "PartnerSync_OpenAI",
          "Base_URL__c": "/v1/chat/completions",
          "Model_Name__c": "gpt-5",
          "Temperature__c": "0.30",
          "Max_Tokens__c": "600",
          "Timeout_Seconds__c": "30"
        }
      },
      {
        "developerName": "AzureOpenAI",
        "label": "Azure OpenAI",
        "protected_x": false,
        "values": {
          "Provider_Name__c": "Azure OpenAI",
          "Provider_Type__c": "AzureOpenAI",
          "Active__c": "false",
          "Named_Credential__c": "PartnerSync_Azure_OpenAI",
          "Base_URL__c": "/openai/deployments/partnersync/chat/completions",
          "Api_Version__c": "2024-06-01",
          "Temperature__c": "0.30",
          "Max_Tokens__c": "600",
          "Timeout_Seconds__c": "30"
        }
      }
    ]
  }
]
