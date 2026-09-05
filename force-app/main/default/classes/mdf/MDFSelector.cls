/*
 * Selector layer for MDF_Request__c and its related partner budget
 * fields. Queries are split by audience: selectMyRequests/selectForPartner
 * scope to the caller's own partner account, while selectReviewQueue/
 * selectForInternalReview additionally assert the internal MDF-review
 * permission before returning records outside that scope.
 */
public without sharing class MDFSelector {
  public static List<MDF_Request__c> selectMyRequests(Id partnerAccountId) {
    SecurityUtil.assertReadable(MDF_Request__c.SObjectType);

    return [
      SELECT
        Id,
        Name,
        Partner_Account__r.Name,
        Campaign_Name__c,
        Campaign_Type__c,
        Requested_Amount__c,
        Approved_Amount__c,
        Status__c,
        Activity_Start_Date__c,
        Activity_End_Date__c
      FROM MDF_Request__c
      WHERE Partner_Account__c = :partnerAccountId
      WITH USER_MODE
      ORDER BY CreatedDate DESC
      LIMIT 200
    ];
  }

  public static List<MDF_Request__c> selectReviewQueue() {
    PartnerPermissionService.assertCanViewAllMdf();
    SecurityUtil.assertReadable(MDF_Request__c.SObjectType);

    return [
      SELECT
        Id,
        Name,
        Partner_Account__r.Name,
        Campaign_Name__c,
        Campaign_Type__c,
        Requested_Amount__c,
        Approved_Amount__c,
        Status__c,
        Activity_Start_Date__c,
        Activity_End_Date__c
      FROM MDF_Request__c
      WHERE Status__c IN ('Submitted', 'Under Review')
      WITH SYSTEM_MODE
      ORDER BY CreatedDate ASC
      LIMIT 500
    ];
  }

  public static Account selectPartnerBudget(Id partnerAccountId) {
    SecurityUtil.assertReadable(Account.SObjectType);

    List<Account> rows = [
      SELECT Id, MDF_Annual_Budget__c, MDF_Used__c
      FROM Account
      WHERE Id = :partnerAccountId AND Is_Partner__c = TRUE
      WITH USER_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Partner account not found.');
    }

    return rows[0];
  }

  public static MDF_Request__c selectForPartner(
    Id requestId,
    Id partnerAccountId
  ) {
    SecurityUtil.assertReadable(MDF_Request__c.SObjectType);

    List<MDF_Request__c> rows = [
      SELECT
        Id,
        Name,
        Partner_Account__c,
        Partner_Account__r.Name,
        Submitted_By__c,
        Campaign_Name__c,
        Campaign_Type__c,
        Requested_Amount__c,
        Approved_Amount__c,
        Activity_Start_Date__c,
        Activity_End_Date__c,
        Expected_Leads__c,
        Actual_Leads__c,
        Status__c,
        Approval_Comments__c,
        Approver__c
      FROM MDF_Request__c
      WHERE Id = :requestId AND Partner_Account__c = :partnerAccountId
      WITH USER_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('MDF request not accessible.');
    }

    return rows[0];
  }

  public static MDF_Request__c selectForInternalReview(Id requestId) {
    PartnerPermissionService.assertCanViewAllMdf();
    SecurityUtil.assertReadable(MDF_Request__c.SObjectType);

    List<MDF_Request__c> rows = [
      SELECT
        Id,
        Name,
        Partner_Account__c,
        Partner_Account__r.Name,
        Submitted_By__c,
        Campaign_Name__c,
        Campaign_Type__c,
        Requested_Amount__c,
        Approved_Amount__c,
        Activity_Start_Date__c,
        Activity_End_Date__c,
        Expected_Leads__c,
        Actual_Leads__c,
        Status__c,
        Approval_Comments__c,
        Approver__c
      FROM MDF_Request__c
      WHERE Id = :requestId
      WITH SYSTEM_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('MDF request not found.');
    }

    return rows[0];
  }
}
