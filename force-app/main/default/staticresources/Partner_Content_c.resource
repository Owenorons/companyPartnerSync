[
  {
    "apiName": "Partner_Content__c",
    "label": "Partner Content",
    "pluralLabel": "Partner Content",
    "sharingModel": "Private",
    "defaultFieldPermissionSet": "PartnerSync_Internal_Admin",
    "defaultFieldReadable": true,
    "defaultFieldEditable": true,
    "nameFieldType": "Text",
    "nameFieldLabel": "Title",
    "fields": [
      {
        "apiName": "Category__c",
        "label": "Category",
        "type": "Picklist",
        "required": false,
        "values": [
          "Sales Deck",
          "Product Sheet",
          "Pricing Guide",
          "Marketing Asset",
          "Training",
          "Case Study"
        ]
      },
      {
        "apiName": "Content_Document_Id__c",
        "label": "File",
        "type": "Text",
        "length": 18,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Description__c",
        "label": "Description",
        "description": "Description of the partner content asset.",
        "type": "LongTextArea",
        "length": 32768,
        "visibleLines": 5
      },
      {
        "apiName": "Featured__c",
        "label": "Featured",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Is_Active__c",
        "label": "Is Active",
        "type": "Checkbox",
        "defaultValue": "true"
      },
      {
        "apiName": "Partner_Tier__c",
        "label": "Partner Tier",
        "description": "Partner tier targeted by the content asset.",
        "type": "Picklist",
        "required": false,
        "values": ["Silver", "Gold", "Platinum", "Strategic"]
      },
      {
        "apiName": "Partner_Type__c",
        "label": "Partner Type",
        "description": "Partner type targeted by the content asset.",
        "type": "Picklist",
        "required": false,
        "values": ["Distributor", "Reseller", "Agent", "Dealer", "Referral"]
      },
      {
        "apiName": "Published_Date__c",
        "label": "Published Date",
        "type": "Date",
        "required": false
      },
      {
        "apiName": "Sort_Order__c",
        "label": "Sort Order",
        "type": "Number",
        "precision": 18,
        "scale": 0,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Visibility__c",
        "label": "Visibility",
        "description": "Visibility rule for the partner content asset.",
        "type": "Picklist",
        "required": false,
        "values": ["All Partners", "Internal Only", "Restricted"]
      }
    ],
    "fieldPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Category__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Content_Document_Id__c",
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
        "field": "Featured__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Is_Active__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Partner_Tier__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Partner_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Published_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Sort_Order__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "field": "Visibility__c",
        "readable": true,
        "editable": true
      }
    ],
    "objectPermissions": [
      {
        "permissionSet": "PartnerSync_Internal_Admin",
        "objectApiName": "Partner_Content__c",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "modifyAllRecords": false
      }
    ]
  }
]
