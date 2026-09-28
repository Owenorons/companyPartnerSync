/**
 * Executes Partner_Renewal__c commands across the identified-to-renewed
 * lifecycle: confirmParticipation/declineParticipation (partner-facing),
 * qualify (the eligibility chain, doc section 42.26), requestReview/approve
 * (material-change branching, doc section 42.28), markRenewed/
 * markNotRenewed. Renewal protection (doc section 42.23) is created as a
 * distinct Deal_Protection_Grant__c row, never a mutation of the original
 * registration grant.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class RenewalCommandService {
  /**
   * Confirms the partner's continued participation in a renewal.
   *
   * @param command renewalId + expectedVersion.
   * @return The updated renewal.
   */
  public static Partner_Renewal__c confirmParticipation(
    RenewalCommand command
  ) {
    Partner_Renewal__c renewal = requireExpectedVersion(command);
    assertPartnerCanRespond(renewal, 'PartnerSync_Confirm_Renewal');
    if (renewal.Status__c != 'Partner Confirmation Required') {
      throw new PartnerSyncHandledException(
        'This renewal is not awaiting partner confirmation.'
      );
    }

    renewal.Status__c = 'Partner Confirmed';
    renewal.Confirmed_On__c = System.now();
    persist(renewal);

    publish(
      renewal,
      'RenewalPartnerConfirmed',
      'A partner confirmed a renewal.',
      'Info'
    );
    return renewal;
  }

  /**
   * Declines the partner's continued participation in a renewal.
   *
   * @param command renewalId + expectedVersion + reason.
   * @return The updated renewal.
   */
  public static Partner_Renewal__c declineParticipation(
    RenewalCommand command
  ) {
    Partner_Renewal__c renewal = requireExpectedVersion(command);
    assertPartnerCanRespond(renewal, 'PartnerSync_Decline_Renewal');
    if (renewal.Status__c != 'Partner Confirmation Required') {
      throw new PartnerSyncHandledException(
        'This renewal is not awaiting partner confirmation.'
      );
    }

    renewal.Status__c = 'Not Renewed';
    renewal.Declined_On__c = System.now();
    renewal.Renewal_Health__c = 'Lost';
    persist(renewal);

    publish(
      renewal,
      'RenewalPartnerDeclined',
      'A partner declined a renewal.',
      'Warning'
    );
    return renewal;
  }

  /**
   * Runs the eligibility chain (doc section 42.26: partner active,
   * onboarding valid, no outstanding critical risk - a performance
   * threshold via a PartnerPerformanceDomain would apply here too, but no
   * such domain exists in this org yet, Known Adaptation shared with
   * Sprint 40/41's identical Partner_Performance__c gap). Advances to
   * Review Required or Approved depending on the resolved policy, and
   * creates a distinct Renewal protection grant when the policy calls for
   * one.
   *
   * @param command renewalId + expectedVersion.
   * @return The updated renewal.
   */
  public static Partner_Renewal__c qualify(RenewalCommand command) {
    PartnerAccessService.assertInternalUser();
    Partner_Renewal__c renewal = requireExpectedVersion(command);
    if (
      renewal.Status__c != 'Partner Confirmed' &&
      renewal.Status__c != 'Qualification'
    ) {
      throw new PartnerSyncHandledException(
        'This renewal must be partner-confirmed before qualification.'
      );
    }

    // Qualification is persisted as its own step (not just an in-memory
    // phase of this one call) so a renewal that fails the eligibility
    // chain below is left visibly in Qualification for follow-up, rather
    // than snapping back to Partner Confirmed as if nothing happened. The
    // status check above accepts either status, so re-running qualify()
    // after fixing the blocker is a normal retry, not a stuck state.
    if (renewal.Status__c == 'Partner Confirmed') {
      renewal.Status__c = 'Qualification';
      persist(renewal);
    }

    assertEligible(renewal);

    Renewal_Policy__mdt policy = RenewalPolicyResolver.resolvePolicy(
      productFamilyFor(renewal)
    );
    renewal.Partner_Continuity_Policy__c = policy.Partner_Continuity_Policy__c;

    // 'On Approval' mode deliberately waits for approve() instead of
    // granting here - only 'Automatic' mode protects a renewal that hasn't
    // been reviewed/approved yet.
    if (policy.Renewal_Protection_Mode__c == 'Automatic') {
      grantRenewalProtection(renewal);
    }

    // Either flag routes to Review Required, since approve() is the one
    // action that resolves it regardless of which requirement triggered
    // the stop - a policy requiring formal approval but not a full review
    // still needs a human in the loop before Renewed.
    renewal.Status__c = (policy.Require_Renewal_Review__c == true ||
      policy.Require_Renewal_Approval__c == true)
      ? 'Review Required'
      : 'Approved';
    persist(renewal);

    publish(renewal, 'RenewalQualified', 'A renewal was qualified.', 'Info');
    return renewal;
  }

  /**
   * Explicitly routes a renewal to review - the material-change path (doc
   * section 42.28) for a renewal whose terms have changed enough that
   * automatic qualification is not appropriate.
   *
   * @param command renewalId + expectedVersion + reason (the material change).
   * @return The updated renewal.
   */
  public static Partner_Renewal__c requestReview(RenewalCommand command) {
    PartnerAccessService.assertInternalUser();
    if (String.isBlank(command.reason)) {
      throw new PartnerSyncHandledException(
        'A reason is required to request renewal review.'
      );
    }
    Partner_Renewal__c renewal = requireExpectedVersion(command);
    if (
      renewal.Status__c != 'Qualification' &&
      renewal.Status__c != 'Partner Confirmed' &&
      renewal.Status__c != 'Review Required'
    ) {
      throw new PartnerSyncHandledException(
        'This renewal is not in a state that can be sent to review.'
      );
    }

    renewal.Status__c = 'Review Required';
    renewal.Material_Change__c = true;
    renewal.Material_Change_Reason__c = command.reason;
    persist(renewal);

    publish(
      renewal,
      'RenewalReviewRequested',
      'A renewal was sent to review.',
      'Warning'
    );
    return renewal;
  }

  /**
   * Approves a renewal awaiting review, requiring
   * PartnerSync_Manage_Renewal.
   *
   * @param command renewalId + expectedVersion.
   * @return The updated renewal.
   */
  public static Partner_Renewal__c approve(RenewalCommand command) {
    if (
      !PartnerAccessService.isInternalUser() ||
      !DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Manage_Renewal'
      )
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to approve this renewal.'
      );
    }
    Partner_Renewal__c renewal = requireExpectedVersion(command);
    if (renewal.Status__c != 'Review Required') {
      throw new PartnerSyncHandledException(
        'Only a renewal in Review Required can be approved.'
      );
    }

    if (renewal.Original_Protection__c == null) {
      Renewal_Policy__mdt policy = RenewalPolicyResolver.resolvePolicy(
        productFamilyFor(renewal)
      );
      if (policy.Renewal_Protection_Mode__c == 'On Approval') {
        grantRenewalProtection(renewal);
      }
    }

    renewal.Status__c = 'Approved';
    persist(renewal);

    publish(renewal, 'RenewalApproved', 'A renewal was approved.', 'Info');
    return renewal;
  }

  /**
   * Marks a renewal as won: sets Status__c/Renewal_Health__c and books
   * Renewal-type revenue via RevenueCommandService.importRevenue() (doc
   * section 42.61, Known Adaptation #11 - wired in this same sprint rather
   * than left as unwired prose). Does not touch the customer's overall
   * Customer_Success_Engagement__c health - that stays a separate signal.
   *
   * @param command renewalId + expectedVersion + renewedAmount.
   * @return The updated renewal.
   */
  public static Partner_Renewal__c markRenewed(RenewalCommand command) {
    PartnerAccessService.assertInternalUser();
    Partner_Renewal__c renewal = requireExpectedVersion(command);
    if (renewal.Status__c != 'Approved') {
      throw new PartnerSyncHandledException(
        'Only an Approved renewal can be marked renewed.'
      );
    }

    renewal.Status__c = 'Renewed';
    renewal.Renewal_Health__c = 'Won';
    if (command.currentDealId != null) {
      renewal.Current_Deal__c = command.currentDealId;
    }
    persist(renewal);

    if (command.renewedAmount != null) {
      RevenueImportRequest request = new RevenueImportRequest();
      request.sourceType = 'Manual';
      request.explicitDealId = renewal.Current_Deal__c == null
        ? renewal.Original_Deal__c
        : renewal.Current_Deal__c;
      request.revenueType = 'Renewal';
      request.grossAmount = command.renewedAmount;
      request.netAmount = command.renewedAmount;
      request.currencyIsoCode = command.currencyIsoCode;
      request.externalRevenueKey = 'renewal-' + renewal.Id;
      request.revenueDate = Date.today();
      RevenueCommandService.importRevenue(request);
    }

    publish(renewal, 'RenewalWon', 'A renewal was won.', 'Info');
    return renewal;
  }

  /**
   * Marks a renewal as lost. Deliberately does NOT declare customer churn
   * (doc section 42.31) - churn is a distinct, explicit action on
   * CustomerSuccessCommandService, never an automatic side effect of a
   * lost renewal (a customer can lose one renewal cycle and still remain
   * a customer via a different commercial path).
   *
   * @param command renewalId + expectedVersion + reason.
   * @return The updated renewal.
   */
  public static Partner_Renewal__c markNotRenewed(RenewalCommand command) {
    PartnerAccessService.assertInternalUser();
    if (String.isBlank(command.reason)) {
      throw new PartnerSyncHandledException(
        'A reason is required to mark a renewal not renewed.'
      );
    }
    Partner_Renewal__c renewal = requireExpectedVersion(command);
    if (renewal.Status__c == 'Renewed' || renewal.Status__c == 'Not Renewed') {
      throw new PartnerSyncHandledException(
        'This renewal has already reached a final outcome.'
      );
    }

    renewal.Status__c = 'Not Renewed';
    renewal.Renewal_Health__c = 'Lost';
    persist(renewal);

    publish(
      renewal,
      'RenewalLost',
      'A renewal was lost: ' + command.reason,
      'Warning'
    );
    return renewal;
  }

  // Internal users may always respond on a partner's behalf; an external
  // user needs the specific action permission and must own the renewal's
  // partner account - mirrors PartnerAccessService.assertCurrentUserCanAccessPartnerAccount()'s
  // reasoning, plus a per-action permission since confirming and declining
  // are different partner-facing capabilities.
  private static void assertPartnerCanRespond(
    Partner_Renewal__c renewal,
    String permissionName
  ) {
    if (PartnerAccessService.isInternalUser()) {
      return;
    }
    if (!DealLifecyclePermissionService.hasPermission(permissionName)) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to respond to this renewal.'
      );
    }
    PartnerAccessService.assertCurrentUserCanAccessPartnerAccount(
      renewal.Primary_Partner__c
    );
  }

  private static void assertEligible(Partner_Renewal__c renewal) {
    if (renewal.Primary_Partner__c != null) {
      List<Account> partners = [
        SELECT Partner_Status__c, Onboarding_Status__c
        FROM Account
        WHERE Id = :renewal.Primary_Partner__c
        WITH SYSTEM_MODE
      ];
      if (!partners.isEmpty()) {
        Account partner = partners[0];
        if (partner.Partner_Status__c != 'Active') {
          throw new PartnerSyncHandledException(
            'The renewing partner is not Active and cannot be qualified for renewal.'
          );
        }
        if (
          partner.Onboarding_Status__c != 'Approved' &&
          partner.Onboarding_Status__c != 'Complete'
        ) {
          throw new PartnerSyncHandledException(
            'The renewing partner has not completed onboarding.'
          );
        }
      }
    }

    if (
      renewal.Customer_Success_Engagement__c != null &&
      [
        SELECT COUNT()
        FROM Customer_Success_Risk__c
        WHERE
          Customer_Success_Engagement__c = :renewal.Customer_Success_Engagement__c
          AND Severity__c = 'Critical'
          AND Status__c NOT IN ('Resolved', 'Accepted', 'Closed')
        WITH SYSTEM_MODE
      ] > 0
    ) {
      throw new PartnerSyncHandledException(
        'This customer has an unresolved Critical risk and cannot be qualified for renewal yet.'
      );
    }
  }

  // Current__c is deliberately left false: Current_Grant_Key__c is unique
  // per Deal__c, so only one grant per deal can hold Current__c = true at
  // a time (the original registration grant's own governance semantics -
  // see DealProtectionCommandService). A renewal protection grant is still
  // a real, distinct, Active row - Require_Protection__c-style checks key
  // off Status__c = 'Active', not Current__c - it just never contends for
  // that one-per-deal "current" slot.
  private static void grantRenewalProtection(Partner_Renewal__c renewal) {
    if (renewal.Current_Deal__c == null && renewal.Original_Deal__c == null) {
      return;
    }
    Deal_Protection_Grant__c grant = new Deal_Protection_Grant__c(
      Deal__c = renewal.Current_Deal__c == null
        ? renewal.Original_Deal__c
        : renewal.Current_Deal__c,
      Protection_Type__c = 'Renewal',
      Status__c = 'Active',
      Current__c = false,
      Start_Date__c = Date.today(),
      Version_Number__c = 0
    );
    Database.insert(grant, AccessLevel.SYSTEM_MODE);
    renewal.Original_Protection__c = grant.Id;
  }

  private static String productFamilyFor(Partner_Renewal__c renewal) {
    if (renewal.Commercial_Entitlement__c == null) {
      return null;
    }
    List<Customer_Commercial_Entitlement__c> entitlements = [
      SELECT Product_Family__c
      FROM Customer_Commercial_Entitlement__c
      WHERE Id = :renewal.Commercial_Entitlement__c
      WITH SYSTEM_MODE
    ];
    return entitlements.isEmpty() ? null : entitlements[0].Product_Family__c;
  }

  private static Partner_Renewal__c requireExpectedVersion(
    RenewalCommand command
  ) {
    if (command.renewalId == null) {
      throw new PartnerSyncHandledException(
        'A renewal is required for this command.'
      );
    }
    Partner_Renewal__c renewal = RenewalSelector.selectForUpdate(
      command.renewalId
    );
    if (
      command.expectedVersion != null &&
      coalesceVersion(renewal) != command.expectedVersion
    ) {
      throw new PartnerSyncHandledException(
        'This renewal has changed since it was loaded - refresh and try again.'
      );
    }
    return renewal;
  }

  private static void persist(Partner_Renewal__c renewal) {
    renewal.Version_Number__c = coalesceVersion(renewal) + 1;
    Database.update(renewal, AccessLevel.SYSTEM_MODE);
  }

  private static Integer coalesceVersion(Partner_Renewal__c renewal) {
    return renewal.Version_Number__c == null
      ? 0
      : Integer.valueOf(renewal.Version_Number__c);
  }

  private static void publish(
    Partner_Renewal__c renewal,
    String eventType,
    String summary,
    String severity
  ) {
    PlatformEventPublisherService.publish(
      eventType,
      renewal.Id,
      'Partner_Renewal__c',
      renewal.Primary_Partner__c,
      summary,
      severity
    );
  }
}
