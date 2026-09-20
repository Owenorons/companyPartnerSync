[
  {
    "apiName": "AI_Configuration__c",
    "label": "AI Configuration",
    "pluralLabel": "AI Configurations",
    "sharingModel": "Private",
    "nameFieldType": "Text",
    "nameFieldLabel": "Provider Developer Name",
    "fields": [
      {
        "apiName": "Provider__c",
        "label": "Provider",
        "description": "Developer name of the AI_Provider_Config__mdt record this status reflects.",
        "type": "Text",
        "length": 100,
        "required": false,
        "unique": false,
        "externalId": false
      },
      {
        "apiName": "Connection_Status__c",
        "label": "Connection Status",
        "description": "Result of the most recent connection test.",
        "type": "Picklist",
        "required": false,
        "values": ["Not Tested", "Connected", "Failed"]
      },
      {
        "apiName": "Last_Test_Date__c",
        "label": "Last Test Date",
        "description": "When the connection test was last run.",
        "type": "DateTime",
        "required": false
      },
      {
        "apiName": "Last_Test_Result__c",
        "label": "Last Test Result",
        "description": "Message from the most recent connection test.",
        "type": "LongTextArea",
        "length": 32768,
        "visibleLines": 5
      }
    ]
  }
]
