/*
 * Narrow post-insert lookup for the public partner application form. Guest
 * users cannot read records after ownership transfers to the site's default
 * owner, so this selector deliberately bypasses record sharing only to return
 * confirmation fields for the record created in the current transaction.
 */
public without sharing class PartnerApplicationSubmissionSelector {
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
