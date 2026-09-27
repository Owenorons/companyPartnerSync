/**
 * Selector layer for Implementation_Issue__c.
 */
public without sharing class ImplementationIssueSelector {
  /**
   * Locks and reads a single issue record by Id.
   *
   * @param issueId Id of the issue to load.
   * @return The locked Implementation_Issue__c record.
   */
  public static Implementation_Issue__c selectForUpdate(Id issueId) {
    List<Implementation_Issue__c> rows = [
      SELECT
        Id,
        Implementation__c,
        Milestone__c,
        Issue_Type__c,
        Severity__c,
        Status__c,
        Title__c,
        Description__c,
        Raised_On__c,
        Raised_By__c,
        Owner__c,
        Partner_Account__c,
        Impact__c,
        Resolution__c,
        Target_Resolution_On__c,
        Resolved_On__c,
        Customer_Impact__c,
        Commercial_Impact__c,
        Escalation_Level__c
      FROM Implementation_Issue__c
      WHERE Id = :issueId
      WITH SYSTEM_MODE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Implementation issue not found.');
    }

    return rows[0];
  }

  /**
   * Queries every open (not Resolved/Accepted Risk/Closed) issue for an
   * implementation.
   *
   * @param implementationId Id of the implementation.
   * @return The implementation's open issues.
   */
  public static List<Implementation_Issue__c> selectOpenForImplementation(
    Id implementationId
  ) {
    return [
      SELECT Severity__c, Status__c
      FROM Implementation_Issue__c
      WHERE
        Implementation__c = :implementationId
        AND Status__c NOT IN ('Resolved', 'Accepted Risk', 'Closed')
      WITH SYSTEM_MODE
    ];
  }

  /**
   * Queries every issue (open and resolved) for an implementation, for a
   * full detail/history view.
   *
   * @param implementationId Id of the implementation.
   * @return The implementation's issues, most recently raised first.
   */
  public static List<Implementation_Issue__c> selectForImplementation(
    Id implementationId
  ) {
    return [
      SELECT
        Id,
        Title__c,
        Issue_Type__c,
        Severity__c,
        Status__c,
        Raised_On__c,
        Resolved_On__c,
        Target_Resolution_On__c,
        Customer_Impact__c
      FROM Implementation_Issue__c
      WHERE Implementation__c = :implementationId
      WITH SYSTEM_MODE
      ORDER BY Raised_On__c DESC
    ];
  }
}
