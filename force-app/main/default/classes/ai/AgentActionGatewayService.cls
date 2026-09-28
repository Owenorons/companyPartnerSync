/**
 * Deterministic authorization + Command Bus dispatch layer for an AI
 * agent's proposed actions - never a raw field mutation. proposeAction()
 * records a proposal after checking AI_Action_Policy__mdt allows it;
 * executeAction() re-checks that policy's Requires_Permission__c against
 * the running user at execute time (never trusts that propose-time
 * authorization is still valid, the same reasoning this codebase already
 * applies to expected-version staleness, applied here to authority
 * instead), then dispatches to the real command service exactly the way
 * an interactive user would. This is the entry point a future Agentforce
 * Action would call once one is configured (Known Adaptation #1) - it is
 * directly callable and fully tested today independent of that.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class AgentActionGatewayService {
  /**
   * Proposes an action, recording it as an AI_Recommendation__c after
   * confirming an active AI_Action_Policy__mdt allows this action for this
   * use case. Does not execute anything.
   *
   * @param useCaseKey The governed use case.
   * @param actionKey The proposed action (matches AI_Action_Policy__mdt.Action_Key__c).
   * @param interactionId Id of the AI_Interaction__c this proposal stems from.
   * @param relatedObject The SObject API name of the related record.
   * @param relatedRecordId Id of the related record the action would apply to.
   * @param partnerAccountId Id of the partner account this action concerns, if any.
   * @param recommendationText Human-readable description of the proposed action.
   * @param confidence Confidence score for the proposal, if any.
   * @return The inserted, Proposed recommendation.
   */
  public static AI_Recommendation__c proposeAction(
    String useCaseKey,
    String actionKey,
    Id interactionId,
    String relatedObject,
    Id relatedRecordId,
    Id partnerAccountId,
    String recommendationText,
    Decimal confidence
  ) {
    if (resolvePolicy(useCaseKey, actionKey) == null) {
      throw new PartnerSyncHandledException(
        'This action is not permitted for this use case.'
      );
    }
    if (String.isBlank(recommendationText)) {
      throw new PartnerSyncHandledException(
        'A recommendation description is required.'
      );
    }

    AI_Recommendation__c recommendation = new AI_Recommendation__c(
      Interaction__c = interactionId,
      Related_Object__c = relatedObject,
      Related_Record_Id__c = relatedRecordId,
      Partner_Account__c = partnerAccountId,
      Recommended_Action_Key__c = actionKey,
      Recommendation_Text__c = recommendationText,
      Confidence__c = confidence,
      Status__c = 'Proposed'
    );
    Database.insert(recommendation, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'AIRecommendationProposed',
      recommendation.Id,
      'AI_Recommendation__c',
      partnerAccountId,
      'An AI action was proposed.',
      'Info'
    );

    return recommendation;
  }

  /**
   * Executes a proposed action, re-checking authority at execute time and
   * dispatching to the real command service the action maps to - never a
   * bypass. An action key with no wired dispatch branch fails closed even
   * if its AI_Action_Policy__mdt row exists (a policy row alone documents
   * intent; only a real branch here can actually execute it).
   *
   * @param recommendationId Id of the Proposed recommendation to execute.
   * @param reason A reason to pass through to the underlying command, if the target command requires one.
   * @return The updated recommendation.
   */
  public static AI_Recommendation__c executeAction(
    Id recommendationId,
    String reason
  ) {
    if (recommendationId == null) {
      throw new PartnerSyncHandledException(
        'A recommendation is required for this command.'
      );
    }
    List<AI_Recommendation__c> rows = [
      SELECT
        Interaction__r.Use_Case_Key__c,
        Related_Object__c,
        Related_Record_Id__c,
        Recommended_Action_Key__c,
        Status__c
      FROM AI_Recommendation__c
      WHERE Id = :recommendationId
      WITH SYSTEM_MODE
    ];
    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Recommendation not found.');
    }
    AI_Recommendation__c recommendation = rows[0];
    if (recommendation.Status__c != 'Proposed') {
      throw new PartnerSyncHandledException(
        'Only a Proposed recommendation can be executed.'
      );
    }

    AI_Action_Policy__mdt policy = resolvePolicy(
      recommendation.Interaction__r?.Use_Case_Key__c,
      recommendation.Recommended_Action_Key__c
    );
    if (policy == null) {
      throw new PartnerSyncHandledException(
        'This action is no longer permitted for this use case.'
      );
    }
    // Re-checked here, not trusted from propose time: a user's authority
    // can change between proposal and execution.
    if (
      String.isNotBlank(policy.Requires_Permission__c) &&
      (!PartnerAccessService.isInternalUser() ||
      !DealLifecyclePermissionService.hasPermission(
        policy.Requires_Permission__c
      ))
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to execute this action.'
      );
    }

    Boolean dispatched = dispatch(
      recommendation.Recommended_Action_Key__c,
      recommendation.Related_Record_Id__c,
      reason
    );
    if (!dispatched) {
      throw new PartnerSyncHandledException(
        'This action has no wired dispatch target.'
      );
    }

    recommendation.Status__c = 'Executed';
    recommendation.Executed_On__c = System.now();
    recommendation.Executed_By__c = UserInfo.getUserId();
    Database.update(recommendation, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'AIRecommendationExecuted',
      recommendation.Id,
      'AI_Recommendation__c',
      null,
      'An AI-recommended action was executed.',
      'Info'
    );

    return recommendation;
  }

  // Real, compiled dispatch targets - a Target_Command_Service__c string
  // on the CMDT row is documentation for admins, never dynamically
  // invoked, matching this codebase's static-dispatch convention.
  private static Boolean dispatch(
    String actionKey,
    Id relatedRecordId,
    String reason
  ) {
    if (actionKey == 'RequestRenewalReview') {
      RenewalCommand command = new RenewalCommand();
      command.renewalId = relatedRecordId;
      command.reason = String.isBlank(reason)
        ? 'Requested by an AI-recommended action.'
        : reason;
      RenewalCommandService.requestReview(command);
      return true;
    }
    return false;
  }

  private static AI_Action_Policy__mdt resolvePolicy(
    String useCaseKey,
    String actionKey
  ) {
    if (String.isBlank(useCaseKey) || String.isBlank(actionKey)) {
      return null;
    }
    List<AI_Action_Policy__mdt> rows = [
      SELECT Requires_Permission__c
      FROM AI_Action_Policy__mdt
      WHERE
        Active__c = TRUE
        AND Use_Case_Key__c = :useCaseKey
        AND Action_Key__c = :actionKey
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    return rows.isEmpty() ? null : rows[0];
  }
}
