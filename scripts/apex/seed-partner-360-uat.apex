// Repeatable Partner 360 UAT fixture for a namespaced scratch org.
// Creates one deliberately blocked partner with lifecycle and commercial data.

String partnerName = 'Partner 360 UAT - Blocked';
List<Account> existing = [
  SELECT Id
  FROM Account
  WHERE Name = :partnerName
  LIMIT 1
];

if (!existing.isEmpty()) {
  System.debug(
    LoggingLevel.INFO,
    'PARTNER_360_UAT already exists; partnerAccountId=' + existing[0].Id
  );
} else {
  Account partner = new Account(
    Name = partnerName,
    psync__Is_Partner__c = true,
    psync__Partner_ID__c = 'UAT-P360-BLOCKED',
    psync__Partner_Status__c = 'Onboarding',
    psync__Partner_Tier__c = 'Gold',
    psync__Partner_Type__c = 'Reseller',
    psync__Partner_Region__c = 'ANZ'
  );
  insert partner;

  Contact contact = new Contact(
    AccountId = partner.Id,
    FirstName = 'Jordan',
    LastName = 'PartnerUAT',
    Email = 'partner360-uat@example.test',
    psync__Is_Partner_User__c = true
  );
  insert contact;

  psync__Partner_Application__c application = new psync__Partner_Application__c(
    Name = partnerName,
    psync__Company_Name__c = partnerName,
    psync__Business_Email__c = 'partner360-uat@example.test',
    psync__Application_Status__c = 'Approved',
    psync__Country__c = 'Australia',
    psync__Partner_Type__c = 'Reseller',
    psync__Requested_Tier__c = 'Gold'
  );
  insert application;

  psync__Partner_Onboarding__c onboarding = new psync__Partner_Onboarding__c(
    psync__Application__c = application.Id,
    psync__Partner_Account__c = partner.Id,
    psync__Onboarding_Key__c = String.valueOf(application.Id),
    psync__Status__c = 'Onboarding',
    psync__Current_Stage__c = 'Readiness',
    psync__Activation_Gate_Status__c = 'Blocked',
    psync__Recertification_Due_On__c = Date.today().addDays(90),
    psync__Version_Number__c = 1
  );
  insert onboarding;

  psync__Partner_Relationship__c relationship = new psync__Partner_Relationship__c(
    psync__Onboarding__c = onboarding.Id,
    psync__Relationship_Key__c = onboarding.Id + ':UAT-REL',
    psync__Account__c = partner.Id,
    psync__Programme_Key__c = 'RESELLER',
    psync__Status__c = 'Pending Enablement'
  );
  insert relationship;

  insert new psync__Partner_Document_Requirement__c(
    psync__Onboarding__c = onboarding.Id,
    psync__Requirement_Key__c = onboarding.Id + ':UAT-DOC',
    psync__Document_Type__c = 'Business Registration',
    psync__Requirement_Level__c = 'Mandatory',
    psync__Gate__c = 'Approval',
    psync__Status__c = 'Awaiting Submission',
    psync__Blocking__c = true,
    psync__Waiver_Eligible__c = false
  );

  psync__Partner_Assessment__c assessment = new psync__Partner_Assessment__c(
    psync__Onboarding__c = onboarding.Id,
    psync__Assessment_Key__c = onboarding.Id + ':UAT-RISK',
    psync__Assessment_Type__c = 'Sanctions',
    psync__Status__c = 'Failed',
    psync__Blocking__c = true
  );
  insert assessment;
  insert new psync__Partner_Assessment_Finding__c(
    psync__Assessment__c = assessment.Id,
    psync__Finding_Key__c = assessment.Id + ':UAT-FINDING',
    psync__Severity__c = 'Critical',
    psync__Status__c = 'Open',
    psync__Blocking__c = true,
    psync__Description__c = 'UAT blocker: verify sanctions screening.'
  );

  insert new psync__Partner_Access_Request__c(
    psync__Onboarding__c = onboarding.Id,
    psync__Request_Key__c = onboarding.Id + ':UAT-ACCESS',
    psync__Relationship__c = relationship.Id,
    psync__Contact__c = contact.Id,
    psync__Access_Bundle__c = 'PSG_Partner_User',
    psync__Status__c = 'Pending Approval'
  );
  insert new psync__Partner_Training_Assignment__c(
    psync__Onboarding__c = onboarding.Id,
    psync__Assignment_Key__c = onboarding.Id + ':UAT-TRAINING',
    psync__Training_Key__c = 'PARTNER-FOUNDATIONS',
    psync__Mandatory__c = true,
    psync__Status__c = 'Assigned',
    psync__Due_On__c = Date.today().addDays(14)
  );

  Account customer = new Account(Name = 'Partner 360 UAT Customer');
  insert customer;
  insert new psync__Deal_Registration__c(
    psync__Customer_Account__c = customer.Id,
    psync__Customer_Name__c = customer.Name,
    psync__Partner_Account__c = partner.Id,
    psync__Partner_Contact__c = contact.Id,
    psync__Status__c = 'Submitted',
    psync__Conflict_Status__c = 'No Conflict',
    psync__Estimated_Revenue__c = 125000,
    psync__Estimated_Close_Date__c = Date.today().addDays(45),
    psync__Business_Problem__c = 'UAT validation of Partner 360 commercial summary.',
    psync__Proposed_Solution__c = 'Partner-led implementation.',
    psync__Submitted_On__c = System.now()
  );
  insert new psync__MDF_Request__c(
    psync__Partner_Account__c = partner.Id,
    psync__Submitted_By__c = contact.Id,
    psync__Campaign_Name__c = 'Partner 360 UAT Campaign',
    psync__Campaign_Type__c = 'Webinar',
    psync__Requested_Amount__c = 2500,
    psync__Activity_Start_Date__c = Date.today().addDays(14),
    psync__Activity_End_Date__c = Date.today().addDays(30),
    psync__Status__c = 'Submitted'
  );

  insert new psync__Partner_Lifecycle_Event__c(
    psync__Onboarding__c = onboarding.Id,
    psync__Event_Type__c = 'Readiness Blocked',
    psync__Stage__c = 'Readiness',
    psync__Summary__c = 'UAT partner awaits documents, risk clearance, access, and training.',
    psync__Occurred_On__c = System.now(),
    psync__Idempotency_Key__c = onboarding.Id + ':UAT-P360'
  );

  System.debug(
    LoggingLevel.INFO,
    'PARTNER_360_UAT created; partnerAccountId=' + partner.Id +
    ' onboardingId=' + onboarding.Id
  );
}
