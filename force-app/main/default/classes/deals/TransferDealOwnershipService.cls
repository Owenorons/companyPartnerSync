/**
 * Governed primary-partner transfer (doc §38.41): validates the
 * destination partner and relationship, always re-runs conflict analysis
 * and review/approval reassessment (unconditionally - a transfer is
 * always material, not policy-gated like DealParticipantChangePolicyService's
 * other change types), supersedes the old originating Deal_Participant__c
 * and creates the new one, amends the current protection grant, updates
 * the Deal_Registration__c.Partner_Account__c projection under its own
 * lock, and recalculates sharing. This is the first governance ever
 * placed on Partner_Account__c - no validation rule/trigger/flow
 * constrained it before this.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class TransferDealOwnershipService {
  /**
   * Executes a governed ownership transfer.
   *
   * @param command The transfer request.
   */
  public static void execute(TransferDealOwnershipCommand command) {
    if (
      !PermissionService.hasCustomPermission(
        'PartnerSync_Transfer_Deal_Ownership'
      )
    ) {
      throw new PartnerSyncHandledException(
        'You do not have permission to transfer deal ownership.'
      );
    }

    if (
      command == null ||
      command.dealId == null ||
      command.newPartnerAccountId == null
    ) {
      throw new PartnerSyncHandledException(
        'A deal and a destination partner account are required.'
      );
    }

    List<Deal_Registration__c> deals = [
      SELECT Id, Partner_Account__c, Version_Number__c
      FROM Deal_Registration__c
      WHERE Id = :command.dealId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];
    if (deals.isEmpty()) {
      throw new PartnerSyncHandledException('Deal registration not found.');
    }
    Deal_Registration__c deal = deals[0];

    Integer dealVersion = deal.Version_Number__c == null
      ? 0
      : Integer.valueOf(deal.Version_Number__c);
    if (
      command.expectedDealVersion == null ||
      command.expectedDealVersion != dealVersion
    ) {
      throw new PartnerSyncHandledException(
        'The deal changed. Refresh and retry.'
      );
    }

    if (deal.Partner_Account__c == command.newPartnerAccountId) {
      throw new PartnerSyncHandledException(
        'The destination partner already owns this deal.'
      );
    }

    List<Account> destinationPartners = [
      SELECT Id, Partner_Status__c
      FROM Account
      WHERE Id = :command.newPartnerAccountId
      WITH SYSTEM_MODE
    ];
    if (
      destinationPartners.isEmpty() ||
      destinationPartners[0].Partner_Status__c != 'Active'
    ) {
      throw new PartnerSyncHandledException(
        'The destination partner account is not active.'
      );
    }

    PartnerAccountRelationshipService.requireActiveRelationship(
      deal.Partner_Account__c,
      command.newPartnerAccountId
    );

    // Always required for a transfer, unlike DealParticipantChangePolicyService's
    // other change types - not gated behind Deal_Participant_Change_Policy__mdt.
    DealConflictCommandService.reanalyseForMaterialChange(deal.Id);
    DealReviewPlanService.generate(new Set<Id>{ deal.Id });

    Datetime now = System.now();

    for (Deal_Participant__c existingOriginating : [
      SELECT Id, Version_Number__c
      FROM Deal_Participant__c
      WHERE
        Deal__c = :deal.Id
        AND Participant_Type__c = 'Originating Partner'
        AND Status__c = 'Active'
      WITH SYSTEM_MODE
      FOR UPDATE
    ]) {
      existingOriginating.Status__c = 'Superseded';
      existingOriginating.Effective_To__c = now;
      existingOriginating.Active_Participant_Key__c = null;
      existingOriginating.Version_Number__c =
        (existingOriginating.Version_Number__c == null
          ? 0
          : Integer.valueOf(existingOriginating.Version_Number__c)) + 1;
      Database.update(existingOriginating, AccessLevel.SYSTEM_MODE);
    }

    Database.insert(
      new Deal_Participant__c(
        Deal__c = deal.Id,
        Partner_Account__c = command.newPartnerAccountId,
        Participant_Type__c = 'Originating Partner',
        Participant_Role__c = 'Deal Owner',
        Status__c = 'Active',
        Access_Level__c = 'Full Partner',
        Effective_From__c = now,
        Last_Activity_On__c = now,
        Invitation_Reason__c = command.reason,
        Version_Number__c = 0
      ),
      AccessLevel.SYSTEM_MODE
    );

    // Protection amendment (Known Adaptation #1): no versioned grant
    // chain exists yet, so a transfer bumps the current grant's
    // Version_Number__c as a signal that its commercial ownership
    // changed, rather than creating a new protection version.
    for (Deal_Protection_Grant__c grant : [
      SELECT Id, Version_Number__c
      FROM Deal_Protection_Grant__c
      WHERE Deal__c = :deal.Id AND Current__c = TRUE
      WITH SYSTEM_MODE
      FOR UPDATE
    ]) {
      grant.Version_Number__c =
        (grant.Version_Number__c == null
          ? 0
          : Integer.valueOf(grant.Version_Number__c)) + 1;
      Database.update(grant, AccessLevel.SYSTEM_MODE);
    }

    deal.Partner_Account__c = command.newPartnerAccountId;
    deal.Version_Number__c = dealVersion + 1;
    Database.update(deal, AccessLevel.SYSTEM_MODE);

    DealParticipantSharingService.reconcileForDeal(deal.Id);

    PlatformEventPublisherService.publish(
      'DealOwnershipTransferred',
      deal.Id,
      'Deal_Registration__c',
      command.newPartnerAccountId,
      'Deal ownership was transferred to a new partner.',
      'Info'
    );

    LoggingService.info(
      'TransferDealOwnershipService',
      'Deal ownership transferred. DealId=' + deal.Id
    );
  }
}
