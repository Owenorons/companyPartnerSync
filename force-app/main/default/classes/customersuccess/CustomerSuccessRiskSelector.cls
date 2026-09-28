/**
 * Selector layer for Customer_Success_Risk__c.
 */
public without sharing class CustomerSuccessRiskSelector {
  /**
   * Locks and reads a single risk record by Id.
   *
   * @param riskId Id of the risk to load.
   * @return The locked Customer_Success_Risk__c record.
   */
  public static Customer_Success_Risk__c selectForUpdate(Id riskId) {
    List<Customer_Success_Risk__c> rows = [
      SELECT
        Id,
        Customer_Success_Engagement__c,
        Risk_Type__c,
        Severity__c,
        Status__c,
        Description__c,
        Raised_On__c,
        Resolved_On__c,
        Raised_By__c,
        Resolution__c
      FROM Customer_Success_Risk__c
      WHERE Id = :riskId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Customer Success risk not found.');
    }

    return rows[0];
  }

  /**
   * Queries every open (not Resolved/Accepted/Closed) risk for an
   * engagement.
   *
   * @param engagementId Id of the engagement.
   * @return The engagement's open risks.
   */
  public static List<Customer_Success_Risk__c> selectOpenForEngagement(
    Id engagementId
  ) {
    return [
      SELECT Severity__c, Status__c
      FROM Customer_Success_Risk__c
      WHERE
        Customer_Success_Engagement__c = :engagementId
        AND Status__c NOT IN ('Resolved', 'Accepted', 'Closed')
      WITH SYSTEM_MODE
    ];
  }
}
