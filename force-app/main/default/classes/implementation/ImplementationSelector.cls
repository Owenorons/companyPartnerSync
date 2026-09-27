/**
 * Selector layer for the Deal_Implementation__c aggregate.
 */
public without sharing class ImplementationSelector {
  /**
   * Locks and reads a single implementation record by Id, for a command to
   * apply a decision to.
   *
   * @param implementationId Id of the implementation to load.
   * @return The locked Deal_Implementation__c record.
   */
  public static Deal_Implementation__c selectForUpdate(Id implementationId) {
    List<Deal_Implementation__c> rows = [
      SELECT
        Id,
        Deal__c,
        Opportunity__c,
        Deal_Opportunity__c,
        Customer_Account__c,
        Primary_Partner__c,
        Primary_Participant__c,
        Protection__c,
        Parent_Implementation__c,
        Implementation_Type__c,
        Status__c,
        Health__c,
        Planned_Start_Date__c,
        Planned_Completion_Date__c,
        Actual_Start_Date__c,
        Actual_Completion_Date__c,
        Version_Number__c
      FROM Deal_Implementation__c
      WHERE Id = :implementationId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Implementation not found.');
    }

    return rows[0];
  }

  /**
   * Queries every implementation for a deal.
   *
   * @param dealId Id of the deal.
   * @return The deal's implementations, most recently created first.
   */
  public static List<Deal_Implementation__c> selectForDeal(Id dealId) {
    return [
      SELECT
        Id,
        Deal__c,
        Implementation_Type__c,
        Status__c,
        Health__c,
        Planned_Start_Date__c,
        Planned_Completion_Date__c,
        Actual_Start_Date__c,
        Actual_Completion_Date__c
      FROM Deal_Implementation__c
      WHERE Deal__c = :dealId
      WITH SYSTEM_MODE
      ORDER BY CreatedDate DESC
    ];
  }

  /**
   * Indicates whether a deal already has a non-terminal implementation, to
   * avoid duplicate creation on a re-processed Closed Won detection.
   *
   * @param dealId Id of the deal.
   * @return True if an active (non-Cancelled/Failed/Superseded) implementation exists.
   */
  public static Boolean hasActiveForDeal(Id dealId) {
    return [
        SELECT COUNT()
        FROM Deal_Implementation__c
        WHERE Deal__c = :dealId AND Status__c NOT IN ('Cancelled', 'Superseded')
        WITH SYSTEM_MODE
      ] > 0;
  }

  /**
   * Loads a single implementation's summary fields (deal/customer/partner
   * names, type, status, health, dates), for the detail DTO.
   *
   * @param implementationId Id of the implementation.
   * @return The implementation's summary record.
   */
  public static Deal_Implementation__c selectSummaryById(Id implementationId) {
    List<Deal_Implementation__c> rows = [
      SELECT
        Id,
        Deal__c,
        Customer_Account__r.Name,
        Primary_Partner__r.Name,
        Implementation_Type__c,
        Status__c,
        Health__c,
        Planned_Start_Date__c,
        Planned_Completion_Date__c,
        Actual_Start_Date__c,
        Actual_Completion_Date__c,
        Version_Number__c
      FROM Deal_Implementation__c
      WHERE Id = :implementationId
      WITH SYSTEM_MODE
    ];
    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Implementation not found.');
    }
    return rows[0];
  }

  /**
   * Loads a deal's current (non-Cancelled/Superseded) implementation
   * summary, for the partner-facing workspace's single-implementation view.
   *
   * @param dealId Id of the deal.
   * @return The deal's current implementation, or null if none exists.
   */
  public static Deal_Implementation__c selectCurrentSummaryForDeal(Id dealId) {
    List<Deal_Implementation__c> rows = [
      SELECT
        Id,
        Deal__c,
        Customer_Account__r.Name,
        Primary_Partner__r.Name,
        Implementation_Type__c,
        Status__c,
        Health__c,
        Planned_Start_Date__c,
        Planned_Completion_Date__c,
        Actual_Start_Date__c,
        Actual_Completion_Date__c,
        Version_Number__c
      FROM Deal_Implementation__c
      WHERE Deal__c = :dealId AND Status__c NOT IN ('Cancelled', 'Superseded')
      WITH SYSTEM_MODE
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    return rows.isEmpty() ? null : rows[0];
  }

  /**
   * Loads up to 200 implementations whose Status__c matches one of the
   * given values, for an internal workbench queue tab.
   *
   * @param statuses The Status__c values to match.
   * @return Matching implementations, most recently created first.
   */
  public static List<Deal_Implementation__c> selectByStatus(
    Set<String> statuses
  ) {
    return [
      SELECT
        Id,
        Deal__c,
        Customer_Account__r.Name,
        Primary_Partner__r.Name,
        Implementation_Type__c,
        Status__c,
        Health__c,
        Planned_Start_Date__c,
        Planned_Completion_Date__c,
        Actual_Start_Date__c,
        Actual_Completion_Date__c,
        Version_Number__c
      FROM Deal_Implementation__c
      WHERE Status__c IN :statuses
      WITH SYSTEM_MODE
      ORDER BY CreatedDate DESC
      LIMIT 200
    ];
  }

  /**
   * Loads up to 200 non-terminal implementations whose Health__c matches
   * one of the given values, for an internal workbench queue tab (At
   * Risk/Blocked, Overdue).
   *
   * @param healthValues The Health__c values to match.
   * @return Matching implementations, most recently created first.
   */
  public static List<Deal_Implementation__c> selectByHealth(
    Set<String> healthValues
  ) {
    return [
      SELECT
        Id,
        Deal__c,
        Customer_Account__r.Name,
        Primary_Partner__r.Name,
        Implementation_Type__c,
        Status__c,
        Health__c,
        Planned_Start_Date__c,
        Planned_Completion_Date__c,
        Actual_Start_Date__c,
        Actual_Completion_Date__c,
        Version_Number__c
      FROM Deal_Implementation__c
      WHERE
        Health__c IN :healthValues
        AND Status__c NOT IN ('Cancelled', 'Superseded', 'Completed')
      WITH SYSTEM_MODE
      ORDER BY CreatedDate DESC
      LIMIT 200
    ];
  }
}
