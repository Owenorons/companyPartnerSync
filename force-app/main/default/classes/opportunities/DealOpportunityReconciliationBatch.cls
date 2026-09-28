/**
 * Scheduled/batch job that detects Opportunity-side changes on each deal's
 * primary Deal_Opportunity__c relationship - stage, closed-won/lost,
 * deletion (orphaning), and drift against the approval snapshot - and
 * projects them into PartnerSync state (Sprint 39 §39.19-39.20, §39.47).
 *
 * Deliberately scheduled-batch, not a live Opportunity trigger (Known
 * Adaptation: correctly avoiding recursion against a customer's own,
 * unknown Opportunity automation is a substantial undertaking on its own
 * and is left as a future hardening pass). Scoped to each deal's PRIMARY
 * relationship only - secondary/expansion relationships aren't reconciled
 * for deal-level stage/health in this build.
 *
 * Sync-authority default (hardcoded, not a configurable field map): the
 * Opportunity is always the source for Amount/CloseDate/Stage; PartnerSync
 * fields (approval, conflict, participants, protection dates) are never
 * written back to the Opportunity by this batch.
 *
 * Bulk-safety: the plain Stage__c/Lifecycle_Health__c field updates and the
 * sync-failure log entries are accumulated per chunk and flushed in one
 * bulk DML call each, rather than one DML statement per row - each
 * execute() invocation runs in its own transaction with its own governor
 * limits, but 150+ individual DML statements in one chunk would still
 * exceed the per-transaction DML statement limit. Closed-lost protection
 * release and material-change evaluation are NOT bulk-batched across the
 * chunk - each affected row still makes its own DealProtectionCommandService/
 * DealMaterialChangeService call, matching this codebase's existing
 * accepted pattern (DealExpiryBatch calls DealProtectionCommandService
 * per grant, unbatched); the risk is bounded since these paths only fire
 * for rows actually transitioning to closed-lost or drifting in one run,
 * not every row in the chunk. Full bulk-batching of those two paths is a
 * named follow-up, not attempted here. Sprint 40 adds a third: Closed Won
 * triggers ImplementationCommandService.create() per row too (also
 * unbatched, same accepted-risk category) - that single-record command
 * does 5 SOQL + 3 DML statements per deal (policy resolution, deal/
 * primary-opportunity/originating-participant lookups, the implementation
 * insert, its generated milestones, and the lifecycle phase advance), so
 * this class's own test coverage proves it safe at a real, honestly-scoped
 * 15 simultaneous transitions (see
 * closedWon15OpportunitiesCreatesImplementationsWithinGovernorLimits in
 * this class's own test), not a false 200 claim - 200 deals closing won in
 * the exact same batch chunk is not realistic, and would exceed both the
 * SOQL and DML statement limits at that per-row cost. The closed-lost
 * release path costs the same 3 SOQL + 3 DML per row via
 * DealProtectionCommandService, proven safe at the same honestly-scoped 15
 * (see closedLost15ReleasesProtectionWithinGovernorLimits) - a pre-beta
 * bulk-safety audit found this class's own doc comment had asserted this
 * path was "bounded" without ever actually proving it with a bulk test.
 * That same audit also found resolveClosedLostBehaviour() was re-querying
 * Deal_Protection_Policy__mdt on every closed-lost row instead of once per
 * job run - fixed by caching it on the batch instance (Salesforce reuses
 * one Batchable instance across every chunk in a run, so this now costs
 * exactly one query total, not one per chunk or per row).
 *
 * Per-record failures are caught, logged to PartnerSync_Opportunity_Sync_Log__c,
 * and the batch continues - a bad row never fails the whole chunk, and
 * this batch never touches the Opportunity itself, so a failure here can
 * never roll back a legitimate customer Opportunity update.
 */
public without sharing class DealOpportunityReconciliationBatch implements Database.Batchable<SObject>, Schedulable {
  // Deal_Protection_Policy__mdt is an org singleton, so tests can't seed
  // alternate CMDT rows per case - same test-override shape as
  // DealLifecyclePermissionService.testOverrides.
  @TestVisible
  private static String testClosedLostBehaviourOverride;

  // Instance fields persist across execute() calls within the same batch
  // job run (Salesforce reuses one Batchable instance for every chunk),
  // so resolving this once here instead of per row - previously a real
  // SOQL query inside the per-row loop, found during a pre-beta
  // bulk-safety audit - costs one query for the whole job, not one per
  // closed-lost row.
  private String cachedClosedLostBehaviour;
  private Boolean closedLostBehaviourCached = false;

  /**
   * Builds the query locator over every deal's current primary
   * Deal_Opportunity__c relationship, joined to live Opportunity and deal
   * state for one-pass reconciliation.
   *
   * @param context Batch execution context (unused).
   * @return A query locator over current primary Deal_Opportunity__c rows.
   */
  public Database.QueryLocator start(Database.BatchableContext context) {
    return Database.getQueryLocator(
      [
        SELECT
          Id,
          Deal__c,
          Opportunity__c,
          Partner_Account__c,
          Deal__r.Lifecycle_Health__c,
          Deal__r.Stage__c,
          Deal__r.Approved_Revenue__c,
          Deal__r.Approved_Customer_Account__c,
          Deal__r.Approved_Close_Date__c,
          Deal__r.Approved_Owner__c,
          Deal__r.Approved_Opportunity__c,
          Opportunity__r.StageName,
          Opportunity__r.Amount,
          Opportunity__r.CloseDate,
          Opportunity__r.AccountId,
          Opportunity__r.OwnerId,
          Opportunity__r.IsWon,
          Opportunity__r.IsClosed
        FROM Deal_Opportunity__c
        WHERE Current__c = TRUE AND Primary__c = TRUE
      ]
    );
  }

  /**
   * Reconciles each primary relationship in scope, accumulating simple
   * field updates and sync-failure log entries for one bulk DML call each
   * at the end, rather than per row.
   *
   * @param context Batch execution context (unused).
   * @param scope Batch of current primary Deal_Opportunity__c rows to reconcile.
   */
  public void execute(
    Database.BatchableContext context,
    List<Deal_Opportunity__c> scope
  ) {
    Map<Id, Deal_Registration__c> dealUpdatesByDealId = new Map<Id, Deal_Registration__c>();
    List<PartnerSync_Opportunity_Sync_Log__c> failureLogs = new List<PartnerSync_Opportunity_Sync_Log__c>();

    for (Deal_Opportunity__c relationship : scope) {
      try {
        reconcile(relationship, dealUpdatesByDealId);
      } catch (Exception ex) {
        LoggingService.error(
          'DealOpportunityReconciliationBatch',
          'Failed to reconcile deal opportunity relationship ' +
          relationship.Id,
          ex
        );
        failureLogs.add(
          new PartnerSync_Opportunity_Sync_Log__c(
            Deal_Opportunity__c = relationship.Id,
            Status__c = 'Failed',
            Attempt_Count__c = 1,
            Last_Error__c = ex.getMessage(),
            Next_Attempt_On__c = System.now().addHours(1)
          )
        );
      }
    }

    if (!dealUpdatesByDealId.isEmpty()) {
      Database.update(dealUpdatesByDealId.values(), AccessLevel.SYSTEM_MODE);
    }
    if (!failureLogs.isEmpty()) {
      Database.insert(failureLogs, AccessLevel.SYSTEM_MODE);
    }
  }

  /**
   * No post-processing is required after this batch runs.
   *
   * @param context Batch execution context (unused).
   */
  public void finish(Database.BatchableContext context) {
  }

  /**
   * Scheduled entry point: launches this class as a batch job with a chunk size of 200.
   *
   * @param context Scheduled execution context (unused).
   */
  public void execute(SchedulableContext context) {
    Database.executeBatch(new DealOpportunityReconciliationBatch(), 200);
  }

  private void reconcile(
    Deal_Opportunity__c relationship,
    Map<Id, Deal_Registration__c> dealUpdatesByDealId
  ) {
    if (relationship.Opportunity__c == null) {
      handleOrphaned(relationship, dealUpdatesByDealId);
      return;
    }

    Boolean isClosed = relationship.Opportunity__r.IsClosed == true;
    Boolean isWon = relationship.Opportunity__r.IsWon == true;

    if (isClosed && isWon) {
      handleClosedWon(relationship, dealUpdatesByDealId);
    } else if (isClosed && !isWon) {
      handleClosedLost(relationship, dealUpdatesByDealId);
    } else {
      handleOpen(relationship, dealUpdatesByDealId);
    }
  }

  private Deal_Registration__c dealUpdateFor(
    Map<Id, Deal_Registration__c> dealUpdatesByDealId,
    Id dealId
  ) {
    if (!dealUpdatesByDealId.containsKey(dealId)) {
      dealUpdatesByDealId.put(dealId, new Deal_Registration__c(Id = dealId));
    }
    return dealUpdatesByDealId.get(dealId);
  }

  private void handleOrphaned(
    Deal_Opportunity__c relationship,
    Map<Id, Deal_Registration__c> dealUpdatesByDealId
  ) {
    if (relationship.Deal__r.Lifecycle_Health__c == 'Blocked') {
      return;
    }
    dealUpdateFor(dealUpdatesByDealId, relationship.Deal__c)
      .Lifecycle_Health__c = 'Blocked';
    PlatformEventPublisherService.publish(
      'DealOpportunityOrphaned',
      relationship.Deal__c,
      'Deal_Registration__c',
      relationship.Partner_Account__c,
      'The deal\'s primary opportunity relationship is no longer accessible.',
      'Warning'
    );
  }

  private void handleClosedWon(
    Deal_Opportunity__c relationship,
    Map<Id, Deal_Registration__c> dealUpdatesByDealId
  ) {
    if (relationship.Deal__r.Stage__c == 'Closed Won') {
      return;
    }
    dealUpdateFor(dealUpdatesByDealId, relationship.Deal__c)
      .Stage__c = 'Closed Won';
    PlatformEventPublisherService.publish(
      'SalesExecutionClosedWon',
      relationship.Deal__c,
      'Deal_Registration__c',
      relationship.Partner_Account__c,
      'The deal\'s primary opportunity closed won.',
      'Info'
    );

    // Sprint 40 §40.6/Known Adaptation #5: implementation creation hooks
    // in here synchronously, reusing this batch's own per-row try/catch
    // isolation and sync-log failure logging - same risk profile as
    // DealExpiryBatch calling DealProtectionCommandService per grant.
    ImplementationCommand command = new ImplementationCommand();
    command.action = 'Create';
    command.dealId = relationship.Deal__c;
    ImplementationCommandService.execute(command);
  }

  private void handleClosedLost(
    Deal_Opportunity__c relationship,
    Map<Id, Deal_Registration__c> dealUpdatesByDealId
  ) {
    if (relationship.Deal__r.Stage__c == 'Closed Lost') {
      return;
    }
    dealUpdateFor(dealUpdatesByDealId, relationship.Deal__c)
      .Stage__c = 'Closed Lost';
    PlatformEventPublisherService.publish(
      'SalesExecutionClosedLost',
      relationship.Deal__c,
      'Deal_Registration__c',
      relationship.Partner_Account__c,
      'The deal\'s primary opportunity closed lost.',
      'Info'
    );
    evaluateClosedLostProtection(relationship.Deal__c, dealUpdatesByDealId);
  }

  // "Release After Grace" and "Require Review" are both implemented as a
  // flag + audit entry for internal follow-up rather than full grace-period
  // tracking or an interactive review workflow - see the field's own
  // description on Deal_Protection_Policy__mdt.Closed_Lost_Behaviour__c.
  private void evaluateClosedLostProtection(
    Id dealId,
    Map<Id, Deal_Registration__c> dealUpdatesByDealId
  ) {
    String behaviour = resolveClosedLostBehaviour();
    if (behaviour == 'No Change' || String.isBlank(behaviour)) {
      return;
    }

    if (behaviour == 'Release Immediately') {
      releaseProtection(dealId);
      return;
    }

    dealUpdateFor(dealUpdatesByDealId, dealId).Lifecycle_Health__c = 'At Risk';
    AuditLogRequestDTO request = AuditFactory.createSuccess(
      'Deal_Registration__c',
      dealId,
      'Flag Closed Lost Protection For Review'
    );
    request.metadataJson = JSON.serialize(
      new Map<String, Object>{ 'closedLostBehaviour' => behaviour }
    );
    AuditService.log(request);
  }

  private void releaseProtection(Id dealId) {
    List<Deal_Protection_Grant__c> grants = [
      SELECT Id, Version_Number__c
      FROM Deal_Protection_Grant__c
      WHERE Deal__c = :dealId AND Current__c = TRUE AND Status__c = 'Active'
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    if (grants.isEmpty()) {
      return;
    }
    DealProtectionCommand command = new DealProtectionCommand();
    command.dealId = dealId;
    command.action = 'Release Protection';
    command.commandKey = 'closed-lost-release-' + dealId;
    command.expectedVersion = Integer.valueOf(grants[0].Version_Number__c);
    command.reason = 'Released automatically: primary opportunity closed lost.';
    DealProtectionCommandService.execute(command);
  }

  private String resolveClosedLostBehaviour() {
    if (Test.isRunningTest() && testClosedLostBehaviourOverride != null) {
      return testClosedLostBehaviourOverride;
    }
    if (closedLostBehaviourCached) {
      return cachedClosedLostBehaviour;
    }
    List<Deal_Protection_Policy__mdt> policies = [
      SELECT Closed_Lost_Behaviour__c
      FROM Deal_Protection_Policy__mdt
      WHERE Active__c = TRUE
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    cachedClosedLostBehaviour = policies.isEmpty()
      ? null
      : policies[0].Closed_Lost_Behaviour__c;
    closedLostBehaviourCached = true;
    return cachedClosedLostBehaviour;
  }

  private void handleOpen(
    Deal_Opportunity__c relationship,
    Map<Id, Deal_Registration__c> dealUpdatesByDealId
  ) {
    // Doc §39.45: reopening a previously closed opportunity re-evaluates
    // rather than blindly reactivating - flags for review via the same
    // audit pattern as a closed-lost review flag, never auto-restores
    // protection.
    if (
      relationship.Deal__r.Stage__c == 'Closed Won' ||
      relationship.Deal__r.Stage__c == 'Closed Lost'
    ) {
      dealUpdateFor(dealUpdatesByDealId, relationship.Deal__c)
        .Lifecycle_Health__c = 'At Risk';
      AuditLogRequestDTO request = AuditFactory.createSuccess(
        'Deal_Registration__c',
        relationship.Deal__c,
        'Reopen Sales Execution'
      );
      AuditService.log(request);
      PlatformEventPublisherService.publish(
        'SalesExecutionReopened',
        relationship.Deal__c,
        'Deal_Registration__c',
        relationship.Partner_Account__c,
        'The deal\'s primary opportunity was reopened after closing.',
        'Info'
      );
    }

    String canonicalStage = DealSalesStageProjectionService.resolveCanonicalStage(
      relationship.Opportunity__r.StageName
    );
    if (
      canonicalStage != null &&
      canonicalStage != relationship.Deal__r.Stage__c
    ) {
      dealUpdateFor(dealUpdatesByDealId, relationship.Deal__c)
        .Stage__c = canonicalStage;
    }
    checkForMaterialDrift(relationship);
  }

  private void checkForMaterialDrift(Deal_Opportunity__c relationship) {
    Deal_Registration__c deal = relationship.Deal__r;
    if (deal.Approved_Opportunity__c == null) {
      // No approval snapshot yet (deal not yet approved) - nothing to
      // diff drift against.
      return;
    }

    if (
      deal.Approved_Customer_Account__c != null &&
      relationship.Opportunity__r.AccountId != deal.Approved_Customer_Account__c
    ) {
      DealMaterialChangeService.evaluate(
        relationship.Deal__c,
        'CustomerChanged',
        'The opportunity\'s account changed since approval.',
        null,
        null
      );
      return;
    }

    if (
      deal.Approved_Revenue__c != null &&
      relationship.Opportunity__r.Amount != null &&
      relationship.Opportunity__r.Amount != deal.Approved_Revenue__c
    ) {
      DealMaterialChangeService.evaluate(
        relationship.Deal__c,
        'AmountChanged',
        'The opportunity\'s amount changed since approval.',
        relationship.Opportunity__r.Amount,
        deal.Approved_Revenue__c
      );
      return;
    }

    if (
      deal.Approved_Close_Date__c != null &&
      relationship.Opportunity__r.CloseDate != deal.Approved_Close_Date__c
    ) {
      DealMaterialChangeService.evaluate(
        relationship.Deal__c,
        'CloseDateChanged',
        'The opportunity\'s close date changed since approval.',
        null,
        null
      );
      return;
    }

    if (
      deal.Approved_Owner__c != null &&
      relationship.Opportunity__r.OwnerId != deal.Approved_Owner__c
    ) {
      DealMaterialChangeService.evaluate(
        relationship.Deal__c,
        'OwnerChanged',
        'The opportunity\'s owner changed since approval.',
        null,
        null
      );
    }
  }
}
