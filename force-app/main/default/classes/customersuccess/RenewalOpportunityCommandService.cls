/**
 * Creates the Opportunity a renewal is tracked against, by delegating
 * directly to DealOpportunityCommandService.createOpportunityForDeal() -
 * that command is deal-centric, not new-deal-only, and already handles
 * primary-relationship bookkeeping, so no new Opportunity-integration
 * layer is built here (doc Sprint 42 point 5).
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class RenewalOpportunityCommandService {
  /**
   * Creates an Opportunity for a renewal's current deal (falling back to
   * its original deal if no current deal has been set yet), linking it
   * back onto the renewal as Current_Opportunity__c.
   *
   * @param command renewalId + expectedVersion.
   * @return The updated renewal.
   */
  public static Partner_Renewal__c createOpportunityForRenewal(
    RenewalCommand command
  ) {
    PartnerAccessService.assertInternalUser();
    if (command.renewalId == null) {
      throw new PartnerSyncHandledException(
        'A renewal is required to create an opportunity for it.'
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
    Id dealId = renewal.Current_Deal__c == null
      ? renewal.Original_Deal__c
      : renewal.Current_Deal__c;
    if (dealId == null) {
      throw new PartnerSyncHandledException(
        'This renewal has no deal to create an opportunity for.'
      );
    }

    DealOpportunityCommand createCommand = new DealOpportunityCommand();
    createCommand.dealId = dealId;
    createCommand.relationshipType = 'Primary';
    DealOpportunityOutcome outcome = DealOpportunityCommandService.createOpportunityForDeal(
      createCommand
    );

    renewal.Current_Deal__c = dealId;
    renewal.Current_Opportunity__c = outcome.relationship?.Opportunity__c;
    renewal.Version_Number__c = coalesceVersion(renewal) + 1;
    Database.update(renewal, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'RenewalOpportunityCreated',
      renewal.Id,
      'Partner_Renewal__c',
      renewal.Primary_Partner__c,
      'An opportunity was created for a renewal.',
      'Info'
    );

    return renewal;
  }

  private static Integer coalesceVersion(Partner_Renewal__c renewal) {
    return renewal.Version_Number__c == null
      ? 0
      : Integer.valueOf(renewal.Version_Number__c);
  }
}
