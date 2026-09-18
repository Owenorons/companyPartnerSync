/*
 * Shared builder of unsaved sObjects (not yet inserted) for test setup
 * across the PartnerSync domain packages. Kept in the top-level classes
 * folder rather than a subpackage since almost every domain's tests depend
 * on it; each method fills only the fields required to satisfy validation
 * rules / required fields, leaving callers free to override before insert.
 */
@IsTest
public class PartnerSyncTestDataFactory {
  /**
   * Builds an unsaved, active Gold-tier reseller partner Account with a
   * populated MDF budget.
   *
   * @param name The account name.
   * @return An unsaved partner Account.
   */
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

  /**
   * Builds an unsaved, non-partner (customer) Account.
   *
   * @param name The account name.
   * @return An unsaved customer Account.
   */
  public static Account customerAccount(String name) {
    return new Account(Name = name, Is_Partner__c = false);
  }

  /**
   * Builds an unsaved partner-user Contact under the given account, with
   * the Partner Admin portal role.
   *
   * @param accountId The Id of the partner account the contact belongs to.
   * @return An unsaved partner Contact.
   */
  public static Contact partnerContact(Id accountId) {
    return new Contact(
      LastName = 'Partner Contact',
      AccountId = accountId,
      Email = uniqueEmail('partner-contact'),
      Is_Partner_User__c = true,
      Portal_Role__c = 'Partner Admin'
    );
  }

  /**
   * Builds an unsaved Opportunity linked to a customer account and a
   * sourcing partner account/contact.
   *
   * @param customerAccountId The Id of the customer account the opportunity is on.
   * @param partnerAccountId The Id of the partner account that sourced the opportunity.
   * @param partnerContactId The Id of the partner contact that sourced the opportunity.
   * @return An unsaved Opportunity.
   */
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

  /**
   * Builds an unsaved Lead assigned to a partner account/contact, with an
   * open distribution status and a 24-hour SLA deadline.
   *
   * @param partnerAccountId The Id of the partner account the lead is assigned to.
   * @param partnerContactId The Id of the partner contact the lead is assigned to.
   * @return An unsaved Lead.
   */
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

  /**
   * Builds an unsaved, submitted Deal_Registration__c linking a customer
   * account, a partner account/contact, and an opportunity.
   *
   * @param customerAccountId The Id of the customer account the deal is on.
   * @param partnerAccountId The Id of the partner account registering the deal.
   * @param partnerContactId The Id of the partner contact registering the deal.
   * @param opportunityId The Id of the related opportunity.
   * @return An unsaved Deal_Registration__c.
   */
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

  /**
   * Builds an unsaved, submitted MDF_Request__c for a partner account and
   * submitting contact.
   *
   * @param partnerAccountId The Id of the partner account the request is for.
   * @param contactId The Id of the contact submitting the request.
   * @return An unsaved MDF_Request__c.
   */
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

  /**
   * Builds an unsaved, active, featured Partner_Content__c record with the
   * given visibility.
   *
   * @param visibility The Visibility__c value to set on the content record.
   * @return An unsaved Partner_Content__c.
   */
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

  /**
   * Builds an unsaved, accepted AI_Insight__c ('Deal Risk') for a partner
   * account.
   *
   * @param partnerAccountId The Id of the partner account the insight is for.
   * @return An unsaved AI_Insight__c.
   */
  public static AI_Insight__c insight(Id partnerAccountId) {
    return new AI_Insight__c(
      Partner_Account__c = partnerAccountId,
      Feature_Name__c = 'Deal Risk',
      Provider__c = 'Rules',
      Confidence__c = 85,
      Insight_Text__c = 'Strong partner engagement.',
      Recommendation__c = 'Prioritize follow-up.',
      Status__c = 'Accepted'
    );
  }

  private static String uniqueEmail(String prefix) {
    return prefix + '-' + DateTime.now().getTime() + '@example.com';
  }
}
