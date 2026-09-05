@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class DealApprovalPlanService {
  private static final Integer MAX_STEPS = 25;

  public static List<Deal_Approval_Plan__c> generate(Set<Id> dealIds) {
    if (dealIds == null || dealIds.isEmpty())
      return new List<Deal_Approval_Plan__c>();
    List<Deal_Approval_Step_Rule__mdt> rules = [
      SELECT
        DeveloperName,
        Sequence__c,
        Parallel_Group__c,
        Approval_Model__c,
        Assignment_Type__c,
        Minimum_Amount__c,
        Maximum_Amount__c
      FROM Deal_Approval_Step_Rule__mdt
      WHERE Active__c = TRUE
      WITH SYSTEM_MODE
      ORDER BY Sequence__c, DeveloperName
    ];
    if (rules.isEmpty() || rules.size() > MAX_STEPS)
      throw new ApprovalPlanException(
        'Approval routing must contain between 1 and 25 active steps.'
      );
    List<Deal_Registration__c> deals = [
      SELECT Id, Estimated_Revenue__c, Version_Number__c
      FROM Deal_Registration__c
      WHERE Id IN :dealIds
      FOR UPDATE
    ];
    Map<Id, Deal_Approval_Plan__c> currentByDeal = new Map<Id, Deal_Approval_Plan__c>();
    for (Deal_Approval_Plan__c plan : [
      SELECT Id, Deal__c, Version_Number__c
      FROM Deal_Approval_Plan__c
      WHERE Deal__c IN :dealIds AND Current__c = TRUE
    ])
      currentByDeal.put(plan.Deal__c, plan);
    List<Deal_Approval_Plan__c> superseded = new List<Deal_Approval_Plan__c>();
    for (Deal_Approval_Plan__c plan : currentByDeal.values()) {
      plan.Current__c = false;
      plan.Current_Plan_Key__c = null;
      plan.Status__c = 'Superseded';
      superseded.add(plan);
    }
    if (!superseded.isEmpty())
      Database.update(superseded, AccessLevel.SYSTEM_MODE);
    List<Deal_Approval_Plan__c> plans = new List<Deal_Approval_Plan__c>();
    for (Deal_Registration__c deal : deals) {
      Deal_Approval_Plan__c prior = currentByDeal.get(deal.Id);
      plans.add(
        new Deal_Approval_Plan__c(
          Deal__c = deal.Id,
          Current__c = true,
          Current_Plan_Key__c = String.valueOf(deal.Id),
          Version_Number__c = prior == null ? 1 : prior.Version_Number__c + 1,
          Deal_Version__c = deal.Version_Number__c == null
            ? 0
            : deal.Version_Number__c,
          Status__c = 'Pending',
          Approval_Model__c = rules[0].Approval_Model__c,
          Generated_On__c = System.now()
        )
      );
    }
    Database.insert(plans, AccessLevel.SYSTEM_MODE);
    Map<Id, Deal_Approval_Plan__c> planByDeal = new Map<Id, Deal_Approval_Plan__c>();
    for (Deal_Approval_Plan__c plan : plans)
      planByDeal.put(plan.Deal__c, plan);
    List<Deal_Approval__c> steps = new List<Deal_Approval__c>();
    for (Deal_Registration__c deal : deals) {
      Decimal amount = deal.Estimated_Revenue__c == null
        ? 0
        : deal.Estimated_Revenue__c;
      for (Deal_Approval_Step_Rule__mdt rule : rules) {
        if (
          (rule.Minimum_Amount__c != null && amount < rule.Minimum_Amount__c) ||
          (rule.Maximum_Amount__c != null &&
          amount > rule.Maximum_Amount__c)
        )
          continue;
        Id assignee = rule.Assignment_Type__c == 'Current User'
          ? UserInfo.getUserId()
          : null;
        steps.add(
          new Deal_Approval__c(
            Plan__c = planByDeal.get(deal.Id).Id,
            Deal__c = deal.Id,
            Step_Key__c = rule.DeveloperName,
            Sequence__c = rule.Sequence__c,
            Parallel_Group__c = rule.Parallel_Group__c,
            Assigned_To__c = assignee,
            Authority_Limit__c = rule.Maximum_Amount__c,
            Version_Number__c = 0,
            Status__c = assignee == null ? 'Routing Failed' : 'Pending'
          )
        );
      }
    }
    if (!steps.isEmpty())
      Database.insert(steps, AccessLevel.SYSTEM_MODE);
    return plans;
  }
  public class ApprovalPlanException extends Exception {
  }
}
