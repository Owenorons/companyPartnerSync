/**
 * Query layer for Partner_Application__c across the onboarding flow:
 * duplicate detection at submit time, the reviewer queue, and single-record
 * lookups for detail/decision. Each method selects only the columns its
 * specific caller needs rather than one shared "full record" query.
 */
public with sharing class PartnerApplicationSelector {
  /**
   * Finds submitted, under-review, or approved applications matching the
   * given normalized company name or business email, for duplicate
   * detection at submission time.
   *
   * @param normalizedCompanyName Normalized company name to match against.
   * @param businessEmail Business email to match against.
   * @return Up to 10 Partner_Application__c records considered potential
   * duplicates.
   */
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

  /**
   * Retrieves a single partner application by Id with the fields needed
   * for the reviewer detail view.
   *
   * @param applicationId Id of the Partner_Application__c to retrieve.
   * @return The matching Partner_Application__c record.
   */
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
        Assigned_Reviewer__c,
        Assigned_Reviewer__r.Name,
        Created_Account__c,
        Created_Contact__c,
        Provisioned_User__c,
        Provisioning_Status__c,
        Provisioning_Error__c,
        Provisioned_On__c
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

  /**
   * Retrieves a single partner application locked for update, with the
   * fields needed to record a review decision or provisioning outcome.
   *
   * @param applicationId Id of the Partner_Application__c to retrieve.
   * @return The matching Partner_Application__c record, locked
   * (FOR UPDATE).
   */
  public static Partner_Application__c selectForDecisionById(Id applicationId) {
    SecurityUtil.assertReadable(Partner_Application__c.SObjectType);

    List<Partner_Application__c> rows = [
      SELECT
        Id,
        Company_Name__c,
        Business_Email__c,
        Phone__c,
        Website__c,
        Region__c,
        Requested_Tier__c,
        Partner_Type__c,
        Submitted_By_Contact_Name__c,
        Submitted_By_Email__c,
        Application_Status__c,
        Decision__c,
        Assigned_Reviewer__c,
        Created_Account__c,
        Created_Contact__c,
        Provisioned_User__c,
        Provisioning_Status__c,
        Provisioning_Job_Id__c,
        Provisioning_Started_On__c,
        Active_Company_Key__c,
        Active_Email_Key__c
      FROM Partner_Application__c
      WHERE Id = :applicationId
      WITH USER_MODE
      LIMIT 1
      FOR UPDATE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Partner application not found.');
    }

    return rows[0];
  }

  /**
   * Retrieves applications currently awaiting review, ordered by
   * submission date, for the reviewer queue.
   *
   * @return Up to 500 Partner_Application__c records with status
   * Submitted or Under Review.
   */
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
