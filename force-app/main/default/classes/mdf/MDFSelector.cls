public with sharing class MDFSelector {
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
      ORDER BY CreatedDate DESC
      LIMIT 200
    ];
  }

  public static List<MDF_Request__c> selectReviewQueue() {
    PartnerPermissionService.assertCanApproveMdf();
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
      ORDER BY CreatedDate ASC
      LIMIT 500
    ];
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
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('MDF request not accessible.');
    }

    return rows[0];
  }

  public static MDF_Request__c selectForInternalReview(Id requestId) {
    PartnerPermissionService.assertCanApproveMdf();
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
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('MDF request not found.');
    }

    return rows[0];
  }
}
