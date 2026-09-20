/**
 * Selector layer for MDF_Request__c and its related partner budget
 * fields. Queries are split by audience: selectMyRequests/selectForPartner
 * scope to the caller's own partner account, while selectReviewQueue/
 * selectForInternalReview additionally assert the internal MDF-review
 * permission before returning records outside that scope.
 */
public without sharing class MDFSelector {
  /**
   * Locks the request before checking its decision status. Decision commands
   * always lock the request first, then its partner budget, until commit.
   *
   * @param requestId Request to decide.
   * @return The current, locked request.
   */
  public static MDF_Request__c selectForDecision(Id requestId) {
    PartnerPermissionService.assertCanViewAllMdf();
    SecurityUtil.assertReadable(MDF_Request__c.SObjectType);
    List<MDF_Request__c> rows = [
      SELECT Id, Partner_Account__c, Status__c
      FROM MDF_Request__c
      WHERE Id = :requestId
      WITH SYSTEM_MODE
      LIMIT 1
      FOR UPDATE
    ];
    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('MDF request not found.');
    }
    return rows[0];
  }

  /**
   * Locks the shared budget before reading the consumption used in approval.
   * Kept separate from the unlocked, cacheable partner budget read path.
   *
   * @param partnerAccountId Partner whose budget is being consumed.
   * @return Current budget while holding the account lock.
   */
  public static Account selectPartnerBudgetForApproval(Id partnerAccountId) {
    PartnerPermissionService.assertCanApproveMdf();
    SecurityUtil.assertReadable(Account.SObjectType);
    List<Account> rows = [
      SELECT Id, MDF_Annual_Budget__c, MDF_Used__c
      FROM Account
      WHERE Id = :partnerAccountId AND Is_Partner__c = TRUE
      WITH USER_MODE
      LIMIT 1
      FOR UPDATE
    ];
    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Partner account not found.');
    }
    return rows[0];
  }

  /**
   * Returns the MDF requests submitted by the given partner account,
   * most recent first.
   *
   * @param partnerAccountId Id of the partner account to scope to.
   * @return Up to 200 MDF_Request__c records for that partner account.
   */
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

  /**
   * Returns all MDF requests awaiting internal decision (Submitted or
   * Under Review), across all partner accounts. Requires the internal
   * MDF-review permission.
   *
   * @return Up to 500 pending MDF_Request__c records, oldest first.
   */
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

  /**
   * Returns the partner Account's MDF budget fields.
   *
   * @param partnerAccountId Id of the partner account.
   * @return The Account record with its MDF budget fields queried.
   */
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

  /**
   * Returns a single MDF request, scoped to the given partner account.
   *
   * @param requestId Id of the MDF_Request__c record to fetch.
   * @param partnerAccountId Id of the partner account the caller belongs to.
   * @return The matching MDF_Request__c record.
   */
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

  /**
   * Returns a single MDF request for internal review, without scoping
   * to a partner account. Requires the internal MDF-review permission.
   *
   * @param requestId Id of the MDF_Request__c record to fetch.
   * @return The matching MDF_Request__c record.
   */
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
