// Run second, after seed-access-groups.apex.
//
// This script performs non-setup DML only. It deliberately refuses to create
// a duplicate fixture set; remove the existing  accounts explicitly
// before reseeding.
List<Account> existingSeedAccounts = [
  SELECT Id
  FROM Account
  WHERE
    Name IN (
      ' Alderbrook Logistics',
      ' Bramwell Retail Group',
      ' Northlake Systems',
      ' Kestrel Freight Alliance'
    )
  LIMIT 1
];

if (!existingSeedAccounts.isEmpty()) {
  System.debug(
    LoggingLevel.INFO,
    '=== PartnerSync business seed already exists; no records created ==='
  );
} else {
  List<Account> partners = new List<Account>{
    new Account(
      Name = ' Alderbrook Logistics',
      psync__Is_Partner__c = true,
      psync__Partner_Status__c = 'Active',
      psync__Partner_Tier__c = 'Strategic',
      psync__Partner_Type__c = 'Reseller',
      psync__Partner_Region__c = 'Americas',
      psync__MDF_Annual_Budget__c = 50000,
      psync__MDF_Used__c = 31000,
      psync__MDF_Available_Budget__c = 19000
    ),
    new Account(
      Name = ' Bramwell Retail Group',
      psync__Is_Partner__c = true,
      psync__Partner_Status__c = 'Active',
      psync__Partner_Tier__c = 'Gold',
      psync__Partner_Type__c = 'Distributor',
      psync__Partner_Region__c = 'EMEA',
      psync__MDF_Annual_Budget__c = 30000,
      psync__MDF_Used__c = 12000,
      psync__MDF_Available_Budget__c = 18000
    ),
    new Account(
      Name = ' Northlake Systems',
      psync__Is_Partner__c = true,
      psync__Partner_Status__c = 'Active',
      psync__Partner_Tier__c = 'Platinum',
      psync__Partner_Type__c = 'Agent',
      psync__Partner_Region__c = 'APAC',
      psync__MDF_Annual_Budget__c = 40000,
      psync__MDF_Used__c = 6000,
      psync__MDF_Available_Budget__c = 34000
    ),
    new Account(
      Name = ' Kestrel Freight Alliance',
      psync__Is_Partner__c = true,
      psync__Partner_Status__c = 'Active',
      psync__Partner_Tier__c = 'Silver',
      psync__Partner_Type__c = 'Dealer',
      psync__Partner_Region__c = 'ANZ',
      psync__MDF_Annual_Budget__c = 15000,
      psync__MDF_Used__c = 2000,
      psync__MDF_Available_Budget__c = 13000
    )
  };
  insert partners;

  // Customer accounts each partner is registering deals against.
  List<Account> customers = new List<Account>{
    new Account(
      Name = ' Meridian Health Systems',
      psync__Is_Partner__c = false
    ),
    new Account(Name = ' Cascade Manufacturing', psync__Is_Partner__c = false),
    new Account(Name = ' Union Freight Co', psync__Is_Partner__c = false),
    new Account(Name = ' Baypoint Financial', psync__Is_Partner__c = false)
  };
  insert customers;

  List<Contact> contacts = new List<Contact>();
  List<String> contactNames = new List<String>{
    'Dana Whitfield',
    'Priya Nair',
    'Marcus O Briain',
    'Jules Kestrel'
  };

  for (Integer i = 0; i < partners.size(); i++) {
    contacts.add(
      new Contact(
        FirstName = contactNames[i].substringBefore(' '),
        LastName = contactNames[i].substringAfter(' '),
        AccountId = partners[i].Id,
        Email = 'partner-contact-' +
          i +
          '-' +
          DateTime.now().getTime() +
          '@example.com',
        psync__Is_Partner_User__c = true,
        psync__Portal_Role__c = 'Partner Admin',
        psync__Can_Submit_Deals__c = true,
        psync__Can_Submit_MDF__c = true,
        psync__Can_View_Analytics__c = true,
        psync__Certification_Status__c = 'Active'
      )
    );
  }
  insert contacts;

  List<Opportunity> opps = new List<Opportunity>();
  List<Decimal> oppAmounts = new List<Decimal>{ 412000, 290000, 84000, 41500 };

  for (Integer i = 0; i < partners.size(); i++) {
    opps.add(
      new Opportunity(
        Name = ' ' + customers[i].Name.replace(' ', '') + ' Expansion',
        AccountId = customers[i].Id,
        StageName = 'Negotiation/Review',
        CloseDate = Date.today().addDays(30),
        Amount = oppAmounts[i],
        psync__Partner_Account__c = partners[i].Id,
        psync__Partner_Contact__c = contacts[i].Id
      )
    );
  }
  insert opps;

  List<psync__Deal_Registration__c> deals = new List<psync__Deal_Registration__c>();

  // Partner 0 (Strategic, top performer): two approved, one under review.
  deals.add(
    new psync__Deal_Registration__c(
      psync__Customer_Account__c = customers[0].Id,
      psync__Customer_Name__c = customers[0].Name,
      psync__Partner_Account__c = partners[0].Id,
      psync__Partner_Contact__c = contacts[0].Id,
      psync__Opportunity__c = opps[0].Id,
      psync__Status__c = 'Approved',
      psync__Stage__c = 'Negotiation',
      psync__Conflict_Status__c = 'None',
      psync__Estimated_Revenue__c = 412000,
      psync__Estimated_Close_Date__c = Date.today().addDays(45),
      psync__Protection_Start_Date__c = Date.today().addDays(-30),
      psync__Protection_End_Date__c = Date.today().addDays(60),
      psync__Business_Problem__c = 'Legacy platform can\'t scale with regional growth.',
      psync__Proposed_Solution__c = 'Phased migration with partner-led implementation.',
      psync__Submitted_On__c = System.now().addDays(-10),
      psync__Approved_Date__c = System.now().addDays(-3)
    )
  );
  deals.add(
    new psync__Deal_Registration__c(
      psync__Customer_Account__c = customers[0].Id,
      psync__Customer_Name__c = customers[0].Name,
      psync__Partner_Account__c = partners[0].Id,
      psync__Partner_Contact__c = contacts[0].Id,
      psync__Status__c = 'Under Review',
      psync__Stage__c = 'Discovery',
      psync__Conflict_Status__c = 'Potential Conflict',
      psync__Estimated_Revenue__c = 96000,
      psync__Estimated_Close_Date__c = Date.today().addDays(60),
      psync__Business_Problem__c = 'Needs a secondary vendor evaluation.',
      psync__Proposed_Solution__c = 'Competitive proof-of-concept.',
      psync__Submitted_On__c = System.now().addDays(-2)
    )
  );

  // Partner 1 (Gold): one approved, one rejected — exercises the stamp's "bad" state.
  deals.add(
    new psync__Deal_Registration__c(
      psync__Customer_Account__c = customers[1].Id,
      psync__Customer_Name__c = customers[1].Name,
      psync__Partner_Account__c = partners[1].Id,
      psync__Partner_Contact__c = contacts[1].Id,
      psync__Opportunity__c = opps[1].Id,
      psync__Status__c = 'Approved',
      psync__Stage__c = 'Closed Won',
      psync__Conflict_Status__c = 'None',
      psync__Estimated_Revenue__c = 290000,
      psync__Estimated_Close_Date__c = Date.today().addDays(-5),
      psync__Protection_Start_Date__c = Date.today().addDays(-60),
      psync__Protection_End_Date__c = Date.today().addDays(30),
      psync__Business_Problem__c = 'Manual reconciliation across regional warehouses.',
      psync__Proposed_Solution__c = 'Unified inventory platform rollout.',
      psync__Submitted_On__c = System.now().addDays(-20),
      psync__Approved_Date__c = System.now().addDays(-14)
    )
  );
  deals.add(
    new psync__Deal_Registration__c(
      psync__Customer_Account__c = customers[1].Id,
      psync__Customer_Name__c = customers[1].Name,
      psync__Partner_Account__c = partners[1].Id,
      psync__Partner_Contact__c = contacts[1].Id,
      psync__Status__c = 'Rejected',
      psync__Stage__c = 'Qualification',
      psync__Conflict_Status__c = 'Confirmed Conflict',
      psync__Estimated_Revenue__c = 58000,
      psync__Estimated_Close_Date__c = Date.today().addDays(90),
      psync__Business_Problem__c = 'Overlapping territory with another registered partner.',
      psync__Proposed_Solution__c = 'Referral fee arrangement proposed instead.',
      psync__Rejection_Reason__c = 'Customer already protected by another partner\'s active registration.',
      psync__Submitted_On__c = System.now().addDays(-15),
      psync__Decision_On__c = System.now().addDays(-9)
    )
  );

  // Partner 2 (Platinum): submitted, awaiting review.
  deals.add(
    new psync__Deal_Registration__c(
      psync__Customer_Account__c = customers[2].Id,
      psync__Customer_Name__c = customers[2].Name,
      psync__Partner_Account__c = partners[2].Id,
      psync__Partner_Contact__c = contacts[2].Id,
      psync__Opportunity__c = opps[2].Id,
      psync__Status__c = 'Submitted',
      psync__Stage__c = 'Discovery',
      psync__Conflict_Status__c = 'None',
      psync__Estimated_Revenue__c = 84000,
      psync__Estimated_Close_Date__c = Date.today().addDays(45),
      psync__Business_Problem__c = 'Fleet tracking data lives in three disconnected systems.',
      psync__Proposed_Solution__c = 'Single integrated telematics platform.',
      psync__Submitted_On__c = System.now().addDays(-1)
    )
  );

  // Partner 3 (Silver): one approved, small deal.
  deals.add(
    new psync__Deal_Registration__c(
      psync__Customer_Account__c = customers[3].Id,
      psync__Customer_Name__c = customers[3].Name,
      psync__Partner_Account__c = partners[3].Id,
      psync__Partner_Contact__c = contacts[3].Id,
      psync__Opportunity__c = opps[3].Id,
      psync__Status__c = 'Approved',
      psync__Stage__c = 'Negotiation',
      psync__Conflict_Status__c = 'None',
      psync__Estimated_Revenue__c = 41500,
      psync__Estimated_Close_Date__c = Date.today().addDays(20),
      psync__Protection_Start_Date__c = Date.today().addDays(-10),
      psync__Protection_End_Date__c = Date.today().addDays(80),
      psync__Business_Problem__c = 'Reporting delays during month-end close.',
      psync__Proposed_Solution__c = 'Automated close checklist and dashboards.',
      psync__Submitted_On__c = System.now().addDays(-6),
      psync__Approved_Date__c = System.now().addDays(-1)
    )
  );

  insert deals;

  List<Lead> leads = new List<Lead>();

  leads.add(
    new Lead(
      FirstName = 'Rowan',
      LastName = 'Voss',
      Company = ' Silverline Contracting',
      Email = 'lead-0-' + DateTime.now().getTime() + '@example.com',
      Status = 'Open - Not Contacted',
      psync__Partner_Account__c = partners[0].Id,
      psync__Partner_Contact__c = contacts[0].Id,
      psync__Lead_Distribution_Status__c = 'Assigned',
      psync__Assigned_Date__c = System.now().addHours(-22),
      psync__Response_SLA_Hours__c = 24,
      psync__SLA_Deadline__c = System.now().addHours(2) // near-breach: exercises the danger tag
    )
  );
  leads.add(
    new Lead(
      FirstName = 'Imani',
      LastName = 'Castellano',
      Company = 'Ferro Industrial',
      Email = 'lead-1-' + DateTime.now().getTime() + '@example.com',
      Status = 'Working',
      psync__Partner_Account__c = partners[0].Id,
      psync__Partner_Contact__c = contacts[0].Id,
      psync__Lead_Distribution_Status__c = 'Accepted',
      psync__Assigned_Date__c = System.now().addDays(-2),
      psync__Response_SLA_Hours__c = 24,
      psync__SLA_Deadline__c = System.now().addDays(-1)
    )
  );
  leads.add(
    new Lead(
      FirstName = 'Otis',
      LastName = 'Brandt',
      Company = ' Harborview Supply',
      Email = 'lead-2-' + DateTime.now().getTime() + '@example.com',
      Status = 'Qualified',
      psync__Partner_Account__c = partners[1].Id,
      psync__Partner_Contact__c = contacts[1].Id,
      psync__Lead_Distribution_Status__c = 'Converted',
      psync__Assigned_Date__c = System.now().addDays(-9),
      psync__Accepted_Date__c = System.now().addDays(-8),
      psync__Response_SLA_Hours__c = 24,
      psync__SLA_Deadline__c = System.now().addDays(-8)
    )
  );
  leads.add(
    new Lead(
      FirstName = 'Willa',
      LastName = 'Emerson',
      Company = ' Bluepeak Analytics',
      Email = 'lead-3-' + DateTime.now().getTime() + '@example.com',
      Status = 'Open - Not Contacted',
      psync__Partner_Account__c = partners[1].Id,
      psync__Partner_Contact__c = contacts[1].Id,
      psync__Lead_Distribution_Status__c = 'Rejected',
      psync__Assigned_Date__c = System.now().addDays(-4),
      psync__Rejected_Date__c = System.now().addDays(-3),
      psync__Response_SLA_Hours__c = 24,
      psync__SLA_Deadline__c = System.now().addDays(-3)
    )
  );
  leads.add(
    new Lead(
      FirstName = 'Theo',
      LastName = 'Marchetti',
      Company = ' Northgate Retail',
      Email = 'lead-4-' + DateTime.now().getTime() + '@example.com',
      Status = 'Open - Not Contacted',
      psync__Partner_Account__c = partners[2].Id,
      psync__Partner_Contact__c = contacts[2].Id,
      psync__Lead_Distribution_Status__c = 'Assigned',
      psync__Assigned_Date__c = System.now().addHours(-1),
      psync__Response_SLA_Hours__c = 24,
      psync__SLA_Deadline__c = System.now().addHours(23) // comfortably within SLA
    )
  );
  leads.add(
    new Lead(
      FirstName = 'Simone',
      LastName = 'Alaoui',
      Company = ' Redshift Logistics',
      Email = 'lead-5-' + DateTime.now().getTime() + '@example.com',
      Status = 'Open - Not Contacted',
      psync__Partner_Account__c = partners[3].Id,
      psync__Partner_Contact__c = contacts[3].Id,
      psync__Lead_Distribution_Status__c = 'Assigned',
      psync__Assigned_Date__c = System.now().addHours(-20),
      psync__Response_SLA_Hours__c = 24,
      psync__SLA_Deadline__c = System.now().addHours(4)
    )
  );

  insert leads;

  List<psync__MDF_Request__c> mdfRequests = new List<psync__MDF_Request__c>();

  mdfRequests.add(
    new psync__MDF_Request__c(
      Name = ' Q3 Regional Webinar Series',
      psync__Partner_Account__c = partners[0].Id,
      psync__Submitted_By__c = contacts[0].Id,
      psync__Status__c = 'Approved',
      psync__Campaign_Name__c = 'Q3 Regional Webinar Series',
      psync__Campaign_Type__c = 'Webinar',
      psync__Requested_Amount__c = 5000,
      psync__Approved_Amount__c = 5000,
      psync__Activity_Start_Date__c = Date.today().addDays(-14),
      psync__Activity_End_Date__c = Date.today().addDays(7),
      psync__Expected_Leads__c = 40
    )
  );
  mdfRequests.add(
    new psync__MDF_Request__c(
      Name = ' Field Marketing Roadshow',
      psync__Partner_Account__c = partners[0].Id,
      psync__Submitted_By__c = contacts[0].Id,
      psync__Status__c = 'Under Review',
      psync__Campaign_Name__c = 'Field Marketing Roadshow',
      psync__Campaign_Type__c = 'Event',
      psync__Requested_Amount__c = 12000,
      psync__Activity_Start_Date__c = Date.today().addDays(20),
      psync__Activity_End_Date__c = Date.today().addDays(24),
      psync__Expected_Leads__c = 75
    )
  );
  mdfRequests.add(
    new psync__MDF_Request__c(
      Name = ' Spring Digital Advertising Push',
      psync__Partner_Account__c = partners[1].Id,
      psync__Submitted_By__c = contacts[1].Id,
      psync__Status__c = 'Reimbursed',
      psync__Campaign_Name__c = 'Spring Digital Advertising Push',
      psync__Campaign_Type__c = 'Digital Advertising',
      psync__Requested_Amount__c = 8000,
      psync__Approved_Amount__c = 7500,
      psync__Spent_Amount__c = 7500,
      psync__Activity_Start_Date__c = Date.today().addDays(-60),
      psync__Activity_End_Date__c = Date.today().addDays(-30),
      psync__Expected_Leads__c = 50,
      psync__Actual_Leads__c = 62
    )
  );
  mdfRequests.add(
    new psync__MDF_Request__c(
      Name = ' Direct Mail Renewal Campaign',
      psync__Partner_Account__c = partners[2].Id,
      psync__Submitted_By__c = contacts[2].Id,
      psync__Status__c = 'Draft',
      psync__Campaign_Name__c = 'Direct Mail Renewal Campaign',
      psync__Campaign_Type__c = 'Direct Mail',
      psync__Requested_Amount__c = 3000,
      psync__Activity_Start_Date__c = Date.today().addDays(30),
      psync__Activity_End_Date__c = Date.today().addDays(37)
    )
  );
  mdfRequests.add(
    new psync__MDF_Request__c(
      Name = ' Content Syndication Trial',
      psync__Partner_Account__c = partners[3].Id,
      psync__Submitted_By__c = contacts[3].Id,
      psync__Status__c = 'Submitted',
      psync__Campaign_Name__c = 'Content Syndication Trial',
      psync__Campaign_Type__c = 'Content Syndication',
      psync__Requested_Amount__c = 2000,
      psync__Activity_Start_Date__c = Date.today().addDays(10),
      psync__Activity_End_Date__c = Date.today().addDays(17),
      psync__Expected_Leads__c = 20
    )
  );

  insert mdfRequests;

  //
  // 7. AI insights — real psync__Feature_Name__c/psync__Provider__c values.
  //
  List<psync__AI_Insight__c> insights = new List<psync__AI_Insight__c>{
    new psync__AI_Insight__c(
      psync__Partner_Account__c = partners[0].Id,
      psync__Feature_Name__c = 'AI',
      psync__Provider__c = 'OpenAI',
      psync__Status__c = 'Generated',
      psync__Confidence__c = 84,
      psync__Insight_Text__c = 'This deal shows elevated risk due to an extended sales cycle relative to this segment.',
      psync__Recommendation__c = 'Schedule an executive check-in within 5 days.'
    ),
    new psync__AI_Insight__c(
      psync__Partner_Account__c = partners[1].Id,
      psync__Feature_Name__c = 'MDF',
      psync__Provider__c = 'Azure OpenAI',
      psync__Status__c = 'Generated',
      psync__Confidence__c = 91,
      psync__Insight_Text__c = 'MDF spend efficiency for this partner is trending well above segment average.',
      psync__Recommendation__c = 'Consider approving the next requested campaign at full amount.'
    )
  };
  insert insights;

  //
  // 8. Partner notifications — recipient is the running user (so whoever executes
  //    this script sees populated notifications immediately), plus a few tied to
  //    partner contacts for when previewing as a partner persona.
  //
  Id runningUserId = UserInfo.getUserId();

  List<psync__Partner_Notification__c> notifications = new List<psync__Partner_Notification__c>{
    new psync__Partner_Notification__c(
      psync__Recipient_User__c = runningUserId,
      psync__Partner_Account__c = partners[1].Id,
      psync__Notification_Type__c = 'Deal',
      psync__Priority__c = 'High',
      psync__Title__c = 'Deal registration needs review',
      psync__Message__c = 'Bramwell Retail Group submitted a deal conflict that needs a decision.',
      psync__Is_Read__c = false
    ),
    new psync__Partner_Notification__c(
      psync__Recipient_User__c = runningUserId,
      psync__Partner_Account__c = partners[0].Id,
      psync__Notification_Type__c = 'MDF',
      psync__Priority__c = 'Normal',
      psync__Title__c = 'MDF request approved',
      psync__Message__c = 'Q3 Regional Webinar Series was approved for Alderbrook Logistics.',
      psync__Is_Read__c = false
    ),
    new psync__Partner_Notification__c(
      psync__Recipient_User__c = runningUserId,
      psync__Partner_Account__c = partners[2].Id,
      psync__Notification_Type__c = 'Lead',
      psync__Priority__c = 'Normal',
      psync__Title__c = 'New lead assigned',
      psync__Message__c = 'Northgate Retail was assigned to Northlake Systems.',
      psync__Is_Read__c = true,
      psync__Read_On__c = System.now().addHours(-3)
    ),
    new psync__Partner_Notification__c(
      psync__Recipient_User__c = runningUserId,
      psync__Notification_Type__c = 'System',
      psync__Priority__c = 'Low',
      psync__Title__c = 'Weekly partner digest ready',
      psync__Message__c = 'Your channel performance summary for last week is ready to view.',
      psync__Is_Read__c = true,
      psync__Read_On__c = System.now().addDays(-1)
    ),
    new psync__Partner_Notification__c(
      psync__Recipient_Contact__c = contacts[0].Id,
      psync__Partner_Account__c = partners[0].Id,
      psync__Notification_Type__c = 'Deal',
      psync__Priority__c = 'High',
      psync__Title__c = 'Your deal was approved',
      psync__Message__c = 'Meridian Health Systems is now approved and protected.',
      psync__Is_Read__c = false
    ),
    new psync__Partner_Notification__c(
      psync__Recipient_Contact__c = contacts[1].Id,
      psync__Partner_Account__c = partners[1].Id,
      psync__Notification_Type__c = 'Deal',
      psync__Priority__c = 'High',
      psync__Title__c = 'Deal rejected',
      psync__Message__c = 'Your Cascade Manufacturing registration was rejected — see notes for details.',
      psync__Is_Read__c = false
    )
  };
  insert notifications;

  //
  // 9. Partner content — for the Content Hub, real psync__Category__c/psync__Visibility__c values.
  //
  List<psync__Partner_Content__c> content = new List<psync__Partner_Content__c>{
    new psync__Partner_Content__c(
      Name = ' Competitive Battlecard: Q3',
      psync__Description__c = 'Positioning against the top three competitors this quarter.',
      psync__Category__c = 'Sales Deck',
      psync__Visibility__c = 'All Partners',
      psync__Is_Active__c = true,
      psync__Featured__c = true,
      psync__Published_Date__c = Date.today().addDays(-5),
      psync__Sort_Order__c = 1
    ),
    new psync__Partner_Content__c(
      Name = ' API Integration Guide',
      psync__Description__c = 'Step-by-step guide for integrating with the platform API.',
      psync__Category__c = 'Training',
      psync__Visibility__c = 'All Partners',
      psync__Is_Active__c = true,
      psync__Featured__c = false,
      psync__Published_Date__c = Date.today().addDays(-30),
      psync__Sort_Order__c = 2
    ),
    new psync__Partner_Content__c(
      Name = ' 2025 Product Roadmap',
      psync__Description__c = 'Upcoming feature releases for the next two quarters.',
      psync__Category__c = 'Product Sheet',
      psync__Visibility__c = 'Restricted',
      psync__Partner_Tier__c = 'Strategic',
      psync__Is_Active__c = true,
      psync__Featured__c = true,
      psync__Published_Date__c = Date.today().addDays(-2),
      psync__Sort_Order__c = 3
    ),
    new psync__Partner_Content__c(
      Name = ' Standard Pricing Guide',
      psync__Description__c = 'Current list pricing and discount tiers.',
      psync__Category__c = 'Pricing Guide',
      psync__Visibility__c = 'All Partners',
      psync__Is_Active__c = true,
      psync__Featured__c = false,
      psync__Published_Date__c = Date.today().addDays(-90),
      psync__Sort_Order__c = 4
    ),
    new psync__Partner_Content__c(
      Name = ' Regional Success Story: Meridian Health',
      psync__Description__c = 'Case study covering the Meridian Health Systems deployment.',
      psync__Category__c = 'Case Study',
      psync__Visibility__c = 'All Partners',
      psync__Is_Active__c = true,
      psync__Featured__c = false,
      psync__Published_Date__c = Date.today().addDays(-45),
      psync__Sort_Order__c = 5
    ),
    new psync__Partner_Content__c(
      Name = ' Internal Enablement Notes (retired)',
      psync__Description__c = 'Superseded internal notes kept for reference only.',
      psync__Category__c = 'Training',
      psync__Visibility__c = 'Internal Only',
      psync__Is_Active__c = false,
      psync__Featured__c = false,
      psync__Published_Date__c = Date.today().addDays(-400),
      psync__Sort_Order__c = 6
    )
  };
  insert content;

  //
  // 10. One extra, un-registered Opportunity per partner so "Register Deal" has
  //     a real eligible opportunity to submit through the UI. Every Opportunity
  //     created in section 3 already has a matching Deal_Registration__c, so
  //     without these, psDealRegistrationForm's picker would be empty for every
  //     partner and only show the "No eligible opportunities" empty state.
  //
  List<Account> eligibleOppCustomers = new List<Account>{
    new Account(
      Name = ' Thornfield Logistics Group',
      psync__Is_Partner__c = false
    ),
    new Account(
      Name = ' Pinecrest Retail Holdings',
      psync__Is_Partner__c = false
    ),
    new Account(Name = ' Ridgeway Systems Corp', psync__Is_Partner__c = false),
    new Account(Name = ' Anchorpoint Freight Co', psync__Is_Partner__c = false)
  };
  insert eligibleOppCustomers;

  List<Decimal> eligibleOppAmounts = new List<Decimal>{
    68000,
    125000,
    52500,
    19000
  };
  List<Opportunity> eligibleOpps = new List<Opportunity>();

  for (Integer i = 0; i < partners.size(); i++) {
    eligibleOpps.add(
      new Opportunity(
        Name = ' ' +
          eligibleOppCustomers[i].Name.replace(' ', '') +
          ' New Business',
        AccountId = eligibleOppCustomers[i].Id,
        StageName = 'Qualification',
        CloseDate = Date.today().addDays(60),
        Amount = eligibleOppAmounts[i],
        psync__Partner_Account__c = partners[i].Id,
        psync__Partner_Contact__c = contacts[i].Id
      )
    );
  }
  insert eligibleOpps;

  //
  // 11. Partner applications — one per review-queue status, so
  //     psPartnerApplicationReview's internal queue has real applications to
  //     work through. (Submitted/Under Review are what actually show up in the
  //     queue; Approved/Rejected are included so the detail view's decided-state
  //     stamp can be exercised too.)
  //
  List<psync__Partner_Application__c> applications = new List<psync__Partner_Application__c>{
    new psync__Partner_Application__c(
      Name = ' Harborline Distribution',
      psync__Company_Name__c = 'Harborline Distribution',
      psync__Business_Email__c = 'partnerships@harborline-test.example.com',
      psync__Phone__c = '555-0110',
      psync__Website__c = 'https://harborline-test.example.com',
      psync__Country__c = 'United States',
      psync__Region__c = 'Americas',
      psync__Requested_Tier__c = 'Gold',
      psync__Partner_Type__c = 'Distributor',
      psync__Submitted_By_Contact_Name__c = 'Nora Fenwick',
      psync__Submitted_By_Email__c = 'nora.fenwick@harborline-test.example.com',
      psync__Application_Status__c = 'Submitted',
      psync__Decision__c = 'Pending',
      psync__Submitted_On__c = System.now().addDays(-1)
    ),
    new psync__Partner_Application__c(
      Name = ' Trestlewood Agents',
      psync__Company_Name__c = 'Trestlewood Agents',
      psync__Business_Email__c = 'apply@trestlewood-test.example.com',
      psync__Phone__c = '555-0121',
      psync__Website__c = 'https://trestlewood-test.example.com',
      psync__Country__c = 'Canada',
      psync__Region__c = 'Americas',
      psync__Requested_Tier__c = 'Silver',
      psync__Partner_Type__c = 'Agent',
      psync__Submitted_By_Contact_Name__c = 'Gideon Marsh',
      psync__Submitted_By_Email__c = 'gideon.marsh@trestlewood-test.example.com',
      psync__Application_Status__c = 'Submitted',
      psync__Decision__c = 'Pending',
      psync__Submitted_On__c = System.now().addDays(-3)
    ),
    new psync__Partner_Application__c(
      Name = ' Ferncliff Reseller Group',
      psync__Company_Name__c = 'Ferncliff Reseller Group',
      psync__Business_Email__c = 'partners@ferncliff-test.example.com',
      psync__Phone__c = '555-0132',
      psync__Website__c = 'https://ferncliff-test.example.com',
      psync__Country__c = 'United Kingdom',
      psync__Region__c = 'EMEA',
      psync__Requested_Tier__c = 'Platinum',
      psync__Partner_Type__c = 'Reseller',
      psync__Submitted_By_Contact_Name__c = 'Elowen Pryce',
      psync__Submitted_By_Email__c = 'elowen.pryce@ferncliff-test.example.com',
      psync__Application_Status__c = 'Under Review',
      psync__Decision__c = 'Pending',
      psync__Submitted_On__c = System.now().addDays(-6)
    ),
    new psync__Partner_Application__c(
      Name = ' Windmere Dealer Co',
      psync__Company_Name__c = 'Windmere Dealer Co',
      psync__Business_Email__c = 'hello@windmere-test.example.com',
      psync__Phone__c = '555-0143',
      psync__Website__c = 'https://windmere-test.example.com',
      psync__Country__c = 'Australia',
      psync__Region__c = 'APAC',
      psync__Requested_Tier__c = 'Silver',
      psync__Partner_Type__c = 'Dealer',
      psync__Submitted_By_Contact_Name__c = 'Casimir Doyle',
      psync__Submitted_By_Email__c = 'casimir.doyle@windmere-test.example.com',
      psync__Application_Status__c = 'Approved',
      psync__Decision__c = 'Approved',
      psync__Submitted_On__c = System.now().addDays(-14),
      psync__Decision_On__c = System.now().addDays(-9),
      psync__Approval_Date__c = Date.today().addDays(-9),
      psync__Approval_Notes__c = 'Strong regional footprint, approved at requested tier.'
    ),
    new psync__Partner_Application__c(
      Name = ' Redgate Referral Partners',
      psync__Company_Name__c = 'Redgate Referral Partners',
      psync__Business_Email__c = 'info@redgate-test.example.com',
      psync__Phone__c = '555-0154',
      psync__Website__c = 'https://redgate-test.example.com',
      psync__Country__c = 'New Zealand',
      psync__Region__c = 'ANZ',
      psync__Requested_Tier__c = 'Gold',
      psync__Partner_Type__c = 'Referral',
      psync__Submitted_By_Contact_Name__c = 'Beatrix Sallow',
      psync__Submitted_By_Email__c = 'beatrix.sallow@redgate-test.example.com',
      psync__Application_Status__c = 'Rejected',
      psync__Decision__c = 'Rejected',
      psync__Submitted_On__c = System.now().addDays(-20),
      psync__Decision_On__c = System.now().addDays(-17),
      psync__Rejection_Reason__c = 'Territory overlap with an existing Strategic partner.'
    )
  };
  insert applications;

  //
  // 12. Map the setup-only Groups created by seed-access-groups.apex to the
  //     partner accounts. Group queries are safe here; only Group DML is a setup
  //     operation and therefore belongs in the first script.
  //
  List<String> accessGroupNames = new List<String>{
    'Alderbrook Logistics Access Group',
    'Bramwell Retail Group Access Group',
    'Northlake Systems Access Group',
    'Kestrel Freight Alliance Access Group'
  };
  Map<String, Group> accessGroupByName = new Map<String, Group>();
  for (Group accessGroup : [
    SELECT Id, Name
    FROM Group
    WHERE Name IN :accessGroupNames AND Type = 'Regular'
  ]) {
    accessGroupByName.put(accessGroup.Name, accessGroup);
  }

  if (accessGroupByName.size() != accessGroupNames.size()) {
    throw new IllegalArgumentException(
      'Partner access groups are missing. Run seed-access-groups.apex first.'
    );
  }

  List<psync__Partner_Access_Group__c> accessGroupMappings = new List<psync__Partner_Access_Group__c>();

  for (Integer i = 0; i < partners.size(); i++) {
    Group accessGroup = accessGroupByName.get(accessGroupNames[i]);
    accessGroupMappings.add(
      new psync__Partner_Access_Group__c(
        psync__Partner_Account__c = partners[i].Id,
        psync__Group_Id__c = accessGroup.Id,
        psync__Active__c = true
      )
    );
  }
  insert accessGroupMappings;

  System.debug(
    '=== Seed complete === partners:' +
      partners.size() +
      ' customers:' +
      customers.size() +
      ' contacts:' +
      contacts.size() +
      ' opportunities:' +
      opps.size() +
      ' deals:' +
      deals.size() +
      ' leads:' +
      leads.size() +
      ' mdfRequests:' +
      mdfRequests.size() +
      ' insights:' +
      insights.size() +
      ' notifications:' +
      notifications.size() +
      ' content:' +
      content.size() +
      ' eligibleOpportunities:' +
      eligibleOpps.size() +
      ' partnerApplications:' +
      applications.size() +
      ' partnerAccessGroups:' +
      accessGroupByName.size()
  );
}
