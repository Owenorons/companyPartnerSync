@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class DealApprovalCommandService {
  public static Deal_Approval__c complete(DealApprovalCommand command) {
    if (
      command == null ||
      command.approvalId == null ||
      String.isBlank(command.decision)
    )
      throw new ApprovalCommandException(
        'Approval, decision, and version are required.'
      );
    Deal_Approval__c step = [
      SELECT
        Id,
        Deal__c,
        Plan__c,
        Step_Key__c,
        Status__c,
        Assigned_To__c,
        Authority_Limit__c,
        Version_Number__c,
        Deal__r.Estimated_Revenue__c
      FROM Deal_Approval__c
      WHERE Id = :command.approvalId
      FOR UPDATE
    ];
    if (
      command.expectedVersion == null ||
      step.Version_Number__c != command.expectedVersion
    )
      throw new ApprovalCommandException(
        'The approval changed. Refresh and retry.'
      );
    if (step.Status__c != 'Pending')
      throw new ApprovalCommandException(
        'Only pending approval steps may be completed.'
      );
    assertAuthority(step);
    String decision = command.decision.trim();
    if (
      !new Set<String>{
          'Approved',
          'Approved with Conditions',
          'Rejected',
          'Returned'
        }
        .contains(decision)
    )
      throw new ApprovalCommandException(
        'Unsupported approval decision: ' + decision
      );
    if (
      (decision == 'Rejected' || decision == 'Returned') &&
      String.isBlank(command.reason)
    )
      throw new ApprovalCommandException(
        'A reason is required for this decision.'
      );
    if (
      decision == 'Approved with Conditions' &&
      (String.isBlank(command.conditionType) ||
      String.isBlank(command.conditionDescription))
    )
      throw new ApprovalCommandException(
        'Condition type and description are required.'
      );
    step.Decision__c = decision;
    step.Decision_Reason__c = command.reason;
    step.Decision_By__c = UserInfo.getUserId();
    step.Decision_On__c = System.now();
    step.Authority_Snapshot__c = JSON.serialize(
      new Map<String, Object>{
        'userId' => UserInfo.getUserId(),
        'amount' => step.Deal__r.Estimated_Revenue__c,
        'authorityLimit' => step.Authority_Limit__c,
        'validatedOn' => System.now()
      }
    );
    step.Status__c = 'Completed';
    step.Version_Number__c++;
    Database.update(step, AccessLevel.SYSTEM_MODE);
    if (decision == 'Approved with Conditions')
      Database.insert(
        new Deal_Approval_Condition__c(
          Deal__c = step.Deal__c,
          Plan__c = step.Plan__c,
          Approval__c = step.Id,
          Condition_Type__c = command.conditionType,
          Description__c = command.conditionDescription,
          Status__c = 'Open'
        ),
        AccessLevel.SYSTEM_MODE
      );
    coordinate(step.Plan__c, decision);
    return step;
  }

  private static void assertAuthority(Deal_Approval__c step) {
    Decimal amount = step.Deal__r.Estimated_Revenue__c == null
      ? 0
      : step.Deal__r.Estimated_Revenue__c;
    if (
      step.Assigned_To__c == null ||
      step.Assigned_To__c != UserInfo.getUserId() ||
      (step.Authority_Limit__c != null &&
      amount > step.Authority_Limit__c)
    )
      throw new ApprovalCommandException(
        'Current user lacks authority for this decision.'
      );
  }

  private static void coordinate(Id planId, String decision) {
    Deal_Approval_Plan__c plan = [
      SELECT Id, Status__c
      FROM Deal_Approval_Plan__c
      WHERE Id = :planId
      FOR UPDATE
    ];
    if (decision == 'Rejected' || decision == 'Returned') {
      plan.Status__c = decision;
      plan.Completed_On__c = System.now();
    } else {
      List<Deal_Approval__c> steps = [
        SELECT Status__c, Decision__c
        FROM Deal_Approval__c
        WHERE Plan__c = :planId
      ];
      Boolean complete = true;
      Boolean conditional = false;
      for (Deal_Approval__c item : steps) {
        complete = complete && item.Status__c == 'Completed';
        conditional =
          conditional || item.Decision__c == 'Approved with Conditions';
      }
      if (complete) {
        plan.Status__c = conditional ? 'Approved with Conditions' : 'Approved';
        plan.Completed_On__c = System.now();
      }
    }
    Database.update(plan, AccessLevel.SYSTEM_MODE);
  }
  public class ApprovalCommandException extends Exception {
  }
}
