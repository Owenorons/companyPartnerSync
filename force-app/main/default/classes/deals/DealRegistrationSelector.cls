/**
 * Selector layer for the partner-facing registration flow: opportunity
 * eligibility, duplicate-registration checks, a partner's own deals, and
 * the conflict lookup used at submission time. Everything here is scoped
 * to a single partner account. Compare to DealReviewSelector, which
 * intentionally has no partner scoping because internal reviewers must see
 * across all partners.
 */
public with sharing class DealRegistrationSelector {
  /**
   * Queries a single Opportunity for use during deal registration.
   *
   * @param opportunityId Id of the opportunity to load.
   * @return The Opportunity record.
   */
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

  /**
   * Queries opportunities belonging to a partner that don't already have a deal registration.
   *
   * @param partnerAccountId Id of the partner account whose opportunities are queried.
   * @return Up to 100 eligible opportunities, ordered by close date ascending.
   */
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

    // Deal_Opportunity__c is the authoritative claim, not just
    // Deal_Registration__c.Opportunity__c - an opportunity already linked
    // to any deal as a secondary/expansion/etc. relationship must not be
    // offered again either (Sprint 39 §39.2).
    for (Deal_Opportunity__c relationship : [
      SELECT Opportunity__c
      FROM Deal_Opportunity__c
      WHERE Partner_Account__c = :partnerAccountId AND Current__c = TRUE
      WITH USER_MODE
    ]) {
      registeredOpportunityIds.add(relationship.Opportunity__c);
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

  /**
   * Checks whether an opportunity already has a deal registration.
   *
   * @param opportunityId Id of the opportunity to check.
   * @return True if at least one deal registration already exists for the opportunity.
   */
  public static Boolean hasExistingRegistration(Id opportunityId) {
    SecurityUtil.assertReadable(Deal_Registration__c.SObjectType);

    List<Deal_Registration__c> existing = [
      SELECT Id
      FROM Deal_Registration__c
      WHERE Opportunity__c = :opportunityId
      WITH USER_MODE
      LIMIT 1
    ];

    if (!existing.isEmpty()) {
      return true;
    }

    // Deal_Opportunity__c is the authoritative claim going forward (Sprint
    // 39 §39.2) - an opportunity already linked to a different deal as any
    // relationship type must still block a brand new registration from
    // independently claiming it, even before that deal's own
    // Deal_Registration__c.Opportunity__c projection would have shown it.
    SecurityUtil.assertReadable(Deal_Opportunity__c.SObjectType);
    return DealOpportunitySelector.selectActiveLinkForOpportunity(
        opportunityId
      ) != null;
  }

  /**
   * Queries a partner's own deal registrations for the "My Deals" list.
   *
   * @param partnerAccountId Id of the partner account whose deals are queried.
   * @return Up to 200 deal registration rows, most recently created first.
   */
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
  /**
   * Counts a partner's deal registrations that are still open (Submitted, Under Review, or Approved).
   *
   * @param partnerAccountId Id of the partner account whose deals are counted.
   * @return Number of open deal registrations for the partner.
   */
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

  /**
   * Queries a single deal registration record by Id.
   *
   * @param dealId Id of the deal registration to load.
   * @return The Deal_Registration__c record.
   */
  public static Deal_Registration__c selectById(Id dealId) {
    SecurityUtil.assertReadable(Deal_Registration__c.SObjectType);

    List<Deal_Registration__c> rows = [
      SELECT
        Id,
        Name,
        Opportunity__c,
        Opportunity__r.StageName,
        Customer_Account__c,
        Customer_Account__r.Name,
        Partner_Account__c,
        Partner_Account__r.Name,
        Partner_Contact__c,
        Status__c,
        Conflict_Status__c,
        Attribution_Type__c,
        Estimated_Revenue__c,
        Estimated_Close_Date__c,
        Protection_End_Date__c,
        Business_Problem__c,
        Proposed_Solution__c,
        Notes__c,
        Lifecycle_Phase__c,
        Lifecycle_Health__c,
        Current_Action_Required__c,
        Next_Action_Due__c,
        CreatedDate
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

  /**
   * Queries a deal's partner-visible lifecycle events for the deal detail
   * timeline, most recent first. Internal-only events (Partner_Visible__c
   * = false) are excluded.
   *
   * @param dealId Id of the deal registration whose events are queried.
   * @return Up to 50 partner-visible Deal_Event__c records.
   */
  public static List<Deal_Event__c> selectPartnerVisibleEvents(Id dealId) {
    SecurityUtil.assertReadable(Deal_Event__c.SObjectType);

    return [
      SELECT Id, Event_Type__c, Summary__c, Occurred_On__c
      FROM Deal_Event__c
      WHERE Deal__c = :dealId AND Partner_Visible__c = TRUE
      WITH USER_MODE
      ORDER BY Occurred_On__c DESC
      LIMIT 50
    ];
  }

  /**
   * Finds other deal registrations on the same customer account that may conflict with a
   * just-inserted deal, at submission time.
   *
   * @param customerAccountId Id of the customer account to check for conflicts on.
   * @param currentDealId Id of the deal being analyzed, excluded from the results.
   * @return Up to 20 potentially conflicting deal registrations.
   */
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

  /**
   * Queries deals whose co-sell participation is currently Active, for the
   * internal Co-Sell Workbench's "Active Co-Sell Deals" view.
   *
   * @return Up to 200 deals with CoSell_Status__c = 'Active'.
   */
  public static List<Deal_Registration__c> selectActiveCoSellDeals() {
    return [
      SELECT
        Id,
        Customer_Name__c,
        Partner_Account__c,
        Partner_Account__r.Name,
        CoSell_Status__c
      FROM Deal_Registration__c
      WHERE CoSell_Status__c = 'Active'
      WITH SYSTEM_MODE
      ORDER BY LastModifiedDate DESC
      LIMIT 200
    ];
  }

  /**
   * Queries approved deals with no current Deal_Opportunity__c relationship
   * at all, for the internal Sales Execution Workbench's "Opportunity
   * Pending Link" view. This org's registration flow backfills a primary
   * relationship unconditionally at registration time, so this should be
   * rare in practice - a genuine invariant-violation catch, not the common
   * case the doc's Creation_Mode-driven "pending" state assumes.
   *
   * @return Up to 200 approved deals with no current opportunity relationship.
   */
  public static List<Deal_Registration__c> selectApprovedDealsWithoutOpportunityLink() {
    Set<Id> dealIdsWithRelationships = new Set<Id>();
    for (Deal_Opportunity__c relationship : [
      SELECT Deal__c
      FROM Deal_Opportunity__c
      WHERE Current__c = TRUE
      WITH SYSTEM_MODE
    ]) {
      dealIdsWithRelationships.add(relationship.Deal__c);
    }

    return [
      SELECT Id, Customer_Name__c, Partner_Account__r.Name, Status__c, Stage__c
      FROM Deal_Registration__c
      WHERE
        Status__c IN ('Approved', 'Approved with Conditions')
        AND Id NOT IN :dealIdsWithRelationships
      WITH SYSTEM_MODE
      ORDER BY LastModifiedDate DESC
      LIMIT 200
    ];
  }

  /**
   * Queries deals currently back in Under Review because a material change
   * triggered reapproval (DealMaterialChangeService), for the internal
   * Sales Execution Workbench's "Reapproval Required" view.
   *
   * @return Up to 200 deals under review due to a material change.
   */
  public static List<Deal_Registration__c> selectReapprovalRequiredDeals() {
    return [
      SELECT Id, Customer_Name__c, Partner_Account__r.Name, Status__c, Stage__c
      FROM Deal_Registration__c
      WHERE
        Status__c = 'Under Review'
        AND Last_Lifecycle_Event__c = 'DealReapprovalRequested'
      WITH SYSTEM_MODE
      ORDER BY LastModifiedDate DESC
      LIMIT 200
    ];
  }

  /**
   * Queries deals whose primary opportunity relationship is orphaned
   * (DealOpportunityReconciliationBatch), for the internal Sales Execution
   * Workbench's "Orphaned Relationships" view.
   *
   * @return Up to 200 deals with Lifecycle_Health__c = 'Blocked'.
   */
  public static List<Deal_Registration__c> selectOrphanedOpportunityDeals() {
    return [
      SELECT Id, Customer_Name__c, Partner_Account__r.Name, Status__c, Stage__c
      FROM Deal_Registration__c
      WHERE Lifecycle_Health__c = 'Blocked'
      WITH SYSTEM_MODE
      ORDER BY LastModifiedDate DESC
      LIMIT 200
    ];
  }

  /**
   * Queries deals whose canonical Stage__c is Closed Won/Lost, for the
   * internal Sales Execution Workbench's "Recently Closed" view.
   *
   * @return Up to 200 recently closed deals.
   */
  public static List<Deal_Registration__c> selectRecentlyClosedDeals() {
    return [
      SELECT Id, Customer_Name__c, Partner_Account__r.Name, Status__c, Stage__c
      FROM Deal_Registration__c
      WHERE Stage__c IN ('Closed Won', 'Closed Lost')
      WITH SYSTEM_MODE
      ORDER BY LastModifiedDate DESC
      LIMIT 200
    ];
  }
}
