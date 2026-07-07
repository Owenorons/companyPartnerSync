public with sharing class AnalyticsSelector {
  public static List<Lead> selectPartnerLeads(Id partnerAccountId) {
    SecurityUtil.assertReadable(Lead.SObjectType);

    return [
      SELECT Id, Lead_Distribution_Status__c
      FROM Lead
      WHERE Partner_Account__c = :partnerAccountId
      LIMIT 5000
    ];
  }

  public static List<Deal_Registration__c> selectPartnerDeals(
    Id partnerAccountId
  ) {
    SecurityUtil.assertReadable(Deal_Registration__c.SObjectType);

    return [
      SELECT Id, Status__c, Estimated_Revenue__c
      FROM Deal_Registration__c
      WHERE Partner_Account__c = :partnerAccountId
      LIMIT 5000
    ];
  }

  public static List<Opportunity> selectPartnerOpportunities(
    Id partnerAccountId
  ) {
    SecurityUtil.assertReadable(Opportunity.SObjectType);

    return [
      SELECT Id, Amount, StageName, AccountId, Account.Name, Partner_Account__c
      FROM Opportunity
      WHERE Partner_Account__c = :partnerAccountId
      LIMIT 5000
    ];
  }

  public static Account selectPartnerBudget(Id partnerAccountId) {
    SecurityUtil.assertReadable(Account.SObjectType);

    List<Account> rows = [
      SELECT Id, MDF_Annual_Budget__c, MDF_Used__c
      FROM Account
      WHERE Id = :partnerAccountId
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Partner account not found.');
    }

    return rows[0];
  }

  public static List<Account> selectActivePartners() {
    SecurityUtil.assertReadable(Account.SObjectType);

    return [
      SELECT Id, Name, Partner_Tier__c, Partner_Status__c
      FROM Account
      WHERE Is_Partner__c = TRUE
      LIMIT 1000
    ];
  }

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
      WHERE StageName = 'Closed Won' AND Partner_Account__c != NULL
      LIMIT 10000
    ];
  }
}
