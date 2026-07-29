[
  {
    "apiName": "MDF_Request__c",
    "label": "MDF Request",
    "pluralLabel": "MDF Requests",
    "sharingModel": "Private",
    "defaultFieldPermissionSet": "PartnerSync_Internal_Admin",
    "defaultFieldReadable": true,
    "defaultFieldEditable": true,
    "nameFieldType": "Text",
    "nameFieldLabel": "MDF Request Name",
    "fields": [
      {
        "apiName": "Activity_End_Date__c",
        "label": "Activity End Date",
        "description": "End date for the MDF-funded activity.",
        "type": "Date",
        "required": false
      },
      {
        "apiName": "Activity_Start_Date__c",
        "label": "Activity Start Date",
        "description": "Start date for the MDF-funded activity.",
        "type": "Date",
        "required": false
      },
      {
        "apiName": "Actual_Leads__c",
        "label": "Actual Leads",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Approval_Comments__c",
        "label": "Approval Comments",
        "description": "Approval review comments for the MDF request.",
        "type": "LongTextArea",
        "length": 32768,
        "visibleLines": 5
      },
      {
        "apiName": "Approved_Amount__c",
        "label": "Approved Amount",
        "description": "Amount approved for MDF funding.",
        "type": "Currency",
        "precision": 18,
        "scale": 2,
        "required": false
      },
      {
        "apiName": "Approver__c",
        "label": "Approver",
        "description": "User responsible for approving the MDF request.",
        "type": "Lookup",
        "required": false,
        "referenceTo": "User",
        "relationshipName": "Approved_MDF_Requests"
      },
      {
        "apiName": "Budget_Period__c",
        "label": "Budget Period",
        "description": "Budget period associated with the MDF request.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Campaign_Name__c",
        "label": "Campaign Name",
        "description": "Campaign name for the MDF-funded activity.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Campaign_Type__c",
        "label": "Campaign Type",
        "description": "Type of MDF-funded campaign or activity.",
        "type": "Picklist",
        "required": false,
        "values": [
          "Event",
          "Webinar",
          "Digital Advertising",
          "Content Syndication",
          "Direct Mail",
          "Other"
        ]
      },
      {
        "apiName": "Expected_Leads__c",
        "label": "Expected Leads",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "MDF_Request_Number__c",
        "label": "MDF Request Number",
        "type": "AutoNumber",
        "externalId": false,
        "displayFormat": "MDF-{000000}"
      },
      {
        "apiName": "Partner_Account__c",
        "label": "Partner Account",
        "description": "Partner account submitting the MDF request.",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Account",
        "relationshipName": "MDF_Requests"
      },
      {
        "apiName": "Proof_Submitted_Date__c",
        "label": "Proof Submitted Date",
        "description": "Date when proof of performance was submitted.",
        "type": "Date",
        "required": false
      },
      {
        "apiName": "Reimbursement_Status__c",
        "label": "Reimbursement Status",
        "description": "Current reimbursement status for the MDF request.",
        "type": "Picklist",
        "required": false,
        "values": ["Not Started", "Pending", "Processing", "Paid", "Failed"]
      },
      {
        "apiName": "Requested_Amount__c",
        "label": "Requested Amount",
        "description": "Amount requested for MDF funding.",
        "type": "Currency",
        "precision": 18,
        "scale": 2,
        "required": false
      },
      {
        "apiName": "Spent_Amount__c",
        "label": "Spent Amount",
        "description": "Actual amount spent for the MDF activity.",
        "type": "Currency",
        "precision": 18,
        "scale": 2,
        "required": false
      },
      {
        "apiName": "Status__c",
        "label": "Status",
        "description": "Lifecycle status of the MDF request.",
        "type": "Picklist",
        "required": false,
        "values": [
          "Draft",
          "Submitted",
          "Under Review",
          "Approved",
          "Rejected",
          "In Progress",
          "Proof Submitted",
          "Reimbursed",
          "Closed"
        ]
      },
      {
        "apiName": "Submitted_By__c",
        "label": "Submitted By",
        "description": "Partner contact who submitted the MDF request.",
        "type": "Lookup",
        "required": false,
        "referenceTo": "Contact",
        "relationshipName": "Submitted_MDF_Requests"
      }
    ],
    "objectPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "objectApiName": "MDF_Request__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "modifyAllRecords": false
      }
    ],
    "fieldPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Activity_End_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Activity_Start_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Actual_Leads__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Approval_Comments__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Approved_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Approver__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Budget_Period__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Campaign_Name__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Campaign_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Expected_Leads__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "MDF_Request_Number__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Partner_Account__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Proof_Submitted_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Reimbursement_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Requested_Amount__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Spent_Amount__c",
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
        "field": "Submitted_By__c",
        "readable": true,
        "editable": true
      }
    ]
  }
]
