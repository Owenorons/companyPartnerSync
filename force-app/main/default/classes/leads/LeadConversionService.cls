public with sharing class LeadConversionService {
  public static LeadConversionResultDTO convertLead(
    LeadConversionRequestDTO request
  ) {
    if (!TenantConfigService.isDealsEnabled()) {
      throw new PartnerSyncHandledException('Deal registration is disabled.');
    }

    LeadConversionDomain.validate(request);

    SecurityUtil.assertCreateable(Opportunity.SObjectType);

    SecurityUtil.assertCreateable(Deal_Registration__c.SObjectType);

    SecurityUtil.assertUpdateable(Lead.SObjectType);

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    Lead lead = LeadDistributionSelector.selectPartnerLeadById(
      request.leadId,
      partnerAccountId
    );

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

    insert sanitizedOpportunities;

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

    lead.Converted_Deal__c = deal.Id;

    lead.Lead_Distribution_Status__c = 'Converted';

    update SecurityUtil.stripForUpdate(new List<SObject>{ lead });

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
