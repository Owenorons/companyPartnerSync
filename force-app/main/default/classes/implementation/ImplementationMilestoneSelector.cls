/**
 * Selector layer for Implementation_Milestone__c.
 */
public without sharing class ImplementationMilestoneSelector {
  /**
   * Locks and reads a single milestone record by Id.
   *
   * @param milestoneId Id of the milestone to load.
   * @return The locked Implementation_Milestone__c record.
   */
  public static Implementation_Milestone__c selectForUpdate(Id milestoneId) {
    List<Implementation_Milestone__c> rows = [
      SELECT
        Id,
        Implementation__c,
        Milestone_Type__c,
        Name__c,
        Sequence__c,
        Status__c,
        Planned_Date__c,
        Actual_Date__c,
        Due_On__c,
        Blocking__c,
        Required__c,
        Completion_Percentage__c,
        Evidence_Required__c,
        Customer_Acceptance_Required__c,
        Version_Number__c
      FROM Implementation_Milestone__c
      WHERE Id = :milestoneId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException(
        'Implementation milestone not found.'
      );
    }

    return rows[0];
  }

  /**
   * Queries every milestone for an implementation, in sequence order.
   *
   * @param implementationId Id of the implementation.
   * @return The implementation's milestones.
   */
  public static List<Implementation_Milestone__c> selectForImplementation(
    Id implementationId
  ) {
    return [
      SELECT
        Id,
        Milestone_Type__c,
        Name__c,
        Sequence__c,
        Status__c,
        Planned_Date__c,
        Actual_Date__c,
        Due_On__c,
        Blocking__c,
        Required__c,
        Completion_Percentage__c,
        Evidence_Required__c,
        Customer_Acceptance_Required__c,
        Version_Number__c
      FROM Implementation_Milestone__c
      WHERE Implementation__c = :implementationId
      WITH SYSTEM_MODE
      ORDER BY Sequence__c ASC NULLS LAST
    ];
  }
}
