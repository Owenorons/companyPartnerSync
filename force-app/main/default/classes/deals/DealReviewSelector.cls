/*
 * Selector layer for the internal review workflow. Deliberately not scoped
 * to a single partner account — reviewers need visibility across all
 * partners' deals, so authorization here is enforced by
 * PartnerPermissionService in the service layer (assertCanViewAllDeals /
 * assertCanReviewDeals), not by a WHERE-clause partner filter. Compare to
 * DealRegistrationSelector, which is intentionally scoped per partner.
 */
public without sharing class DealReviewSelector {
  public static List<Deal_Registration__c> selectReviewQueue() {
    SecurityUtil.assertReadable(Deal_Registration__c.SObjectType);

    // Oldest submissions first (FIFO) so the queue surfaces the deals
    // that have been waiting longest for a decision.
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
      WHERE Status__c IN ('Submitted', 'Under Review', 'Approved', 'Rejected')
      WITH SYSTEM_MODE
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
      WITH SYSTEM_MODE
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

    // Includes 'Under Review', unlike DealRegistrationSelector
    // .findConflictingDeals — by the time a deal reaches this screen, other
    // deals on the same customer account may themselves be mid-review, and
    // those still count as live conflicts.
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
      WITH SYSTEM_MODE
      ORDER BY CreatedDate DESC
      LIMIT 50
    ];
  }
}
