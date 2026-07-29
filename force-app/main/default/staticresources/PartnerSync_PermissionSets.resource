[
  {
    "fullName": "PartnerSync_AI_Admin",
    "label": "PartnerSync AI Admin",
    "description": "Manage AI provider configuration, test AI connections, and view AI-generated insights and logs.",
    "classAccesses": [
      {
        "apexClass": "AIInsightController",
        "enabled": true
      }
    ],
    "objectPermissions": [
      {
        "objectApiName": "AI_Configuration__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "AI_Insight__c",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": false
      }
    ],
    "fieldPermissions": [
      {
        "field": "AI_Configuration__c.Connection_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "AI_Configuration__c.Last_Test_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "AI_Configuration__c.Last_Test_Result__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "AI_Configuration__c.Provider__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "AI_Insight__c.Confidence__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Feature_Name__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Insight_Text__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Partner_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Provider__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Recommendation__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Status__c",
        "readable": true,
        "editable": false
      }
    ]
  },
  {
    "fullName": "PartnerSync_AI_User",
    "label": "PartnerSync AI User",
    "description": "AI Copilot access: view AI-generated insights and next-best-action recommendations.",
    "hasActivationRequired": false,
    "classAccesses": [
      {
        "apexClass": "PartnerAIController",
        "enabled": true
      }
    ],
    "objectPermissions": [
      {
        "objectApiName": "AI_Insight__c",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      }
    ],
    "fieldPermissions": [
      {
        "field": "AI_Insight__c.Confidence__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Feature_Name__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Insight_Text__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Partner_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Provider__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Recommendation__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Status__c",
        "readable": true,
        "editable": false
      }
    ]
  },
  {
    "fullName": "PartnerSync_Analytics_User",
    "label": "PartnerSync Analytics User",
    "hasActivationRequired": false,
    "classAccesses": [
      {
        "apexClass": "AnalyticsController",
        "enabled": true
      },
      {
        "apexClass": "PartnerAIController",
        "enabled": true
      }
    ],
    "objectPermissions": [
      {
        "objectApiName": "AI_Insight__c",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Badge__c",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Performance__c",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      }
    ],
    "fieldPermissions": [
      {
        "field": "AI_Insight__c.Confidence__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Feature_Name__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Insight_Text__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Partner_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Provider__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Recommendation__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Status__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Badge__c.Active__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Badge__c.Awarded_By_Process__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Badge__c.Awarded_On__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Badge__c.Badge_Code__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Badge__c.Badge_Name__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Badge__c.Partner_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Badge__c.Reason__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Content_Downloads__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Leaderboard_Rank__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Leads_Accepted__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Leads_Assigned__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Leads_Converted__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.MDF_Approved__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.MDF_Claimed__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Opportunities_Created__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Opportunities_Won__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Partner_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Partner_Score__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Pipeline_Value__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Reporting_Period_End__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Reporting_Period_Start__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Won_Value__c",
        "readable": true,
        "editable": false
      }
    ]
  },
  {
    "fullName": "PartnerSync_Approval_Override",
    "label": "PartnerSync Approval Override",
    "description": "Add-on escalation authority. Assign alongside PartnerSync_MDF_Reviewer or PartnerSync_Internal_Admin to allow approving an MDF request that exceeds the partner's remaining annual budget. Grants no object access on its own.",
    "hasActivationRequired": false,
    "customPermissions": [
      "PartnerSync_Override_MDF_Budget"
    ]
  },
  {
    "fullName": "PartnerSync_Channel_Manager",
    "label": "PartnerSync Channel Manager",
    "hasActivationRequired": false,
    "classAccesses": [
      {
        "apexClass": "AnalyticsController",
        "enabled": true
      },
      {
        "apexClass": "DealRegistrationController",
        "enabled": true
      },
      {
        "apexClass": "DealReviewController",
        "enabled": true
      },
      {
        "apexClass": "LeadDistributionController",
        "enabled": true
      },
      {
        "apexClass": "MDFController",
        "enabled": true
      },
      {
        "apexClass": "NotificationController",
        "enabled": true
      },
      {
        "apexClass": "PartnerAIController",
        "enabled": true
      },
      {
        "apexClass": "PartnerApplicationController",
        "enabled": true
      },
      {
        "apexClass": "PartnerApprovalController",
        "enabled": true
      },
      {
        "apexClass": "PartnerContentController",
        "enabled": true
      },
      {
        "apexClass": "PartnerPortalController",
        "enabled": true
      }
    ],
    "customPermissions": [
      "PartnerSync_Approve_Deal",
      "PartnerSync_Reject_Deal",
      "PartnerSync_Resolve_Deal_Conflict"
    ],
    "objectPermissions": [
      {
        "objectApiName": "Account",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "AI_Insight__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Audit_Log__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Contact",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Content_Usage_Log__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Deal_Registration__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Lead",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Lead_Distribution_Log__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "MDF_Request__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Opportunity",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Access_Group__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Activity__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Application__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Badge__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Content__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Content_Access__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Notification__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Performance__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Record_Share__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Usage_Metric__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      }
    ],
    "fieldPermissions": [
      {
        "field": "Account.Assigned_Channel_Manager__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Is_Partner__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.MDF_Annual_Budget__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.MDF_Available_Budget__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.MDF_Used__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Onboarding_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Partner_Capacity__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Partner_ID__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Partner_Region__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Partner_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Partner_Tier__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Partner_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Primary_Partner_Admin_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Program_End_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Program_Start_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "AI_Insight__c.Confidence__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "AI_Insight__c.Feature_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "AI_Insight__c.Insight_Text__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "AI_Insight__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "AI_Insight__c.Provider__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "AI_Insight__c.Recommendation__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "AI_Insight__c.Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Action__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Audit_Timestamp__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Customer_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Metadata_JSON__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.New_Value_JSON__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Object_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Old_Value_JSON__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Partner_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Performed_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Performed_By_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Performed_By_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Record_Id__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Record_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Severity__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Contact.Can_Submit_Deals__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Contact.Can_Submit_MDF__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Contact.Can_View_Analytics__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Contact.Certification_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Contact.Is_Partner_User__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Contact.Portal_Role__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Action__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Partner_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Partner_Content__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Performed_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Performed_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.API_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Approval_Notes__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Approved_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Approved_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Auto_Number_Format__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Business_Problem__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Conflict_Resolution_Notes__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Conflict_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Customer_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Customer_Email__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Customer_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Deal_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Deal_Value__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Decision_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Decision_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Description__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Estimated_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Estimated_Close_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Estimated_Revenue__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Expiration_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Implementation_Timeline__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Name_Field_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Notes__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Object_Label__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Opportunity__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Partner_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Proposed_Solution__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Protection_End_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Protection_Start_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Rejection_Reason__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Source_Lead__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Stage__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Submitted_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Submitted_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Action__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Assigned_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Assigned_User__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Assignment_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Lead__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Notes__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Partner_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Performed_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Performed_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Rule_Key__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.Accepted_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.Assigned_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.Converted_Deal__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.Customer_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.Lead_Distribution_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.Partner_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.Rejected_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.Response_SLA_Hours__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.SLA_Deadline__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Activity_End_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Activity_Start_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Actual_Leads__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Approval_Comments__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Approved_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Approver__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Budget_Period__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Campaign_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Campaign_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Expected_Leads__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.MDF_Request_Number__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "MDF_Request__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Proof_Submitted_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Reimbursement_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Requested_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Spent_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Submitted_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Opportunity.Lead_Source__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Opportunity.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Opportunity.Partner_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Opportunity.Partner_Deal_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Opportunity.Source_Lead__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Access_Group__c.Active__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Access_Group__c.Group_Id__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Access_Group__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Activity__c.Activity_DateTime__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Activity__c.Activity_Message__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Activity__c.Activity_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Activity__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Activity__c.Performed_By_User__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Activity__c.Related_Object__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Activity__c.Related_Record_Id__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Activity__c.Visibility__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Application_Number__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Application__c.Application_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Approval_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Approval_Notes__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Assigned_Reviewer__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Business_Email__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Company_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Country__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Created_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Created_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Decision__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Decision_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Decision_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Duplicate_Check_Key__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Normalized_Company_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Partner_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Phone__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Region__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Rejection_Reason__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Requested_Tier__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Source__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Submitted_By_Contact_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Submitted_By_Email__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Submitted_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Website__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Badge__c.Active__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Badge__c.Awarded_By_Process__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Badge__c.Awarded_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Badge__c.Badge_Code__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Badge__c.Badge_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Badge__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Badge__c.Reason__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Category__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Content_Document_Id__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Description__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Featured__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Is_Active__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Partner_Tier__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Partner_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Published_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Sort_Order__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Visibility__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content_Access__c.Access_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content_Access__c.Content_Category__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content_Access__c.ContentDocumentId__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content_Access__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content_Access__c.Partner_Tier__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content_Access__c.Region__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Action_Label__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Action_URL__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Dismissed__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Is_Read__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Message__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Notification_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Priority__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Read_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Recipient_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Recipient_User__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Related_Object__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Related_Record_Id__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Title__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Content_Downloads__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Leaderboard_Rank__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Leads_Accepted__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Leads_Assigned__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Leads_Converted__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.MDF_Approved__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.MDF_Claimed__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Opportunities_Created__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Opportunities_Won__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Partner_Score__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Pipeline_Value__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Reporting_Period_End__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Reporting_Period_Start__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Won_Value__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Record_Share__c.Access_Level__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Record_Share__c.Active__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Record_Share__c.Expiry_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Record_Share__c.Granted_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Record_Share__c.Granted_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Record_Share__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Record_Share__c.Revoked_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Record_Share__c.Share_Reason__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Record_Share__c.Target_Object__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Record_Share__c.Target_Record_Id__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Usage_Metric__c.License_Tier__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Usage_Metric__c.Metric_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Usage_Metric__c.Metric_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Usage_Metric__c.Quantity__c",
        "readable": true,
        "editable": true
      }
    ]
  },
  {
    "fullName": "PartnerSync_Content_Admin",
    "label": "PartnerSync Content Admin",
    "description": "Content Hub management: create, edit, and retire Partner_Content__c records and review usage logs.",
    "hasActivationRequired": false,
    "classAccesses": [
      {
        "apexClass": "PartnerContentController",
        "enabled": true
      }
    ],
    "objectPermissions": [
      {
        "objectApiName": "Content_Usage_Log__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Content__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": true,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": true
      },
      {
        "objectApiName": "Partner_Content_Access__c",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": false
      }
    ],
    "fieldPermissions": [
      {
        "field": "Content_Usage_Log__c.Action__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Partner_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Partner_Content__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Performed_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Performed_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Category__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Content_Document_Id__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Description__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Featured__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Is_Active__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Partner_Tier__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Partner_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Published_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Sort_Order__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Visibility__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content_Access__c.Access_Status__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Content_Access__c.Content_Category__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Content_Access__c.ContentDocumentId__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Content_Access__c.Partner_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Content_Access__c.Partner_Tier__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Content_Access__c.Region__c",
        "readable": true,
        "editable": false
      }
    ]
  },
  {
    "fullName": "PartnerSync_Deal_Reviewer",
    "label": "PartnerSync Deal Reviewer",
    "description": "Standalone deal approval authority. Assign alongside PartnerSync_Executive_User (or any other role) to grant deal approve/reject/conflict-resolution rights without folding them into that role's base permission set.",
    "hasActivationRequired": false,
    "classAccesses": [
      {
        "apexClass": "DealReviewController",
        "enabled": true
      }
    ],
    "customPermissions": [
      "PartnerSync_Approve_Deal",
      "PartnerSync_Reject_Deal",
      "PartnerSync_Resolve_Deal_Conflict"
    ],
    "objectPermissions": [
      {
        "objectApiName": "Deal_Registration__c",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": true
      }
    ],
    "fieldPermissions": [
      {
        "field": "Deal_Registration__c.Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Approval_Notes__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Rejection_Reason__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Decision_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Decision_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Protection_Start_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Protection_End_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Conflict_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Conflict_Resolution_Notes__c",
        "readable": true,
        "editable": true
      }
    ]
  },
  {
    "fullName": "PartnerSync_Executive_User",
    "label": "PartnerSync Executive User",
    "description": "Read-only executive dashboards and AI insights across the partner program. No create/edit/delete anywhere.",
    "hasActivationRequired": false,
    "classAccesses": [
      {
        "apexClass": "AnalyticsController",
        "enabled": true
      },
      {
        "apexClass": "PartnerAIController",
        "enabled": true
      }
    ],
    "customPermissions": [
      "PartnerSync_View_Executive_Analytics",
      "PartnerSync_Export_Executive_Reports"
    ],
    "objectPermissions": [
      {
        "objectApiName": "AI_Insight__c",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Deal_Registration__c",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": true,
        "viewAllFields": true,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "MDF_Request__c",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": true,
        "viewAllFields": true,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Badge__c",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": true,
        "viewAllFields": true,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Performance__c",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Usage_Metric__c",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": true,
        "viewAllFields": true,
        "modifyAllRecords": false
      }
    ],
    "fieldPermissions": [
      {
        "field": "AI_Insight__c.Confidence__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Feature_Name__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Insight_Text__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Partner_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Provider__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Recommendation__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Status__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Content_Downloads__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Leaderboard_Rank__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Leads_Accepted__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Leads_Assigned__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Leads_Converted__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.MDF_Approved__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.MDF_Claimed__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Opportunities_Created__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Opportunities_Won__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Partner_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Partner_Score__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Pipeline_Value__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Reporting_Period_End__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Reporting_Period_Start__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Won_Value__c",
        "readable": true,
        "editable": false
      }
    ]
  },
  {
    "fullName": "PartnerSync_Internal_Admin",
    "label": "PartnerSync Internal Admin",
    "hasActivationRequired": false,
    "classAccesses": [
      {
        "apexClass": "AnalyticsController",
        "enabled": true
      },
      {
        "apexClass": "DealRegistrationController",
        "enabled": true
      },
      {
        "apexClass": "DealReviewController",
        "enabled": true
      },
      {
        "apexClass": "LeadDistributionController",
        "enabled": true
      },
      {
        "apexClass": "MDFController",
        "enabled": true
      },
      {
        "apexClass": "NotificationController",
        "enabled": true
      },
      {
        "apexClass": "PartnerAIController",
        "enabled": true
      },
      {
        "apexClass": "PartnerApplicationController",
        "enabled": true
      },
      {
        "apexClass": "PartnerApprovalController",
        "enabled": true
      },
      {
        "apexClass": "PartnerContentController",
        "enabled": true
      },
      {
        "apexClass": "PartnerPortalController",
        "enabled": true
      }
    ],
    "customPermissions": [
      "PartnerSync_Approve_Deal",
      "PartnerSync_Reject_Deal",
      "PartnerSync_Resolve_Deal_Conflict",
      "PartnerSync_Approve_MDF",
      "PartnerSync_Reject_MDF",
      "PartnerSync_Override_MDF_Budget",
      "PartnerSync_View_Executive_Analytics",
      "PartnerSync_Export_Executive_Reports"
    ],
    "objectPermissions": [
      {
        "objectApiName": "Account",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "AI_Insight__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": true,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": true
      },
      {
        "objectApiName": "Audit_Log__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": true,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": true
      },
      {
        "objectApiName": "Event_DLQ__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": true,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": true
      },
      {
        "objectApiName": "Contact",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Content_Usage_Log__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": true,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": true
      },
      {
        "objectApiName": "Deal_Registration__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": true,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": true
      },
      {
        "objectApiName": "Lead",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Lead_Distribution_Log__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": true,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": true
      },
      {
        "objectApiName": "MDF_Request__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": true,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": true
      },
      {
        "objectApiName": "Opportunity",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Access_Group__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": true,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": true
      },
      {
        "objectApiName": "Partner_Activity__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": true,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": true
      },
      {
        "objectApiName": "Partner_Application__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": true,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": true
      },
      {
        "objectApiName": "Partner_Badge__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": true,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": true
      },
      {
        "objectApiName": "Partner_Content__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": true,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": true
      },
      {
        "objectApiName": "Partner_Content_Access__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": true,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": true
      },
      {
        "objectApiName": "Partner_Notification__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": true,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": true
      },
      {
        "objectApiName": "Partner_Performance__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": true,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": true
      },
      {
        "objectApiName": "Partner_Record_Share__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": true,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": true
      },
      {
        "objectApiName": "Usage_Metric__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": true,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": true
      }
    ],
    "fieldPermissions": [
      {
        "field": "Account.Assigned_Channel_Manager__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Is_Partner__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.MDF_Annual_Budget__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.MDF_Available_Budget__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.MDF_Used__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Onboarding_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Partner_Capacity__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Partner_ID__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Partner_Region__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Partner_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Partner_Tier__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Partner_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Primary_Partner_Admin_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Program_End_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Program_Start_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "AI_Insight__c.Confidence__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "AI_Insight__c.Feature_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "AI_Insight__c.Insight_Text__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "AI_Insight__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "AI_Insight__c.Provider__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "AI_Insight__c.Recommendation__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "AI_Insight__c.Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Action__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Audit_Timestamp__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Customer_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Metadata_JSON__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.New_Value_JSON__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Object_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Old_Value_JSON__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Partner_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Performed_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Performed_By_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Performed_By_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Record_Id__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Record_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Severity__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Audit_Log__c.Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Event_DLQ__c.Error_Message__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Event_DLQ__c.Event_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Event_DLQ__c.Last_Retry_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Event_DLQ__c.Payload__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Event_DLQ__c.Retry_Count__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Event_DLQ__c.Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Contact.Can_Submit_Deals__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Contact.Can_Submit_MDF__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Contact.Can_View_Analytics__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Contact.Certification_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Contact.Is_Partner_User__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Contact.Portal_Role__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Action__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Partner_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Partner_Content__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Performed_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Performed_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.API_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Approval_Notes__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Approved_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Approved_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Auto_Number_Format__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Business_Problem__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Conflict_Resolution_Notes__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Conflict_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Customer_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Customer_Email__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Customer_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Deal_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Deal_Value__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Decision_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Decision_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Description__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Estimated_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Estimated_Close_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Estimated_Revenue__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Expiration_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Implementation_Timeline__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Name_Field_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Notes__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Object_Label__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Opportunity__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Partner_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Proposed_Solution__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Protection_End_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Protection_Start_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Rejection_Reason__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Source_Lead__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Stage__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Submitted_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Submitted_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Action__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Assigned_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Assigned_User__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Assignment_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Lead__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Notes__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Partner_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Performed_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Performed_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Rule_Key__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead_Distribution_Log__c.Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.Accepted_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.Assigned_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.Converted_Deal__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.Customer_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.Lead_Distribution_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.Partner_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.Rejected_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.Response_SLA_Hours__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.SLA_Deadline__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Activity_End_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Activity_Start_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Actual_Leads__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Approval_Comments__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Approved_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Approver__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Budget_Period__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Campaign_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Campaign_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Expected_Leads__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.MDF_Request_Number__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "MDF_Request__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Proof_Submitted_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Reimbursement_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Requested_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Spent_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Submitted_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Opportunity.Lead_Source__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Opportunity.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Opportunity.Partner_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Opportunity.Partner_Deal_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Opportunity.Source_Lead__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Access_Group__c.Active__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Access_Group__c.Group_Id__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Access_Group__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Activity__c.Activity_DateTime__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Activity__c.Activity_Message__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Activity__c.Activity_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Activity__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Activity__c.Performed_By_User__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Activity__c.Related_Object__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Activity__c.Related_Record_Id__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Activity__c.Visibility__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Application_Number__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Application__c.Application_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Approval_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Approval_Notes__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Assigned_Reviewer__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Business_Email__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Company_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Country__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Created_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Created_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Decision__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Decision_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Decision_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Duplicate_Check_Key__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Normalized_Company_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Partner_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Phone__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Region__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Rejection_Reason__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Requested_Tier__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Source__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Submitted_By_Contact_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Submitted_By_Email__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Submitted_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Application__c.Website__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Badge__c.Active__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Badge__c.Awarded_By_Process__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Badge__c.Awarded_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Badge__c.Badge_Code__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Badge__c.Badge_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Badge__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Badge__c.Reason__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Category__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Content_Document_Id__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Description__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Featured__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Is_Active__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Partner_Tier__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Partner_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Published_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Sort_Order__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content__c.Visibility__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content_Access__c.Access_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content_Access__c.Content_Category__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content_Access__c.ContentDocumentId__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content_Access__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content_Access__c.Partner_Tier__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Content_Access__c.Region__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Action_Label__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Action_URL__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Dismissed__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Is_Read__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Message__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Notification_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Priority__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Read_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Recipient_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Recipient_User__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Related_Object__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Related_Record_Id__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Title__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Content_Downloads__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Leaderboard_Rank__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Leads_Accepted__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Leads_Assigned__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Leads_Converted__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.MDF_Approved__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.MDF_Claimed__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Opportunities_Created__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Opportunities_Won__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Partner_Score__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Pipeline_Value__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Reporting_Period_End__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Reporting_Period_Start__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Performance__c.Won_Value__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Record_Share__c.Access_Level__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Record_Share__c.Active__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Record_Share__c.Expiry_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Record_Share__c.Granted_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Record_Share__c.Granted_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Record_Share__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Record_Share__c.Revoked_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Record_Share__c.Share_Reason__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Record_Share__c.Target_Object__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Record_Share__c.Target_Record_Id__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Usage_Metric__c.License_Tier__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Usage_Metric__c.Metric_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Usage_Metric__c.Metric_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Usage_Metric__c.Quantity__c",
        "readable": true,
        "editable": true
      }
    ]
  },
  {
    "fullName": "PartnerSync_MDF_Reviewer",
    "label": "PartnerSync MDF Reviewer",
    "description": "Internal MDF approvals: review, approve, or reject MDF requests across all partners and adjust partner MDF budget usage.",
    "hasActivationRequired": false,
    "classAccesses": [
      {
        "apexClass": "MDFController",
        "enabled": true
      }
    ],
    "customPermissions": [
      "PartnerSync_Approve_MDF",
      "PartnerSync_Reject_MDF",
      "PartnerSync_Override_MDF_Budget"
    ],
    "objectPermissions": [
      {
        "objectApiName": "Account",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "MDF_Request__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": true,
        "viewAllFields": false,
        "modifyAllRecords": true
      }
    ],
    "fieldPermissions": [
      {
        "field": "Account.MDF_Annual_Budget__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.MDF_Available_Budget__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.MDF_Used__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Account.Partner_Status__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Partner_Tier__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "MDF_Request__c.Activity_End_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Activity_Start_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Actual_Leads__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Approval_Comments__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Approved_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Approver__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Budget_Period__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Campaign_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Campaign_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Expected_Leads__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.MDF_Request_Number__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "MDF_Request__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Proof_Submitted_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Reimbursement_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Requested_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Spent_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Submitted_By__c",
        "readable": true,
        "editable": true
      }
    ]
  },
  {
    "fullName": "PartnerSync_Partner_Admin",
    "label": "PartnerSync Partner Admin",
    "hasActivationRequired": false,
    "classAccesses": [
      {
        "apexClass": "AnalyticsController",
        "enabled": true
      },
      {
        "apexClass": "DealRegistrationController",
        "enabled": true
      },
      {
        "apexClass": "LeadDistributionController",
        "enabled": true
      },
      {
        "apexClass": "MDFController",
        "enabled": true
      },
      {
        "apexClass": "NotificationController",
        "enabled": true
      },
      {
        "apexClass": "PartnerAIController",
        "enabled": true
      },
      {
        "apexClass": "PartnerContentController",
        "enabled": true
      },
      {
        "apexClass": "PartnerPortalController",
        "enabled": true
      }
    ],
    "objectPermissions": [
      {
        "objectApiName": "Account",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Contact",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Deal_Registration__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Lead",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "MDF_Request__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Opportunity",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Activity__c",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Badge__c",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Notification__c",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Performance__c",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      }
    ],
    "fieldPermissions": [
      {
        "field": "Account.Assigned_Channel_Manager__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Is_Partner__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.MDF_Annual_Budget__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.MDF_Available_Budget__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.MDF_Used__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Onboarding_Status__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Partner_Capacity__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Partner_ID__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Partner_Region__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Partner_Status__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Partner_Tier__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Partner_Type__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Primary_Partner_Admin_Contact__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Program_End_Date__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Program_Start_Date__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Confidence__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Feature_Name__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Insight_Text__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Partner_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Provider__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Recommendation__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "AI_Insight__c.Status__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Contact.Can_Submit_Deals__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Contact.Can_Submit_MDF__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Contact.Can_View_Analytics__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Contact.Certification_Status__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Contact.Is_Partner_User__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Contact.Portal_Role__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Deal_Registration__c.API_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Approval_Notes__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Approved_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Approved_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Auto_Number_Format__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Business_Problem__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Conflict_Resolution_Notes__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Conflict_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Customer_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Customer_Email__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Customer_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Deal_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Deal_Value__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Decision_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Decision_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Description__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Estimated_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Estimated_Close_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Estimated_Revenue__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Expiration_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Implementation_Timeline__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Name_Field_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Notes__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Object_Label__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Opportunity__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Partner_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Proposed_Solution__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Protection_End_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Protection_Start_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Rejection_Reason__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Source_Lead__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Stage__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Submitted_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Submitted_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.Accepted_Date__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Lead.Assigned_Date__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Lead.Converted_Deal__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Lead.Customer_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Lead.Lead_Distribution_Status__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Lead.Partner_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Lead.Partner_Contact__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Lead.Rejected_Date__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Lead.Response_SLA_Hours__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Lead.SLA_Deadline__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "MDF_Request__c.Activity_End_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Activity_Start_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Actual_Leads__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Approval_Comments__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Approved_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Approver__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Budget_Period__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Campaign_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Campaign_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Expected_Leads__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.MDF_Request_Number__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "MDF_Request__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Proof_Submitted_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Reimbursement_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Requested_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Spent_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Submitted_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Opportunity.Lead_Source__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Opportunity.Partner_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Opportunity.Partner_Contact__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Opportunity.Partner_Deal_Status__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Opportunity.Source_Lead__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Activity__c.Activity_DateTime__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Activity__c.Activity_Message__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Activity__c.Activity_Type__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Activity__c.Partner_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Activity__c.Performed_By_User__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Activity__c.Related_Object__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Activity__c.Related_Record_Id__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Activity__c.Visibility__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Badge__c.Active__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Badge__c.Awarded_By_Process__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Badge__c.Awarded_On__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Badge__c.Badge_Code__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Badge__c.Badge_Name__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Badge__c.Partner_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Badge__c.Reason__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Action_Label__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Action_URL__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Dismissed__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Is_Read__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Message__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Notification_Type__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Partner_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Priority__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Read_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Recipient_Contact__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Recipient_User__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Related_Object__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Related_Record_Id__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Title__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Content_Downloads__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Leaderboard_Rank__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Leads_Accepted__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Leads_Assigned__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Leads_Converted__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.MDF_Approved__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.MDF_Claimed__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Opportunities_Created__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Opportunities_Won__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Partner_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Partner_Score__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Pipeline_Value__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Reporting_Period_End__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Reporting_Period_Start__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Performance__c.Won_Value__c",
        "readable": true,
        "editable": false
      }
    ]
  },
  {
    "fullName": "PartnerSync_Partner_User",
    "label": "PartnerSync Partner User",
    "description": "Standard partner functionality: profile visibility, notifications, deal registration, MDF requests, and Content Hub access.",
    "hasActivationRequired": false,
    "classAccesses": [
      {
        "apexClass": "DealRegistrationController",
        "enabled": true
      },
      {
        "apexClass": "DealReviewController",
        "enabled": true
      },
      {
        "apexClass": "MDFController",
        "enabled": true
      },
      {
        "apexClass": "NotificationController",
        "enabled": true
      },
      {
        "apexClass": "PartnerContentController",
        "enabled": true
      },
      {
        "apexClass": "PartnerPortalController",
        "enabled": true
      }
    ],
    "objectPermissions": [
      {
        "objectApiName": "Account",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Contact",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Content_Usage_Log__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Deal_Registration__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Lead",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "MDF_Request__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Opportunity",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Activity__c",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Content_Access__c",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Content__c",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      },
      {
        "objectApiName": "Partner_Notification__c",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "viewAllFields": false,
        "modifyAllRecords": false
      }
    ],
    "fieldPermissions": [
      {
        "field": "Account.Assigned_Channel_Manager__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Is_Partner__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.MDF_Annual_Budget__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.MDF_Available_Budget__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.MDF_Used__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Onboarding_Status__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Partner_Capacity__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Partner_ID__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Partner_Region__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Partner_Status__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Partner_Tier__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Partner_Type__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Primary_Partner_Admin_Contact__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Program_End_Date__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Account.Program_Start_Date__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Contact.Can_Submit_Deals__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Contact.Can_Submit_MDF__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Contact.Can_View_Analytics__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Contact.Certification_Status__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Contact.Is_Partner_User__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Contact.Portal_Role__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Content_Usage_Log__c.Action__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Partner_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Partner_Content__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Performed_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Content_Usage_Log__c.Performed_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.API_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Approval_Notes__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Approved_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Approved_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Auto_Number_Format__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Business_Problem__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Conflict_Resolution_Notes__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Conflict_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Customer_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Customer_Email__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Customer_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Deal_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Deal_Value__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Decision_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Decision_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Description__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Estimated_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Estimated_Close_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Estimated_Revenue__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Expiration_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Implementation_Timeline__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Name_Field_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Notes__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Object_Label__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Opportunity__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Partner_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Proposed_Solution__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Protection_End_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Protection_Start_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Rejection_Reason__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Source_Lead__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Stage__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Submitted_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Deal_Registration__c.Submitted_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Lead.Accepted_Date__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Lead.Assigned_Date__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Lead.Converted_Deal__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Lead.Customer_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Lead.Lead_Distribution_Status__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Lead.Partner_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Lead.Partner_Contact__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Lead.Rejected_Date__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Lead.Response_SLA_Hours__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Lead.SLA_Deadline__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "MDF_Request__c.Activity_End_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Activity_Start_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Actual_Leads__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Approval_Comments__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Approved_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Approver__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Budget_Period__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Campaign_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Campaign_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Expected_Leads__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.MDF_Request_Number__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "MDF_Request__c.Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Proof_Submitted_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Reimbursement_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Requested_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Spent_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Status__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "MDF_Request__c.Submitted_By__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Opportunity.Lead_Source__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Opportunity.Partner_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Opportunity.Partner_Contact__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Opportunity.Partner_Deal_Status__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Opportunity.Source_Lead__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Activity__c.Activity_DateTime__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Activity__c.Activity_Message__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Activity__c.Activity_Type__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Activity__c.Partner_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Activity__c.Performed_By_User__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Activity__c.Related_Object__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Activity__c.Related_Record_Id__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Activity__c.Visibility__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Content_Access__c.Access_Status__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Content_Access__c.ContentDocumentId__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Content_Access__c.Content_Category__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Content_Access__c.Partner_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Content_Access__c.Partner_Tier__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Content_Access__c.Region__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Content__c.Category__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Content__c.Content_Document_Id__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Content__c.Description__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Content__c.Featured__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Content__c.Is_Active__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Content__c.Partner_Tier__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Content__c.Partner_Type__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Content__c.Published_Date__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Content__c.Sort_Order__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Content__c.Visibility__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Action_Label__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Action_URL__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Dismissed__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Is_Read__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Message__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Notification_Type__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Partner_Account__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Priority__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Read_On__c",
        "readable": true,
        "editable": true
      },
      {
        "field": "Partner_Notification__c.Recipient_Contact__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Recipient_User__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Related_Object__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Related_Record_Id__c",
        "readable": true,
        "editable": false
      },
      {
        "field": "Partner_Notification__c.Title__c",
        "readable": true,
        "editable": false
      }
    ]
  }
]
