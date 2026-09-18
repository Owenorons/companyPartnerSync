/**
 * Selector layer for analytics: all SOQL backing KPI, leaderboard, and
 * customer-revenue calculations lives here, each query explicitly enforcing
 * WITH USER_MODE / readable checks so AnalyticsService and AnalyticsDomain
 * never touch raw queries.
 */
public with sharing class AnalyticsSelector {
  /**
   * Loads KPI totals in eight queries regardless of the number of partners.
   * Group only by account so each result stays within the leaderboard's
   * 1,000-account bound, even when every partner has every lifecycle status.
   *
   * @param partnerAccountIds Visible partner accounts to summarise (at most 1,000).
   * @return Zero-initialised totals for every requested account, including inactive ones.
   */
  public static Map<Id, AnalyticsDomain.KpiTotals> selectKpiTotals(
    Set<Id> partnerAccountIds
  ) {
    Map<Id, AnalyticsDomain.KpiTotals> totals = new Map<Id, AnalyticsDomain.KpiTotals>();
    if (partnerAccountIds == null || partnerAccountIds.isEmpty()) {
      return totals;
    }
    if (partnerAccountIds.size() > 1000) {
      throw new PartnerSyncHandledException(
        'Request KPI totals for at most 1,000 partners at a time.'
      );
    }
    SecurityUtil.assertReadable(Lead.SObjectType);
    SecurityUtil.assertReadable(Deal_Registration__c.SObjectType);
    SecurityUtil.assertReadable(Opportunity.SObjectType);
    for (Id partnerId : partnerAccountIds) {
      totals.put(partnerId, new AnalyticsDomain.KpiTotals());
    }
    for (AggregateResult row : [
      SELECT Partner_Account__c partnerId, COUNT(Id) recordCount
      FROM Lead
      WHERE Partner_Account__c IN :partnerAccountIds
      WITH USER_MODE
      GROUP BY Partner_Account__c
    ]) {
      totals.get((Id) row.get('partnerId')).totalLeads = (Integer) row.get(
        'recordCount'
      );
    }
    for (AggregateResult row : [
      SELECT Partner_Account__c partnerId, COUNT(Id) recordCount
      FROM Lead
      WHERE
        Partner_Account__c IN :partnerAccountIds
        AND Lead_Distribution_Status__c IN ('Accepted', 'Converted')
      WITH USER_MODE
      GROUP BY Partner_Account__c
    ]) {
      totals.get((Id) row.get('partnerId')).acceptedLeads = (Integer) row.get(
        'recordCount'
      );
    }
    for (AggregateResult row : [
      SELECT Partner_Account__c partnerId, COUNT(Id) recordCount
      FROM Lead
      WHERE
        Partner_Account__c IN :partnerAccountIds
        AND Lead_Distribution_Status__c = 'Converted'
      WITH USER_MODE
      GROUP BY Partner_Account__c
    ]) {
      totals.get((Id) row.get('partnerId')).convertedLeads = (Integer) row.get(
        'recordCount'
      );
    }
    for (AggregateResult row : [
      SELECT Partner_Account__c partnerId, COUNT(Id) recordCount
      FROM Deal_Registration__c
      WHERE Partner_Account__c IN :partnerAccountIds
      WITH USER_MODE
      GROUP BY Partner_Account__c
    ]) {
      totals.get((Id) row.get('partnerId')).totalDeals = (Integer) row.get(
        'recordCount'
      );
    }
    for (AggregateResult row : [
      SELECT Partner_Account__c partnerId, COUNT(Id) recordCount
      FROM Deal_Registration__c
      WHERE Partner_Account__c IN :partnerAccountIds AND Status__c = 'Approved'
      WITH USER_MODE
      GROUP BY Partner_Account__c
    ]) {
      totals.get((Id) row.get('partnerId')).approvedDeals = (Integer) row.get(
        'recordCount'
      );
    }
    for (AggregateResult row : [
      SELECT Partner_Account__c partnerId, SUM(Estimated_Revenue__c) totalAmount
      FROM Deal_Registration__c
      WHERE
        Partner_Account__c IN :partnerAccountIds
        AND Status__c IN :AnalyticsDomain.OPEN_PIPELINE_STATUSES
      WITH USER_MODE
      GROUP BY Partner_Account__c
    ]) {
      totals.get((Id) row.get('partnerId')).totalPipeline = row.get(
          'totalAmount'
        ) == null
        ? 0
        : (Decimal) row.get('totalAmount');
    }
    for (AggregateResult row : [
      SELECT Partner_Account__c partnerId, COUNT(Id) recordCount
      FROM Opportunity
      WHERE Partner_Account__c IN :partnerAccountIds AND IsClosed = TRUE
      WITH USER_MODE
      GROUP BY Partner_Account__c
    ]) {
      totals.get((Id) row.get('partnerId'))
        .closedOpportunities = (Integer) row.get('recordCount');
    }
    for (AggregateResult row : [
      SELECT
        Partner_Account__c partnerId,
        COUNT(Id) recordCount,
        SUM(Amount) totalAmount
      FROM Opportunity
      WHERE Partner_Account__c IN :partnerAccountIds AND IsWon = TRUE
      WITH USER_MODE
      GROUP BY Partner_Account__c
    ]) {
      totals.get((Id) row.get('partnerId')).wonDeals = (Integer) row.get(
        'recordCount'
      );
      totals.get((Id) row.get('partnerId')).totalRevenue = row.get(
          'totalAmount'
        ) == null
        ? 0
        : (Decimal) row.get('totalAmount');
    }
    return totals;
  }

  /**
   * Retrieves the leads owned by the given partner account, for KPI
   * calculation.
   *
   * @param partnerAccountId The partner account to retrieve leads for.
   * @return Up to 5000 Lead records for the partner account.
   */
  public static List<Lead> selectPartnerLeads(Id partnerAccountId) {
    SecurityUtil.assertReadable(Lead.SObjectType);

    return [
      SELECT Id, Lead_Distribution_Status__c
      FROM Lead
      WHERE Partner_Account__c = :partnerAccountId
      WITH USER_MODE
      LIMIT 5000
    ];
  }

  /**
   * Retrieves the deal registrations owned by the given partner account,
   * for KPI calculation.
   *
   * @param partnerAccountId The partner account to retrieve deal registrations for.
   * @return Up to 5000 Deal_Registration__c records for the partner account.
   */
  public static List<Deal_Registration__c> selectPartnerDeals(
    Id partnerAccountId
  ) {
    SecurityUtil.assertReadable(Deal_Registration__c.SObjectType);

    return [
      SELECT Id, Status__c, Estimated_Revenue__c
      FROM Deal_Registration__c
      WHERE Partner_Account__c = :partnerAccountId
      WITH USER_MODE
      LIMIT 5000
    ];
  }

  /**
   * Retrieves the opportunities linked to the given partner account, for
   * KPI calculation.
   *
   * @param partnerAccountId The partner account to retrieve opportunities for.
   * @return Up to 5000 Opportunity records for the partner account.
   */
  public static List<Opportunity> selectPartnerOpportunities(
    Id partnerAccountId
  ) {
    SecurityUtil.assertReadable(Opportunity.SObjectType);

    return [
      SELECT
        Id,
        Amount,
        StageName,
        IsClosed,
        IsWon,
        AccountId,
        Account.Name,
        Partner_Account__c
      FROM Opportunity
      WHERE Partner_Account__c = :partnerAccountId
      WITH USER_MODE
      LIMIT 5000
    ];
  }

  /**
   * Retrieves the MDF budget fields for the given partner account.
   *
   * @param partnerAccountId The partner account to retrieve budget data for.
   * @return The Account record with its MDF budget fields populated.
   */
  public static Account selectPartnerBudget(Id partnerAccountId) {
    SecurityUtil.assertReadable(Account.SObjectType);

    List<Account> rows = [
      SELECT Id, MDF_Annual_Budget__c, MDF_Used__c
      FROM Account
      WHERE Id = :partnerAccountId
      WITH USER_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Partner account not found.');
    }

    return rows[0];
  }

  /**
   * Retrieves the active partner accounts, for building the partner
   * leaderboard.
   *
   * @return Up to 1000 Account records flagged as partners.
   */
  public static List<Account> selectActivePartners() {
    SecurityUtil.assertReadable(Account.SObjectType);

    return [
      SELECT
        Id,
        Name,
        Partner_Tier__c,
        Partner_Status__c,
        MDF_Annual_Budget__c,
        MDF_Used__c
      FROM Account
      WHERE Is_Partner__c = TRUE
      WITH USER_MODE
      LIMIT 1000
    ];
  }

  /**
   * Retrieves closed-won opportunities that are partner-sourced (channel
   * deals), for the customer revenue report.
   *
   * @return Up to 10000 closed-won Opportunity records with a partner account set.
   */
  public static List<Opportunity> selectWonOpportunitiesForRevenue() {
    SecurityUtil.assertReadable(Opportunity.SObjectType);

    return [
      SELECT
        Id,
        Amount,
        AccountId,
        Account.Name,
        Partner_Account__c,
        Partner_Account__r.Name
      FROM Opportunity
      // Partner_Account__c != NULL excludes direct (non-channel) deals so
      // executive customer-revenue reporting only reflects partner-sourced business.
      WHERE StageName = 'Closed Won' AND Partner_Account__c != NULL
      WITH USER_MODE
      LIMIT 10000
    ];
  }
}
