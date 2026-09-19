[
  {
    "apiName": "AI_Insight__c",
    "label": "AI Insight",
    "pluralLabel": "AI Insights",
    "sharingModel": "Private",
    "nameFieldType": "AutoNumber",
    "nameFieldLabel": "AI Insight Number",
    "displayFormat": "AI-{000000}",
    "startingNumber": 1,
    "fields": [
      {
        "apiName": "Confidence__c",
        "label": "Confidence",
        "description": "Confidence score returned for the AI insight.",
        "type": "Percent",
        "precision": 5,
        "scale": 2,
        "required": false
      },
      {
        "apiName": "Feature_Name__c",
        "label": "Feature Name",
        "type": "Picklist",
        "required": false,
        "values": [
          "AI",
          "MDF",
          "Analytics",
          "Notifications",
          "Content Hub",
          "Leaderboards",
          "Webhooks",
          "Agentforce"
        ]
      },
      {
        "apiName": "Insight_Text__c",
        "label": "Insight Text",
        "description": "Generated AI insight text.",
        "type": "LongTextArea",
        "length": 32768,
        "visibleLines": 5
      },
      {
        "apiName": "Partner_Account__c",
        "label": "Partner Account",
        "description": "Partner account associated with the AI insight.",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Account",
        "relationshipName": "AI_Insights"
      },
      {
        "apiName": "Provider__c",
        "label": "Provider",
        "description": "AI provider that generated the insight.",
        "type": "Picklist",
        "required": false,
        "values": ["OpenAI", "Azure OpenAI", "Einstein", "Agentforce"]
      },
      {
        "apiName": "Recommendation__c",
        "label": "Recommendation",
        "description": "Recommended action generated from the AI insight.",
        "type": "LongTextArea",
        "length": 32768,
        "visibleLines": 5
      },
      {
        "apiName": "Status__c",
        "label": "Status",
        "description": "Lifecycle status of the AI insight.",
        "type": "Picklist",
        "required": false,
        "values": [
          "Draft",
          "Generated",
          "Reviewed",
          "Accepted",
          "Dismissed",
          "Archived"
        ]
      }
    ],
    "fieldPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Confidence__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Feature_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Insight_Text__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Provider__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Recommendation__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Status__c",
        "readable": true,
        "editable": true
      }
    ],
    "objectPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "objectApiName": "AI_Insight__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "modifyAllRecords": false
      }
    ],
    "defaultFieldPermissionSet": "PartnerSync_Internal_Admin",
    "defaultFieldReadable": true,
    "defaultFieldEditable": true
  }
]
