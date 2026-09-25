/**
 * Evaluates Deal_Participant_Change_Policy__mdt for a given participant
 * change, re-triggering conflict/review/approval reassessment where the
 * matching policy row requires it. Require_Protection_Amendment__c is a
 * guard consulted by callers before completing a protection-sensitive
 * transition (see DealParticipantCommandService.remove()), not an action
 * taken here.
 */
public without sharing class DealParticipantChangePolicyService {
  /**
   * Evaluates the active policy for a change type and reacts to it.
   *
   * @param dealId Id of the deal the change occurred on.
   * @param changeType One of the closed Change_Type__c values.
   * @param participantId Id of the participant the change concerns (unused by Phase 7's reactions, kept for future policy-specific logic and audit context).
   */
  public static void evaluate(Id dealId, String changeType, Id participantId) {
    Deal_Participant_Change_Policy__mdt policy = resolvePolicy(changeType);
    if (policy == null) {
      return;
    }

    if (policy.Require_Conflict_Reanalysis__c) {
      DealConflictCommandService.reanalyseForMaterialChange(dealId);
    }
    if (policy.Require_Review_Reassessment__c) {
      DealReviewPlanService.generate(new Set<Id>{ dealId });
    }
    if (policy.Require_Approval_Reassessment__c) {
      regenerateApprovalPlan(dealId);
    }
    // Require_Protection_Amendment__c is a guard, consulted directly by
    // callers (e.g. the remove-participant dependency check) - nothing to
    // do here.
  }

  /**
   * Indicates whether a change type's policy requires a protection
   * amendment before the triggering transition can complete.
   *
   * @param changeType One of the closed Change_Type__c values.
   * @return True if Require_Protection_Amendment__c is set for the active policy.
   */
  public static Boolean requiresProtectionAmendment(String changeType) {
    Deal_Participant_Change_Policy__mdt policy = resolvePolicy(changeType);
    return policy != null && policy.Require_Protection_Amendment__c;
  }

  private static Deal_Participant_Change_Policy__mdt resolvePolicy(
    String changeType
  ) {
    List<Deal_Participant_Change_Policy__mdt> policies = [
      SELECT
        Require_Conflict_Reanalysis__c,
        Require_Review_Reassessment__c,
        Require_Approval_Reassessment__c,
        Require_Protection_Amendment__c
      FROM Deal_Participant_Change_Policy__mdt
      WHERE Active__c = TRUE AND Change_Type__c = :changeType
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    return policies.isEmpty() ? null : policies[0];
  }

  private static void regenerateApprovalPlan(Id dealId) {
    List<Deal_Registration__c> deals = [
      SELECT Id, Estimated_Revenue__c, Customer_Name__c, Version_Number__c
      FROM Deal_Registration__c
      WHERE Id = :dealId
      WITH SYSTEM_MODE
    ];
    if (deals.isEmpty()) {
      return;
    }
    Deal_Registration__c deal = deals[0];
    ApprovalPlanService.generate(
      'Deal_Registration__c',
      new Set<Id>{ dealId },
      new Map<Id, Decimal>{ dealId => deal.Estimated_Revenue__c },
      new Map<Id, String>{ dealId => deal.Customer_Name__c },
      new Map<Id, Integer>{
        dealId => deal.Version_Number__c == null
          ? 0
          : Integer.valueOf(deal.Version_Number__c)
      }
    );
  }
}
