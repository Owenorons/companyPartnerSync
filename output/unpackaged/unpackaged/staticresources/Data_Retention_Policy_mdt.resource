[
  {
    "apiName": "Data_Retention_Policy__mdt",
    "label": "Data Retention Policy",
    "pluralLabel": "Data Retention Policies",
    "nameFieldType": "Text",
    "nameFieldLabel": "Data Retention Policy Name",
    "fields": [
      {
        "apiName": "Object_API_Name__c",
        "label": "Object API Name",
        "description": "API name of the object governed by this retention policy.",
        "type": "Text",
        "length": 255
      },
      {
        "apiName": "Retention_Days__c",
        "label": "Retention Days",
        "description": "Number of days records should be retained.",
        "type": "Number",
        "precision": 18,
        "scale": 0
      },
      {
        "apiName": "Archive_Enabled__c",
        "label": "Archive Enabled",
        "description": "Indicates whether records should be archived before deletion.",
        "type": "Checkbox",
        "defaultValue": "false"
      },
      {
        "apiName": "Active__c",
        "label": "Active",
        "description": "Indicates whether the retention policy is active.",
        "type": "Checkbox",
        "defaultValue": "true"
      }
    ]
  }
]
