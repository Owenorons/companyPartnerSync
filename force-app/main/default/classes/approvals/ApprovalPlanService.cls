/**
 * Generates approval plans and their steps for a set of records from the active
 * Approval_Step_Rule__mdt configuration scoped to the given object, superseding any existing
 * current plan for each record first. Steps are filtered per record by the caller-supplied
 * amount against each rule's min/max. A rule routes to either a single assignee ('Current User',
 * i.e. whoever generated the plan) or, more commonly, any internal user holding a named
 * permission set ('Permission Set') - steps are marked 'Routing Failed' when neither resolves.
 * Object-agnostic: knows nothing about any specific target object's schema - the caller supplies
 * the amount, display label, and version for each record, since those vary by object.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ApprovalPlanService {
  private static final Integer MAX_STEPS = 25;

  /**
   * Generates a new current approval plan (and its steps) for each record in the given set,
   * superseding any prior current plan.
   *
   * @param objectName API name of the target object (e.g. 'Deal_Registration__c').
   * @param targetRecordIds Ids of the target records to generate approval plans for.
   * @param amountsByTargetId Amount to evaluate each record's rule tier against.
   * @param labelsByTargetId Display label to snapshot onto each plan/step for the given record.
   * @param versionsByTargetId Version of each target record to snapshot onto its plan - the
   * caller's responsibility since the engine never queries the target object itself. A missing
   * entry defaults to 0.
   * @return The newly created, current Approval_Plan__c records, one per record.
   */
  public static List<Approval_Plan__c> generate(
    String objectName,
    Set<Id> targetRecordIds,
    Map<Id, Decimal> amountsByTargetId,
    Map<Id, String> labelsByTargetId,
    Map<Id, Integer> versionsByTargetId
  ) {
    if (
      String.isBlank(objectName) ||
      targetRecordIds == null ||
      targetRecordIds.isEmpty()
    )
      return new List<Approval_Plan__c>();
    List<Approval_Step_Rule__mdt> rules = [
      SELECT
        DeveloperName,
        Sequence__c,
        Parallel_Group__c,
        Approval_Model__c,
        Assignment_Type__c,
        Approver_Permission_Set__c,
        Minimum_Amount__c,
        Maximum_Amount__c
      FROM Approval_Step_Rule__mdt
      WHERE Active__c = TRUE AND Object_Name__c = :objectName
      WITH SYSTEM_MODE
      ORDER BY Sequence__c, DeveloperName
    ];
    if (rules.isEmpty() || rules.size() > MAX_STEPS)
      throw new ApprovalPlanException(
        'Approval routing for ' +
          objectName +
          ' must contain between 1 and 25 active steps.'
      );
    Map<Id, Approval_Plan__c> currentByTarget = new Map<Id, Approval_Plan__c>();
    for (Approval_Plan__c plan : [
      SELECT Id, Target_Record_Id__c, Version_Number__c
      FROM Approval_Plan__c
      WHERE
        Object_Name__c = :objectName
        AND Target_Record_Id__c IN :targetRecordIds
        AND Current__c = TRUE
    ])
      currentByTarget.put(plan.Target_Record_Id__c, plan);
    List<Approval_Plan__c> superseded = new List<Approval_Plan__c>();
    for (Approval_Plan__c plan : currentByTarget.values()) {
      plan.Current__c = false;
      plan.Current_Plan_Key__c = null;
      plan.Status__c = 'Superseded';
      superseded.add(plan);
    }
    if (!superseded.isEmpty())
      Database.update(superseded, AccessLevel.SYSTEM_MODE);
    List<Approval_Plan__c> plans = new List<Approval_Plan__c>();
    for (Id targetId : targetRecordIds) {
      Approval_Plan__c prior = currentByTarget.get(targetId);
      String label = labelsByTargetId == null
        ? null
        : labelsByTargetId.get(targetId);
      plans.add(
        new Approval_Plan__c(
          Object_Name__c = objectName,
          Target_Record_Id__c = targetId,
          Target_Label__c = label,
          Current__c = true,
          Current_Plan_Key__c = objectName + ':' + targetId,
          Version_Number__c = prior == null ? 1 : prior.Version_Number__c + 1,
          Target_Version__c = resolveVersion(targetId, versionsByTargetId),
          Status__c = 'Pending',
          Approval_Model__c = rules[0].Approval_Model__c,
          Generated_On__c = System.now()
        )
      );
    }
    Database.insert(plans, AccessLevel.SYSTEM_MODE);
    Map<Id, Approval_Plan__c> planByTarget = new Map<Id, Approval_Plan__c>();
    for (Approval_Plan__c plan : plans)
      planByTarget.put(plan.Target_Record_Id__c, plan);
    List<Approval__c> steps = new List<Approval__c>();
    for (Id targetId : targetRecordIds) {
      Decimal amount = amountsByTargetId == null ||
        amountsByTargetId.get(targetId) == null
        ? 0
        : amountsByTargetId.get(targetId);
      String label = labelsByTargetId == null
        ? null
        : labelsByTargetId.get(targetId);
      for (Approval_Step_Rule__mdt rule : rules) {
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
          new Approval__c(
            Plan__c = planByTarget.get(targetId).Id,
            Object_Name__c = objectName,
            Target_Record_Id__c = targetId,
            Target_Label__c = label,
            Target_Amount__c = amount,
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

  private static Integer resolveVersion(
    Id targetId,
    Map<Id, Integer> versionsByTargetId
  ) {
    if (versionsByTargetId == null || versionsByTargetId.get(targetId) == null)
      return 0;
    return versionsByTargetId.get(targetId);
  }
  /**
   * Thrown when an approval plan can't be generated, e.g. no active step rules exist for the
   * target object or the configured rule count is out of the supported range.
   */
  public class ApprovalPlanException extends Exception {
  }
}
