/**
 * Orchestrates the internal review/decision workflow (approve, reject,
 * resolve conflict, extend protection) for a deal already created by
 * DealRegistrationService. Layers a permission check (assertCanDecide) on
 * top of a record-state check (assertCanFinalize) before mutating status —
 * see the comment on assertCanFinalize for why both are needed.
 */
public without sharing class DealReviewService {
  /**
   * Loads the internal review queue for reviewers with permission to view all deals.
   *
   * @return Row shapes for deals awaiting or already through review.
   */
  public static List<DealReviewListDTO> getReviewQueue() {
    PartnerPermissionService.assertCanViewAllDeals();

    List<DealReviewListDTO> results = new List<DealReviewListDTO>();

    for (Deal_Registration__c record : DealReviewSelector.selectReviewQueue()) {
      results.add(DealReviewDomain.toListDTO(record));
    }

    return results;
  }

  /**
   * Loads the full review detail (including conflicts, computed risk, and per-decision
   * permission flags) for a single deal, for reviewers with permission to view all deals.
   *
   * @param dealId Id of the deal registration to load.
   * @return The full review detail DTO for the deal.
   */
  public static DealReviewDetailDTO getReviewDetail(Id dealId) {
    PartnerPermissionService.assertCanViewAllDeals();

    Deal_Registration__c record = DealReviewSelector.selectForInternalReview(
      dealId
    );

    List<Deal_Registration__c> conflicts = DealReviewSelector.selectConflictsForDeal(
      record.Customer_Account__c,
      record.Id
    );

    DealReviewDetailDTO dto = DealReviewDomain.toDetailDTO(record, conflicts);

    dto.canApprove = PartnerPermissionService.canApproveDeal();
    dto.canReject = PartnerPermissionService.canRejectDeal();
    dto.canResolveConflict = PartnerPermissionService.canResolveDealConflict();

    return dto;
  }

  /**
   * Overrides a deal's attribution classification. DealAttributionEngine
   * computes this automatically at submission from a timestamp heuristic;
   * a reviewer may correct it for cases the heuristic gets wrong (e.g. a
   * lead that technically predates the Opportunity but was actually
   * partner-generated).
   *
   * @param dealId Id of the deal registration to update.
   * @param attributionType The corrected classification ('Partner-Sourced' or 'Co-Sell').
   * @return The updated deal registration record.
   */
  public static Deal_Registration__c overrideAttribution(
    Id dealId,
    String attributionType
  ) {
    PartnerPermissionService.assertCanReviewDeals();
    if (
      attributionType != DealAttributionEngine.PARTNER_SOURCED &&
      attributionType != DealAttributionEngine.CO_SELL
    ) {
      throw new PartnerSyncHandledException(
        'A valid attribution type is required.'
      );
    }

    Deal_Registration__c record = [
      SELECT Id, Attribution_Type__c
      FROM Deal_Registration__c
      WHERE Id = :dealId
      WITH SYSTEM_MODE
      LIMIT 1
      FOR UPDATE
    ];
    record.Attribution_Type__c = attributionType;
    Database.update(record, AccessLevel.SYSTEM_MODE);
    return record;
  }

  /**
   * Processes an internal reviewer's decision on a deal: checks the reviewer's permission for
   * the requested decision, validates the request, and dispatches to the matching branch
   * (approve, reject, resolve conflict, or extend protection), publishing a platform event on
   * approval.
   *
   * @param request The reviewer's decision request.
   */
  public static void processDecision(DealReviewDecisionDTO request) {
    assertCanDecide(request.decision);

    DealReviewDomain.validateDecision(request);

    SecurityUtil.assertUpdateable(Deal_Registration__c.SObjectType);

    Deal_Registration__c record = DealReviewSelector.selectForInternalReview(
      request.dealId
    );

    Boolean commandHandled = false;
    if (request.decision == 'Approved') {
      assertCanApprove(record);
      executeDecisionCommand(
        record,
        DealRegistrationLifecycleConstants.FINALISE_APPROVAL,
        null,
        request.approvalNotes
      );
      commandHandled = true;
    } else if (request.decision == 'Rejected') {
      assertCanFinalize(record);
      executeDecisionCommand(
        record,
        DealRegistrationLifecycleConstants.REJECT,
        request.rejectionReason,
        request.approvalNotes
      );
      commandHandled = true;
    } else if (request.decision == 'Conflict Resolved') {
      resolveConflict(record, request);
    } else if (request.decision == 'Protection Extended') {
      extendProtection(record, request);
      commandHandled = true;
    }

    if (!commandHandled) {
      Database.update(record, AccessLevel.SYSTEM_MODE);
    }

    if (request.decision == 'Approved') {
      PlatformEventPublisherService.publish(
        'DealApproved',
        record.Id,
        'Deal_Registration__c',
        record.Partner_Account__c,
        'Deal registration approved.',
        'Info'
      );
    }

    LoggingService.info(
      'DealReviewService',
      'Deal review decision processed. DealId=' + record.Id
    );
  }

  private static void executeDecisionCommand(
    Deal_Registration__c record,
    String action,
    String reason,
    String approvalNotes
  ) {
    Integer version = currentVersion(record.Id);
    DealRegistrationCommandFacade.execute(
      record.Id,
      action,
      version,
      'legacy-review-' + record.Id + '-' + action + '-' + version,
      reason,
      new Map<String, Object>{ 'approvalNotes' => approvalNotes }
    );
  }

  private static Integer currentVersion(Id dealId) {
    Deal_Registration__c versionRow = [
      SELECT Version_Number__c
      FROM Deal_Registration__c
      WHERE Id = :dealId
      WITH SYSTEM_MODE
    ];
    return versionRow.Version_Number__c == null
      ? 0
      : Integer.valueOf(versionRow.Version_Number__c);
  }

  private static void assertCanDecide(String decision) {
    if (decision == 'Approved' || decision == 'Protection Extended') {
      PartnerPermissionService.assertCanApproveDeal();
    } else if (decision == 'Rejected') {
      PartnerPermissionService.assertCanRejectDeal();
    } else if (decision == 'Conflict Resolved') {
      PartnerPermissionService.assertCanResolveDealConflict();
    } else {
      PartnerPermissionService.assertCanReviewDeals();
    }
  }

  // Permission (assertCanDecide) says the user is allowed to approve/reject
  // in general; this separately guards against re-deciding a deal that's
  // already Approved/Rejected — a permission check alone wouldn't catch a
  // stale UI resubmitting a decision on a deal that moved on in the
  // meantime.
  private static void assertCanFinalize(Deal_Registration__c record) {
    if (record.Status__c != 'Submitted' && record.Status__c != 'Under Review') {
      throw new PartnerSyncHandledException(
        'Only submitted or under review deals can be approved or rejected.'
      );
    }
  }

  // Approval additionally requires that any flagged conflict has already
  // been resolved via the 'Conflict Resolved' decision — otherwise a
  // reviewer could approve a deal that still overlaps with another
  // partner's active registration on the same customer account.
  private static void assertCanApprove(Deal_Registration__c record) {
    assertCanFinalize(record);

    if (
      record.Conflict_Status__c == 'Potential Conflict' ||
      record.Conflict_Status__c == 'Confirmed Conflict'
    ) {
      throw new PartnerSyncHandledException(
        'This deal has an unresolved conflict and must be resolved before it can be approved.'
      );
    }
  }

  private static void resolveConflict(
    Deal_Registration__c record,
    DealReviewDecisionDTO request
  ) {
    record.Conflict_Status__c = 'Resolved';
    record.Conflict_Resolution_Notes__c = request.conflictResolutionNotes;

    record.Decision_By__c = UserInfo.getUserId();
    record.Decision_On__c = System.now();
  }

  // Extension is routed through DealProtectionCommandService rather than
  // mutating Protection_End_Date__c directly, because Deal_Protection_Grant__c
  // (not Deal_Registration__c) is the authoritative protection record as of
  // Sprint 37 - the deal's own Protection_Start/End_Date__c fields are a
  // system-managed projection that only DealProtectionCommandService's
  // syncSummary() should write. Writing them here too would let this path
  // silently diverge from the grant it's supposed to be extending.
  private static void extendProtection(
    Deal_Registration__c record,
    DealReviewDecisionDTO request
  ) {
    List<Deal_Protection_Grant__c> grants = [
      SELECT Version_Number__c
      FROM Deal_Protection_Grant__c
      WHERE Deal__c = :record.Id AND Current__c = TRUE
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    if (grants.isEmpty()) {
      throw new PartnerSyncHandledException(
        'This deal has no active protection grant to extend.'
      );
    }

    DealProtectionCommand command = new DealProtectionCommand();
    command.dealId = record.Id;
    command.action = 'Extend Protection';
    command.commandKey =
      'legacy-review-extend-' +
      record.Id +
      '-' +
      System.now().getTime();
    command.expectedVersion = Integer.valueOf(grants[0].Version_Number__c);
    command.extensionDays = request.protectionExtensionDays;
    command.reason = String.isBlank(request.approvalNotes)
      ? 'Extended via deal review decision.'
      : request.approvalNotes;

    try {
      DealProtectionCommandService.execute(command);
    } catch (DealProtectionCommandService.ProtectionCommandException ex) {
      throw new PartnerSyncHandledException(ex.getMessage());
    }

    Database.update(
      new Deal_Registration__c(
        Id = record.Id,
        Approval_Notes__c = request.approvalNotes,
        Decision_By__c = UserInfo.getUserId(),
        Decision_On__c = System.now()
      ),
      AccessLevel.SYSTEM_MODE
    );
  }
}
