/*
 * Orchestrates the internal review/decision workflow (approve, reject,
 * resolve conflict, extend protection) for a deal already created by
 * DealRegistrationService. Layers a permission check (assertCanDecide) on
 * top of a record-state check (assertCanFinalize) before mutating status —
 * see the comment on assertCanFinalize for why both are needed.
 */
public without sharing class DealReviewService {
  public static List<DealReviewListDTO> getReviewQueue() {
    PartnerPermissionService.assertCanViewAllDeals();

    List<DealReviewListDTO> results = new List<DealReviewListDTO>();

    for (Deal_Registration__c record : DealReviewSelector.selectReviewQueue()) {
      results.add(DealReviewDomain.toListDTO(record));
    }

    return results;
  }

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

  /*
   * Entry point for unattended expiry enforcement (e.g. DealExpiryBatch).
   * processDecision()'s decisions all gate on assertCanDecide(), a
   * permission-set check meant for an interactive reviewer action. A
   * scheduled/batch job runs as whoever scheduled it, who may not hold that
   * permission set, so gating this path the same way would silently break
   * expiry cleanup. Authorization here instead comes from the record
   * actually being Approved and past its Protection_End_Date__c.
   */
  public static void expireProtection(Id dealId) {
    Deal_Registration__c record = DealReviewSelector.selectForInternalReview(
      dealId
    );

    if (
      record.Status__c != 'Approved' ||
      record.Protection_End_Date__c == null ||
      record.Protection_End_Date__c >= Date.today()
    ) {
      throw new PartnerSyncHandledException(
        'Deal registration is not past its protection window: ' + dealId
      );
    }

    record.Status__c = 'Expired';

    Database.update(record, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'DealExpired',
      record.Id,
      'Deal_Registration__c',
      record.Partner_Account__c,
      'Deal registration protection window expired.',
      'Info'
    );

    LoggingService.info(
      'DealReviewService',
      'Deal registration expired. DealId=' + record.Id
    );
  }

  private static void extendProtection(
    Deal_Registration__c record,
    DealReviewDecisionDTO request
  ) {
    // Extends from the existing end date (not from today) when one is
    // already set, so a second extension stacks on top of the first
    // instead of resetting the protection window's clock.
    Date baseDate = record.Protection_End_Date__c == null
      ? Date.today()
      : record.Protection_End_Date__c;

    record.Protection_End_Date__c = baseDate.addDays(
      request.protectionExtensionDays
    );

    record.Approval_Notes__c = request.approvalNotes;
    record.Decision_By__c = UserInfo.getUserId();
    record.Decision_On__c = System.now();
  }
}
