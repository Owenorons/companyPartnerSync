[
  {
    "apiName": "Content_Category_Config__mdt",
    "label": "Content Category Config",
    "pluralLabel": "Content Category Configs",
    "nameFieldType": "Text",
    "nameFieldLabel": "Content Category Config Name",
    "fields": [
      {
        "apiName": "Active__c",
        "label": "Active",
        "type": "Checkbox",
        "defaultValue": "true"
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
        "apiName": "Icon__c",
        "label": "Icon",
        "description": "Lightning Design System icon name for this category.",
        "type": "Text",
        "length": 255,
        "required": false,
        "unique": false,
        "externalId": false
      }
    ],
    "records": [
      {
        "developerName": "Sales",
        "label": "Sales",
        "protected_x": false,
        "values": {
          "Active__c": "true",
          "Sort_Order__c": "10",
          "Icon__c": "utility:knowledge_base"
        }
      },
      {
        "developerName": "Marketing",
        "label": "Marketing",
        "protected_x": false,
        "values": {
          "Active__c": "true",
          "Sort_Order__c": "20",
          "Icon__c": "utility:knowledge_base"
        }
      },
      {
        "developerName": "Technical",
        "label": "Technical",
        "protected_x": false,
        "values": {
          "Active__c": "true",
          "Sort_Order__c": "30",
          "Icon__c": "utility:knowledge_base"
        }
      },
      {
        "developerName": "Certification",
        "label": "Certification",
        "protected_x": false,
        "values": {
          "Active__c": "true",
          "Sort_Order__c": "40",
          "Icon__c": "utility:knowledge_base"
        }
      },
      {
        "developerName": "Enablement",
        "label": "Enablement",
        "protected_x": false,
        "values": {
          "Active__c": "true",
          "Sort_Order__c": "50",
          "Icon__c": "utility:knowledge_base"
        }
      },
      {
        "developerName": "Product",
        "label": "Product",
        "protected_x": false,
        "values": {
          "Active__c": "true",
          "Sort_Order__c": "60",
          "Icon__c": "utility:knowledge_base"
        }
      },
      {
        "developerName": "Competitive",
        "label": "Competitive Intelligence",
        "protected_x": false,
        "values": {
          "Active__c": "true",
          "Sort_Order__c": "70",
          "Icon__c": "utility:knowledge_base"
        }
      },
      {
        "developerName": "ReleaseNotes",
        "label": "Release Notes",
        "protected_x": false,
        "values": {
          "Active__c": "true",
          "Sort_Order__c": "80",
          "Icon__c": "utility:knowledge_base"
        }
      }
    ]
  }
]
