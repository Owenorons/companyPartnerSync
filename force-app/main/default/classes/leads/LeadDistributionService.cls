/**
 * Routes a Lead to a partner account/contact and starts its SLA clock — the
 * first step of the lead lifecycle, upstream of LeadDecisionService
 * (accept/reject) and LeadConversionService (conversion to a deal). This
 * class assigns leads; it never converts them into Opportunity/Deal
 * Registration records.
 *
 * Two entry points share the same underlying assignment: assignLeadToPartner
 * is a human explicitly picking the partner (Manual strategy);
 * distributeLead resolves the partner automatically from active
 * Lead_Distribution_Rule__mdt records. Both create a durable
 * Partner_Lead_Assignment__c record rather than only mutating Lead fields,
 * so a lead's full assignment history (including a rejected-then-reassigned
 * chain) survives rather than being overwritten.
 */
public with sharing class LeadDistributionService {
  /**
   * Assigns a Lead to a partner account/contact and starts its SLA clock.
   *
   * @param request The lead assignment request.
   */
  public static void assignLeadToPartner(LeadAssignmentRequestDTO request) {
    if (!TenantConfigService.isLeadsEnabled()) {
      throw new PartnerSyncHandledException('Lead distribution is disabled.');
    }

    // Assignment is gated by a dedicated internal-only permission set, not
    // just Lead update access — otherwise anyone with generic Lead edit
    // rights could reroute leads across partner territories.
    PartnerPermissionService.assertCanAssignLeads();

    LeadDistributionDomain.validateAssignment(request);

    SecurityUtil.assertUpdateable(Lead.SObjectType);

    validatePartnerAccount(request.partnerAccountId);

    if (request.partnerContactId != null) {
      validatePartnerContact(
        request.partnerContactId,
        request.partnerAccountId
      );
    }

    if (request.customerAccountId != null) {
      CustomerAccountSelector.selectCustomerAccountById(
        request.customerAccountId
      );
    }

    Lead lead = LeadDistributionSelector.selectInternalLead(request.leadId);
    lead.Customer_Account__c = request.customerAccountId;

    assertNoActiveAssignment(lead.Id);

    Integer slaHours = request.slaHoursOverride != null
      ? request.slaHoursOverride
      : TenantConfigService.getLeadSlaHours();

    createAssignment(
      lead,
      request.partnerAccountId,
      request.partnerContactId,
      'Manual',
      null,
      'Manually assigned by an internal user.',
      slaHours,
      request.notes
    );
  }

  /**
   * Automatically distributes a Lead to a partner using the highest-priority active
   * Lead_Distribution_Rule__mdt record whose criteria match the lead and whose distribution
   * method has an implemented LeadAssignmentStrategy. A rule that matches but has no
   * implemented strategy (e.g. Territory, Product Specialization, Partner Tier, AI
   * Recommendation - none built yet) is skipped rather than failing the whole distribution
   * attempt, so already-configured-but-unbuilt rules don't block the ones that are ready.
   *
   * @param leadId Id of the lead to distribute.
   */
  public static void distributeLead(Id leadId) {
    if (!TenantConfigService.isLeadsEnabled()) {
      throw new PartnerSyncHandledException('Lead distribution is disabled.');
    }

    PartnerPermissionService.assertCanAssignLeads();

    if (leadId == null) {
      throw new PartnerSyncHandledException('Lead Id is required.');
    }

    SecurityUtil.assertUpdateable(Lead.SObjectType);

    Lead lead = LeadDistributionSelector.selectInternalLead(leadId);

    assertNoActiveAssignment(lead.Id);

    List<Account> activePartners = PartnerLeadAssignmentSelector.selectActivePartnerAccounts();

    for (
      Lead_Distribution_Rule__mdt rule : PartnerLeadAssignmentSelector.selectActiveRules()
    ) {
      if (!matchesLead(rule, lead)) {
        continue;
      }

      LeadAssignmentStrategy strategy = strategyFor(
        rule.Distribution_Method__c
      );
      if (strategy == null) {
        continue;
      }

      List<Id> candidates = eligibleCandidateIds(rule, activePartners);
      if (candidates.isEmpty()) {
        throw new PartnerSyncHandledException(
          'No eligible partner is available for this lead.'
        );
      }

      Id selectedPartnerAccountId = strategy.selectPartner(candidates);
      if (selectedPartnerAccountId == null) {
        throw new PartnerSyncHandledException(
          'No eligible partner is available for this lead.'
        );
      }

      createAssignment(
        lead,
        selectedPartnerAccountId,
        null,
        rule.Distribution_Method__c,
        rule.DeveloperName,
        'Distributed by rule ' +
          rule.DeveloperName +
          ' (' +
          rule.Distribution_Method__c +
          ').',
        TenantConfigService.getLeadSlaHours(),
        null
      );
      return;
    }

    throw new PartnerSyncHandledException(
      'No active distribution rule with an implemented strategy applies to this lead.'
    );
  }

  /**
   * Loads the leads currently visible to the signed-in partner user.
   *
   * @return The signed-in partner's leads.
   */
  public static List<LeadDistributionDTO> getMyLeads() {
    if (!TenantConfigService.isLeadsEnabled()) {
      throw new PartnerSyncHandledException('Lead distribution is disabled.');
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    List<LeadDistributionDTO> results = new List<LeadDistributionDTO>();

    for (
      Lead lead : LeadDistributionSelector.selectAssignedLeadsByPartner(
        partnerAccountId
      )
    ) {
      results.add(LeadDistributionDomain.toDTO(lead));
    }

    return results;
  }

  private static void assertNoActiveAssignment(Id leadId) {
    if (PartnerLeadAssignmentSelector.selectActiveForLead(leadId) != null) {
      throw new PartnerSyncHandledException(
        'This lead already has an active assignment awaiting a partner decision.'
      );
    }
  }

  private static void createAssignment(
    Lead lead,
    Id partnerAccountId,
    Id partnerContactId,
    String strategy,
    String ruleKey,
    String routingReason,
    Integer slaHours,
    String notes
  ) {
    lead.Partner_Account__c = partnerAccountId;
    lead.Partner_Contact__c = partnerContactId;
    lead.Lead_Distribution_Status__c = 'Assigned';
    lead.Assigned_Date__c = System.now();
    lead.Response_SLA_Hours__c = slaHours;
    lead.SLA_Deadline__c = System.now().addHours(slaHours);

    update SecurityUtil.stripForUpdate(new List<SObject>{ lead });

    Database.insert(
      new Partner_Lead_Assignment__c(
        Lead__c = lead.Id,
        Partner_Account__c = partnerAccountId,
        Partner_Contact__c = partnerContactId,
        Status__c = 'Assigned',
        Assignment_Strategy__c = strategy,
        Distribution_Rule_Key__c = ruleKey,
        Routing_Reason__c = routingReason,
        Assigned_On__c = lead.Assigned_Date__c,
        Response_Due_On__c = lead.SLA_Deadline__c,
        Active_Assignment_Key__c = String.valueOf(lead.Id),
        Version_Number__c = 0
      ),
      AccessLevel.SYSTEM_MODE
    );

    UsageMetricService.log(
      partnerAccountId,
      UsageMetricService.METRIC_TYPE_LEAD_ASSIGNED
    );

    LeadDistributionLogService.logAction(
      lead.Id,
      partnerAccountId,
      partnerContactId,
      'Assigned',
      'Assigned',
      notes
    );

    LoggingService.info(
      'LeadDistributionService',
      'Lead assigned to partner. LeadId=' + lead.Id + ' Strategy=' + strategy
    );
  }

  // Region__c has no corresponding field on Lead (this org has no lead
  // territory/region field), so only Country and Industry are matched here.
  // A blank criterion always matches - the seeded rules ship with every
  // criterion blank, so every rule applies to every lead until an admin
  // configures otherwise.
  private static Boolean matchesLead(
    Lead_Distribution_Rule__mdt rule,
    Lead lead
  ) {
    if (String.isNotBlank(rule.Country__c) && rule.Country__c != lead.Country) {
      return false;
    }
    if (
      String.isNotBlank(rule.Industry__c) && rule.Industry__c != lead.Industry
    ) {
      return false;
    }
    return true;
  }

  private static List<Id> eligibleCandidateIds(
    Lead_Distribution_Rule__mdt rule,
    List<Account> activePartners
  ) {
    List<Id> candidates = new List<Id>();
    for (Account partner : activePartners) {
      if (
        String.isNotBlank(rule.Partner_Tier__c) &&
        rule.Partner_Tier__c != partner.Partner_Tier__c
      ) {
        continue;
      }
      if (
        String.isNotBlank(rule.Partner_Type__c) &&
        rule.Partner_Type__c != partner.Partner_Type__c
      ) {
        continue;
      }
      candidates.add(partner.Id);
    }
    return candidates;
  }

  private static LeadAssignmentStrategy strategyFor(String distributionMethod) {
    if (distributionMethod == 'Round Robin') {
      return new RoundRobinAssignmentStrategy();
    }
    return null;
  }

  private static void validatePartnerAccount(Id partnerAccountId) {
    LeadDistributionSelector.selectActivePartnerAccount(partnerAccountId);
  }

  private static void validatePartnerContact(
    Id contactId,
    Id partnerAccountId
  ) {
    LeadDistributionSelector.selectPartnerContact(contactId, partnerAccountId);
  }
}
