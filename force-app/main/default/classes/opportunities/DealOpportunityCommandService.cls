/**
 * Executes Deal_Opportunity__c commands: link an existing Opportunity to a
 * deal, create a new Opportunity for a deal, unlink, set primary, or mark a
 * relationship historical (Sprint 39 §39.10-39.12, §39.43). Follows the same
 * FOR UPDATE + Version_Number__c pattern as every other command service in
 * this codebase.
 *
 * linkOpportunityToDeal never auto-links merely on a matching AccountId
 * (doc §39.11's explicit warning) - it runs the same eligibility-style
 * checks used at registration and returns a committed outcome rather than
 * throwing for every rejection, mirroring DealParticipantOutcome's framing.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class DealOpportunityCommandService {
  private static final String OVERRIDE_LINK_PERMISSION = 'PartnerSync_Override_Opportunity_Link';
  private static final String CREATE_PERMISSION = 'PartnerSync_Create_Deal_Opportunity';
  private static final String LINK_PERMISSION = 'PartnerSync_Link_Deal_Opportunity';
  private static final String UNLINK_PERMISSION = 'PartnerSync_Unlink_Deal_Opportunity';

  /**
   * Links an existing Opportunity to a deal as a new Deal_Opportunity__c
   * relationship, running the doc's linking eligibility checks first.
   *
   * @param command dealId, opportunityId, relationshipType, reason.
   * @return The outcome of the link attempt.
   */
  public static DealOpportunityOutcome linkOpportunityToDeal(
    DealOpportunityCommand command
  ) {
    PartnerAccessService.assertInternalUser();
    assertPermission(LINK_PERMISSION);
    if (command.dealId == null || command.opportunityId == null) {
      throw new PartnerSyncHandledException(
        'A deal and an opportunity are required to link them.'
      );
    }
    String relationshipType = String.isBlank(command.relationshipType)
      ? 'Secondary'
      : command.relationshipType;

    Deal_Registration__c deal = selectDeal(command.dealId);
    Opportunity opportunity = selectOpportunity(command.opportunityId);

    if (opportunity.IsClosed == true && relationshipType != 'Historical') {
      return new DealOpportunityOutcome(
        DealOpportunityOutcome.OPPORTUNITY_CLOSED,
        null,
        'This opportunity is already closed and cannot be linked as an active relationship.'
      );
    }

    if (
      DealOpportunitySelector.selectActiveLinkForOpportunity(opportunity.Id) !=
      null
    ) {
      return new DealOpportunityOutcome(
        DealOpportunityOutcome.ALREADY_LINKED,
        null,
        'This opportunity is already linked to a deal.'
      );
    }

    Boolean overrideGranted = DealLifecyclePermissionService.hasPermission(
      OVERRIDE_LINK_PERMISSION
    );
    if (
      !overrideGranted &&
      deal.Customer_Account__c != null &&
      opportunity.AccountId != deal.Customer_Account__c
    ) {
      return new DealOpportunityOutcome(
        DealOpportunityOutcome.ACCOUNT_MISMATCH,
        null,
        'This opportunity\'s account does not match the deal\'s customer account.'
      );
    }

    if (
      !DealRegistrationSelector.findConflictingDeals(
          opportunity.AccountId,
          deal.Id
        )
        .isEmpty()
    ) {
      return new DealOpportunityOutcome(
        DealOpportunityOutcome.COMMERCIAL_CONFLICT,
        null,
        'Another deal is already registered or approved for this customer account.'
      );
    }

    if (relationshipType == 'Co-Sell' && hasExclusiveProtection(deal.Id)) {
      return new DealOpportunityOutcome(
        DealOpportunityOutcome.PROTECTION_MISMATCH,
        null,
        'This deal has exclusive protection and cannot take on a co-sell opportunity relationship without amending protection first.'
      );
    }

    Deal_Opportunity_Policy__mdt policy = resolvePolicy();
    if (policy.Creation_Mode__c == 'Disabled') {
      return new DealOpportunityOutcome(
        DealOpportunityOutcome.LINK_REQUIRES_REVIEW,
        null,
        'Opportunity linking is disabled for this organisation and requires manual review.'
      );
    }

    Boolean makePrimary =
      DealOpportunitySelector.selectCurrentPrimary(deal.Id) == null;
    Deal_Opportunity__c relationship = insertRelationship(
      deal,
      opportunity,
      relationshipType,
      makePrimary
    );

    if (makePrimary) {
      DealSalesStageProjectionService.recompute(deal.Id);
    }

    PlatformEventPublisherService.publish(
      'OpportunityLinkedToDeal',
      deal.Id,
      'Deal_Registration__c',
      deal.Partner_Account__c,
      'An opportunity was linked to a deal.',
      'Info'
    );

    return new DealOpportunityOutcome(
      DealOpportunityOutcome.LINKED,
      relationship,
      'Linked.'
    );
  }

  /**
   * Creates a new Opportunity and links it to a deal, only when the
   * resolved policy's Creation_Mode__c allows PartnerSync to create
   * Opportunities directly.
   *
   * @param command dealId, relationshipType, reason.
   * @return The outcome of the creation attempt.
   */
  public static DealOpportunityOutcome createOpportunityForDeal(
    DealOpportunityCommand command
  ) {
    PartnerAccessService.assertInternalUser();
    assertPermission(CREATE_PERMISSION);
    if (command.dealId == null) {
      throw new PartnerSyncHandledException(
        'A deal is required to create an opportunity for it.'
      );
    }

    Deal_Opportunity_Policy__mdt policy = resolvePolicy();
    if (
      policy.Creation_Mode__c != 'Create New' &&
      policy.Creation_Mode__c != 'Create or Link'
    ) {
      throw new PartnerSyncHandledException(
        'This organisation\'s Opportunity policy does not allow PartnerSync to create opportunities directly.'
      );
    }

    Deal_Registration__c deal = selectDealForCreation(command.dealId);

    Opportunity opportunity = new Opportunity(
      Name = deal.Name + ' - ' + deal.Customer_Name__c,
      AccountId = deal.Customer_Account__c,
      Partner_Account__c = deal.Partner_Account__c,
      CloseDate = deal.Estimated_Close_Date__c != null
        ? deal.Estimated_Close_Date__c
        : Date.today().addDays(90),
      Amount = deal.Estimated_Revenue__c,
      StageName = resolveDefaultStageName()
    );
    Database.insert(opportunity, AccessLevel.SYSTEM_MODE);

    String relationshipType = String.isBlank(command.relationshipType)
      ? 'Primary'
      : command.relationshipType;
    Boolean makePrimary =
      DealOpportunitySelector.selectCurrentPrimary(deal.Id) == null;
    Deal_Opportunity__c relationship = insertRelationship(
      deal,
      opportunity,
      relationshipType,
      makePrimary
    );

    if (makePrimary) {
      DealSalesStageProjectionService.recompute(deal.Id);
    }

    PlatformEventPublisherService.publish(
      'OpportunityCreatedForDeal',
      deal.Id,
      'Deal_Registration__c',
      deal.Partner_Account__c,
      'A new opportunity was created for a deal.',
      'Info'
    );

    return new DealOpportunityOutcome(
      DealOpportunityOutcome.LINKED,
      relationship,
      'Created and linked.'
    );
  }

  /**
   * Marks a Deal_Opportunity__c relationship as no longer current.
   *
   * @param command dealOpportunityId, expectedVersion, reason.
   */
  public static void unlinkOpportunityFromDeal(DealOpportunityCommand command) {
    PartnerAccessService.assertInternalUser();
    assertPermission(UNLINK_PERMISSION);
    Deal_Opportunity__c relationship = selectAndCheckVersion(command);
    if (relationship.Primary__c == true) {
      throw new PartnerSyncHandledException(
        'The primary opportunity relationship cannot be unlinked directly - set a different primary first.'
      );
    }
    relationship.Current__c = false;
    relationship.Version_Number__c = versionAfter(relationship);
    Database.update(relationship, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'OpportunityUnlinkedFromDeal',
      relationship.Deal__c,
      'Deal_Registration__c',
      relationship.Partner_Account__c,
      'An opportunity was unlinked from a deal.',
      'Info'
    );
  }

  /**
   * Flips Primary__c across a deal's current relationships so exactly the
   * named relationship is primary.
   *
   * @param command dealOpportunityId, expectedVersion, reason.
   */
  public static void setPrimaryOpportunity(DealOpportunityCommand command) {
    PartnerAccessService.assertInternalUser();
    assertPermission(LINK_PERMISSION);
    Deal_Opportunity__c newPrimary = selectAndCheckVersion(command);

    List<Deal_Opportunity__c> siblings = DealOpportunitySelector.selectForDeal(
      newPrimary.Deal__c
    );
    List<Deal_Opportunity__c> toUpdate = new List<Deal_Opportunity__c>();
    for (Deal_Opportunity__c sibling : siblings) {
      if (sibling.Id == newPrimary.Id || sibling.Primary__c != true) {
        continue;
      }
      sibling.Primary__c = false;
      sibling.Version_Number__c = versionAfter(sibling);
      toUpdate.add(sibling);
    }

    newPrimary.Primary__c = true;
    newPrimary.Version_Number__c = versionAfter(newPrimary);
    toUpdate.add(newPrimary);

    Database.update(toUpdate, AccessLevel.SYSTEM_MODE);
    DealSalesStageProjectionService.recompute(newPrimary.Deal__c);

    PlatformEventPublisherService.publish(
      'PrimaryOpportunityChanged',
      newPrimary.Deal__c,
      'Deal_Registration__c',
      newPrimary.Partner_Account__c,
      'The deal\'s primary opportunity relationship changed.',
      'Info'
    );
  }

  /**
   * Marks a relationship Historical - no longer current, but its
   * Relationship_Type__c is preserved as a record of what it was rather
   * than a plain unlink.
   *
   * @param command dealOpportunityId, expectedVersion, reason.
   */
  public static void markOpportunityRelationshipHistorical(
    DealOpportunityCommand command
  ) {
    PartnerAccessService.assertInternalUser();
    assertPermission(UNLINK_PERMISSION);
    Deal_Opportunity__c relationship = selectAndCheckVersion(command);
    if (relationship.Primary__c == true) {
      throw new PartnerSyncHandledException(
        'The primary opportunity relationship cannot be marked historical directly - set a different primary first.'
      );
    }
    relationship.Relationship_Type__c = 'Historical';
    relationship.Current__c = false;
    relationship.Version_Number__c = versionAfter(relationship);
    Database.update(relationship, AccessLevel.SYSTEM_MODE);
  }

  // ---------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------

  private static void assertPermission(String permissionName) {
    if (!DealLifecyclePermissionService.hasPermission(permissionName)) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to perform this opportunity relationship action.'
      );
    }
  }

  private static Deal_Opportunity__c selectAndCheckVersion(
    DealOpportunityCommand command
  ) {
    if (command.dealOpportunityId == null) {
      throw new PartnerSyncHandledException(
        'A deal opportunity relationship is required for this command.'
      );
    }
    Deal_Opportunity__c relationship = DealOpportunitySelector.selectForUpdate(
      command.dealOpportunityId
    );
    Integer version = relationship.Version_Number__c == null
      ? 0
      : Integer.valueOf(relationship.Version_Number__c);
    if (command.expectedVersion == null || command.expectedVersion != version) {
      throw new PartnerSyncHandledException(
        'This opportunity relationship changed. Refresh before retrying.'
      );
    }
    return relationship;
  }

  private static Integer versionAfter(Deal_Opportunity__c relationship) {
    Integer current = relationship.Version_Number__c == null
      ? 0
      : Integer.valueOf(relationship.Version_Number__c);
    return current + 1;
  }

  private static Deal_Opportunity__c insertRelationship(
    Deal_Registration__c deal,
    Opportunity opportunity,
    String relationshipType,
    Boolean makePrimary
  ) {
    Deal_Opportunity__c relationship = new Deal_Opportunity__c(
      Deal__c = deal.Id,
      Opportunity__c = opportunity.Id,
      Partner_Account__c = deal.Partner_Account__c,
      Relationship_Type__c = relationshipType,
      Primary__c = makePrimary,
      Current__c = true,
      Relationship_Key__c = deal.Id + '|' + opportunity.Id,
      Version_Number__c = 0
    );
    // A duplicate-key insert failure (a concurrent link winning the race for
    // the same deal/opportunity pair) surfaces as a DmlException here - the
    // selectActiveLinkForOpportunity pre-check above is the common-case UX,
    // this is the hard backstop.
    Database.insert(relationship, AccessLevel.SYSTEM_MODE);
    return relationship;
  }

  private static Boolean hasExclusiveProtection(Id dealId) {
    List<Deal_Protection_Grant__c> grants = [
      SELECT Id, Exclusivity_Type__c
      FROM Deal_Protection_Grant__c
      WHERE Deal__c = :dealId AND Current__c = TRUE AND Status__c = 'Active'
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    return !grants.isEmpty() && grants[0].Exclusivity_Type__c == 'Exclusive';
  }

  private static Deal_Opportunity_Policy__mdt resolvePolicy() {
    List<Deal_Opportunity_Policy__mdt> rows = [
      SELECT
        Creation_Timing__c,
        Creation_Mode__c,
        Allow_Multiple_Opportunities__c,
        Maximum_Opportunities__c
      FROM Deal_Opportunity_Policy__mdt
      WHERE Active__c = TRUE
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException(
        'No active Deal Opportunity Policy is configured.'
      );
    }
    return rows[0];
  }

  private static String resolveDefaultStageName() {
    for (
      Schema.PicklistEntry entry : Opportunity.StageName.getDescribe()
        .getPicklistValues()
    ) {
      if (entry.isDefaultValue()) {
        return entry.getValue();
      }
    }
    List<Schema.PicklistEntry> active = Opportunity.StageName.getDescribe()
      .getPicklistValues();
    return active.isEmpty() ? null : active[0].getValue();
  }

  private static Deal_Registration__c selectDeal(Id dealId) {
    List<Deal_Registration__c> rows = [
      SELECT Id, Status__c, Customer_Account__c, Partner_Account__c
      FROM Deal_Registration__c
      WHERE Id = :dealId
      WITH SYSTEM_MODE
    ];
    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Deal registration not found.');
    }
    return rows[0];
  }

  private static Deal_Registration__c selectDealForCreation(Id dealId) {
    List<Deal_Registration__c> rows = [
      SELECT
        Id,
        Name,
        Customer_Name__c,
        Customer_Account__c,
        Partner_Account__c,
        Estimated_Revenue__c,
        Estimated_Close_Date__c
      FROM Deal_Registration__c
      WHERE Id = :dealId
      WITH SYSTEM_MODE
    ];
    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Deal registration not found.');
    }
    return rows[0];
  }

  private static Opportunity selectOpportunity(Id opportunityId) {
    List<Opportunity> rows = [
      SELECT Id, AccountId, IsClosed, IsWon, StageName
      FROM Opportunity
      WHERE Id = :opportunityId
      WITH SYSTEM_MODE
    ];
    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Opportunity not found.');
    }
    return rows[0];
  }
}
