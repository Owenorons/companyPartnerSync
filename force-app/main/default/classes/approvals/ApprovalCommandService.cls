/**
 * Processes a decision (Approved, Approved with Conditions, Rejected, Returned) on a single
 * pending Approval__c step: locks and validates the step, checks the deciding user's
 * authority (either an exact Assigned_To__c match, or holding the step's
 * Approver_Permission_Set__c) against the snapshotted Target_Amount__c, records the decision,
 * creates a condition record when applicable, and coordinates the parent Approval_Plan__c's
 * overall status. Object-agnostic - works identically for any target object's steps.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ApprovalCommandService {
  /**
   * Completes a pending approval step with the given decision.
   *
   * @param command The approval decision command, including the approval Id, decision, expected
   * version, and (when applicable) reason/condition details.
   * @return The updated Approval__c step.
   */
  public static Approval__c complete(ApprovalCommand command) {
    if (
      command == null ||
      command.approvalId == null ||
      String.isBlank(command.decision)
    )
      throw new ApprovalCommandException(
        'Approval, decision, and version are required.'
      );
    Approval__c step = [
      SELECT
        Id,
        Object_Name__c,
        Target_Record_Id__c,
        Target_Amount__c,
        Plan__c,
        Step_Key__c,
        Status__c,
        Assigned_To__c,
        Approver_Permission_Set__c,
        Authority_Limit__c,
        Version_Number__c
      FROM Approval__c
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
        'amount' => step.Target_Amount__c,
        'authorityLimit' => step.Authority_Limit__c,
        'validatedOn' => System.now()
      }
    );
    step.Status__c = 'Completed';
    step.Version_Number__c++;
    Database.update(step, AccessLevel.SYSTEM_MODE);
    if (decision == 'Approved with Conditions')
      Database.insert(
        new Approval_Condition__c(
          Object_Name__c = step.Object_Name__c,
          Target_Record_Id__c = step.Target_Record_Id__c,
          Plan__c = step.Plan__c,
          Approval__c = step.Id,
          Condition_Type__c = command.conditionType,
          Description__c = command.conditionDescription,
          Status__c = 'Open'
        ),
        AccessLevel.SYSTEM_MODE
      );
    coordinate(
      step.Plan__c,
      decision,
      step.Object_Name__c,
      step.Target_Record_Id__c,
      command.reason
    );
    return step;
  }

  private static void assertAuthority(Approval__c step) {
    Decimal amount = step.Target_Amount__c == null ? 0 : step.Target_Amount__c;
    Boolean hasRoutedAuthority = step.Assigned_To__c != null
      ? step.Assigned_To__c == UserInfo.getUserId()
      : String.isNotBlank(step.Approver_Permission_Set__c) &&
        PermissionService.hasPermissionSet(step.Approver_Permission_Set__c);
    if (
      !hasRoutedAuthority ||
      (step.Authority_Limit__c != null &&
      amount > step.Authority_Limit__c)
    )
      throw new ApprovalCommandException(
        'Current user lacks authority for this decision.'
      );
  }

  private static void coordinate(
    Id planId,
    String decision,
    String objectName,
    Id targetRecordId,
    String decisionReason
  ) {
    Approval_Plan__c plan = [
      SELECT Id, Status__c
      FROM Approval_Plan__c
      WHERE Id = :planId
      FOR UPDATE
    ];
    if (decision == 'Rejected' || decision == 'Returned') {
      plan.Status__c = decision;
      plan.Completed_On__c = System.now();
      // Rejected is a terminal, human decision - no recovery path needed.
      // Returned means "send back for correction," so each target object
      // gets a chance to react (e.g. MDF flips to Needs Information and
      // lets the submitter regenerate the plan) via
      // ApprovalReturnConsumerService, dispatched off this event. The
      // engine stays object-agnostic - it publishes, it doesn't know or
      // care what (if anything) reacts.
      if (decision == 'Returned') {
        PlatformEventPublisherService.publish(
          'ApprovalPlanReturned',
          targetRecordId,
          objectName,
          null,
          decisionReason,
          'Warning'
        );
      }
    } else {
      List<Approval__c> steps = [
        SELECT Status__c, Decision__c
        FROM Approval__c
        WHERE Plan__c = :planId
      ];
      Boolean complete = true;
      Boolean conditional = false;
      for (Approval__c item : steps) {
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
  /**
   * Thrown when an approval command can't be completed, e.g. a stale version, a step that isn't
   * pending, insufficient decision authority, or a missing required reason/condition.
   */
  public class ApprovalCommandException extends Exception {
  }
}
