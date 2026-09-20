[
  {
    "apiName": "Webhook_Endpoint__mdt",
    "label": "Webhook Endpoint",
    "pluralLabel": "Webhook Endpoints",
    "nameFieldType": "Text",
    "nameFieldLabel": "Webhook Endpoint Name",
    "fields": [
      {
        "apiName": "Active__c",
        "label": "Active",
        "description": "Indicates whether the webhook endpoint is active.",
        "type": "Checkbox",
        "defaultValue": "true"
      },
      {
        "apiName": "Endpoint_Name__c",
        "label": "Endpoint Name",
        "description": "Business name of the webhook endpoint.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Event_Filter__c",
        "label": "Event Filter",
        "description": "Semicolon-separated list of events that trigger this webhook, or All.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Secret_Key__c",
        "label": "Secret Key",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "URL__c",
        "label": "URL",
        "description": "Webhook endpoint URL.",
        "type": "Url",
        "required": false
      },
      {
        "apiName": "Retry_Count__c",
        "label": "Retry Count",
        "description": "Number of retry attempts on delivery failure.",
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
        "developerName": "Default",
        "label": "Default Webhook",
        "protected_x": false,
        "values": {
          "Endpoint_Name__c": "Default Webhook",
          "URL__c": "https://example.com/webhooks/partnersync",
          "Secret_Key__c": "CHANGE_ME",
          "Active__c": "false",
          "Retry_Count__c": "3",
          "Timeout_Seconds__c": "30",
          "Event_Filter__c": "All"
        }
      },
      {
        "developerName": "SalesforceCRM",
        "label": "Salesforce CRM",
        "protected_x": false,
        "values": {
          "Endpoint_Name__c": "Salesforce CRM",
          "Active__c": "false",
          "Event_Filter__c": "Deal Approved;MDF Approved"
        }
      },
      {
        "developerName": "ERP",
        "label": "ERP",
        "protected_x": false,
        "values": {
          "Endpoint_Name__c": "ERP Integration",
          "Active__c": "false",
          "Event_Filter__c": "Closed Won"
        }
      }
    ]
  }
]
