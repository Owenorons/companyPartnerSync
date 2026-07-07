@IsTest
public class PartnerSyncTestDataFactory {
  public static Account partnerAccount(String name) {
    return new Account(
      Name = name,
      Is_Partner__c = true,
      Partner_Status__c = 'Active',
      Partner_Tier__c = 'Gold',
      Partner_Type__c = 'Reseller',
      MDF_Annual_Budget__c = 10000,
      MDF_Used__c = 2500
    );
  }

  public static Account customerAccount(String name) {
    return new Account(Name = name, Is_Partner__c = false);
  }

  public static Contact partnerContact(Id accountId) {
    return new Contact(
      LastName = 'Partner Contact',
      AccountId = accountId,
      Email = uniqueEmail('partner-contact'),
      Is_Partner_User__c = true,
      Portal_Role__c = 'Partner Admin'
    );
  }

  public static Opportunity opportunity(
    Id customerAccountId,
    Id partnerAccountId,
    Id partnerContactId
  ) {
    return new Opportunity(
      Name = 'Partner Opportunity',
      AccountId = customerAccountId,
      StageName = 'Qualification',
      CloseDate = Date.today().addDays(30),
      Amount = 50000,
      Partner_Account__c = partnerAccountId,
      Partner_Contact__c = partnerContactId
    );
  }

  public static Lead lead(Id partnerAccountId, Id partnerContactId) {
    return new Lead(
      LastName = 'Lead',
      Company = 'Customer Prospect',
      Email = uniqueEmail('lead'),
      Status = 'Open - Not Contacted',
      Partner_Account__c = partnerAccountId,
      Partner_Contact__c = partnerContactId,
      Lead_Distribution_Status__c = 'Assigned',
      Assigned_Date__c = System.now(),
      SLA_Deadline__c = System.now().addHours(24)
    );
  }

  public static Deal_Registration__c deal(
    Id customerAccountId,
    Id partnerAccountId,
    Id partnerContactId,
    Id opportunityId
  ) {
    return new Deal_Registration__c(
      Customer_Account__c = customerAccountId,
      Partner_Account__c = partnerAccountId,
      Partner_Contact__c = partnerContactId,
      Opportunity__c = opportunityId,
      Status__c = 'Submitted',
      Conflict_Status__c = 'No Conflict',
      Estimated_Revenue__c = 50000,
      Estimated_Close_Date__c = Date.today().addDays(30),
      Business_Problem__c = 'Need partner coverage',
      Proposed_Solution__c = 'Joint solution',
      Submitted_On__c = System.now()
    );
  }

  public static MDF_Request__c mdfRequest(Id partnerAccountId, Id contactId) {
    return new MDF_Request__c(
      Partner_Account__c = partnerAccountId,
      Submitted_By__c = contactId,
      Campaign_Name__c = 'Partner Campaign',
      Campaign_Type__c = 'Webinar',
      Requested_Amount__c = 1000,
      Activity_Start_Date__c = Date.today(),
      Activity_End_Date__c = Date.today().addDays(7),
      Status__c = 'Submitted'
    );
  }

  public static Partner_Content__c content(String visibility) {
    return new Partner_Content__c(
      Name = 'Partner Guide',
      Description__c = 'Guide description',
      Category__c = 'Sales',
      Visibility__c = visibility,
      Partner_Tier__c = 'Gold',
      Partner_Type__c = 'Reseller',
      Is_Active__c = true,
      Featured__c = true,
      Published_Date__c = Date.today()
    );
  }

  public static AI_Insight__c insight(Id partnerAccountId) {
    return new AI_Insight__c(
      Partner_Account__c = partnerAccountId,
      Feature_Name__c = 'Deal Risk',
      Provider__c = 'Rules',
      Confidence__c = 85,
      Insight_Text__c = 'Strong partner engagement.',
      Recommendation__c = 'Prioritize follow-up.',
      Status__c = 'Generated'
    );
  }

  private static String uniqueEmail(String prefix) {
    return prefix + '-' + DateTime.now().getTime() + '@example.com';
  }
}
