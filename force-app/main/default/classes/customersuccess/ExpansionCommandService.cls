/**
 * Executes Partner_Expansion__c commands: identify, qualify (resolves
 * Expansion_Policy__mdt - doc section 42.35's critical rule: a minor
 * expansion within Minor_Expansion_Threshold_Percentage__c may stay
 * Minor-Approved with no new deal per section 42.38; anything else, or no
 * matching policy row, defaults to Requires_New_Deal__c per the org-level
 * wildcard row), createExpansionDeal (only reachable from New Deal
 * Required - routes through the real, unmodified PDLM registration
 * pipeline, no bypass), and complete (books Expansion-type revenue via
 * RevenueCommandService.importRevenue(), the same explicit
 * internal-command pattern RenewalCommandService.markRenewed() uses - not
 * an automatic batch hook, since no automatic Closed-Won revenue hook
 * exists anywhere in this codebase today for revenue booking).
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ExpansionCommandService {
  // CMDT org-singleton - per-test-case seeding isn't possible, so tests
  // override this the same way IncentiveCommandService/RenewalPolicyResolver
  // do.
  @TestVisible
  private static Expansion_Policy__mdt testPolicyOverride;

  /**
   * Identifies a new expansion opportunity for a customer.
   *
   * @param command engagementId + customerAccountId + expansionType + description.
   * @return The inserted expansion.
   */
  public static Partner_Expansion__c identify(ExpansionCommand command) {
    PartnerAccessService.assertInternalUser();
    if (
      command.customerSuccessEngagementId == null ||
      command.customerAccountId == null ||
      String.isBlank(command.expansionType)
    ) {
      throw new PartnerSyncHandledException(
        'A customer success engagement, customer account, and expansion type are required.'
      );
    }

    Partner_Expansion__c expansion = new Partner_Expansion__c(
      Customer_Success_Engagement__c = command.customerSuccessEngagementId,
      Customer_Account__c = command.customerAccountId,
      Originating_Deal__c = command.originatingDealId,
      Primary_Partner__c = command.primaryPartnerId,
      Expansion_Type__c = command.expansionType,
      Description__c = command.description,
      Status__c = 'Identified',
      Identified_On__c = System.now(),
      Version_Number__c = 0
    );
    Database.insert(expansion, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'ExpansionIdentified',
      expansion.Id,
      'Partner_Expansion__c',
      expansion.Primary_Partner__c,
      'A partner expansion opportunity was identified.',
      'Info'
    );

    return expansion;
  }

  /**
   * Qualifies an expansion, deciding whether it stays minor (no new deal)
   * or requires a full new deal, per the resolved Expansion_Policy__mdt.
   *
   * @param command expansionId + expectedVersion + estimatedPercentageIncrease.
   * @return The updated expansion.
   */
  public static Partner_Expansion__c qualify(ExpansionCommand command) {
    assertManageExpansionAuthority();
    Partner_Expansion__c expansion = requireExpectedVersion(command);
    if (expansion.Status__c != 'Identified') {
      throw new PartnerSyncHandledException(
        'Only an Identified expansion can be qualified.'
      );
    }

    Expansion_Policy__mdt policy = resolvePolicy(expansion.Expansion_Type__c);
    Boolean staysMinor =
      policy.Requires_New_Deal__c != true &&
      command.estimatedPercentageIncrease != null &&
      policy.Minor_Expansion_Threshold_Percentage__c != null &&
      command.estimatedPercentageIncrease <=
      policy.Minor_Expansion_Threshold_Percentage__c;

    expansion.Status__c = staysMinor ? 'Minor-Approved' : 'New Deal Required';
    expansion.Qualified_On__c = System.now();
    persist(expansion);

    publish(
      expansion,
      staysMinor ? 'ExpansionQualified' : 'ExpansionDealRequired',
      'A partner expansion was qualified as ' + expansion.Status__c + '.',
      'Info'
    );
    return expansion;
  }

  /**
   * Creates a brand-new Deal_Registration__c for a major expansion, only
   * reachable from New Deal Required, and only ever through the real,
   * unmodified registration pipeline
   * (DealRegistrationService.createDealRegistrationInternal(), which itself
   * runs the full validate/conflict/approval flow) - provenance
   * (Origin_Type__c/Parent_Deal__c/Originating_Customer_Success__c) is
   * annotated afterward, never used to skip a check.
   *
   * @param command expansionId + expectedVersion + business case fields for the new deal.
   * @return The updated expansion, linked to the new deal.
   */
  public static Partner_Expansion__c createExpansionDeal(
    ExpansionCommand command
  ) {
    assertManageExpansionAuthority();
    Partner_Expansion__c expansion = requireExpectedVersion(command);
    if (expansion.Status__c != 'New Deal Required') {
      throw new PartnerSyncHandledException(
        'An expansion deal can only be created once qualification determines a new deal is required.'
      );
    }

    Opportunity expansionOpportunity = new Opportunity(
      Name = 'Expansion - ' + expansion.Id,
      AccountId = expansion.Customer_Account__c,
      Partner_Account__c = expansion.Primary_Partner__c,
      StageName = resolveDefaultStageName(),
      CloseDate = command.estimatedCloseDate == null
        ? Date.today().addDays(90)
        : command.estimatedCloseDate,
      Amount = command.estimatedRevenue
    );
    Database.insert(expansionOpportunity, AccessLevel.SYSTEM_MODE);

    DealRegistrationRequestDTO request = new DealRegistrationRequestDTO();
    request.opportunityId = expansionOpportunity.Id;
    request.businessProblem = command.businessProblem;
    request.proposedSolution = command.proposedSolution;
    request.estimatedRevenue = command.estimatedRevenue;
    request.estimatedCloseDate = command.estimatedCloseDate;

    Deal_Registration__c newDeal = DealRegistrationService.createDealRegistrationInternal(
      expansionOpportunity,
      request
    );

    Database.update(
      new Deal_Registration__c(
        Id = newDeal.Id,
        Origin_Type__c = 'Expansion',
        Parent_Deal__c = expansion.Originating_Deal__c,
        Originating_Customer_Success__c = expansion.Customer_Success_Engagement__c
      ),
      AccessLevel.SYSTEM_MODE
    );

    expansion.Status__c = 'Deal Created';
    expansion.Resulting_Deal__c = newDeal.Id;
    persist(expansion);

    publish(
      expansion,
      'ExpansionDealCreated',
      'A new deal was created for a partner expansion.',
      'Info'
    );
    return expansion;
  }

  /**
   * Completes an expansion once its commercial outcome is real: a minor
   * expansion completes directly, a major expansion requires its resulting
   * deal to have actually closed won. Books Expansion-type revenue via
   * RevenueCommandService.importRevenue() when an amount is given.
   *
   * @param command expansionId + expectedVersion + completedAmount.
   * @return The updated expansion.
   */
  public static Partner_Expansion__c complete(ExpansionCommand command) {
    assertManageExpansionAuthority();
    Partner_Expansion__c expansion = requireExpectedVersion(command);

    Id revenueDealId;
    if (expansion.Status__c == 'Minor-Approved') {
      revenueDealId = expansion.Originating_Deal__c;
    } else if (expansion.Status__c == 'Deal Created') {
      if (expansion.Resulting_Deal__c == null) {
        throw new PartnerSyncHandledException(
          'This expansion has no resulting deal to complete.'
        );
      }
      List<Deal_Registration__c> resultingDeals = [
        SELECT Stage__c
        FROM Deal_Registration__c
        WHERE Id = :expansion.Resulting_Deal__c
        WITH SYSTEM_MODE
      ];
      if (
        resultingDeals.isEmpty() || resultingDeals[0].Stage__c != 'Closed Won'
      ) {
        throw new PartnerSyncHandledException(
          'The expansion\'s resulting deal has not closed won yet.'
        );
      }
      revenueDealId = expansion.Resulting_Deal__c;
    } else {
      throw new PartnerSyncHandledException(
        'This expansion is not in a state that can be completed.'
      );
    }

    expansion.Status__c = 'Completed';
    persist(expansion);

    if (command.completedAmount != null) {
      RevenueImportRequest request = new RevenueImportRequest();
      request.sourceType = 'Manual';
      request.explicitDealId = revenueDealId;
      request.revenueType = 'Expansion';
      request.grossAmount = command.completedAmount;
      request.netAmount = command.completedAmount;
      request.externalRevenueKey = 'expansion-' + expansion.Id;
      request.revenueDate = Date.today();
      RevenueCommandService.importRevenue(request);
    }

    publish(
      expansion,
      'ExpansionCompleted',
      'A partner expansion was completed.',
      'Info'
    );
    return expansion;
  }

  private static void assertManageExpansionAuthority() {
    if (
      !PartnerAccessService.isInternalUser() ||
      !DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Manage_Expansion'
      )
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to manage this partner expansion.'
      );
    }
  }

  private static Expansion_Policy__mdt resolvePolicy(String expansionType) {
    if (Test.isRunningTest() && testPolicyOverride != null) {
      return testPolicyOverride;
    }
    if (String.isNotBlank(expansionType)) {
      List<Expansion_Policy__mdt> exactMatches = [
        SELECT Minor_Expansion_Threshold_Percentage__c, Requires_New_Deal__c
        FROM Expansion_Policy__mdt
        WHERE Active__c = TRUE AND Expansion_Type__c = :expansionType
        WITH SYSTEM_MODE
        ORDER BY Priority__c DESC NULLS LAST
        LIMIT 1
      ];
      if (!exactMatches.isEmpty()) {
        return exactMatches[0];
      }
    }
    List<Expansion_Policy__mdt> fallback = [
      SELECT Minor_Expansion_Threshold_Percentage__c, Requires_New_Deal__c
      FROM Expansion_Policy__mdt
      WHERE Active__c = TRUE AND Expansion_Type__c = NULL
      WITH SYSTEM_MODE
      ORDER BY Priority__c DESC NULLS LAST
      LIMIT 1
    ];
    return fallback.isEmpty()
      ? new Expansion_Policy__mdt(Requires_New_Deal__c = true)
      : fallback[0];
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
    return null;
  }

  private static Partner_Expansion__c requireExpectedVersion(
    ExpansionCommand command
  ) {
    if (command.expansionId == null) {
      throw new PartnerSyncHandledException(
        'An expansion is required for this command.'
      );
    }
    Partner_Expansion__c expansion = ExpansionSelector.selectForUpdate(
      command.expansionId
    );
    if (
      command.expectedVersion != null &&
      coalesceVersion(expansion) != command.expectedVersion
    ) {
      throw new PartnerSyncHandledException(
        'This expansion has changed since it was loaded - refresh and try again.'
      );
    }
    return expansion;
  }

  private static void persist(Partner_Expansion__c expansion) {
    expansion.Version_Number__c = coalesceVersion(expansion) + 1;
    Database.update(expansion, AccessLevel.SYSTEM_MODE);
  }

  private static Integer coalesceVersion(Partner_Expansion__c expansion) {
    return expansion.Version_Number__c == null
      ? 0
      : Integer.valueOf(expansion.Version_Number__c);
  }

  private static void publish(
    Partner_Expansion__c expansion,
    String eventType,
    String summary,
    String severity
  ) {
    PlatformEventPublisherService.publish(
      eventType,
      expansion.Id,
      'Partner_Expansion__c',
      expansion.Primary_Partner__c,
      summary,
      severity
    );
  }
}
