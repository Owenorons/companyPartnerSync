[
  {
    "apiName": "AI_Feature_Config__mdt",
    "label": "AI Feature Config",
    "pluralLabel": "AI Feature Configs",
    "nameFieldType": "Text",
    "nameFieldLabel": "AI Feature Config Name",
    "fields": [
      {
        "apiName": "Feature_Name__c",
        "label": "Feature Name",
        "description": "Display name for this AI feature.",
        "type": "Text",
        "length": 100,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Enabled__c",
        "label": "Enabled",
        "description": "Whether this AI feature is enabled.",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Provider_Name__c",
        "label": "Provider Name",
        "description": "Developer name of the AI_Provider_Config__mdt record to route this feature to.",
        "type": "Text",
        "length": 100,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Prompt_Template__c",
        "label": "Prompt Template",
        "description": "Prompt sent to the provider. Use {context} as the substitution placeholder for request context data.",
        "type": "LongTextArea",
        "length": 32768,
        "visibleLines": 5
      },
      {
        "apiName": "Model_Override__c",
        "label": "Model Override",
        "description": "Optional model name overriding the provider's default for this feature.",
        "type": "Text",
        "length": 100,
        "required": false,
        "unique": false,
        "externalId": false
      }
    ],
    "records": [
      {
        "developerName": "LeadFitScoring",
        "label": "Lead Fit Scoring",
        "protected_x": false,
        "values": {
          "Feature_Name__c": "Lead Fit Scoring",
          "Enabled__c": "true",
          "Provider_Name__c": "OpenAI",
          "Prompt_Template__c": "Assess how well this partner-submitted lead fits successful conversion patterns. Context: {context}. Respond with a fit score from 0-100, a one-sentence rationale, and a recommended next action."
        }
      },
      {
        "developerName": "DealRiskAnalysis",
        "label": "Deal Risk Analysis",
        "protected_x": false,
        "values": {
          "Feature_Name__c": "Deal Risk Analysis",
          "Enabled__c": "true",
          "Provider_Name__c": "OpenAI",
          "Prompt_Template__c": "Assess the risk level of this partner deal registration. Context: {context}. Respond with a risk score from 0-100, a one-sentence rationale, and a recommended next action."
        }
      },
      {
        "developerName": "MDFRecommendation",
        "label": "MDF Recommendation",
        "protected_x": false,
        "values": {
          "Feature_Name__c": "MDF Recommendation",
          "Enabled__c": "false",
          "Provider_Name__c": "Disabled",
          "Prompt_Template__c": "Recommend the most effective MDF campaign types for this partner. Context: {context}. Respond with the top recommendation and a one-sentence rationale."
        }
      },
      {
        "developerName": "PartnerHealthScore",
        "label": "Partner Health Score",
        "protected_x": false,
        "values": {
          "Feature_Name__c": "Partner Health Score",
          "Enabled__c": "false",
          "Provider_Name__c": "Disabled",
          "Prompt_Template__c": "Assess the overall health of this partner relationship. Context: {context}. Respond with a health score from 0-100 and a one-sentence rationale."
        }
      },
      {
        "developerName": "ContentRecommendation",
        "label": "Content Recommendation",
        "protected_x": false,
        "values": {
          "Feature_Name__c": "Content Recommendation",
          "Enabled__c": "false",
          "Provider_Name__c": "Disabled",
          "Prompt_Template__c": "Recommend the most relevant Content Hub items for this partner. Context: {context}. Respond with the top recommendation and a one-sentence rationale."
        }
      }
    ]
  }
]
