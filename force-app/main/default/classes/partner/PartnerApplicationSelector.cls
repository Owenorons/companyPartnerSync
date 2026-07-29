/*
 * Query layer for Partner_Application__c across the onboarding flow:
 * duplicate detection at submit time, the reviewer queue, and single-record
 * lookups for detail/decision. Each method selects only the columns its
 * specific caller needs rather than one shared "full record" query.
 */
public with sharing class PartnerApplicationSelector {
  public static List<Partner_Application__c> findPotentialDuplicates(
    String normalizedCompanyName,
    String businessEmail
  ) {
    SecurityUtil.assertReadable(Partner_Application__c.SObjectType);

    return [
      SELECT Id, Name, Company_Name__c, Business_Email__c, Application_Status__c
      FROM Partner_Application__c
      WHERE
        Application_Status__c IN ('Submitted', 'Under Review', 'Approved')
        AND (Normalized_Company_Name__c = :normalizedCompanyName
        OR Business_Email__c = :businessEmail)
      WITH USER_MODE
      LIMIT 10
    ];
  }

  public static Partner_Application__c selectById(Id applicationId) {
    SecurityUtil.assertReadable(Partner_Application__c.SObjectType);

    List<Partner_Application__c> rows = [
      SELECT
        Id,
        Name,
        Application_Number__c,
        Company_Name__c,
        Business_Email__c,
        Phone__c,
        Website__c,
        Country__c,
        Region__c,
        Requested_Tier__c,
        Partner_Type__c,
        Submitted_By_Contact_Name__c,
        Submitted_By_Email__c,
        Application_Status__c,
        Decision__c,
        Rejection_Reason__c,
        Approval_Notes__c,
        Submitted_On__c,
        Created_Account__c,
        Created_Contact__c
      FROM Partner_Application__c
      WHERE Id = :applicationId
      WITH USER_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Partner application not found.');
    }

    return rows[0];
  }

  public static Partner_Application__c selectSubmissionResultById(
    Id applicationId
  ) {
    SecurityUtil.assertReadable(Partner_Application__c.SObjectType);

    List<Partner_Application__c> rows = [
      SELECT Id, Name, Application_Number__c, Application_Status__c
      FROM Partner_Application__c
      WHERE Id = :applicationId
      WITH USER_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Partner application not found.');
    }

    return rows[0];
  }

  public static List<Partner_Application__c> selectPendingApplications() {
    SecurityUtil.assertReadable(Partner_Application__c.SObjectType);

    return [
      SELECT
        Id,
        Name,
        Application_Number__c,
        Company_Name__c,
        Business_Email__c,
        Requested_Tier__c,
        Partner_Type__c,
        Application_Status__c,
        Submitted_On__c,
        Assigned_Reviewer__c
      FROM Partner_Application__c
      WHERE Application_Status__c IN ('Submitted', 'Under Review')
      WITH USER_MODE
      ORDER BY Submitted_On__c ASC NULLS LAST, CreatedDate ASC
      LIMIT 500
    ];
  }
}
