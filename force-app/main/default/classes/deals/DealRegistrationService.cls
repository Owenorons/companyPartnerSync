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

    // Conflict analysis must run after insert, not before: it queries for
    // other active registrations on the same customer account and needs
    // insertedRecord.Id to exclude itself from those results.
    DealConflictDTO conflict = DealConflictService.analyze(insertedRecord);

    /*
     * Enterprise Governance Pattern
     *
     * ALL deals require internal review.
     *
     * No conflict:
     *      Submitted + No Conflict
     *
     * Conflict:
     *      Under Review + Potential Conflict
     */

    if (conflict.hasConflict) {
      insertedRecord.Status__c = 'Under Review';

      insertedRecord.Conflict_Status__c = 'Potential Conflict';
    } else {
      insertedRecord.Status__c = 'Submitted';

      insertedRecord.Conflict_Status__c = 'No Conflict';
    }

    update SecurityUtil.stripForUpdate(new List<SObject>{ insertedRecord });

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
