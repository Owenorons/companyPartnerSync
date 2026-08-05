/*
 * Selector layer for the partner-facing registration flow: opportunity
 * eligibility, duplicate-registration checks, a partner's own deals, and
 * the conflict lookup used at submission time. Everything here is scoped
 * to a single partner account. Compare to DealReviewSelector, which
 * intentionally has no partner scoping because internal reviewers must see
 * across all partners.
 */
public with sharing class DealRegistrationSelector {
  public static Opportunity selectOpportunityForRegistration(Id opportunityId) {
    SecurityUtil.assertReadable(Opportunity.SObjectType);

    List<Opportunity> rows = [
      SELECT
        Id,
        AccountId,
        Partner_Account__c,
        Partner_Contact__c,
        StageName,
        Source_Lead__c
      FROM Opportunity
      WHERE Id = :opportunityId
      WITH USER_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Opportunity not found.');
    }

    return rows[0];
  }

  public static List<Opportunity> selectEligibleOpportunitiesForPartner(
    Id partnerAccountId
  ) {
    SecurityUtil.assertReadable(Opportunity.SObjectType);
    SecurityUtil.assertReadable(Deal_Registration__c.SObjectType);

    Set<Id> registeredOpportunityIds = new Set<Id>();

    for (Deal_Registration__c registration : [
      SELECT Opportunity__c
      FROM Deal_Registration__c
      WHERE Partner_Account__c = :partnerAccountId AND Opportunity__c != NULL
      WITH USER_MODE
    ]) {
      registeredOpportunityIds.add(registration.Opportunity__c);
    }

    return [
      SELECT Id, Name, StageName, Amount, CloseDate
      FROM Opportunity
      WHERE
        Partner_Account__c = :partnerAccountId
        AND Id NOT IN :registeredOpportunityIds
      WITH USER_MODE
      ORDER BY CloseDate ASC
      LIMIT 100
    ];
  }

  public static Boolean hasExistingRegistration(Id opportunityId) {
    SecurityUtil.assertReadable(Deal_Registration__c.SObjectType);

    List<Deal_Registration__c> existing = [
      SELECT Id
      FROM Deal_Registration__c
      WHERE Opportunity__c = :opportunityId
      WITH USER_MODE
      LIMIT 1
    ];

    return !existing.isEmpty();
  }

  public static List<Deal_Registration__c> selectPartnerDeals(
    Id partnerAccountId
  ) {
    SecurityUtil.assertReadable(Deal_Registration__c.SObjectType);

    return [
      SELECT
        Id,
        Name,
        Status__c,
        Conflict_Status__c,
        Estimated_Revenue__c,
        Protection_End_Date__c,
        CreatedDate,
        Customer_Account__r.Name,
        Partner_Account__r.Name,
        Opportunity__r.StageName
      FROM Deal_Registration__c
      WHERE Partner_Account__c = :partnerAccountId
      WITH USER_MODE
      ORDER BY CreatedDate DESC
      LIMIT 200
    ];
  }

  // 'Draft' is excluded (never submitted, doesn't count against the cap);
  // 'Rejected'/'Expired'/'Converted'/'Closed Won'/'Closed Lost' are terminal
  // and no longer occupy a slot.
  public static Integer countOpenDealsForPartner(Id partnerAccountId) {
    SecurityUtil.assertReadable(Deal_Registration__c.SObjectType);

    return [
      SELECT COUNT()
      FROM Deal_Registration__c
      WHERE
        Partner_Account__c = :partnerAccountId
        AND Status__c IN ('Submitted', 'Under Review', 'Approved')
      WITH USER_MODE
    ];
  }

  public static Deal_Registration__c selectById(Id dealId) {
    SecurityUtil.assertReadable(Deal_Registration__c.SObjectType);

    List<Deal_Registration__c> rows = [
      SELECT
        Id,
        Name,
        Opportunity__c,
        Customer_Account__c,
        Partner_Account__c,
        Partner_Contact__c,
        Status__c,
        Conflict_Status__c,
        Estimated_Revenue__c,
        Estimated_Close_Date__c,
        Protection_End_Date__c,
        Business_Problem__c,
        Proposed_Solution__c,
        Notes__c
      FROM Deal_Registration__c
      WHERE Id = :dealId
      WITH USER_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Deal registration not found.');
    }

    return rows[0];
  }

  public static List<Deal_Registration__c> findConflictingDeals(
    Id customerAccountId,
    Id currentDealId
  ) {
    SecurityUtil.assertReadable(Deal_Registration__c.SObjectType);

    // Only 'Submitted' and 'Approved' are checked here: this runs on the
    // just-inserted record before it can ever be 'Under Review', so that
    // status can't exist yet for the deal being analyzed. DealReviewSelector
    // .selectConflictsForDeal also includes 'Under Review' because it runs
    // later, once other deals may already be mid-review.
    return [
      SELECT
        Id,
        Name,
        Partner_Account__c,
        Status__c,
        Conflict_Status__c,
        Protection_End_Date__c
      FROM Deal_Registration__c
      WHERE
        Customer_Account__c = :customerAccountId
        AND Status__c IN ('Submitted', 'Approved')
        AND Id != :currentDealId
      WITH USER_MODE
      LIMIT 20
    ];
  }
}
