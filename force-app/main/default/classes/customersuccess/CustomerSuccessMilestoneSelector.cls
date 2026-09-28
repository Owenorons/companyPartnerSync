/**
 * Selector layer for Customer_Success_Milestone__c.
 */
public without sharing class CustomerSuccessMilestoneSelector {
  /**
   * Locks and reads a single milestone record by Id.
   *
   * @param milestoneId Id of the milestone to load.
   * @return The locked Customer_Success_Milestone__c record.
   */
  public static Customer_Success_Milestone__c selectForUpdate(Id milestoneId) {
    List<Customer_Success_Milestone__c> rows = [
      SELECT
        Id,
        Customer_Success_Engagement__c,
        Milestone_Type__c,
        Status__c,
        Target_On__c,
        Completed_On__c,
        Notes__c
      FROM Customer_Success_Milestone__c
      WHERE Id = :milestoneId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException(
        'Customer Success milestone not found.'
      );
    }

    return rows[0];
  }

  /**
   * Queries every milestone for an engagement, oldest target date first.
   *
   * @param engagementId Id of the engagement.
   * @return The engagement's milestones.
   */
  public static List<Customer_Success_Milestone__c> selectForEngagement(
    Id engagementId
  ) {
    return [
      SELECT Id, Milestone_Type__c, Status__c, Target_On__c, Completed_On__c
      FROM Customer_Success_Milestone__c
      WHERE Customer_Success_Engagement__c = :engagementId
      WITH SYSTEM_MODE
      ORDER BY Target_On__c ASC NULLS LAST
    ];
  }
}
