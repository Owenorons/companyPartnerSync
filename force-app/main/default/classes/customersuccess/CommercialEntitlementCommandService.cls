/**
 * Executes Customer_Commercial_Entitlement__c commands: record (via
 * CommercialEntitlementAdapter), renew (closes the current entitlement and
 * inserts a new version - never mutates dates in place, matching this
 * codebase's "create a new version" precedent for renewal-shaped changes),
 * and cancel.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CommercialEntitlementCommandService {
  private static final CommercialEntitlementAdapter ADAPTER = new ManualCommercialEntitlementAdapter();

  /**
   * Records a new Active commercial entitlement.
   *
   * @param command The entitlement details to record.
   * @return The inserted entitlement.
   */
  public static Customer_Commercial_Entitlement__c record(
    CommercialEntitlementCommand command
  ) {
    PartnerAccessService.assertInternalUser();

    Customer_Commercial_Entitlement__c entitlement = ADAPTER.buildCandidate(
      command
    );
    Database.insert(entitlement, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'CommercialEntitlementRecorded',
      entitlement.Id,
      'Customer_Commercial_Entitlement__c',
      null,
      'A commercial entitlement was recorded.',
      'Info'
    );

    return entitlement;
  }

  /**
   * Renews an entitlement: the current entitlement is closed to Renewed
   * and a new Active entitlement is inserted with the new effective
   * window, linked back for continuity.
   *
   * @param command entitlementId + expectedVersion + the new effective window.
   * @return The newly-inserted entitlement.
   */
  public static Customer_Commercial_Entitlement__c renew(
    CommercialEntitlementCommand command
  ) {
    PartnerAccessService.assertInternalUser();
    if (command.entitlementId == null) {
      throw new PartnerSyncHandledException(
        'An entitlement is required to renew.'
      );
    }
    Customer_Commercial_Entitlement__c current = CommercialEntitlementSelector.selectForUpdate(
      command.entitlementId
    );
    if (
      command.expectedVersion != null &&
      coalesceVersion(current) != command.expectedVersion
    ) {
      throw new PartnerSyncHandledException(
        'This entitlement has changed since it was loaded - refresh and try again.'
      );
    }
    if (current.Status__c != 'Active' && current.Status__c != 'Expiring') {
      throw new PartnerSyncHandledException(
        'Only an Active or Expiring entitlement can be renewed.'
      );
    }

    current.Status__c = 'Renewed';
    current.Version_Number__c = coalesceVersion(current) + 1;
    Database.update(current, AccessLevel.SYSTEM_MODE);

    CommercialEntitlementCommand renewedCommand = new CommercialEntitlementCommand();
    renewedCommand.customerAccountId = current.Customer_Account__c;
    renewedCommand.customerSuccessEngagementId = current.Customer_Success_Engagement__c;
    renewedCommand.originatingDealId = current.Originating_Deal__c;
    renewedCommand.originatingOpportunityId = command.originatingOpportunityId;
    renewedCommand.product = current.Product__c;
    renewedCommand.productFamily = current.Product_Family__c;
    renewedCommand.entitlementType = current.Entitlement_Type__c;
    renewedCommand.effectiveStartOn = command.effectiveStartOn == null
      ? current.Effective_End_On__c
      : command.effectiveStartOn;
    renewedCommand.effectiveEndOn = command.effectiveEndOn;
    renewedCommand.quantity = command.quantity == null
      ? current.Quantity__c
      : command.quantity;
    renewedCommand.autoRenew = current.Auto_Renew__c;

    Customer_Commercial_Entitlement__c renewed = ADAPTER.buildCandidate(
      renewedCommand
    );
    Database.insert(renewed, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'CommercialEntitlementRenewed',
      renewed.Id,
      'Customer_Commercial_Entitlement__c',
      null,
      'A commercial entitlement was renewed.',
      'Info'
    );

    return renewed;
  }

  /**
   * Cancels an entitlement, requiring a reason.
   *
   * @param command entitlementId + reason.
   */
  public static void cancel(CommercialEntitlementCommand command) {
    PartnerAccessService.assertInternalUser();
    if (String.isBlank(command.reason)) {
      throw new PartnerSyncHandledException(
        'A reason is required to cancel a commercial entitlement.'
      );
    }
    Customer_Commercial_Entitlement__c entitlement = CommercialEntitlementSelector.selectForUpdate(
      command.entitlementId
    );

    entitlement.Status__c = 'Cancelled';
    entitlement.Version_Number__c = coalesceVersion(entitlement) + 1;
    Database.update(entitlement, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'CommercialEntitlementCancelled',
      entitlement.Id,
      'Customer_Commercial_Entitlement__c',
      null,
      'A commercial entitlement was cancelled: ' + command.reason,
      'Warning'
    );
  }

  private static Integer coalesceVersion(
    Customer_Commercial_Entitlement__c entitlement
  ) {
    return entitlement.Version_Number__c == null
      ? 0
      : Integer.valueOf(entitlement.Version_Number__c);
  }
}
