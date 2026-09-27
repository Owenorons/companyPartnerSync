/**
 * Aura controller surface for co-sell participant management: the
 * partner-facing deal team view, the internal pending-invitations queue,
 * and the generic participant command dispatch. Pure pass-through/
 * exception-translation layer over DealParticipantCommandService and
 * DealParticipantSelector - no business logic here.
 */
public with sharing class DealParticipantController {
  /**
   * Loads the partner-safe participant roster for a deal - the current
   * user's own organisation's row plus any co-sell participants -
   * for the partner-facing team card and the internal workbench alike.
   *
   * @param dealId Id of the deal.
   * @return The deal's visible participants, as partner-safe summary DTOs.
   */
  @AuraEnabled(cacheable=true)
  public static List<DealParticipantSummaryDTO> getDealTeam(Id dealId) {
    try {
      if (!PartnerAccessService.canViewDeal(dealId)) {
        throw new PartnerSyncHandledException('This deal is not accessible.');
      }

      Id currentPartnerAccountId = PartnerAccessService.isInternalUser()
        ? null
        : PartnerAccessService.getCurrentPartnerAccountId();

      List<DealParticipantSummaryDTO> results = new List<DealParticipantSummaryDTO>();
      for (
        Deal_Participant__c participant : DealParticipantSelector.selectVisibleParticipantsForDeal(
          dealId
        )
      ) {
        results.add(
          DealParticipantDomain.toSummaryDTO(
            participant,
            participant.Partner_Account__r?.Name,
            currentPartnerAccountId
          )
        );
      }
      return results;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealParticipantController',
        'Unable to load the deal team.',
        'Unable to load the deal team.',
        ex
      );
    }
  }

  /**
   * Loads the internal co-sell workbench's pending-invitations queue.
   *
   * @return Up to 200 Invited participants, as partner-safe summary DTOs.
   */
  @AuraEnabled(cacheable=true)
  public static List<DealParticipantSummaryDTO> getPendingInvitations() {
    try {
      if (!PartnerAccessService.isInternalUser()) {
        throw new PartnerSyncHandledException(
          'This view is only available to internal users.'
        );
      }

      List<DealParticipantSummaryDTO> results = new List<DealParticipantSummaryDTO>();
      for (
        Deal_Participant__c participant : DealParticipantSelector.selectPendingInvitations()
      ) {
        results.add(
          DealParticipantDomain.toSummaryDTO(
            participant,
            participant.Partner_Account__r?.Name,
            null
          )
        );
      }
      return results;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealParticipantController',
        'Unable to load pending invitations.',
        'Unable to load pending invitations.',
        ex
      );
    }
  }

  /**
   * Executes a participant lifecycle command (invite/accept/decline/
   * activate/suspend/resume/remove/change role/change access).
   *
   * @param command The command to execute.
   * @return The resulting participant, as a partner-safe summary DTO.
   */
  @AuraEnabled
  public static DealParticipantSummaryDTO executeCommand(
    DealParticipantCommand command
  ) {
    try {
      Deal_Participant__c participant = DealParticipantCommandService.execute(
        command
      );
      Id currentPartnerAccountId = PartnerAccessService.isInternalUser()
        ? null
        : PartnerAccessService.getCurrentPartnerAccountId();
      String partnerName = resolvePartnerName(participant.Partner_Account__c);
      return DealParticipantDomain.toSummaryDTO(
        participant,
        partnerName,
        currentPartnerAccountId
      );
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealParticipantController',
        'Unable to process the participant command.',
        'Unable to process the participant command.',
        ex
      );
    }
  }

  /**
   * Loads deals whose co-sell participation is currently Active, for the
   * internal Co-Sell Workbench's "Active Co-Sell Deals" view.
   *
   * @return Up to 200 active co-sell deals, as summary DTOs.
   */
  @AuraEnabled(cacheable=true)
  public static List<CoSellDealSummaryDTO> getActiveCoSellDeals() {
    try {
      assertInternalUser();

      List<CoSellDealSummaryDTO> results = new List<CoSellDealSummaryDTO>();
      for (
        Deal_Registration__c deal : DealRegistrationSelector.selectActiveCoSellDeals()
      ) {
        CoSellDealSummaryDTO dto = new CoSellDealSummaryDTO();
        dto.dealId = deal.Id;
        dto.customerName = deal.Customer_Name__c;
        dto.originatingPartnerName = deal.Partner_Account__r?.Name;
        dto.coSellStatus = deal.CoSell_Status__c;
        dto.activeParticipantCount = DealParticipantSelector.selectActiveParticipantsForDeal(
            deal.Id
          )
          .size();
        results.add(dto);
      }
      return results;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealParticipantController',
        'Unable to load active co-sell deals.',
        'Unable to load active co-sell deals.',
        ex
      );
    }
  }

  /**
   * Loads recent participant-related audit entries, for the internal
   * Co-Sell Workbench's "Participant Changes" view.
   *
   * @return Up to 100 recent participant changes.
   */
  @AuraEnabled(cacheable=true)
  public static List<ParticipantChangeDTO> getParticipantChanges() {
    try {
      assertInternalUser();

      List<ParticipantChangeDTO> results = new List<ParticipantChangeDTO>();
      for (
        Audit_Log__c log : DealParticipantSelector.selectRecentParticipantChanges()
      ) {
        ParticipantChangeDTO dto = new ParticipantChangeDTO();
        dto.dealId = String.isBlank(log.Record_Id__c)
          ? null
          : (Id) log.Record_Id__c;
        dto.action = log.Action__c;
        dto.performedByName = log.Performed_By_Name__c;
        dto.performedOn = log.Audit_Timestamp__c;
        results.add(dto);
      }
      return results;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealParticipantController',
        'Unable to load participant changes.',
        'Unable to load participant changes.',
        ex
      );
    }
  }

  /**
   * Loads Proposed (not yet approved) shared-protection requests, for the
   * internal Co-Sell Workbench's "Shared Protection Requests" view.
   *
   * @return Up to 200 pending shared-protection requests.
   */
  @AuraEnabled(cacheable=true)
  public static List<SharedProtectionRequestDTO> getPendingSharedProtectionRequests() {
    try {
      assertInternalUser();

      List<SharedProtectionRequestDTO> results = new List<SharedProtectionRequestDTO>();
      for (
        Deal_Protection_Participant__c request : DealProtectionParticipantSelector.selectPendingRequests()
      ) {
        SharedProtectionRequestDTO dto = new SharedProtectionRequestDTO();
        dto.protectionParticipantId = request.Id;
        dto.dealId = request.Protection__r.Deal__c;
        dto.participantOrganisationName = request.Partner_Account__r?.Name;
        dto.protectionRole = request.Protection_Role__c;
        dto.sharePercentage = request.Share_Percentage__c;
        dto.requestedOn = request.CreatedDate;
        dto.grantVersionNumber = request.Protection__r.Version_Number__c == null
          ? 0
          : Integer.valueOf(request.Protection__r.Version_Number__c);
        results.add(dto);
      }
      return results;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealParticipantController',
        'Unable to load shared protection requests.',
        'Unable to load shared protection requests.',
        ex
      );
    }
  }

  /**
   * Approves a Proposed shared-protection request from the workbench.
   *
   * @param protectionParticipantId Id of the request to approve.
   * @param expectedGrantVersion The protection grant's expected version.
   */
  @AuraEnabled
  public static void approveSharedProtectionRequest(
    Id protectionParticipantId,
    Integer expectedGrantVersion
  ) {
    try {
      ApproveSharedProtectionCommand command = new ApproveSharedProtectionCommand();
      command.protectionParticipantId = protectionParticipantId;
      command.expectedGrantVersion = expectedGrantVersion;
      DealProtectionParticipantCommandService.approveSharedProtection(command);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealParticipantController',
        'Unable to approve the shared protection request.',
        'Unable to approve the shared protection request.',
        ex
      );
    }
  }

  /**
   * Loads Suspended/Expired partner account relationships, for the
   * internal Co-Sell Workbench's "Relationship Exceptions" view.
   *
   * @return Up to 200 relationship exceptions.
   */
  @AuraEnabled(cacheable=true)
  public static List<RelationshipExceptionDTO> getRelationshipExceptions() {
    try {
      assertInternalUser();

      List<RelationshipExceptionDTO> results = new List<RelationshipExceptionDTO>();
      for (
        Partner_Account_Relationship__c relationship : PartnerAccountRelationshipSelector.selectExceptions()
      ) {
        RelationshipExceptionDTO dto = new RelationshipExceptionDTO();
        dto.relationshipId = relationship.Id;
        dto.sourceAccountName = relationship.Source_Account__r?.Name;
        dto.targetAccountName = relationship.Target_Account__r?.Name;
        dto.status = relationship.Status__c;
        dto.effectiveTo = relationship.Effective_To__c;
        results.add(dto);
      }
      return results;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealParticipantController',
        'Unable to load relationship exceptions.',
        'Unable to load relationship exceptions.',
        ex
      );
    }
  }

  /**
   * Loads participants with an SLA concern (at risk or expired), for the
   * internal Co-Sell Workbench's "Participant SLA Breaches" view.
   *
   * @return Up to 200 at-risk or expired participants, as summary DTOs.
   */
  @AuraEnabled(cacheable=true)
  public static List<DealParticipantSummaryDTO> getSlaBreaches() {
    try {
      assertInternalUser();

      List<DealParticipantSummaryDTO> results = new List<DealParticipantSummaryDTO>();
      for (
        Deal_Participant__c participant : DealParticipantSelector.selectSlaBreaches()
      ) {
        results.add(
          DealParticipantDomain.toSummaryDTO(
            participant,
            participant.Partner_Account__r?.Name,
            null
          )
        );
      }
      return results;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealParticipantController',
        'Unable to load participant SLA breaches.',
        'Unable to load participant SLA breaches.',
        ex
      );
    }
  }

  private static void assertInternalUser() {
    if (!PartnerAccessService.isInternalUser()) {
      throw new PartnerSyncHandledException(
        'This view is only available to internal users.'
      );
    }
  }

  private static String resolvePartnerName(Id partnerAccountId) {
    if (partnerAccountId == null) {
      return null;
    }
    List<Account> accounts = [
      SELECT Name
      FROM Account
      WHERE Id = :partnerAccountId
      WITH SYSTEM_MODE
    ];
    return accounts.isEmpty() ? null : accounts[0].Name;
  }
}
