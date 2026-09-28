/**
 * Executes Deal_Revenue__c commands: import (via a RevenueSourceAdapter,
 * doc Sprint 41 §41.14), confirm, adjust, reverse. Follows the same
 * FOR UPDATE + Version_Number__c pattern as every other command service
 * in this codebase for the single-record actions; import() has its own
 * idempotency/resolution pipeline instead, since it creates rather than
 * mutates a record (see DealParticipantCommandService's shape for the
 * general pattern being replicated).
 *
 * Deliberately NOT triggered by internal batch logic reacting to Closed
 * Won (Sprint 41 Context point 6) - real revenue arrives from external
 * finance systems via an adapter; DealOpportunityReconciliationBatch only
 * ever gates eligibility for downstream commands, never creates revenue.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class RevenueCommandService {
  @TestVisible
  private static RevenueSourceAdapter testAdapter;

  /**
   * Imports a revenue event via the adapter matching the request's source
   * type, resolving idempotency and the target Deal before inserting.
   *
   * @param request The normalized import request (sourceType selects the adapter).
   * @return The outcome of the import attempt.
   */
  public static RevenueOutcome importRevenue(RevenueImportRequest request) {
    PartnerAccessService.assertInternalUser();
    if (
      request.sourceType == 'Manual' &&
      !DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Record_Manual_Revenue'
      )
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to record manual revenue.'
      );
    }

    Deal_Revenue__c existing = RevenueSelector.selectByExternalKey(
      request.externalRevenueKey
    );
    if (existing != null) {
      return new RevenueOutcome(
        RevenueOutcome.DUPLICATE_IGNORED,
        existing,
        null,
        'This revenue transaction was already imported.'
      );
    }

    RevenueSourceAdapter adapter = resolveAdapter(request.sourceType);
    Deal_Revenue__c candidate = adapter.buildCandidate(request);

    Id resolvedDealId = resolveDeal(candidate, request);
    if (resolvedDealId == null) {
      Revenue_Reconciliation__c reconciliation = createReconciliation(
        candidate,
        request
      );
      return new RevenueOutcome(
        RevenueOutcome.RECONCILIATION_REQUIRED,
        null,
        reconciliation,
        'Revenue could not be automatically matched to a deal - routed for manual review.'
      );
    }
    candidate.Deal__c = resolvedDealId;

    Database.insert(candidate, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'DealRevenueImported',
      candidate.Deal__c,
      'Deal_Registration__c',
      candidate.Partner_Account__c,
      'A revenue event was imported.',
      'Info'
    );

    return new RevenueOutcome(
      RevenueOutcome.MATCHED,
      candidate,
      null,
      'Revenue imported and matched.'
    );
  }

  /**
   * Confirms a validated revenue record.
   *
   * @param command revenueId + expectedVersion.
   */
  public static void confirmRevenue(RevenueCommand command) {
    Deal_Revenue__c revenue = selectAndCheckVersion(command);
    if (revenue.Status__c != 'Pending' && revenue.Status__c != 'Validated') {
      throw new PartnerSyncHandledException(
        'This revenue record is not in a state that can be confirmed.'
      );
    }
    revenue.Status__c = 'Confirmed';
    revenue.Version_Number__c = versionAfter(revenue);
    Database.update(revenue, AccessLevel.SYSTEM_MODE);

    publish('DealRevenueConfirmed', revenue, 'A revenue event was confirmed.');
  }

  /**
   * Adjusts a revenue record's amounts, requiring a reason - the original
   * values are not silently overwritten without a trace (the adjustment
   * itself is captured via field history).
   *
   * @param command revenueId + expectedVersion + newGrossAmount/newNetAmount + reason.
   */
  public static void adjustRevenue(RevenueCommand command) {
    if (String.isBlank(command.reason)) {
      throw new PartnerSyncHandledException(
        'A reason is required to adjust a revenue record.'
      );
    }
    Deal_Revenue__c revenue = selectAndCheckVersion(command);
    if (revenue.Status__c == 'Reversed' || revenue.Status__c == 'Cancelled') {
      throw new PartnerSyncHandledException(
        'This revenue record can no longer be adjusted.'
      );
    }
    if (command.newGrossAmount != null) {
      revenue.Gross_Amount__c = command.newGrossAmount;
    }
    if (command.newNetAmount != null) {
      revenue.Net_Amount__c = command.newNetAmount;
    }
    revenue.Status__c = 'Adjusted';
    revenue.Version_Number__c = versionAfter(revenue);
    Database.update(revenue, AccessLevel.SYSTEM_MODE);

    publish('DealRevenueAdjusted', revenue, 'A revenue event was adjusted.');
  }

  /**
   * Reverses a confirmed revenue record by creating a compensating record
   * rather than mutating the original (doc §41.41 - never silently modify
   * confirmed revenue).
   *
   * @param command revenueId + expectedVersion + reason.
   * @return The compensating Deal_Revenue__c record.
   */
  public static Deal_Revenue__c reverseRevenue(RevenueCommand command) {
    PartnerAccessService.assertInternalUser();
    if (
      !DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Reverse_Revenue'
      )
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to reverse revenue.'
      );
    }
    if (String.isBlank(command.reason)) {
      throw new PartnerSyncHandledException(
        'A reason is required to reverse a revenue record.'
      );
    }
    Deal_Revenue__c revenue = selectAndCheckVersion(command);
    if (revenue.Status__c == 'Reversed') {
      throw new PartnerSyncHandledException(
        'This revenue record has already been reversed.'
      );
    }

    Deal_Revenue__c compensating = new Deal_Revenue__c(
      Deal__c = revenue.Deal__c,
      Opportunity__c = revenue.Opportunity__c,
      Implementation__c = revenue.Implementation__c,
      Customer_Account__c = revenue.Customer_Account__c,
      Partner_Account__c = revenue.Partner_Account__c,
      Reversal_Of__c = revenue.Id,
      Revenue_Type__c = 'Reversal',
      Source_Type__c = 'Adjustment',
      Status__c = 'Confirmed',
      Gross_Amount__c = revenue.Gross_Amount__c == null
        ? null
        : -revenue.Gross_Amount__c,
      Net_Amount__c = revenue.Net_Amount__c == null
        ? null
        : -revenue.Net_Amount__c,
      CurrencyIsoCode = revenue.CurrencyIsoCode,
      Revenue_Date__c = Date.today(),
      Imported_On__c = System.now(),
      Version_Number__c = 0
    );
    Database.insert(compensating, AccessLevel.SYSTEM_MODE);

    revenue.Status__c = 'Reversed';
    revenue.Version_Number__c = versionAfter(revenue);
    Database.update(revenue, AccessLevel.SYSTEM_MODE);

    publish('DealRevenueReversed', revenue, 'A revenue event was reversed.');

    cascadeReversal(revenue.Id);

    return compensating;
  }

  // Doc §41.42's reversal orchestration: dependent attribution is
  // reversed, and any dependent incentive not yet paid is cancelled
  // rather than left pointing at revenue that no longer exists. A paid
  // incentive is deliberately left untouched here - reversing its payment
  // requires picking which Partner_Incentive_Payment__c row to recover,
  // which stays a deliberate, reviewed action via
  // IncentivePaymentCommandService.reverse() rather than an automatic one.
  private static void cascadeReversal(Id revenueId) {
    for (Deal_Revenue_Attribution__c attribution : [
      SELECT Id, Version_Number__c
      FROM Deal_Revenue_Attribution__c
      WHERE Revenue__c = :revenueId AND Status__c != 'Reversed'
      WITH SYSTEM_MODE
    ]) {
      RevenueAttributionCommand reverseCommand = new RevenueAttributionCommand();
      reverseCommand.attributionId = attribution.Id;
      reverseCommand.expectedVersion = attribution.Version_Number__c == null
        ? 0
        : Integer.valueOf(attribution.Version_Number__c);
      RevenueAttributionCommandService.reverseAttribution(reverseCommand);
    }

    for (Partner_Incentive__c incentive : [
      SELECT Id, Version_Number__c
      FROM Partner_Incentive__c
      WHERE
        Revenue__c = :revenueId
        AND Status__c NOT IN ('Paid', 'Cancelled', 'Reversed')
      WITH SYSTEM_MODE
    ]) {
      IncentiveCommand cancelCommand = new IncentiveCommand();
      cancelCommand.incentiveId = incentive.Id;
      cancelCommand.expectedVersion = incentive.Version_Number__c == null
        ? 0
        : Integer.valueOf(incentive.Version_Number__c);
      IncentiveCommandService.cancel(cancelCommand);
    }
  }

  private static Id resolveDeal(
    Deal_Revenue__c candidate,
    RevenueImportRequest request
  ) {
    if (candidate.Deal__c != null) {
      return candidate.Deal__c;
    }
    if (candidate.Opportunity__c == null) {
      return null;
    }

    List<Deal_Opportunity__c> relationships = [
      SELECT Deal__c
      FROM Deal_Opportunity__c
      WHERE Opportunity__c = :candidate.Opportunity__c AND Current__c = TRUE
      WITH SYSTEM_MODE
    ];
    if (relationships.size() == 1) {
      return relationships[0].Deal__c;
    }
    return null;
  }

  private static Revenue_Reconciliation__c createReconciliation(
    Deal_Revenue__c candidate,
    RevenueImportRequest request
  ) {
    candidate.Status__c = 'Pending';
    Database.insert(candidate, AccessLevel.SYSTEM_MODE);

    Revenue_Reconciliation__c reconciliation = new Revenue_Reconciliation__c(
      Revenue__c = candidate.Id,
      Status__c = 'Open',
      Candidate_Opportunity__c = candidate.Opportunity__c,
      Match_Method__c = 'Automatic'
    );
    Database.insert(reconciliation, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'DealRevenueUnmatched',
      candidate.Id,
      'Deal_Revenue__c',
      null,
      'Imported revenue could not be automatically matched to a deal.',
      'Warning'
    );

    return reconciliation;
  }

  private static RevenueSourceAdapter resolveAdapter(String sourceType) {
    if (Test.isRunningTest() && testAdapter != null) {
      return testAdapter;
    }
    if (sourceType == 'Manual') {
      return new ManualRevenueAdapter();
    }
    if (sourceType == 'Opportunity') {
      return new OpportunityRevenueAdapter();
    }
    throw new PartnerSyncHandledException(
      'Revenue import is not yet supported for source type: ' + sourceType
    );
  }

  private static Deal_Revenue__c selectAndCheckVersion(RevenueCommand command) {
    if (command.revenueId == null) {
      throw new PartnerSyncHandledException(
        'A revenue record is required for this command.'
      );
    }
    Deal_Revenue__c revenue = RevenueSelector.selectForUpdate(
      command.revenueId
    );
    Integer version = revenue.Version_Number__c == null
      ? 0
      : Integer.valueOf(revenue.Version_Number__c);
    if (command.expectedVersion == null || command.expectedVersion != version) {
      throw new PartnerSyncHandledException(
        'This revenue record changed. Refresh before retrying.'
      );
    }
    return revenue;
  }

  private static Integer versionAfter(Deal_Revenue__c revenue) {
    return (revenue.Version_Number__c == null
        ? 0
        : Integer.valueOf(revenue.Version_Number__c)) + 1;
  }

  private static void publish(
    String eventType,
    Deal_Revenue__c revenue,
    String message
  ) {
    PlatformEventPublisherService.publish(
      eventType,
      revenue.Deal__c,
      'Deal_Registration__c',
      revenue.Partner_Account__c,
      message,
      'Info'
    );
  }
}
