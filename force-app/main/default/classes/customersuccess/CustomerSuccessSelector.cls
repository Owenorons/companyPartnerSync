/**
 * Selector layer for Customer_Success_Engagement__c.
 */
public without sharing class CustomerSuccessSelector {
  /**
   * Locks and reads a single engagement record by Id.
   *
   * @param engagementId Id of the engagement to load.
   * @return The locked Customer_Success_Engagement__c record.
   */
  public static Customer_Success_Engagement__c selectForUpdate(
    Id engagementId
  ) {
    List<Customer_Success_Engagement__c> rows = [
      SELECT
        Id,
        Customer_Account__c,
        Originating_Deal__c,
        Originating_Opportunity__c,
        Implementation__c,
        Primary_Partner__c,
        Primary_Participant__c,
        Current_Renewal__c,
        Previous_Engagement__c,
        Status__c,
        Internal_Customer_Success_Owner__c,
        Partner_Success_Owner__c,
        Health_Status__c,
        Health_Score__c,
        Churned_On__c,
        Churn_Reason__c,
        Churn_Category__c,
        Churn_Notes__c,
        Handoff_Snapshot__c,
        Version_Number__c
      FROM Customer_Success_Engagement__c
      WHERE Id = :engagementId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException(
        'Customer Success engagement not found.'
      );
    }

    return rows[0];
  }

  /**
   * Finds the most recent engagement already created from a given deal, if
   * any - used by createEngagement() to stay idempotent when the same
   * CustomerSuccessHandoffRequested event is redelivered.
   *
   * @param dealId Id of the originating deal.
   * @return The existing engagement for that deal, or null if none exists.
   */
  public static Customer_Success_Engagement__c selectByOriginatingDeal(
    Id dealId
  ) {
    List<Customer_Success_Engagement__c> rows = [
      SELECT Id, Status__c, Version_Number__c
      FROM Customer_Success_Engagement__c
      WHERE Originating_Deal__c = :dealId
      WITH SYSTEM_MODE
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    return rows.isEmpty() ? null : rows[0];
  }

  /**
   * Checks whether a churned engagement already has a subsequent
   * (reopened) engagement pointing back to it, so reopenEngagement() does
   * not create a second one.
   *
   * @param previousEngagementId Id of the churned engagement.
   * @return True if a subsequent engagement already exists.
   */
  public static Boolean hasSubsequentEngagement(Id previousEngagementId) {
    return [
        SELECT COUNT()
        FROM Customer_Success_Engagement__c
        WHERE Previous_Engagement__c = :previousEngagementId
        WITH SYSTEM_MODE
      ] > 0;
  }
}
