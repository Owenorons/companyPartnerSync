/**
 * Selector layer for Implementation_Acceptance__c.
 */
public without sharing class ImplementationAcceptanceSelector {
  /**
   * Locks and reads a single acceptance record by Id.
   *
   * @param acceptanceId Id of the acceptance record to load.
   * @return The locked Implementation_Acceptance__c record.
   */
  public static Implementation_Acceptance__c selectForUpdate(Id acceptanceId) {
    List<Implementation_Acceptance__c> rows = [
      SELECT
        Id,
        Implementation__c,
        Acceptance_Type__c,
        Status__c,
        Requested_On__c,
        Requested_By__c,
        Customer_Contact__c,
        Accepted_On__c,
        Accepted_By_Name__c,
        Accepted_By_Email__c,
        Acceptance_Method__c,
        Evidence__c,
        Comments__c,
        Rejection_Reason__c,
        Version_Number__c
      FROM Implementation_Acceptance__c
      WHERE Id = :acceptanceId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException(
        'Implementation acceptance record not found.'
      );
    }

    return rows[0];
  }

  /**
   * Queries every acceptance record for an implementation.
   *
   * @param implementationId Id of the implementation.
   * @return The implementation's acceptance records.
   */
  public static List<Implementation_Acceptance__c> selectForImplementation(
    Id implementationId
  ) {
    return [
      SELECT
        Acceptance_Type__c,
        Status__c,
        Acceptance_Method__c,
        Requested_On__c,
        Accepted_On__c,
        Accepted_By_Name__c
      FROM Implementation_Acceptance__c
      WHERE Implementation__c = :implementationId
      WITH SYSTEM_MODE
      ORDER BY CreatedDate DESC
    ];
  }

  /**
   * Indicates whether an implementation has at least one required
   * acceptance type still not Accepted - used by
   * ImplementationCommandService.complete()'s guard. "Required" here
   * means requested at all (a Draft/Requested/Pending/Rejected/Changes
   * Requested row exists) - an acceptance type never requested isn't a
   * completion blocker.
   *
   * @param implementationId Id of the implementation.
   * @return True if any requested acceptance is not yet Accepted.
   */
  public static Boolean hasUnacceptedRequiredAcceptance(Id implementationId) {
    return [
        SELECT COUNT()
        FROM Implementation_Acceptance__c
        WHERE Implementation__c = :implementationId AND Status__c != 'Accepted'
        WITH SYSTEM_MODE
      ] > 0;
  }
}
