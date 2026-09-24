/**
 * Generates approval plans and their steps for a set of deals from the active
 * Deal_Approval_Step_Rule__mdt configuration, superseding any existing current plan for each
 * deal first. Steps are filtered per deal by the deal's estimated revenue against each rule's
 * min/max amount. A rule routes to either a single assignee ('Current User', i.e. whoever
 * generated the plan) or, more commonly, any internal user holding a named permission set
 * ('Permission Set') - steps are marked 'Routing Failed' when neither resolves.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class DealApprovalPlanService {
  private static final Integer MAX_STEPS = 25;

  /**
   * Generates a new current approval plan (and its steps) for each deal in the given set,
   * superseding any prior current plan.
   *
   * @param dealIds Ids of the deal registrations to generate approval plans for.
   * @return The newly created, current Deal_Approval_Plan__c records, one per deal.
   */
  public static List<Deal_Approval_Plan__c> generate(Set<Id> dealIds) {
    return generate(dealIds, null);
  }

  /**
   * Generates a new current approval plan (and its steps) for each deal in the given set,
   * superseding any prior current plan. Accepts an explicit deal-version override for callers
   * generating a plan mid-transaction, before the deal's own version increment for the current
   * command has been persisted - e.g. a submission handler generating a plan for the version the
   * deal is about to become, not the stale version still on the database row it just locked.
   *
   * @param dealIds Ids of the deal registrations to generate approval plans for.
   * @param dealVersionOverrides Optional per-deal version to snapshot onto the plan instead of
   * the deal's currently-persisted Version_Number__c.
   * @return The newly created, current Deal_Approval_Plan__c records, one per deal.
   */
  public static List<Deal_Approval_Plan__c> generate(
    Set<Id> dealIds,
    Map<Id, Integer> dealVersionOverrides
  ) {
    if (dealIds == null || dealIds.isEmpty())
      return new List<Deal_Approval_Plan__c>();
    List<Deal_Approval_Step_Rule__mdt> rules = [
      SELECT
        DeveloperName,
        Sequence__c,
        Parallel_Group__c,
        Approval_Model__c,
        Assignment_Type__c,
        Approver_Permission_Set__c,
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
          Deal_Version__c = resolveDealVersion(deal, dealVersionOverrides),
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
        String approverPermissionSet = rule.Assignment_Type__c ==
          'Permission Set'
          ? rule.Approver_Permission_Set__c
          : null;
        Boolean routed =
          assignee != null || String.isNotBlank(approverPermissionSet);
        steps.add(
          new Deal_Approval__c(
            Plan__c = planByDeal.get(deal.Id).Id,
            Deal__c = deal.Id,
            Step_Key__c = rule.DeveloperName,
            Sequence__c = rule.Sequence__c,
            Parallel_Group__c = rule.Parallel_Group__c,
            Assigned_To__c = assignee,
            Approver_Permission_Set__c = approverPermissionSet,
            Authority_Limit__c = rule.Maximum_Amount__c,
            Version_Number__c = 0,
            Status__c = routed ? 'Pending' : 'Routing Failed'
          )
        );
      }
    }
    if (!steps.isEmpty())
      Database.insert(steps, AccessLevel.SYSTEM_MODE);
    return plans;
  }

  private static Integer resolveDealVersion(
    Deal_Registration__c deal,
    Map<Id, Integer> dealVersionOverrides
  ) {
    if (
      dealVersionOverrides != null && dealVersionOverrides.containsKey(deal.Id)
    )
      return dealVersionOverrides.get(deal.Id);
    return deal.Version_Number__c == null
      ? 0
      : Integer.valueOf(deal.Version_Number__c);
  }
  /**
   * Thrown when an approval plan can't be generated, e.g. no active step rules exist or the
   * configured rule count is out of the supported range.
   */
  public class ApprovalPlanException extends Exception {
  }
}
