@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class DealReviewPlanService {
  public static List<Deal_Review_Plan__c> generate(Set<Id> dealIds) {
    if (dealIds == null || dealIds.isEmpty())
      return new List<Deal_Review_Plan__c>();
    List<Deal_Review_Routing_Rule__mdt> rules = [
      SELECT
        DeveloperName,
        Rule_Version__c,
        Review_Type__c,
        Blocking__c,
        Sequence__c,
        Parallel_Group__c,
        Depends_On_Key__c,
        Assignment_Type__c,
        Assignment_Key__c,
        Fallback_Queue_Key__c,
        SLA_Hours__c,
        Minimum_Deal_Value__c
      FROM Deal_Review_Routing_Rule__mdt
      WHERE Active__c = TRUE
      WITH USER_MODE
      ORDER BY Sequence__c, DeveloperName
    ];
    List<Deal_Registration__c> deals = [
      SELECT Id, Estimated_Revenue__c
      FROM Deal_Registration__c
      WHERE Id IN :dealIds
      FOR UPDATE
    ];
    Map<Id, Deal_Review_Plan__c> oldByDeal = new Map<Id, Deal_Review_Plan__c>();
    for (Deal_Review_Plan__c oldPlan : [
      SELECT
        Id,
        Deal__c,
        Current__c,
        Current_Plan_Key__c,
        Status__c,
        Version_Number__c
      FROM Deal_Review_Plan__c
      WHERE Deal__c IN :dealIds AND Current__c = TRUE
    ])
      oldByDeal.put(oldPlan.Deal__c, oldPlan);
    for (Deal_Review_Plan__c oldPlan : oldByDeal.values()) {
      oldPlan.Current__c = false;
      oldPlan.Current_Plan_Key__c = null;
      oldPlan.Status__c = 'Superseded';
    }
    if (!oldByDeal.isEmpty())
      Database.update(oldByDeal.values(), AccessLevel.SYSTEM_MODE);

    List<Deal_Review_Plan__c> plans = new List<Deal_Review_Plan__c>();
    for (Deal_Registration__c deal : deals)
      plans.add(
        new Deal_Review_Plan__c(
          Deal__c = deal.Id,
          Current__c = true,
          Current_Plan_Key__c = String.valueOf(deal.Id),
          Rule_Set_Version__c = '1.0',
          Version_Number__c = oldByDeal.containsKey(deal.Id)
            ? oldByDeal.get(deal.Id).Version_Number__c + 1
            : 1,
          Status__c = 'Active',
          Generated_On__c = System.now(),
          Input_Hash__c = hash(deal)
        )
      );
    Database.insert(plans, AccessLevel.SYSTEM_MODE);
    Map<Id, Deal_Review_Plan__c> planByDeal = new Map<Id, Deal_Review_Plan__c>();
    for (Deal_Review_Plan__c plan : plans)
      planByDeal.put(plan.Deal__c, plan);
    List<Deal_Review__c> reviews = new List<Deal_Review__c>();
    for (Deal_Registration__c deal : deals) {
      for (Deal_Review_Routing_Rule__mdt rule : rules) {
        Decimal value = deal.Estimated_Revenue__c == null
          ? 0
          : deal.Estimated_Revenue__c;
        if (
          rule.Minimum_Deal_Value__c != null &&
          value < rule.Minimum_Deal_Value__c
        )
          continue;
        Id assignee = rule.Assignment_Type__c == 'Current User'
          ? UserInfo.getUserId()
          : null;
        reviews.add(
          new Deal_Review__c(
            Plan__c = planByDeal.get(deal.Id).Id,
            Deal__c = deal.Id,
            Review_Key__c = rule.DeveloperName,
            Review_Type__c = rule.Review_Type__c,
            Blocking__c = rule.Blocking__c,
            Sequence__c = rule.Sequence__c,
            Parallel_Group__c = rule.Parallel_Group__c,
            Depends_On_Key__c = rule.Depends_On_Key__c,
            Assigned_To__c = assignee,
            Assignment_Source__c = assignee == null
              ? 'Routing Failed'
              : 'Rule: Current User',
            Status__c = assignee == null
              ? 'Routing Failed'
              : (String.isBlank(rule.Depends_On_Key__c) ? 'Ready' : 'Blocked'),
            Due_On__c = System.now()
              .addHours(
                rule.SLA_Hours__c == null
                  ? 24
                  : Integer.valueOf(rule.SLA_Hours__c)
              ),
            Version_Number__c = 0,
            Rule_Version__c = rule.Rule_Version__c
          )
        );
      }
    }
    if (!reviews.isEmpty())
      Database.insert(reviews, AccessLevel.SYSTEM_MODE);
    return plans;
  }

  private static String hash(Deal_Registration__c deal) {
    return EncodingUtil.convertToHex(
      Crypto.generateDigest(
        'SHA-256',
        Blob.valueOf(
          String.valueOf(deal.Id) +
            '|' +
            String.valueOf(deal.Estimated_Revenue__c)
        )
      )
    );
  }
}
