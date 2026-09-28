/**
 * Executes Partner_Incentive_Claim__c commands: submit (partner-facing,
 * only for a Claim Required incentive), approve/reject (internal). An
 * approved claim sets Partner_Incentive__c.Approved_Amount__c - kept
 * independent of Calculated_Amount__c per doc §41.32's worked example
 * (an approver's decision never overwrites the original calculation).
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class IncentiveClaimCommandService {
  /**
   * Submits a claim for an incentive currently requiring one.
   *
   * @param command incentiveId + claimedAmount + claimReason.
   * @return The inserted claim record.
   */
  public static Partner_Incentive_Claim__c submit(
    IncentiveClaimCommand command
  ) {
    if (
      !PartnerAccessService.isInternalUser() &&
      !DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Submit_Incentive_Claim'
      )
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to submit an incentive claim.'
      );
    }
    if (command.incentiveId == null) {
      throw new PartnerSyncHandledException(
        'An incentive is required to submit a claim.'
      );
    }

    Partner_Incentive__c incentive = IncentiveSelector.selectForUpdate(
      command.incentiveId
    );
    if (incentive.Status__c != 'Claim Required') {
      throw new PartnerSyncHandledException(
        'This incentive does not currently require a claim.'
      );
    }

    Partner_Incentive_Claim__c claim = new Partner_Incentive_Claim__c(
      Incentive__c = incentive.Id,
      Submitted_By__c = UserInfo.getUserId(),
      Submitted_On__c = System.now(),
      Claimed_Amount__c = command.claimedAmount == null
        ? incentive.Calculated_Amount__c
        : command.claimedAmount,
      Claim_Reason__c = command.claimReason,
      Status__c = 'Submitted',
      Version_Number__c = 0
    );
    Database.insert(claim, AccessLevel.SYSTEM_MODE);

    incentive.Status__c = 'Under Review';
    incentive.Version_Number__c = incentive.Version_Number__c == null
      ? 1
      : Integer.valueOf(incentive.Version_Number__c) + 1;
    Database.update(incentive, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'PartnerIncentiveClaimSubmitted',
      incentive.Deal__c,
      'Deal_Registration__c',
      incentive.Partner_Account__c,
      'A partner incentive claim was submitted.',
      'Info'
    );

    return claim;
  }

  /**
   * Approves a submitted claim, setting the incentive's approved amount.
   *
   * @param command claimId + expectedVersion.
   */
  public static void approve(IncentiveClaimCommand command) {
    assertApprovalAuthority();
    Partner_Incentive_Claim__c claim = selectAndCheckVersion(command);
    if (claim.Status__c != 'Submitted' && claim.Status__c != 'Under Review') {
      throw new PartnerSyncHandledException(
        'This claim is not in a state that can be approved.'
      );
    }

    Partner_Incentive__c incentive = IncentiveSelector.selectForUpdate(
      claim.Incentive__c
    );
    // Approving at a different amount than the policy calculated is an
    // override, not an ordinary approval - it needs the additional
    // restricted authority rather than just PartnerSync_Approve_Partner_Incentive.
    if (
      claim.Claimed_Amount__c != incentive.Calculated_Amount__c &&
      !DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Approve_Incentive_Override'
      )
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to approve an incentive claim at an overridden amount.'
      );
    }

    claim.Status__c = 'Approved';
    claim.Decision__c = 'Approved';
    claim.Decision_Reason__c = command.reason;
    claim.Reviewed_By__c = UserInfo.getUserId();
    claim.Reviewed_On__c = System.now();
    claim.Version_Number__c = versionAfter(claim);
    Database.update(claim, AccessLevel.SYSTEM_MODE);

    incentive.Approved_Amount__c = claim.Claimed_Amount__c;
    incentive.Approval_Date__c = Date.today();
    incentive.Status__c = 'Approved';
    incentive.Version_Number__c = incentive.Version_Number__c == null
      ? 1
      : Integer.valueOf(incentive.Version_Number__c) + 1;
    Database.update(incentive, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'PartnerIncentiveApproved',
      incentive.Deal__c,
      'Deal_Registration__c',
      incentive.Partner_Account__c,
      'A partner incentive claim was approved.',
      'Info'
    );
  }

  /**
   * Rejects a submitted claim, requiring a reason.
   *
   * @param command claimId + expectedVersion + reason.
   */
  public static void reject(IncentiveClaimCommand command) {
    assertApprovalAuthority();
    if (String.isBlank(command.reason)) {
      throw new PartnerSyncHandledException(
        'A reason is required to reject an incentive claim.'
      );
    }
    Partner_Incentive_Claim__c claim = selectAndCheckVersion(command);
    if (claim.Status__c != 'Submitted' && claim.Status__c != 'Under Review') {
      throw new PartnerSyncHandledException(
        'This claim is not in a state that can be rejected.'
      );
    }

    claim.Status__c = 'Rejected';
    claim.Decision__c = 'Rejected';
    claim.Decision_Reason__c = command.reason;
    claim.Reviewed_By__c = UserInfo.getUserId();
    claim.Reviewed_On__c = System.now();
    claim.Version_Number__c = versionAfter(claim);
    Database.update(claim, AccessLevel.SYSTEM_MODE);

    Partner_Incentive__c incentive = IncentiveSelector.selectForUpdate(
      claim.Incentive__c
    );
    incentive.Status__c = 'Rejected';
    incentive.Version_Number__c = incentive.Version_Number__c == null
      ? 1
      : Integer.valueOf(incentive.Version_Number__c) + 1;
    Database.update(incentive, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'PartnerIncentiveRejected',
      incentive.Deal__c,
      'Deal_Registration__c',
      incentive.Partner_Account__c,
      'A partner incentive claim was rejected.',
      'Info'
    );
  }

  private static void assertApprovalAuthority() {
    PartnerAccessService.assertInternalUser();
    if (
      !DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Approve_Partner_Incentive'
      )
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to decide incentive claims.'
      );
    }
  }

  private static Partner_Incentive_Claim__c selectAndCheckVersion(
    IncentiveClaimCommand command
  ) {
    if (command.claimId == null) {
      throw new PartnerSyncHandledException(
        'A claim is required for this command.'
      );
    }
    Partner_Incentive_Claim__c claim = IncentiveClaimSelector.selectForUpdate(
      command.claimId
    );
    Integer version = claim.Version_Number__c == null
      ? 0
      : Integer.valueOf(claim.Version_Number__c);
    if (command.expectedVersion == null || command.expectedVersion != version) {
      throw new PartnerSyncHandledException(
        'This claim changed. Refresh before retrying.'
      );
    }
    return claim;
  }

  private static Integer versionAfter(Partner_Incentive_Claim__c claim) {
    return (claim.Version_Number__c == null
        ? 0
        : Integer.valueOf(claim.Version_Number__c)) + 1;
  }
}
