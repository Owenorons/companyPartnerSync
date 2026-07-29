[
  {
    "apiName": "Tenant_Config__mdt",
    "label": "Tenant Config",
    "pluralLabel": "Tenant Configs",
    "nameFieldType": "Text",
    "nameFieldLabel": "Tenant Config Name",
    "fields": [
      {
        "apiName": "Edition__c",
        "label": "Edition",
        "description": "Product edition for this tenant.",
        "type": "Picklist",
        "required": false,
        "values": ["Bronze", "Silver", "Gold", "Enterprise"]
      },
      {
        "apiName": "Enable_Onboarding__c",
        "label": "Enable Onboarding",
        "description": "Indicates whether partner onboarding functionality is enabled.",
        "type": "Checkbox",
        "defaultValue": "true"
      },
      {
        "apiName": "Enable_Deals__c",
        "label": "Enable Deals",
        "description": "Indicates whether deal registration functionality is enabled.",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Enable_Leads__c",
        "label": "Enable Leads",
        "description": "Indicates whether lead distribution functionality is enabled.",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Enable_MDF__c",
        "label": "Enable MDF",
        "description": "Indicates whether MDF functionality is enabled.",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Enable_Content__c",
        "label": "Enable Content",
        "description": "Indicates whether Content Hub functionality is enabled.",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Enable_Analytics__c",
        "label": "Enable Analytics",
        "description": "Indicates whether partner analytics functionality is enabled.",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Enable_AI__c",
        "label": "Enable AI",
        "description": "Indicates whether AI functionality is enabled.",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Deal_Expiry_Days__c",
        "label": "Deal Expiry Days",
        "description": "Default number of days before deal protection expires.",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Lead_SLA_Hours__c",
        "label": "Lead SLA Hours",
        "description": "Default number of hours before an assigned lead breaches SLA.",
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
          "Edition__c": "Bronze",
          "Enable_Onboarding__c": "true",
          "Enable_Deals__c": "false",
          "Enable_Leads__c": "false",
          "Enable_MDF__c": "false",
          "Enable_Content__c": "false",
          "Enable_Analytics__c": "false",
          "Enable_AI__c": "false",
          "Deal_Expiry_Days__c": "30",
          "Lead_SLA_Hours__c": "48"
        }
      }
    ]
  }
]
