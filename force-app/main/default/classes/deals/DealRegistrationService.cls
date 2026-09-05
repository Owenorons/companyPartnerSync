/*
 * Orchestrates creation of a partner deal registration: ownership checks,
 * duplicate-registration guard, insert, conflict detection, and initial
 * status routing. This is the registration-side service; DealReviewService
 * is the separate service that handles what internal reviewers do to a
 * deal after it lands here (approve/reject/resolve conflict/extend
 * protection).
 */
public with sharing class DealRegistrationService {
  public static DealRegistrationResultDTO createDealRegistration(
    DealRegistrationRequestDTO request
  ) {
    if (!TenantConfigService.isDealsEnabled()) {
      throw new PartnerSyncHandledException('Deal registration is disabled.');
    }

    PartnerAccessService.assertCanSubmitDeal();

    DealRegistrationDomain.validate(request);

    SecurityUtil.assertCreateable(Deal_Registration__c.SObjectType);

    Opportunity opportunity = DealRegistrationSelector.selectOpportunityForRegistration(
      request.opportunityId
    );

    Id currentPartnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    if (opportunity.Partner_Account__c != currentPartnerAccountId) {
      throw new PartnerSyncHandledException(
        'Opportunity does not belong to the current partner.'
      );
    }

    if (DealRegistrationSelector.hasExistingRegistration(opportunity.Id)) {
      throw new PartnerSyncHandledException(
        'This opportunity has already been registered.'
      );
    }

    Integer maxOpenDeals = TenantConfigService.getMaxOpenDealsPerPartner();

    if (
      maxOpenDeals != null &&
      DealRegistrationSelector.countOpenDealsForPartner(
        currentPartnerAccountId
      ) >= maxOpenDeals
    ) {
      throw new PartnerSyncHandledException(
        'This partner has reached the maximum number of open deal registrations.'
      );
    }

    Deal_Registration__c record = createDealRegistrationInternal(
      opportunity,
      request
    );

    return DealRegistrationDomain.toDTO(record);
  }

  public static List<EligibleOpportunityDTO> getEligibleOpportunities() {
    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    List<EligibleOpportunityDTO> results = new List<EligibleOpportunityDTO>();

    List<Opportunity> opportunities = DealRegistrationSelector.selectEligibleOpportunitiesForPartner(
      partnerAccountId
    );

    for (Opportunity opportunity : opportunities) {
      EligibleOpportunityDTO dto = new EligibleOpportunityDTO();
      dto.opportunityId = opportunity.Id;
      dto.name = opportunity.Name;
      dto.stageName = opportunity.StageName;
      dto.amount = opportunity.Amount;
      dto.closeDate = opportunity.CloseDate;
      results.add(dto);
    }

    return results;
  }

  public static List<DealRegistrationListDTO> getMyDeals() {
    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    List<DealRegistrationListDTO> results = new List<DealRegistrationListDTO>();

    for (
      Deal_Registration__c record : DealRegistrationSelector.selectPartnerDeals(
        partnerAccountId
      )
    ) {
      results.add(DealRegistrationDomain.toListDTO(record));
    }

    return results;
  }

  public static Deal_Registration__c createDealRegistrationInternal(
    Opportunity opportunity,
    DealRegistrationRequestDTO request
  ) {
    Deal_Registration__c record = DealRegistrationDomain.buildRecord(
      opportunity,
      request
    );

    List<SObject> sanitized = SecurityUtil.stripForCreate(
      new List<SObject>{ record }
    );

    Database.insert(sanitized, AccessLevel.USER_MODE);

    Deal_Registration__c insertedRecord = (Deal_Registration__c) sanitized[0];

    // Backward-compatible facade: callers still create-and-submit in one
    // operation, but the lifecycle transition, conflict routing, event and
    // idempotency ledger are now owned by the command boundary.
    DealRegistrationCommandFacade.execute(
      insertedRecord.Id,
      DealRegistrationLifecycleConstants.SUBMIT,
      0,
      'registration-submit-' + insertedRecord.Id,
      null,
      null
    );
    insertedRecord = DealRegistrationSelector.selectById(insertedRecord.Id);

    PlatformEventPublisherService.publish(
      'DealSubmitted',
      insertedRecord.Id,
      'Deal_Registration__c',
      insertedRecord.Partner_Account__c,
      'Deal registration submitted for review.',
      'Info'
    );

    LoggingService.info(
      'DealRegistrationService',
      'Deal registration created. DealId=' + insertedRecord.Id
    );

    return insertedRecord;
  }
}
