/**
 * Narrow post-insert lookup for the public partner application form. Guest
 * users cannot read records after ownership transfers to the site's default
 * owner, so this selector deliberately bypasses record sharing only to return
 * confirmation fields for the record created in the current transaction.
 */
public without sharing class PartnerApplicationSubmissionSelector {
  /**
   * Finds existing in-flight or approved applications that may already
   * represent the same company or submitter, by normalized company name or
   * business email.
   *
   * @param normalizedCompanyName The normalized company name to match on.
   * @param businessEmail The submitter's business email to match on.
   * @return Up to 10 potentially duplicate Partner_Application__c records.
   */
  public static List<Partner_Application__c> findPotentialDuplicates(
    String normalizedCompanyName,
    String businessEmail
  ) {
    return [
      SELECT Id
      FROM Partner_Application__c
      WHERE
        Application_Status__c IN ('Submitted', 'Under Review', 'Approved')
        AND (Normalized_Company_Name__c = :normalizedCompanyName
        OR Business_Email__c = :businessEmail)
      WITH SYSTEM_MODE
      LIMIT 10
    ];
  }

  /**
   * Loads the confirmation fields for a single, just-submitted partner
   * application.
   *
   * @param applicationId Id of the Partner_Application__c record to load.
   * @return The matching application record.
   */
  public static Partner_Application__c selectById(Id applicationId) {
    List<Partner_Application__c> rows = [
      SELECT Id, Name, Application_Number__c, Application_Status__c
      FROM Partner_Application__c
      WHERE Id = :applicationId
      WITH SYSTEM_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Partner application not found.');
    }

    return rows[0];
  }
}
