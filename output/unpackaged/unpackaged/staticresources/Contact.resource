[
  {
    "apiName": "Contact",
    "label": "Contact",
    "pluralLabel": "Contacts",
    "skipObjectCreation": true,
    "fields": [
      {
        "apiName": "Can_Submit_Deals__c",
        "label": "Can Submit Deals",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Can_Submit_MDF__c",
        "label": "Can Submit MDF",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Can_View_Analytics__c",
        "label": "Can View Analytics",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Certification_Status__c",
        "label": "Certification Status",
        "description": "Certification status for the partner contact.",
        "type": "Picklist",
        "required": false,
        "values": ["Not Certified", "Active", "Expired"]
      },
      {
        "apiName": "Is_Partner_User__c",
        "label": "Is Partner User",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Portal_Role__c",
        "label": "Portal Role",
        "description": "Portal role assigned to the partner contact.",
        "type": "Picklist",
        "required": false,
        "values": [
          "Partner Admin",
          "Sales Rep",
          "Marketing Rep",
          "Finance",
          "Executive",
          "Read Only"
        ]
      }
    ],
    "fieldPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Can_Submit_Deals__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Can_Submit_MDF__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Can_View_Analytics__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Certification_Status__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Is_Partner_User__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Portal_Role__c",
        "readable": true,
        "editable": true
      }
    ],
    "sharingModel": "ControlledByParent"
  }
]
