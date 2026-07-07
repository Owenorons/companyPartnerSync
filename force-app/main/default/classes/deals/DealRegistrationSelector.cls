public with sharing class DealRegistrationSelector {
  public static Opportunity selectOpportunityForRegistration(Id opportunityId) {
    SecurityUtil.assertReadable(Opportunity.SObjectType);

    List<Opportunity> rows = [
      SELECT Id, AccountId, Partner_Account__c, Partner_Contact__c, StageName
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
