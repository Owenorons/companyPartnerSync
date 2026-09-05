/*
 * Orchestrates converting an accepted Lead into an Opportunity and Deal
 * Registration. This is the "conversion" half of the lead lifecycle — it
 * only operates on leads that have already been through the assignment
 * (LeadDistributionService) and acceptance (LeadDecisionService) steps.
 */
public with sharing class LeadConversionService {
  public static LeadConversionResultDTO convertLead(
    LeadConversionRequestDTO request
  ) {
    if (!TenantConfigService.isDealsEnabled()) {
      throw new PartnerSyncHandledException('Deal registration is disabled.');
    }

    LeadConversionDomain.validate(request);

    // The packaged partner permission set intentionally grants read-only
    // access to Lead and Opportunity. Conversion is therefore an internal
    // CRM operation, not a partner self-service capability.
    PartnerAccessService.assertInternalUser();

    SecurityUtil.assertCreateable(Opportunity.SObjectType);

    SecurityUtil.assertCreateable(Deal_Registration__c.SObjectType);

    SecurityUtil.assertUpdateable(Lead.SObjectType);

    PartnerRecordAccessService.assertPartnerAccessToLead(request.leadId);

    Lead lead = LeadDistributionSelector.selectInternalLead(request.leadId);

    // Conversion requires the partner to have already accepted the lead via
    // LeadDecisionService; this blocks internal admins from converting a
    // lead the partner hasn't (or has explicitly declined to) sign off on.
    if (lead.Lead_Distribution_Status__c != 'Accepted') {
      throw new PartnerSyncHandledException(
        'Only accepted leads can be converted.'
      );
    }

    CustomerAccountMatchDTO customerMatch = CustomerAccountService.findOrCreateCustomerAccount(
      lead
    );

    Opportunity opportunity = LeadConversionDomain.buildOpportunity(
      lead,
      customerMatch.accountId,
      request
    );

    List<SObject> sanitizedOpportunities = SecurityUtil.stripForCreate(
      new List<SObject>{ opportunity }
    );

    Database.insert(sanitizedOpportunities, AccessLevel.USER_MODE);

    Opportunity insertedOpportunity = (Opportunity) sanitizedOpportunities[0];

    DealRegistrationRequestDTO dealRequest = new DealRegistrationRequestDTO();

    dealRequest.opportunityId = insertedOpportunity.Id;

    dealRequest.estimatedRevenue = request.estimatedValue;

    dealRequest.estimatedCloseDate = request.estimatedCloseDate;

    dealRequest.notes = request.notes;

    Deal_Registration__c deal = DealRegistrationService.createDealRegistrationInternal(
      insertedOpportunity,
      dealRequest
    );

    // Only flip the lead to 'Converted' after the Opportunity and Deal
    // Registration above have already committed, so a failure earlier in
    // this method leaves the lead 'Accepted' (safe to retry) instead of
    // marking it converted without the records that should back that up.
    lead.Converted_Deal__c = deal.Id;

    lead.Lead_Distribution_Status__c = 'Converted';

    update SecurityUtil.stripForUpdate(new List<SObject>{ lead });

    PlatformEventPublisherService.publish(
      'LeadConverted',
      lead.Id,
      'Lead',
      lead.Partner_Account__c,
      'Lead converted to a deal registration.',
      'Info'
    );

    LoggingService.info(
      'LeadConversionService',
      'Lead converted successfully. LeadId=' + lead.Id
    );

    return LeadConversionDomain.buildResult(
      lead,
      insertedOpportunity,
      deal,
      customerMatch.created
    );
  }
}
