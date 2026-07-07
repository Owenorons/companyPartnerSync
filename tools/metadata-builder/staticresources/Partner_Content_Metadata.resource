[
  {
    "apiName": "Partner_Content__c",
    "label": "Partner Content",
    "pluralLabel": "Partner Content",
    "sharingModel": "Private",
    "defaultFieldPermissionSet": "Partner_Sync_Admin",
    "defaultFieldReadable": true,
    "defaultFieldEditable": true,
    "nameFieldType": "Text",
    "nameFieldLabel": "Title",
    "fields": [
      {
        "apiName": "Description__c",
        "label": "Description",
        "description": "Description of the partner content asset.",
        "type": "LongTextArea",
        "length": 32768,
        "visibleLines": 5
      },
      {
        "apiName": "Category__c",
        "label": "Category",
        "description": "Category used to organize the partner content asset.",
        "type": "Picklist",
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
        "description": "Salesforce ContentDocument Id for the file wrapped by this partner content record.",
        "type": "Text",
        "length": 18
      },
      {
        "apiName": "Visibility__c",
        "label": "Visibility",
        "description": "Visibility rule for the partner content asset.",
        "type": "Picklist",
        "values": [
          "All Partners",
          "Internal Only",
          "Restricted"
        ]
      },
      {
        "apiName": "Partner_Tier__c",
        "label": "Partner Tier",
        "description": "Partner tier targeted by the content asset.",
        "type": "Picklist",
        "values": ["Silver", "Gold", "Platinum", "Strategic"]
      },
      {
        "apiName": "Partner_Type__c",
        "label": "Partner Type",
        "description": "Partner type targeted by the content asset.",
        "type": "Picklist",
        "values": ["Distributor", "Reseller", "Agent", "Dealer", "Referral"]
      },
      {
        "apiName": "Is_Active__c",
        "label": "Is Active",
        "description": "Indicates whether the partner content asset is active.",
        "type": "Checkbox",
        "defaultValue": "true"
      },
      {
        "apiName": "Featured__c",
        "label": "Featured",
        "description": "Indicates whether the content asset should be promoted in the Content Hub.",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Published_Date__c",
        "label": "Published Date",
        "description": "Date when the partner content asset was published.",
        "type": "Date"
      },
      {
        "apiName": "Sort_Order__c",
        "label": "Sort Order",
        "description": "Sort order for displaying the partner content asset.",
        "type": "Number",
        "precision": 18,
        "scale": 0
      }
    ],
    "fieldPermissions": [
      {
        "permissionSet": "Partner_Sync_Admin",
        "field": "Description__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "Partner_Sync_Admin",
        "field": "Category__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "Partner_Sync_Admin",
        "field": "Content_Document_Id__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "Partner_Sync_Admin",
        "field": "Visibility__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "Partner_Sync_Admin",
        "field": "Partner_Tier__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "Partner_Sync_Admin",
        "field": "Partner_Type__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "Partner_Sync_Admin",
        "field": "Is_Active__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "Partner_Sync_Admin",
        "field": "Featured__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "Partner_Sync_Admin",
        "field": "Published_Date__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "Partner_Sync_Admin",
        "field": "Sort_Order__c",
        "readable": true,
        "editable": true
      }
    ]
  }
]
