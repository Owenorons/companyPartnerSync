/**
 * Aura controller surface for Sprint 39: the partner-facing sanitized
 * sales-progress summary, and the internal Sales Execution Workbench's 4
 * queue views (Opportunity Pending Link, Reapproval Required, Orphaned
 * Relationships, Recently Closed). Pure pass-through/exception-translation
 * layer over DealOpportunitySelector/DealRegistrationSelector - no
 * business logic here.
 */
public with sharing class DealOpportunityController {
  /**
   * Loads a deal's sanitized sales-progress summary. Accessible to
   * internal users and to the deal's own partner/co-sell participants via
   * PartnerAccessService.canViewDeal, matching every other deal-detail
   * controller method in this codebase.
   *
   * @param dealId Id of the deal.
   * @return The deal's sanitized sales progress, or a blank DTO if it has no current primary opportunity relationship.
   */
  @AuraEnabled(cacheable=true)
  public static SalesProgressDTO getSalesProgress(Id dealId) {
    try {
      if (!PartnerAccessService.canViewDeal(dealId)) {
        throw new PartnerSyncHandledException('This deal is not accessible.');
      }

      SalesProgressDTO dto = new SalesProgressDTO();
      dto.dealId = dealId;

      Deal_Opportunity__c primary = DealOpportunitySelector.selectCurrentPrimary(
        dealId
      );
      if (primary != null) {
        dto.stage = DealSalesStageProjectionService.resolveCanonicalStage(
          primary.Opportunity__r.StageName
        );
        dto.isWon = primary.Opportunity__r.IsWon;
        dto.isClosed = primary.Opportunity__r.IsClosed;
      }

      List<Deal_Opportunity__c> relationships = DealOpportunitySelector.selectForDeal(
        dealId
      );
      dto.opportunityCount = relationships.size();
      for (Deal_Opportunity__c relationship : relationships) {
        if (relationship.Primary__c == true) {
          dto.amount = relationship.Opportunity__r.Amount;
          dto.closeDate = relationship.Opportunity__r.CloseDate;
        }
      }

      return dto;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealOpportunityController',
        'Unable to load the deal\'s sales progress.',
        'Unable to load the deal\'s sales progress.',
        ex
      );
    }
  }

  /**
   * Loads a deal's current opportunity relationships, for internal use.
   *
   * @param dealId Id of the deal.
   * @return The deal's current Deal_Opportunity__c rows.
   */
  @AuraEnabled(cacheable=true)
  public static List<Deal_Opportunity__c> getOpportunityRelationships(
    Id dealId
  ) {
    try {
      PartnerAccessService.assertInternalUser();
      return DealOpportunitySelector.selectForDeal(dealId);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealOpportunityController',
        'Unable to load the deal\'s opportunity relationships.',
        'Unable to load the deal\'s opportunity relationships.',
        ex
      );
    }
  }

  /**
   * Loads approved deals with no current opportunity relationship, for the
   * internal Sales Execution Workbench's "Opportunity Pending Link" view.
   *
   * @return Up to 200 such deals, as queue row DTOs.
   */
  @AuraEnabled(cacheable=true)
  public static List<SalesExecutionQueueRowDTO> getOpportunityPendingLink() {
    try {
      PartnerAccessService.assertInternalUser();
      return toQueueRows(
        DealRegistrationSelector.selectApprovedDealsWithoutOpportunityLink()
      );
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealOpportunityController',
        'Unable to load deals pending an opportunity link.',
        'Unable to load deals pending an opportunity link.',
        ex
      );
    }
  }

  /**
   * Loads deals currently back in Under Review because a material change
   * triggered reapproval, for the internal Sales Execution Workbench's
   * "Reapproval Required" view.
   *
   * @return Up to 200 such deals, as queue row DTOs.
   */
  @AuraEnabled(cacheable=true)
  public static List<SalesExecutionQueueRowDTO> getReapprovalRequired() {
    try {
      PartnerAccessService.assertInternalUser();
      return toQueueRows(
        DealRegistrationSelector.selectReapprovalRequiredDeals()
      );
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealOpportunityController',
        'Unable to load deals requiring reapproval.',
        'Unable to load deals requiring reapproval.',
        ex
      );
    }
  }

  /**
   * Loads deals whose primary opportunity relationship is orphaned, for
   * the internal Sales Execution Workbench's "Orphaned Relationships" view.
   *
   * @return Up to 200 such deals, as queue row DTOs.
   */
  @AuraEnabled(cacheable=true)
  public static List<SalesExecutionQueueRowDTO> getOrphanedRelationships() {
    try {
      PartnerAccessService.assertInternalUser();
      return toQueueRows(
        DealRegistrationSelector.selectOrphanedOpportunityDeals()
      );
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealOpportunityController',
        'Unable to load orphaned opportunity relationships.',
        'Unable to load orphaned opportunity relationships.',
        ex
      );
    }
  }

  /**
   * Loads recently closed (won/lost) deals, for the internal Sales
   * Execution Workbench's "Recently Closed" view.
   *
   * @return Up to 200 such deals, as queue row DTOs.
   */
  @AuraEnabled(cacheable=true)
  public static List<SalesExecutionQueueRowDTO> getRecentlyClosed() {
    try {
      PartnerAccessService.assertInternalUser();
      return toQueueRows(DealRegistrationSelector.selectRecentlyClosedDeals());
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealOpportunityController',
        'Unable to load recently closed deals.',
        'Unable to load recently closed deals.',
        ex
      );
    }
  }

  private static List<SalesExecutionQueueRowDTO> toQueueRows(
    List<Deal_Registration__c> deals
  ) {
    List<SalesExecutionQueueRowDTO> results = new List<SalesExecutionQueueRowDTO>();
    for (Deal_Registration__c deal : deals) {
      SalesExecutionQueueRowDTO dto = new SalesExecutionQueueRowDTO();
      dto.dealId = deal.Id;
      dto.customerName = deal.Customer_Name__c;
      dto.partnerName = deal.Partner_Account__r?.Name;
      dto.status = deal.Status__c;
      dto.stage = deal.Stage__c;
      results.add(dto);
    }
    return results;
  }
}
