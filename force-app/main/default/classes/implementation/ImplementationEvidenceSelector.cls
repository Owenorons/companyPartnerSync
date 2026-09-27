/**
 * Selector layer for Implementation_Evidence__c.
 */
public without sharing class ImplementationEvidenceSelector {
  /**
   * Locks and reads a single evidence record by Id.
   *
   * @param evidenceId Id of the evidence record to load.
   * @return The locked Implementation_Evidence__c record.
   */
  public static Implementation_Evidence__c selectForUpdate(Id evidenceId) {
    List<Implementation_Evidence__c> rows = [
      SELECT
        Id,
        Implementation__c,
        Milestone__c,
        Evidence_Type__c,
        Status__c,
        ContentDocumentId__c,
        Submitted_By__c,
        Submitted_On__c,
        Reviewed_By__c,
        Reviewed_On__c,
        Review_Outcome__c,
        Partner_Visible__c,
        Customer_Visible__c,
        Description__c
      FROM Implementation_Evidence__c
      WHERE Id = :evidenceId
      WITH SYSTEM_MODE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException(
        'Implementation evidence not found.'
      );
    }

    return rows[0];
  }

  /**
   * Queries every evidence record for an implementation, most recently
   * submitted first.
   *
   * @param implementationId Id of the implementation.
   * @return The implementation's evidence records.
   */
  public static List<Implementation_Evidence__c> selectForImplementation(
    Id implementationId
  ) {
    return [
      SELECT
        Id,
        Milestone__c,
        Evidence_Type__c,
        Status__c,
        ContentDocumentId__c,
        Submitted_On__c,
        Reviewed_On__c,
        Review_Outcome__c,
        Description__c,
        Partner_Visible__c,
        Customer_Visible__c
      FROM Implementation_Evidence__c
      WHERE Implementation__c = :implementationId
      WITH SYSTEM_MODE
      ORDER BY Submitted_On__c DESC
    ];
  }
}
