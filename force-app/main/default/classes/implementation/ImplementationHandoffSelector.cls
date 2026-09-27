/**
 * Selector layer for Deal_Implementation_Handoff__c.
 */
public without sharing class ImplementationHandoffSelector {
  /**
   * Locks and reads a single handoff record by Id.
   *
   * @param handoffId Id of the handoff to load.
   * @return The locked Deal_Implementation_Handoff__c record.
   */
  public static Deal_Implementation_Handoff__c selectForUpdate(Id handoffId) {
    List<Deal_Implementation_Handoff__c> rows = [
      SELECT
        Id,
        Implementation__c,
        Status__c,
        Requested_By__c,
        Sales_Owner__c,
        Delivery_Owner__c,
        Customer_Objectives__c,
        Solution_Summary__c,
        Commercial_Summary__c,
        Scope_Summary__c,
        Key_Assumptions__c,
        Known_Risks__c,
        Dependencies__c,
        Target_Start_Date__c,
        Target_Completion_Date__c,
        Required_Evidence_Complete__c,
        Returned_Reason__c,
        Version_Number__c
      FROM Deal_Implementation_Handoff__c
      WHERE Id = :handoffId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException(
        'Implementation handoff not found.'
      );
    }

    return rows[0];
  }

  /**
   * Queries every handoff for an implementation, most recently created first.
   *
   * @param implementationId Id of the implementation.
   * @return The implementation's handoffs.
   */
  public static List<Deal_Implementation_Handoff__c> selectForImplementation(
    Id implementationId
  ) {
    return [
      SELECT Id, Status__c, Delivery_Owner__c, Version_Number__c
      FROM Deal_Implementation_Handoff__c
      WHERE Implementation__c = :implementationId
      WITH SYSTEM_MODE
      ORDER BY CreatedDate DESC
    ];
  }

  /**
   * Loads up to 200 handoffs still awaiting an internal accept/return
   * decision, with their implementation's summary fields, for the internal
   * workbench's "Pending Handoff" queue tab.
   *
   * @return Matching handoffs, most recently submitted first.
   */
  public static List<Deal_Implementation_Handoff__c> selectPendingHandoffs() {
    return [
      SELECT
        Id,
        Status__c,
        Delivery_Owner__c,
        Version_Number__c,
        Implementation__c,
        Implementation__r.Deal__c,
        Implementation__r.Customer_Account__r.Name,
        Implementation__r.Primary_Partner__r.Name,
        Implementation__r.Implementation_Type__c,
        Implementation__r.Status__c,
        Implementation__r.Health__c,
        Implementation__r.Planned_Start_Date__c,
        Implementation__r.Planned_Completion_Date__c,
        Implementation__r.Actual_Start_Date__c,
        Implementation__r.Actual_Completion_Date__c,
        Implementation__r.Version_Number__c
      FROM Deal_Implementation_Handoff__c
      WHERE Status__c = 'Submitted'
      WITH SYSTEM_MODE
      ORDER BY CreatedDate DESC
      LIMIT 200
    ];
  }
}
