/**
 * Domain layer for the partner-submitted side of deal registration: builds
 * a Deal_Registration__c from an Opportunity + the partner's request DTO,
 * and maps records to their outbound DTOs. This is the registration-side
 * counterpart to DealReviewDomain, which builds/validates the internal
 * review-and-decision DTOs after a deal has already been submitted.
 */
public with sharing class DealRegistrationDomain {
  /**
   * Validates that an inbound deal registration request has the required fields.
   *
   * @param request The partner's deal registration request.
   */
  public static void validate(DealRegistrationRequestDTO request) {
    if (request == null) {
      throw new PartnerSyncHandledException(
        'Deal registration request is required.'
      );
    }

    if (request.opportunityId == null) {
      throw new PartnerSyncHandledException('Opportunity Id is required.');
    }

    if (request.estimatedRevenue == null) {
      throw new PartnerSyncHandledException('Estimated revenue is required.');
    }
  }

  /**
   * Builds an unsaved Deal_Registration__c from an eligible opportunity and the partner's
   * request, defaulting Status__c to 'Draft' and Conflict_Status__c to a 'None' placeholder that
   * gets overwritten once conflict analysis runs post-insert.
   *
   * @param opportunity Opportunity the registration is created against.
   * @param request Partner-submitted registration details.
   * @return An unsaved Deal_Registration__c record ready for insert.
   */
  public static Deal_Registration__c buildRecord(
    Opportunity opportunity,
    DealRegistrationRequestDTO request
  ) {
    Deal_Registration__c record = new Deal_Registration__c();

    record.Opportunity__c = opportunity.Id;

    // Carries lead lineage forward so a deal registered against an
    // opportunity that originated from a lead can still be traced back to
    // that lead (source attribution), even though registration is keyed
    // off the Opportunity, not the Lead.
    record.Source_Lead__c = opportunity.Source_Lead__c;

    record.Customer_Account__c = opportunity.AccountId;

    record.Partner_Account__c = opportunity.Partner_Account__c;

    record.Partner_Contact__c = opportunity.Partner_Contact__c;

    record.Status__c = 'Draft';

    // Placeholder only: DealRegistrationService.createDealRegistrationInternal
    // runs DealConflictService.analyze() right after insert (it needs the
    // record's Id to query for siblings) and overwrites this with the real
    // conflict outcome before the caller ever sees it.
    record.Conflict_Status__c = 'None';

    record.Business_Problem__c = request.businessProblem;

    record.Proposed_Solution__c = request.proposedSolution;

    record.Estimated_Revenue__c = request.estimatedRevenue;

    record.Estimated_Close_Date__c = request.estimatedCloseDate;

    record.Implementation_Timeline__c = request.implementationTimeline;

    record.Submitted_On__c = System.now();

    record.Notes__c = request.notes;

    return record;
  }

  /**
   * Maps a Deal_Registration__c to the minimal confirmation DTO returned to the partner right
   * after creation.
   *
   * @param record Deal registration record to map.
   * @return The mapped DealRegistrationResultDTO.
   */
  public static DealRegistrationResultDTO toDTO(Deal_Registration__c record) {
    DealRegistrationResultDTO dto = new DealRegistrationResultDTO();

    dto.dealRegistrationId = record.Id;

    dto.dealRegistrationNumber = record.Name;

    dto.status = record.Status__c;

    dto.conflictStatus = record.Conflict_Status__c;

    return dto;
  }

  /**
   * Maps a Deal_Registration__c to the row shape used in a partner's own "My Deals" list.
   *
   * @param record Deal registration record to map.
   * @return The mapped DealRegistrationListDTO.
   */
  public static DealRegistrationListDTO toListDTO(Deal_Registration__c record) {
    DealRegistrationListDTO dto = new DealRegistrationListDTO();

    dto.dealId = record.Id;
    dto.dealNumber = record.Name;

    dto.customerName = record.Customer_Account__r.Name;

    dto.partnerName = record.Partner_Account__r.Name;

    dto.dealValue = record.Estimated_Revenue__c;

    dto.stage = record.Opportunity__r.StageName;

    dto.status = record.Status__c;

    dto.conflictStatus = record.Conflict_Status__c;

    dto.protectionEndDate = record.Protection_End_Date__c;

    dto.createdDate = record.CreatedDate;

    return dto;
  }

  /**
   * Maps a Deal_Registration__c and its partner-visible events to the
   * detail view shown when a partner drills into a single deal.
   *
   * @param record Deal registration record to map.
   * @param events The deal's partner-visible lifecycle events, most recent first.
   * @return The mapped DealRegistrationDetailDTO.
   */
  public static DealRegistrationDetailDTO toDetailDTO(
    Deal_Registration__c record,
    List<Deal_Event__c> events
  ) {
    DealRegistrationDetailDTO dto = new DealRegistrationDetailDTO();

    dto.dealId = record.Id;
    dto.dealNumber = record.Name;

    dto.customerName = record.Customer_Account__r?.Name;
    dto.partnerName = record.Partner_Account__r?.Name;
    dto.stage = record.Opportunity__r?.StageName;

    dto.status = record.Status__c;
    dto.conflictStatus = record.Conflict_Status__c;

    dto.dealValue = record.Estimated_Revenue__c;
    dto.estimatedCloseDate = record.Estimated_Close_Date__c;
    dto.protectionEndDate = record.Protection_End_Date__c;

    dto.businessProblem = record.Business_Problem__c;
    dto.proposedSolution = record.Proposed_Solution__c;
    dto.notes = record.Notes__c;

    dto.lifecyclePhase = record.Lifecycle_Phase__c;
    dto.lifecycleHealth = record.Lifecycle_Health__c;
    dto.currentActionRequired = record.Current_Action_Required__c;
    dto.nextActionDue = record.Next_Action_Due__c;

    dto.createdDate = record.CreatedDate;

    dto.events = new List<DealTimelineEventDTO>();
    for (Deal_Event__c event : events) {
      DealTimelineEventDTO eventDto = new DealTimelineEventDTO();
      eventDto.eventType = event.Event_Type__c;
      eventDto.summary = event.Summary__c;
      eventDto.occurredOn = event.Occurred_On__c;
      dto.events.add(eventDto);
    }

    return dto;
  }
}
