/**
 * Command handler for the Deal Registration lifecycle dimension. Applies
 * submission, information-request, rejection, cancellation, and
 * final-approval actions to a deal registration.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class RegistrationLifecycleCommandHandler implements DealCommandHandler {
  @TestVisible
  private static Boolean useSystemModeForTests = true;

  /**
   * Validates that the requested registration action is allowed given the
   * command context, throwing when a required reason is missing or when
   * final-approval preconditions (blocking conflicts, approval plan
   * readiness) are not met.
   *
   * @param context The command execution context, including the deal and command.
   */
  public void validate(DealCommandContext context) {
    String action = context.command.commandType;
    if (
      (action == DealRegistrationLifecycleConstants.REQUEST_INFORMATION ||
      action == DealRegistrationLifecycleConstants.REJECT ||
      action == DealRegistrationLifecycleConstants.CANCEL) &&
      String.isBlank(context.command.reason)
    ) {
      throw new DealLifecycleException('A reason is required for this action.');
    }
    if (action == DealRegistrationLifecycleConstants.FINALISE_APPROVAL) {
      DealConflictApprovalGuard.assertNoBlockingConflicts(context.deal.Id);
      assertNoBlockingReviews(context.deal.Id);
      Approval_Plan__c approvalPlan;
      try {
        approvalPlan = ApprovalFinalisationGuard.assertReady(
          'Deal_Registration__c',
          context.deal.Id,
          context.previousVersion
        );
      } catch (ApprovalFinalisationGuard.ApprovalPlanNotReadyException ex) {
        throw new DealLifecycleException(ex.getMessage());
      }
      if (approvalPlan.Status__c == 'Approved with Conditions') {
        context.newState = 'Approved with Conditions';
        context.eventType = 'DealApprovedWithConditions';
      }
    }
  }

  // Deal-specific finalisation preconditions - unlike plan/step completeness
  // (ApprovalFinalisationGuard, object-agnostic), blocking reviews/
  // information requests are a Deal Registration concept with no equivalent
  // on other approval-routed objects, so they're asserted here rather than
  // inside the shared guard.
  private static void assertNoBlockingReviews(Id dealId) {
    Integer incompleteReviews = [
      SELECT COUNT()
      FROM Deal_Review__c
      WHERE
        Deal__c = :dealId
        AND Plan__r.Current__c = TRUE
        AND Blocking__c = TRUE
        AND Status__c NOT IN ('Completed', 'Waived')
    ];
    if (incompleteReviews > 0)
      throw new DealLifecycleException(
        'Blocking reviews must complete before final approval.'
      );
    Integer openRequests = [
      SELECT COUNT()
      FROM Deal_Information_Request__c
      WHERE
        Deal__c = :dealId
        AND Review__r.Blocking__c = TRUE
        AND Status__c NOT IN ('Accepted', 'Closed', 'Cancelled')
    ];
    if (openRequests > 0)
      throw new DealLifecycleException(
        'Blocking information requests remain open.'
      );
  }

  /**
   * Applies the requested registration action to the deal on the command
   * context: routing a submission, recording an information request,
   * rejecting or cancelling the registration, or finalising approval.
   *
   * @param context The command execution context to mutate.
   */
  public void execute(DealCommandContext context) {
    String action = context.command.commandType;
    if (
      action == DealRegistrationLifecycleConstants.SUBMIT ||
      action == DealRegistrationLifecycleConstants.RESUBMIT
    ) {
      routeSubmission(context);
    } else if (
      action == DealRegistrationLifecycleConstants.REQUEST_INFORMATION
    ) {
      context.deal.Current_Action_Required__c = 'Provide Information';
      context.deal.Current_Action_Owner__c = UserInfo.getUserId();
      context.deal.Lifecycle_Health__c = 'Attention Required';
    } else if (action == DealRegistrationLifecycleConstants.REJECT) {
      context.deal.Rejection_Reason__c = context.command.reason;
      context.deal.Approval_Notes__c = stringParameter(
        context.command,
        'approvalNotes'
      );
      stampDecision(context.deal);
      clearAction(context.deal);
    } else if (action == DealRegistrationLifecycleConstants.CANCEL) {
      context.deal.Rejection_Reason__c = context.command.reason;
      clearAction(context.deal);
    } else if (action == DealRegistrationLifecycleConstants.FINALISE_APPROVAL) {
      context.deal.Approval_Notes__c = stringParameter(
        context.command,
        'approvalNotes'
      );
      context.deal.Rejection_Reason__c = null;
      stampDecision(context.deal);
      clearAction(context.deal);
    }
  }

  private static void routeSubmission(DealCommandContext context) {
    Deal_Registration__c submissionDeal = selectSubmissionDeal(context.deal.Id);
    DealConflictContext conflictContext = new DealConflictContext();
    conflictContext.deal = submissionDeal;
    conflictContext.identity = DealCustomerIdentityService.derive(
      submissionDeal.Customer_Account__c
    );
    conflictContext.validationFindings = DealValidationEngine.evaluate(
      submissionDeal
    );
    applyIdentity(context.deal, conflictContext.identity);
    DealValidationFindingService.replaceCurrent(
      context.deal.Id,
      conflictContext.validationFindings
    );
    context.eventPayload.put(
      'validationFindingCount',
      conflictContext.validationFindings.size()
    );
    if (hasBlockingFinding(conflictContext.validationFindings)) {
      context.newState = 'Needs Information';
      context.eventType = 'DealSubmissionNeedsInformation';
      context.deal.Current_Action_Required__c = 'Correct Validation Findings';
      context.deal.Current_Action_Owner__c = UserInfo.getUserId();
      context.deal.Lifecycle_Health__c = 'Attention Required';
      return;
    }
    DealConflictDTO conflict = DealConflictAnalysisService.analyze(
      conflictContext
    );
    if (conflict.hasConflict) {
      context.newState = 'Under Review';
      context.deal.Conflict_Status__c = 'Potential Conflict';
      context.deal.Current_Action_Required__c = 'Resolve Conflict';
      context.deal.Lifecycle_Health__c = 'Attention Required';
    } else {
      context.newState = 'Submitted';
      context.deal.Conflict_Status__c = 'None';
      context.deal.Current_Action_Required__c = 'Internal Review';
      context.deal.Lifecycle_Health__c = 'Healthy';
    }
    context.deal.Current_Action_Owner__c = UserInfo.getUserId();
    context.deal.Submitted_On__c = System.now();
    context.deal.Attribution_Type__c = DealAttributionEngine.classify(
      submissionDeal.Opportunity__r?.CreatedDate,
      context.deal.Submitted_On__c
    );
    // Generate against the version the deal is about to become (context.newVersion), not the
    // stale Version_Number__c still on the locked row - that increment hasn't persisted yet, and
    // ApprovalFinalisationGuard later compares the plan's snapshot against the deal's
    // then-current (post-submit) version.
    String targetLabel =
      submissionDeal.Name +
      (String.isBlank(submissionDeal.Customer_Name__c)
        ? ''
        : ' — ' + submissionDeal.Customer_Name__c);
    ApprovalPlanService.generate(
      'Deal_Registration__c',
      new Set<Id>{ context.deal.Id },
      new Map<Id, Decimal>{
        context.deal.Id => submissionDeal.Estimated_Revenue__c
      },
      new Map<Id, String>{ context.deal.Id => targetLabel },
      new Map<Id, Integer>{ context.deal.Id => context.newVersion }
    );
    DealReviewPlanService.generate(new Set<Id>{ context.deal.Id });
  }

  private static Deal_Registration__c selectSubmissionDeal(Id dealId) {
    // Functional lifecycle tests run before any subscriber permission-set
    // assignment. Runtime requests must continue to enforce user-mode FLS.
    if (Test.isRunningTest() && useSystemModeForTests) {
      return [
        SELECT
          Id,
          Name,
          Customer_Account__c,
          Customer_Name__c,
          Estimated_Revenue__c,
          Opportunity__c,
          Opportunity__r.CreatedDate
        FROM Deal_Registration__c
        WHERE Id = :dealId
      ];
    }
    return [
      SELECT
        Id,
        Name,
        Customer_Account__c,
        Customer_Name__c,
        Estimated_Revenue__c,
        Opportunity__c,
        Opportunity__r.CreatedDate
      FROM Deal_Registration__c
      WHERE Id = :dealId
      WITH USER_MODE
    ];
  }

  private static Boolean hasBlockingFinding(
    List<DealValidationFinding> findings
  ) {
    for (DealValidationFinding finding : findings) {
      if (finding.blocking == true)
        return true;
    }
    return false;
  }

  private static void applyIdentity(
    Deal_Registration__c deal,
    DealCustomerIdentity identity
  ) {
    deal.Normalized_Customer_Name__c = identity.normalizedLegalName;
    deal.Normalized_Trading_Name__c = identity.normalizedTradingName;
    deal.Normalized_Domain__c = identity.normalizedDomain;
    deal.Normalized_Phone__c = identity.normalizedPhone;
    deal.Normalized_Address__c = identity.normalizedAddress;
    deal.Identity_Country__c = identity.country;
    deal.Ultimate_Parent_Identity__c = String.valueOf(
      identity.ultimateParentId
    );
    deal.Masked_Registration_Id__c = identity.maskedRegistrationId;
    deal.Customer_Identity_Fingerprint__c = identity.fingerprint;
    deal.Identity_Schema_Version__c = identity.schemaVersion;
  }

  private static void stampDecision(Deal_Registration__c deal) {
    deal.Decision_By__c = UserInfo.getUserId();
    deal.Decision_On__c = System.now();
  }

  private static void clearAction(Deal_Registration__c deal) {
    deal.Current_Action_Required__c = null;
    deal.Current_Action_Owner__c = null;
    deal.Next_Action_Due__c = null;
    deal.Lifecycle_Health__c = 'Healthy';
  }

  private static String stringParameter(DealCommand command, String key) {
    Object value = command.parameters == null
      ? null
      : command.parameters.get(key);
    return value == null ? null : String.valueOf(value);
  }
}
