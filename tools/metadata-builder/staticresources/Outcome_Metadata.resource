[
  {
    "apiName": "Outcome",
    "label": "Outcome",
    "pluralLabel": "Outcomes",
    "skipObjectCreation": true,
    "fields": [
      {
        "apiName": "EmployerAttendees__c",
        "label": "Employer Attendees",
        "description": "Employer Attendees",
        "type": "Text",
        "length": 255
      },
      {
        "apiName": "WitnessesAttendees__c",
        "label": "Witnesses Attendees",
        "description": "Witnesses Attendees",
        "type": "Text",
        "length": 255
      },
      {
        "apiName": "NameOfArbitrationOfficer__c",
        "label": "Name Of Arbitration Officer",
        "description": "Name Of Arbitration Officer",
        "type": "Text",
        "length": 255
      },
      {
        "apiName": "CommentsWitness__c",
        "label": "Comments Witness",
        "description": "Comments Witness",
        "type": "LongTextArea",
        "length": 1000,
        "visibleLines": 5
      },
      {
        "apiName": "CommentsEmployer__c",
        "label": "Comments Employer",
        "description": "Comments Employer",
        "type": "LongTextArea",
        "length": 1000,
        "visibleLines": 5
      },
      {
        "apiName": "CommentsOther__c",
        "label": "Comments Other",
        "description": "Comments Other",
        "type": "LongTextArea",
        "length": 1000,
        "visibleLines": 5
      },
      {
        "apiName": "HearingOccurred__c",
        "label": "Hearing Occurred?",
        "description": "Indicates whether the hearing occurred.",
        "type": "Picklist",
        "values": [
          "Yes",
          "No"
        ]
      },
      {
        "apiName": "HearingDateandTime__c",
        "label": "Hearing Date and Time",
        "description": "Date and time of the hearing.",
        "type": "DateTime"
      },
      {
        "apiName": "CertificateOutcomeType__c",
        "label": "Certificate Outcome Type",
        "description": "Certificate outcome type.",
        "type": "Picklist",
        "values": [
          "Confirm",
          "Revoke",
          "Vary"
        ]
      },
      {
        "apiName": "AreScheduleCostsagreed__c",
        "label": "Are Schedule Costs agreed?",
        "description": "Indicates whether schedule costs are agreed.",
        "type": "Picklist",
        "values": [
          "Yes",
          "No"
        ]
      },
      {
        "apiName": "TypeofHearing__c",
        "label": "Type of Hearing",
        "description": "Type of hearing.",
        "type": "Picklist",
        "values": [
          "Initial - Original Appointment",
          "Initial - Rescheduled Appointment",
          "Subsequent - Adjourned",
          "Subsequent - Suspended"
        ]
      },
      {
        "apiName": "PublicComplaint__c",
        "label": "Public Complaint",
        "description": "Public Complaint",
        "type": "Lookup",
        "referenceTo": "Public_Complaint__c",
        "relationshipName": "Outcomes"
      },
      {
        "apiName": "OutcomeType__c",
        "label": "Outcome Type",
        "description": "Outcome type.",
        "type": "Picklist",
        "values": [
          "Refer to RFA",
          "Hearing Details",
          "Pre-Hearing Review",
          "Hearing Outcome",
          "Outcome Certificate",
          "Conciliation Review",
          "Conference Details",
          "Pre-conciliation Review",
          "Conference Outcome"
        ]
      },
      {
        "apiName": "OutcomeSummary__c",
        "label": "Outcome Summary",
        "description": "Outcome Summary",
        "type": "LongTextArea",
        "length": 32000,
        "visibleLines": 5
      },
      {
        "apiName": "AgentOfferMade__c",
        "label": "Agent Offer Made",
        "description": "Indicates whether an agent offer was made.",
        "type": "Picklist",
        "values": [
          "Yes",
          "No"
        ]
      },
      {
        "apiName": "AgentOfferMadeDetails__c",
        "label": "Agent Offer Made Details",
        "description": "Agent offer made details.",
        "type": "Picklist",
        "values": [
          "Acupuncture Therapy",
          "Chiropractic Therapy",
          "Message Therapy",
          "Physiotherapy",
          "Other Medical and Like Service",
          "Weekly Payments"
        ]
      },
      {
        "apiName": "SpecifyMedandLike__c",
        "label": "Specify Med and Like",
        "description": "Specify medical and like service details.",
        "type": "Text",
        "length": 255
      },
      {
        "apiName": "WeeklyPaymentsDetails__c",
        "label": "Weekly Payments Details",
        "description": "Weekly payments details.",
        "type": "Picklist",
        "values": [
          "0 - 4 Weeks",
          "5 - 13 Weeks",
          "14 - 26 Weeks",
          "27 - 52 Weeks",
          "52+ Weeks"
        ]
      },
      {
        "apiName": "ProceedingwithHearing__c",
        "label": "Proceeding with Hearing?",
        "description": "Indicates whether the hearing is proceeding.",
        "type": "Picklist",
        "values": [
          "Yes",
          "No"
        ]
      },
      {
        "apiName": "ReasonNotProceeding__c",
        "label": "Reason Not Proceeding",
        "description": "Reason the matter is not proceeding.",
        "type": "Picklist",
        "values": [
          "Agent Vary",
          "Agent Withdrawn",
          "Agreement",
          "Direction",
          "Dismiss",
          "Genuine Dispute",
          "No Further Action",
          "No Genuine Dispute",
          "Recommendation",
          "Referred to Medical Panel",
          "Unresolved",
          "Withdrawn by Agent",
          "Withdrawn by Worker",
          "Worker Withdrawn"
        ]
      },
      {
        "apiName": "Discussedwith__c",
        "label": "Discussed with",
        "description": "People or teams discussed with.",
        "type": "MultiselectPicklist",
        "visibleLines": 4,
        "values": [
          "Case Manager",
          "Employer",
          "Eligibility Officer",
          "Technical Manager",
          "Witness",
          "Other"
        ]
      },
      {
        "apiName": "AgreedOutcome__c",
        "label": "Agreed Outcome",
        "description": "Agreed outcome.",
        "type": "Picklist",
        "values": [
          "Accept",
          "Maintain",
          "Vary",
          "Withdraw"
        ]
      },
      {
        "apiName": "DateofCertificate__c",
        "label": "Date of Certificate",
        "description": "Date of certificate.",
        "type": "Date"
      },
      {
        "apiName": "Other__c",
        "label": "Other",
        "description": "Other details.",
        "type": "Text",
        "length": 255
      },
      {
        "apiName": "AgentAdvisedofOffer__c",
        "label": "Agent Advised of Offer",
        "description": "Parties advised of offer.",
        "type": "MultiselectPicklist",
        "visibleLines": 4,
        "values": [
          "WIC",
          "Employer",
          "Worker",
          "Worker Representative"
        ]
      },
      {
        "apiName": "GroundsUsedInNotice__c",
        "label": "Grounds Used In Notice",
        "description": "Grounds used in notice.",
        "type": "MultiselectPicklist",
        "visibleLines": 4,
        "values": [
          "Injury Grounds",
          "Incapacity Grounds",
          "Other"
        ]
      },
      {
        "apiName": "RescheduleComments__c",
        "label": "Reschedule Comments",
        "description": "Comments Reschedule",
        "type": "LongTextArea",
        "length": 1000,
        "visibleLines": 5
      },
      {
        "apiName": "OtherGrounds__c",
        "label": "Other Grounds",
        "description": "Other grounds.",
        "type": "Text",
        "length": 255
      },
      {
        "apiName": "OtherAttendees__c",
        "label": "Other Attendees",
        "description": "Other attendees.",
        "type": "Text",
        "length": 255
      },
      {
        "apiName": "AgentOfferDetails__c",
        "label": "Agent Offer Details",
        "description": "Agent offer details.",
        "type": "MultiselectPicklist",
        "visibleLines": 4,
        "values": [
          "Acupuncture Therapy",
          "Chiropractic Therapy",
          "Message Therapy",
          "Physiotherapy",
          "Other Medical and Like Service",
          "Weekly Payments"
        ]
      },
      {
        "apiName": "OtherLocation__c",
        "label": "Other Location",
        "description": "Other location.",
        "type": "Text",
        "length": 255
      },
      {
        "apiName": "StrategyOutcomeDetails__c",
        "label": "Strategy/Outcome Details",
        "description": "Strategy/Outcome Details",
        "type": "LongTextArea",
        "length": 32000,
        "visibleLines": 5
      },
      {
        "apiName": "StrategyActions__c",
        "label": "Strategy Actions",
        "description": "Strategy Actions",
        "type": "LongTextArea",
        "length": 32000,
        "visibleLines": 5
      },
      {
        "apiName": "Reschedule__c",
        "label": "Reschedule?",
        "description": "Indicates whether to reschedule.",
        "type": "Picklist",
        "values": [
          "Yes",
          "No"
        ]
      },
      {
        "apiName": "DueDate__c",
        "label": "Due Date",
        "description": "Due date.",
        "type": "Date"
      },
      {
        "apiName": "RescheduleConference__c",
        "label": "Reschedule Conference",
        "description": "Indicates whether to reschedule the conference.",
        "type": "Picklist",
        "values": [
          "Yes",
          "No"
        ]
      },
      {
        "apiName": "TypeOfReview__c",
        "label": "Type of Review",
        "description": "Type of review.",
        "type": "Picklist",
        "values": [
          "Initial",
          "Subsequent"
        ]
      },
      {
        "apiName": "TypeofConference__c",
        "label": "Type of Conference",
        "description": "Type of conference.",
        "type": "Picklist",
        "values": [
          "Agile",
          "Rapid",
          "Specialised",
          "Undetermined"
        ]
      },
      {
        "apiName": "HasAgentOfferMade__c",
        "label": "Has Agent Offer Made?",
        "description": "Indicates whether the agent offer was made.",
        "type": "Picklist",
        "values": [
          "Yes",
          "No"
        ]
      },
      {
        "apiName": "ProceedingWithConference__c",
        "label": "Proceeding with Conference?",
        "description": "Indicates whether the conference is proceeding.",
        "type": "Picklist",
        "values": [
          "Yes",
          "No"
        ]
      },
      {
        "apiName": "PK_DisputeResolved__c",
        "label": "Dispute Resolved?",
        "description": "Primary dispute resolved picklist value.",
        "type": "Picklist",
        "values": [
          "Yes",
          "No"
        ]
      },
      {
        "apiName": "DisputeResolved__c",
        "label": "Dispute Resolved?",
        "description": "Calculated dispute resolved value.",
        "type": "Formula",
        "formulaReturnType": "Text",
        "length": 255,
        "formula": "IF(AND(ISPICKVAL(OutcomeType__c, \"Pre-conciliation Review\"), ISPICKVAL(ProceedingWithConference__c, \"No\"), ISPICKVAL(ReasonNotProceeding__c, \"Referred to Medical Panel\")), \"Yes\", TEXT(PK_DisputeResolved__c))"
      },
      {
        "apiName": "GenerateMLApprovalLetters__c",
        "label": "Generate M&L Approval Letters?",
        "description": "Indicates whether to generate M&L approval letters.",
        "type": "Picklist",
        "values": [
          "Yes",
          "No"
        ]
      },
      {
        "apiName": "ConferenceType__c",
        "label": "Conference Type",
        "description": "Conference type.",
        "type": "Picklist",
        "values": [
          "Initial - Original Appointment",
          "Initial - Rescheduled Appointment",
          "Subsequent - Adjourned",
          "Subsequent - Suspended"
        ]
      },
      {
        "apiName": "ConferenceDateandTime__c",
        "label": "Conference Date and Time",
        "description": "Date and time of the conference.",
        "type": "DateTime"
      },
      {
        "apiName": "NameOfConciliationOfficer__c",
        "label": "Name Of Conciliation Officer",
        "description": "Name Of Conciliation Officer",
        "type": "Text",
        "length": 255
      },
      {
        "apiName": "HasAgentMadeOffer__c",
        "label": "Has Agent Made Offer?",
        "description": "Indicates whether the agent made an offer.",
        "type": "Picklist",
        "values": [
          "Yes",
          "No"
        ]
      },
      {
        "apiName": "HasConferenceOccurred__c",
        "label": "Has Conference Occurred?",
        "description": "Indicates whether the conference occurred.",
        "type": "Picklist",
        "values": [
          "Yes",
          "No"
        ]
      },
      {
        "apiName": "ConferenceStatus__c",
        "label": "Conference Status",
        "description": "Conference status.",
        "type": "Picklist",
        "values": [
          "Adjourned",
          "Finalised",
          "Referred to Medical Panel",
          "Suspended"
        ]
      },
      {
        "apiName": "ConciliationOutcome__c",
        "label": "Conciliation Outcome",
        "description": "Conciliation outcome.",
        "type": "Picklist",
        "values": [
          "Agreement",
          "Direction",
          "Dismiss",
          "Genuine Dispute",
          "No Further Action",
          "No Genuine Dispute",
          "Recommendation",
          "Unresolved",
          "Withdrawn by Agent",
          "Withdrawn by Worker"
        ]
      },
      {
        "apiName": "Completeanothercertificateoutcome__c",
        "label": "Complete another certificate outcome?",
        "description": "Indicates whether another certificate outcome should be completed.",
        "type": "Picklist",
        "values": [
          "Yes",
          "No"
        ]
      },
      {
        "apiName": "CertificateDisputeOutcome__c",
        "label": "Certificate Dispute Outcome",
        "description": "Certificate dispute outcome.",
        "type": "Picklist",
        "values": [
          "Adjourned",
          "Agreement",
          "Direction",
          "Dismiss",
          "Genuine Dispute",
          "No Further Action",
          "No Genuine Dispute",
          "Recommendation",
          "Suspended",
          "Unresolved",
          "Variation",
          "Withdrawn by Agent",
          "Withdrawn by Worker"
        ]
      }
    ],
    "objectPermissions": [
      {
        "permissionSet": "RCM_Admin",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": true,
        "modifyAllRecords": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "allowRead": true,
        "allowCreate": true,
        "allowEdit": true,
        "allowDelete": false,
        "viewAllRecords": false,
        "modifyAllRecords": false
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "allowRead": true,
        "allowCreate": false,
        "allowEdit": false,
        "allowDelete": false,
        "viewAllRecords": false,
        "modifyAllRecords": false
      }
    ],
    "fieldPermissions": [
      {
        "permissionSet": "RCM_Admin",
        "field": "EmployerAttendees__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "EmployerAttendees__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "EmployerAttendees__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "WitnessesAttendees__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "WitnessesAttendees__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "WitnessesAttendees__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "NameOfArbitrationOfficer__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "NameOfArbitrationOfficer__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "NameOfArbitrationOfficer__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "CommentsWitness__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "CommentsWitness__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "CommentsWitness__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "CommentsEmployer__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "CommentsEmployer__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "CommentsEmployer__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "CommentsOther__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "CommentsOther__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "CommentsOther__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "HearingOccurred__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "HearingOccurred__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "HearingOccurred__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "HearingDateandTime__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "HearingDateandTime__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "HearingDateandTime__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "CertificateOutcomeType__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "CertificateOutcomeType__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "CertificateOutcomeType__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "AreScheduleCostsagreed__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "AreScheduleCostsagreed__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "AreScheduleCostsagreed__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "TypeofHearing__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "TypeofHearing__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "TypeofHearing__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "PublicComplaint__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "PublicComplaint__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "PublicComplaint__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "OutcomeType__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "OutcomeType__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "OutcomeType__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "OutcomeSummary__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "OutcomeSummary__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "OutcomeSummary__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "AgentOfferMade__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "AgentOfferMade__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "AgentOfferMade__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "AgentOfferMadeDetails__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "AgentOfferMadeDetails__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "AgentOfferMadeDetails__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "SpecifyMedandLike__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "SpecifyMedandLike__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "SpecifyMedandLike__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "WeeklyPaymentsDetails__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "WeeklyPaymentsDetails__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "WeeklyPaymentsDetails__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "ProceedingwithHearing__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "ProceedingwithHearing__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "ProceedingwithHearing__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "ReasonNotProceeding__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "ReasonNotProceeding__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "ReasonNotProceeding__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "Discussedwith__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "Discussedwith__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "Discussedwith__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "AgreedOutcome__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "AgreedOutcome__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "AgreedOutcome__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "DateofCertificate__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "DateofCertificate__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "DateofCertificate__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "Other__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "Other__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "Other__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "AgentAdvisedofOffer__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "AgentAdvisedofOffer__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "AgentAdvisedofOffer__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "GroundsUsedInNotice__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "GroundsUsedInNotice__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "GroundsUsedInNotice__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "RescheduleComments__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "RescheduleComments__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "RescheduleComments__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "OtherGrounds__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "OtherGrounds__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "OtherGrounds__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "OtherAttendees__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "OtherAttendees__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "OtherAttendees__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "AgentOfferDetails__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "AgentOfferDetails__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "AgentOfferDetails__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "OtherLocation__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "OtherLocation__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "OtherLocation__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "StrategyOutcomeDetails__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "StrategyOutcomeDetails__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "StrategyOutcomeDetails__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "StrategyActions__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "StrategyActions__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "StrategyActions__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "Reschedule__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "Reschedule__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "Reschedule__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "DueDate__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "DueDate__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "DueDate__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "RescheduleConference__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "RescheduleConference__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "RescheduleConference__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "TypeOfReview__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "TypeOfReview__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "TypeOfReview__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "TypeofConference__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "TypeofConference__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "TypeofConference__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "HasAgentOfferMade__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "HasAgentOfferMade__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "HasAgentOfferMade__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "ProceedingWithConference__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "ProceedingWithConference__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "ProceedingWithConference__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "PK_DisputeResolved__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "PK_DisputeResolved__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "PK_DisputeResolved__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "DisputeResolved__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "DisputeResolved__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "DisputeResolved__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "GenerateMLApprovalLetters__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "GenerateMLApprovalLetters__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "GenerateMLApprovalLetters__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "ConferenceType__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "ConferenceType__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "ConferenceType__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "ConferenceDateandTime__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "ConferenceDateandTime__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "ConferenceDateandTime__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "NameOfConciliationOfficer__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "NameOfConciliationOfficer__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "NameOfConciliationOfficer__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "HasAgentMadeOffer__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "HasAgentMadeOffer__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "HasAgentMadeOffer__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "HasConferenceOccurred__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "HasConferenceOccurred__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "HasConferenceOccurred__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "ConferenceStatus__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "ConferenceStatus__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "ConferenceStatus__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "ConciliationOutcome__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "ConciliationOutcome__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "ConciliationOutcome__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "Completeanothercertificateoutcome__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "Completeanothercertificateoutcome__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "Completeanothercertificateoutcome__c",
        "readable": true,
        "editable": false
      },
      {
        "permissionSet": "RCM_Admin",
        "field": "CertificateDisputeOutcome__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Create_Edit_Access",
        "field": "CertificateDisputeOutcome__c",
        "readable": true,
        "editable": true
      },
      {
        "permissionSet": "RCM_Disputes_and_Conciliation_Read_Access",
        "field": "CertificateDisputeOutcome__c",
        "readable": true,
        "editable": false
      }
    ]
  }
]
