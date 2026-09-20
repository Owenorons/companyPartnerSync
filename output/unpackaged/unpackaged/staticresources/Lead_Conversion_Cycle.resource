[
  {
    "apiName": "Deal_Registration__c",
    "label": "Deal Registration",
    "pluralLabel": "Deal Registrations",
    "sharingModel": "Private",
    "nameFieldType": "AutoNumber",
    "nameFieldLabel": "Deal Registration Number",
    "displayFormat": "DR-{000000}",
    "startingNumber": 1,
    "fields": [
      {
        "apiName": "API_Name__c",
        "label": "API Name",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Approval_Notes__c",
        "label": "Approval Notes",
        "type": "LongTextArea",
        "length": 32768,
        "visibleLines": 5
      },
      {
        "apiName": "Approved_By__c",
        "label": "Approved By",
        "description": "User who approved the deal registration.",
        "type": "Lookup",
        "required": false,
        "referenceTo": "User",
        "relationshipName": "Approved_Deal_Registrations"
      },
      {
        "apiName": "Approved_Date__c",
        "label": "Approved Date",
        "type": "DateTime",
        "required": false
      },
      {
        "apiName": "Auto_Number_Format__c",
        "label": "Auto Number Format",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Business_Problem__c",
        "label": "Business Problem",
        "type": "LongTextArea",
        "length": 32768,
        "visibleLines": 5
      },
      {
        "apiName": "Conflict_Resolution_Notes__c",
        "label": "Conflict Resolution Notes",
        "type": "LongTextArea",
        "length": 32768,
        "visibleLines": 5
      },
      {
        "apiName": "Conflict_Status__c",
        "label": "Conflict Status",
        "type": "Picklist",
        "required": false,
        "values": [
          "None",
          "Potential Conflict",
          "Confirmed Conflict",
          "Resolved"
        ]
      },
      {
        "apiName": "Customer_Account__c",
        "label": "Customer Account",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Account",
        "relationshipName": "Customer_Deal_Registrations"
      },
      {
        "apiName": "Customer_Email__c",
        "label": "Customer Email",
        "type": "Email",
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Customer_Name__c",
        "label": "Customer Name",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Deal_Name__c",
        "label": "Deal Name",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Deal_Value__c",
        "label": "Deal Value",
        "description": "Estimated monetary value of the registered deal.",
        "type": "Currency",
        "precision": 18,
        "scale": 2,
        "required": false
      },
      {
        "apiName": "Decision_By__c",
        "label": "Decision By",
        "type": "Lookup",
        "required": false,
        "referenceTo": "User",
        "relationshipName": "Decided_Deal_Registrations"
      },
      {
        "apiName": "Decision_On__c",
        "label": "Decision On",
        "type": "DateTime",
        "required": false
      },
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
        "apiName": "Estimated_Amount__c",
        "label": "Estimated Amount",
        "type": "Currency",
        "precision": 16,
        "scale": 2,
        "required": false
      },
      {
        "apiName": "Estimated_Close_Date__c",
        "label": "Estimated Close Date",
        "type": "Date",
        "required": false
      },
      {
        "apiName": "Estimated_Revenue__c",
        "label": "Estimated Revenue",
        "type": "Currency",
        "precision": 18,
        "scale": 2,
        "required": false
      },
      {
        "apiName": "Expiration_Date__c",
        "label": "Expiration Date",
        "type": "Date",
        "required": false
      },
      {
        "apiName": "Implementation_Timeline__c",
        "label": "Implementation Timeline",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Name_Field_Type__c",
        "label": "Name Field Type",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Notes__c",
        "label": "Notes",
        "type": "LongTextArea",
        "length": 32768,
        "visibleLines": 5
      },
      {
        "apiName": "Object_Label__c",
        "label": "Object Label",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Opportunity__c",
        "label": "Opportunity",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Opportunity",
        "relationshipName": "Deal_Registrations"
      },
      {
        "apiName": "Partner_Account__c",
        "label": "Partner Account",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Account",
        "relationshipName": "Partner_Deal_Registrations"
      },
      {
        "apiName": "Partner_Contact__c",
        "label": "Partner Contact",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Contact",
        "relationshipName": "Deal_Registrations"
      },
      {
        "apiName": "Proposed_Solution__c",
        "label": "Proposed Solution",
        "type": "LongTextArea",
        "length": 32768,
        "visibleLines": 5
      },
      {
        "apiName": "Protection_End_Date__c",
        "label": "Protection End Date",
        "description": "End date for partner deal protection.",
        "type": "Date",
        "required": false
      },
      {
        "apiName": "Protection_Start_Date__c",
        "label": "Protection Start Date",
        "description": "Start date for partner deal protection.",
        "type": "Date",
        "required": false
      },
      {
        "apiName": "Rejection_Reason__c",
        "label": "Rejection Reason",
        "type": "LongTextArea",
        "length": 32768,
        "visibleLines": 5
      },
      {
        "apiName": "Source_Lead__c",
        "label": "Source Lead",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Lead",
        "relationshipName": "Deal_Registrations"
      },
      {
        "apiName": "Stage__c",
        "label": "Stage",
        "description": "Current sales stage for the registered deal.",
        "type": "Picklist",
        "required": false,
        "values": [
          "Qualification",
          "Discovery",
          "Proposal",
          "Negotiation",
          "Closed Won",
          "Closed Lost"
        ]
      },
      {
        "apiName": "Status__c",
        "label": "Status",
        "type": "Picklist",
        "required": false,
        "values": [
          "Draft",
          "Submitted",
          "Under Review",
          "Approved",
          "Rejected",
          "Expired",
          "Converted",
          "Closed Won",
          "Closed Lost"
        ]
      },
      {
        "apiName": "Submitted_Date__c",
        "label": "Submitted Date",
        "type": "DateTime",
        "required": false
      },
      {
        "apiName": "Submitted_On__c",
        "label": "Submitted On",
        "type": "DateTime",
        "required": false
      }
    ],
    "validationRules": [
      {
        "apiName": "Require_Customer_Name_When_Submitted",
        "active": true,
        "errorConditionFormula": "AND(ISPICKVAL(Status__c, \"Submitted\"), ISBLANK(Customer_Name__c))",
        "errorDisplayField": "Customer_Name__c",
        "errorMessage": "Customer Name is required before submitting."
      }
    ],
    "fieldPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "API_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Approval_Notes__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Approved_By__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Approved_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Auto_Number_Format__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Business_Problem__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Conflict_Resolution_Notes__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Conflict_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Customer_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Customer_Email__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Customer_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Deal_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Deal_Value__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Decision_By__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Decision_On__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Description__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Estimated_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Estimated_Close_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Estimated_Revenue__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Expiration_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Implementation_Timeline__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Name_Field_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Notes__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Object_Label__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Opportunity__c",
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
        "field": "Partner_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Proposed_Solution__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Protection_End_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Protection_Start_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Rejection_Reason__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Source_Lead__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Stage__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Status__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Submitted_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Submitted_On__c",
        "readable": true,
        "editable": true
      }
    ],
    "objectPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "objectApiName": "Deal_Registration__c",
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
  },
  {
    "apiName": "Lead",
    "label": "Lead",
    "pluralLabel": "Leads",
    "skipObjectCreation": true,
    "fields": [
      {
        "apiName": "Accepted_Date__c",
        "label": "Accepted Date",
        "type": "DateTime",
        "required": false
      },
      {
        "apiName": "Assigned_Date__c",
        "label": "Assigned Date",
        "type": "DateTime",
        "required": false
      },
      {
        "apiName": "Converted_Deal__c",
        "label": "Converted Deal",
        "description": "Deal registration created when a distributed partner lead is converted.",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Deal_Registration__c",
        "relationshipName": "Converted_Leads",
        "relationshipLabel": "Converted Leads"
      },
      {
        "apiName": "Customer_Account__c",
        "label": "Customer Account",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Account",
        "relationshipName": "Customer_Leads"
      },
      {
        "apiName": "Lead_Distribution_Status__c",
        "label": "Lead Distribution Status",
        "type": "Picklist",
        "required": false,
        "values": [
          "Pending",
          "Assigned",
          "Accepted",
          "Rejected",
          "Converted"
        ]
      },
      {
        "apiName": "Partner_Account__c",
        "label": "Partner Account",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Account",
        "relationshipName": "Partner_Leads"
      },
      {
        "apiName": "Partner_Contact__c",
        "label": "Partner Contact",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Contact",
        "relationshipName": "Partner_Leads"
      },
      {
        "apiName": "Rejected_Date__c",
        "label": "Rejected Date",
        "type": "DateTime",
        "required": false
      },
      {
        "apiName": "Response_SLA_Hours__c",
        "label": "Response SLA Hours",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false
      },
      {
        "apiName": "SLA_Deadline__c",
        "label": "SLA Deadline",
        "type": "DateTime",
        "required": false
      }
    ],
    "fieldPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Accepted_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Assigned_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Converted_Deal__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Customer_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Lead_Distribution_Status__c",
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
        "field": "Partner_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Rejected_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Response_SLA_Hours__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "SLA_Deadline__c",
        "readable": true,
        "editable": true
      }
    ]
  },
  {
    "apiName": "Opportunity",
    "label": "Opportunity",
    "pluralLabel": "Opportunities",
    "skipObjectCreation": true,
    "fields": [
      {
        "apiName": "Lead_Source__c",
        "label": "Lead Source",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Partner_Account__c",
        "label": "Partner Account",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Account",
        "relationshipName": "Partner_Opportunities"
      },
      {
        "apiName": "Partner_Contact__c",
        "label": "Partner Contact",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Contact",
        "relationshipName": "Partner_Opportunities"
      },
      {
        "apiName": "Partner_Deal_Status__c",
        "label": "Partner Deal Status",
        "type": "Picklist",
        "required": false,
        "values": [
          "Pending Registration",
          "Registered",
          "Rejected"
        ]
      },
      {
        "apiName": "Source_Lead__c",
        "label": "Source Lead",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Lead",
        "relationshipName": "Source_Opportunities"
      }
    ],
    "fieldPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Lead_Source__c",
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
        "field": "Partner_Contact__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Partner_Deal_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Source_Lead__c",
        "readable": true,
        "editable": true
      }
    ]
  }
]
