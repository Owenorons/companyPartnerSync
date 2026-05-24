public with sharing class DealReviewSelector {
  public static List<Deal_Registration__c> selectReviewQueue() {
    SecurityUtil.assertReadable(Deal_Registration__c.SObjectType);

    return [
      SELECT
        Id,
        Name,
        Customer_Account__r.Name,
        Partner_Account__r.Name,
        Estimated_Revenue__c,
        Estimated_Close_Date__c,
        Status__c,
        Conflict_Status__c,
        Protection_End_Date__c,
        Submitted_On__c
      FROM Deal_Registration__c
      WHERE Status__c IN ('Submitted', 'Under Review', 'Approved')
      ORDER BY Submitted_On__c ASC NULLS LAST, CreatedDate ASC
      LIMIT 500
    ];
  }

  public static Deal_Registration__c selectForInternalReview(Id dealId) {
    SecurityUtil.assertReadable(Deal_Registration__c.SObjectType);

    List<Deal_Registration__c> rows = [
      SELECT
        Id,
        Name,
        Opportunity__c,
        Customer_Account__c,
        Customer_Account__r.Name,
        Partner_Account__c,
        Partner_Account__r.Name,
        Partner_Contact__c,
        Status__c,
        Conflict_Status__c,
        Business_Problem__c,
        Proposed_Solution__c,
        Estimated_Revenue__c,
        Estimated_Close_Date__c,
        Implementation_Timeline__c,
        Protection_End_Date__c,
        Submitted_On__c,
        Approval_Notes__c,
        Rejection_Reason__c,
        Conflict_Resolution_Notes__c,
        Notes__c
      FROM Deal_Registration__c
      WHERE Id = :dealId
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Deal registration not found.');
    }

    return rows[0];
  }

  public static List<Deal_Registration__c> selectConflictsForDeal(
    Id customerAccountId,
    Id currentDealId
  ) {
    SecurityUtil.assertReadable(Deal_Registration__c.SObjectType);

    if (customerAccountId == null) {
      return new List<Deal_Registration__c>();
    }

    return [
      SELECT
        Id,
        Name,
        Customer_Account__r.Name,
        Partner_Account__r.Name,
        Estimated_Revenue__c,
        Status__c,
        Protection_End_Date__c
      FROM Deal_Registration__c
      WHERE
        Customer_Account__c = :customerAccountId
        AND Id != :currentDealId
        AND Status__c IN ('Submitted', 'Under Review', 'Approved')
      ORDER BY CreatedDate DESC
      LIMIT 50
    ];
  }
}
