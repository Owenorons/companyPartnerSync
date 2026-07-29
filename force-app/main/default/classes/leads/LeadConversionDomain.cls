/*
 * Domain layer for LeadConversionService: validates a conversion request and
 * shapes the resulting Opportunity/result DTO. Handles the "turn an accepted
 * lead into partner-visible deal records" step — LeadDistributionDomain
 * covers the earlier assignment/accept/reject validation and status mapping,
 * not conversion.
 */
public with sharing class LeadConversionDomain {
  public static void validate(LeadConversionRequestDTO request) {
    if (request == null) {
      throw new PartnerSyncHandledException(
        'Lead conversion request is required.'
      );
    }

    if (request.leadId == null) {
      throw new PartnerSyncHandledException('Lead Id is required.');
    }

    if (String.isBlank(request.opportunityName)) {
      throw new PartnerSyncHandledException('Opportunity name is required.');
    }

    if (request.estimatedCloseDate == null) {
      throw new PartnerSyncHandledException(
        'Estimated close date is required.'
      );
    }
  }

  public static Opportunity buildOpportunity(
    Lead lead,
    Id customerAccountId,
    LeadConversionRequestDTO request
  ) {
    Opportunity opportunity = new Opportunity();

    opportunity.Name = request.opportunityName;

    opportunity.AccountId = customerAccountId;

    opportunity.Partner_Account__c = lead.Partner_Account__c;

    opportunity.Partner_Contact__c = lead.Partner_Contact__c;

    opportunity.StageName = String.isBlank(request.stageName)
      ? 'Qualification'
      : request.stageName;

    opportunity.CloseDate = request.estimatedCloseDate;

    opportunity.Amount = request.estimatedValue;

    opportunity.Lead_Source__c = 'Partner Lead';

    opportunity.Source_Lead__c = lead.Id;

    // 'Pending Registration' reflects that LeadConversionService creates the
    // Deal_Registration__c record immediately after this Opportunity insert;
    // this status is a placeholder, not a terminal state.
    opportunity.Partner_Deal_Status__c = 'Pending Registration';

    return opportunity;
  }

  public static LeadConversionResultDTO buildResult(
    Lead lead,
    Opportunity opportunity,
    Deal_Registration__c deal,
    Boolean customerAccountCreated
  ) {
    LeadConversionResultDTO dto = new LeadConversionResultDTO();

    dto.leadId = lead.Id;
    dto.opportunityId = opportunity.Id;
    dto.dealRegistrationId = deal.Id;
    dto.customerAccountId = opportunity.AccountId;
    dto.customerAccountCreated = customerAccountCreated;

    return dto;
  }
}
