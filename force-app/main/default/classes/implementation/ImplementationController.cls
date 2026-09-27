/**
 * Aura controller surface for Sprint 40: the partner-facing implementation
 * summary/detail, the internal Implementation Workbench's 7 queue views,
 * and per-aggregate command dispatch. Pure pass-through/exception-
 * translation layer over the implementation/ command services and
 * selectors - no business logic here.
 */
public with sharing class ImplementationController {
  /**
   * Loads a deal's current implementation summary. Accessible to internal
   * users and to the deal's own partner/co-sell participants.
   *
   * @param dealId Id of the deal.
   * @return The deal's current implementation summary, or null if it has none.
   */
  @AuraEnabled(cacheable=true)
  public static ImplementationSummaryDTO getImplementationSummary(Id dealId) {
    try {
      if (!PartnerAccessService.canViewDeal(dealId)) {
        throw new PartnerSyncHandledException('This deal is not accessible.');
      }
      Deal_Implementation__c implementation = ImplementationSelector.selectCurrentSummaryForDeal(
        dealId
      );
      return implementation == null ? null : toSummaryDTO(implementation);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to load the implementation summary.',
        'Unable to load the implementation summary.',
        ex
      );
    }
  }

  /**
   * Loads a single implementation's full detail - summary plus its
   * milestones/evidence/issues/acceptances/participants.
   *
   * @param implementationId Id of the implementation.
   * @return The implementation's full detail.
   */
  @AuraEnabled(cacheable=true)
  public static ImplementationDetailDTO getImplementationDetail(
    Id implementationId
  ) {
    try {
      Deal_Implementation__c implementation = ImplementationSelector.selectSummaryById(
        implementationId
      );
      if (!PartnerAccessService.canViewDeal(implementation.Deal__c)) {
        throw new PartnerSyncHandledException(
          'This implementation is not accessible.'
        );
      }

      ImplementationDetailDTO detail = new ImplementationDetailDTO();
      detail.summary = toSummaryDTO(implementation);

      for (
        Implementation_Milestone__c milestone : ImplementationMilestoneSelector.selectForImplementation(
          implementationId
        )
      ) {
        ImplementationMilestoneRowDTO row = new ImplementationMilestoneRowDTO();
        row.milestoneId = milestone.Id;
        row.name = milestone.Name__c;
        row.milestoneType = milestone.Milestone_Type__c;
        row.status = milestone.Status__c;
        row.sequence = milestone.Sequence__c;
        row.plannedDate = milestone.Planned_Date__c;
        row.actualDate = milestone.Actual_Date__c;
        row.dueOn = milestone.Due_On__c;
        row.blocking = milestone.Blocking__c;
        row.required = milestone.Required__c;
        row.completionPercentage = milestone.Completion_Percentage__c;
        row.versionNumber = milestone.Version_Number__c == null
          ? 0
          : Integer.valueOf(milestone.Version_Number__c);
        detail.milestones.add(row);
      }

      for (
        Implementation_Evidence__c evidence : ImplementationEvidenceSelector.selectForImplementation(
          implementationId
        )
      ) {
        ImplementationEvidenceRowDTO row = new ImplementationEvidenceRowDTO();
        row.evidenceId = evidence.Id;
        row.milestoneId = evidence.Milestone__c;
        row.evidenceType = evidence.Evidence_Type__c;
        row.status = evidence.Status__c;
        row.contentDocumentId = evidence.ContentDocumentId__c;
        row.submittedOn = evidence.Submitted_On__c;
        row.reviewedOn = evidence.Reviewed_On__c;
        row.reviewOutcome = evidence.Review_Outcome__c;
        row.description = evidence.Description__c;
        detail.evidenceItems.add(row);
      }

      for (
        Implementation_Issue__c issue : ImplementationIssueSelector.selectForImplementation(
          implementationId
        )
      ) {
        ImplementationIssueRowDTO row = new ImplementationIssueRowDTO();
        row.issueId = issue.Id;
        row.title = issue.Title__c;
        row.issueType = issue.Issue_Type__c;
        row.severity = issue.Severity__c;
        row.status = issue.Status__c;
        row.raisedOn = issue.Raised_On__c;
        row.resolvedOn = issue.Resolved_On__c;
        row.targetResolutionOn = issue.Target_Resolution_On__c;
        row.customerImpact = issue.Customer_Impact__c;
        detail.issues.add(row);
      }

      for (
        Implementation_Acceptance__c acceptance : ImplementationAcceptanceSelector.selectForImplementation(
          implementationId
        )
      ) {
        ImplementationAcceptanceRowDTO row = new ImplementationAcceptanceRowDTO();
        row.acceptanceId = acceptance.Id;
        row.acceptanceType = acceptance.Acceptance_Type__c;
        row.status = acceptance.Status__c;
        row.acceptanceMethod = acceptance.Acceptance_Method__c;
        row.requestedOn = acceptance.Requested_On__c;
        row.acceptedOn = acceptance.Accepted_On__c;
        row.acceptedByName = acceptance.Accepted_By_Name__c;
        detail.acceptances.add(row);
      }

      for (
        Implementation_Participant__c participant : ImplementationParticipantSelector.selectActiveForImplementation(
          implementationId
        )
      ) {
        ImplementationParticipantRowDTO row = new ImplementationParticipantRowDTO();
        row.implementationParticipantId = participant.Id;
        row.dealParticipantId = participant.Deal_Participant__c;
        row.role = participant.Role__c;
        row.isPrimary = participant.Primary__c;
        detail.participants.add(row);
      }

      return detail;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to load the implementation detail.',
        'Unable to load the implementation detail.',
        ex
      );
    }
  }

  /**
   * Loads implementations with a handoff awaiting an internal accept/
   * return decision, for the Implementation Workbench's "Pending Handoff"
   * queue tab.
   *
   * @return Up to 200 such implementations, as summary DTOs.
   */
  @AuraEnabled(cacheable=true)
  public static List<ImplementationSummaryDTO> getPendingHandoff() {
    try {
      PartnerAccessService.assertInternalUser();
      List<ImplementationSummaryDTO> results = new List<ImplementationSummaryDTO>();
      for (
        Deal_Implementation_Handoff__c handoff : ImplementationHandoffSelector.selectPendingHandoffs()
      ) {
        ImplementationSummaryDTO dto = new ImplementationSummaryDTO();
        dto.implementationId = handoff.Implementation__c;
        dto.dealId = handoff.Implementation__r.Deal__c;
        dto.customerName = handoff.Implementation__r.Customer_Account__r?.Name;
        dto.partnerName = handoff.Implementation__r.Primary_Partner__r?.Name;
        dto.implementationType = handoff.Implementation__r.Implementation_Type__c;
        dto.status = handoff.Implementation__r.Status__c;
        dto.health = handoff.Implementation__r.Health__c;
        dto.plannedStartDate = handoff.Implementation__r.Planned_Start_Date__c;
        dto.plannedCompletionDate = handoff.Implementation__r.Planned_Completion_Date__c;
        dto.actualStartDate = handoff.Implementation__r.Actual_Start_Date__c;
        dto.actualCompletionDate = handoff.Implementation__r.Actual_Completion_Date__c;
        dto.versionNumber = handoff.Implementation__r.Version_Number__c == null
          ? 0
          : Integer.valueOf(handoff.Implementation__r.Version_Number__c);
        results.add(dto);
      }
      return results;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to load implementations pending handoff.',
        'Unable to load implementations pending handoff.',
        ex
      );
    }
  }

  /**
   * Loads implementations ready to start (handoff accepted), for the
   * Implementation Workbench's "Ready to Start" queue tab.
   *
   * @return Up to 200 such implementations, as summary DTOs.
   */
  @AuraEnabled(cacheable=true)
  public static List<ImplementationSummaryDTO> getReadyToStart() {
    return getByStatus(new Set<String>{ 'Not Started' });
  }

  /**
   * Loads implementations currently in progress, for the Implementation
   * Workbench's "In Progress" queue tab.
   *
   * @return Up to 200 such implementations, as summary DTOs.
   */
  @AuraEnabled(cacheable=true)
  public static List<ImplementationSummaryDTO> getInProgress() {
    return getByStatus(new Set<String>{ 'In Progress' });
  }

  /**
   * Loads non-terminal implementations flagged At Risk or Blocked, for the
   * Implementation Workbench's "At Risk / Blocked" queue tab.
   *
   * @return Up to 200 such implementations, as summary DTOs.
   */
  @AuraEnabled(cacheable=true)
  public static List<ImplementationSummaryDTO> getAtRiskOrBlocked() {
    return getByHealth(new Set<String>{ 'At Risk', 'Blocked' });
  }

  /**
   * Loads implementations awaiting a customer acceptance decision, for the
   * Implementation Workbench's "Awaiting Acceptance" queue tab.
   *
   * @return Up to 200 such implementations, as summary DTOs.
   */
  @AuraEnabled(cacheable=true)
  public static List<ImplementationSummaryDTO> getAwaitingAcceptance() {
    return getByStatus(new Set<String>{ 'Pending Customer Acceptance' });
  }

  /**
   * Loads non-terminal implementations flagged Overdue, for the
   * Implementation Workbench's "Overdue" queue tab.
   *
   * @return Up to 200 such implementations, as summary DTOs.
   */
  @AuraEnabled(cacheable=true)
  public static List<ImplementationSummaryDTO> getOverdue() {
    return getByHealth(new Set<String>{ 'Overdue' });
  }

  /**
   * Loads completed implementations, for the Implementation Workbench's
   * "Completed" queue tab.
   *
   * @return Up to 200 such implementations, as summary DTOs.
   */
  @AuraEnabled(cacheable=true)
  public static List<ImplementationSummaryDTO> getCompleted() {
    return getByStatus(new Set<String>{ 'Completed' });
  }

  private static List<ImplementationSummaryDTO> getByStatus(
    Set<String> statuses
  ) {
    try {
      PartnerAccessService.assertInternalUser();
      return toSummaryDTOs(ImplementationSelector.selectByStatus(statuses));
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to load implementations.',
        'Unable to load implementations.',
        ex
      );
    }
  }

  private static List<ImplementationSummaryDTO> getByHealth(
    Set<String> healthValues
  ) {
    try {
      PartnerAccessService.assertInternalUser();
      return toSummaryDTOs(ImplementationSelector.selectByHealth(healthValues));
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to load implementations.',
        'Unable to load implementations.',
        ex
      );
    }
  }

  /**
   * Executes an implementation lifecycle command (Create/Start/Pause/
   * Resume/Complete/Cancel/Supersede).
   *
   * @param command The implementation command to execute.
   * @return The resulting implementation, as a summary DTO.
   */
  @AuraEnabled
  public static ImplementationSummaryDTO executeImplementationCommand(
    ImplementationCommand command
  ) {
    try {
      Deal_Implementation__c result = ImplementationCommandService.execute(
        command
      );
      // The command service's returned record wasn't queried with the
      // relationship fields toSummaryDTO() needs (its own selectors are
      // scoped to what each command guard actually reads) - re-select via
      // the dedicated summary query instead of reusing it directly.
      return toSummaryDTO(ImplementationSelector.selectSummaryById(result.Id));
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to process the implementation command.',
        'Unable to process the implementation command.',
        ex
      );
    }
  }

  /**
   * Submits a sales-to-delivery handoff for an implementation.
   *
   * @param command The handoff submission details.
   * @return The outcome of the submission attempt.
   */
  @AuraEnabled
  public static ImplementationHandoffOutcome submitHandoff(
    ImplementationHandoffCommand command
  ) {
    try {
      return ImplementationHandoffCommandService.submit(command);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to submit the handoff.',
        'Unable to submit the handoff.',
        ex
      );
    }
  }

  /**
   * Accepts a submitted handoff.
   *
   * @param command handoffId + expectedVersion.
   */
  @AuraEnabled
  public static void acceptHandoff(ImplementationHandoffCommand command) {
    try {
      ImplementationHandoffCommandService.accept(command);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to accept the handoff.',
        'Unable to accept the handoff.',
        ex
      );
    }
  }

  /**
   * Returns a submitted handoff for more information.
   *
   * @param command handoffId + expectedVersion + reason.
   */
  @AuraEnabled
  public static void returnHandoff(ImplementationHandoffCommand command) {
    try {
      ImplementationHandoffCommandService.doReturn(command);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to return the handoff.',
        'Unable to return the handoff.',
        ex
      );
    }
  }

  /**
   * Starts a milestone.
   *
   * @param command milestoneId + expectedVersion.
   */
  @AuraEnabled
  public static void startMilestone(ImplementationMilestoneCommand command) {
    try {
      ImplementationMilestoneCommandService.start(command);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to start the milestone.',
        'Unable to start the milestone.',
        ex
      );
    }
  }

  /**
   * Completes a milestone.
   *
   * @param command milestoneId + expectedVersion.
   */
  @AuraEnabled
  public static void completeMilestone(ImplementationMilestoneCommand command) {
    try {
      ImplementationMilestoneCommandService.complete(command);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to complete the milestone.',
        'Unable to complete the milestone.',
        ex
      );
    }
  }

  /**
   * Blocks a milestone.
   *
   * @param command milestoneId + expectedVersion + reason.
   */
  @AuraEnabled
  public static void blockMilestone(ImplementationMilestoneCommand command) {
    try {
      ImplementationMilestoneCommandService.block(command);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to block the milestone.',
        'Unable to block the milestone.',
        ex
      );
    }
  }

  /**
   * Waives a required milestone.
   *
   * @param command milestoneId + expectedVersion + reason.
   */
  @AuraEnabled
  public static void waiveMilestone(ImplementationMilestoneCommand command) {
    try {
      ImplementationMilestoneCommandService.waive(command);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to waive the milestone.',
        'Unable to waive the milestone.',
        ex
      );
    }
  }

  /**
   * Submits implementation evidence.
   *
   * @param command The evidence submission details.
   * @return The inserted evidence record's Id.
   */
  @AuraEnabled
  public static Id submitEvidence(ImplementationEvidenceCommand command) {
    try {
      return ImplementationEvidenceCommandService.submit(command).Id;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to submit evidence.',
        'Unable to submit evidence.',
        ex
      );
    }
  }

  /**
   * Reviews (accepts/rejects) submitted evidence.
   *
   * @param command evidenceId + outcome + reason.
   */
  @AuraEnabled
  public static void reviewEvidence(ImplementationEvidenceCommand command) {
    try {
      ImplementationEvidenceCommandService.review(command);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to review evidence.',
        'Unable to review evidence.',
        ex
      );
    }
  }

  /**
   * Raises a delivery issue.
   *
   * @param command The issue details.
   * @return The inserted issue record's Id.
   */
  @AuraEnabled
  public static Id raiseIssue(ImplementationIssueCommand command) {
    try {
      return ImplementationIssueCommandService.raise(command).Id;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to raise the issue.',
        'Unable to raise the issue.',
        ex
      );
    }
  }

  /**
   * Escalates an open issue.
   *
   * @param command issueId + expectedVersion.
   */
  @AuraEnabled
  public static void escalateIssue(ImplementationIssueCommand command) {
    try {
      ImplementationIssueCommandService.escalate(command);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to escalate the issue.',
        'Unable to escalate the issue.',
        ex
      );
    }
  }

  /**
   * Resolves an open issue.
   *
   * @param command issueId + expectedVersion + reason (resolution).
   */
  @AuraEnabled
  public static void resolveIssue(ImplementationIssueCommand command) {
    try {
      ImplementationIssueCommandService.resolve(command);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to resolve the issue.',
        'Unable to resolve the issue.',
        ex
      );
    }
  }

  /**
   * Accepts the risk of an open issue rather than resolving it.
   *
   * @param command issueId + expectedVersion + reason.
   */
  @AuraEnabled
  public static void acceptIssueRisk(ImplementationIssueCommand command) {
    try {
      ImplementationIssueCommandService.acceptRisk(command);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to accept the issue risk.',
        'Unable to accept the issue risk.',
        ex
      );
    }
  }

  /**
   * Requests a customer acceptance.
   *
   * @param command The acceptance request details.
   * @return The inserted acceptance record's Id.
   */
  @AuraEnabled
  public static Id requestAcceptance(ImplementationAcceptanceCommand command) {
    try {
      return ImplementationAcceptanceCommandService.request(command).Id;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to request acceptance.',
        'Unable to request acceptance.',
        ex
      );
    }
  }

  /**
   * Records a requested acceptance as accepted.
   *
   * @param command acceptanceId + expectedVersion + acceptedByName/Email.
   */
  @AuraEnabled
  public static void recordAcceptance(ImplementationAcceptanceCommand command) {
    try {
      ImplementationAcceptanceCommandService.record(command);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to record acceptance.',
        'Unable to record acceptance.',
        ex
      );
    }
  }

  /**
   * Rejects a requested acceptance.
   *
   * @param command acceptanceId + expectedVersion + reason.
   */
  @AuraEnabled
  public static void rejectAcceptance(ImplementationAcceptanceCommand command) {
    try {
      ImplementationAcceptanceCommandService.reject(command);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to reject acceptance.',
        'Unable to reject acceptance.',
        ex
      );
    }
  }

  /**
   * Assigns a delivery role to an existing deal participant on an
   * implementation.
   *
   * @param command The assignment details.
   * @return The assigned participant, as a row DTO.
   */
  @AuraEnabled
  public static ImplementationParticipantRowDTO assignParticipant(
    ImplementationParticipantCommand command
  ) {
    try {
      Implementation_Participant__c participant = ImplementationParticipantCommandService.assign(
        command
      );
      ImplementationParticipantRowDTO row = new ImplementationParticipantRowDTO();
      row.implementationParticipantId = participant.Id;
      row.dealParticipantId = participant.Deal_Participant__c;
      row.role = participant.Role__c;
      row.isPrimary = participant.Primary__c;
      return row;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to assign the participant.',
        'Unable to assign the participant.',
        ex
      );
    }
  }

  /**
   * Removes a delivery participant from an implementation.
   *
   * @param command implementationParticipantId.
   */
  @AuraEnabled
  public static void removeParticipant(
    ImplementationParticipantCommand command
  ) {
    try {
      ImplementationParticipantCommandService.remove(command);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ImplementationController',
        'Unable to remove the participant.',
        'Unable to remove the participant.',
        ex
      );
    }
  }

  private static List<ImplementationSummaryDTO> toSummaryDTOs(
    List<Deal_Implementation__c> implementations
  ) {
    List<ImplementationSummaryDTO> results = new List<ImplementationSummaryDTO>();
    for (Deal_Implementation__c implementation : implementations) {
      results.add(toSummaryDTO(implementation));
    }
    return results;
  }

  private static ImplementationSummaryDTO toSummaryDTO(
    Deal_Implementation__c implementation
  ) {
    ImplementationSummaryDTO dto = new ImplementationSummaryDTO();
    dto.implementationId = implementation.Id;
    dto.dealId = implementation.Deal__c;
    dto.customerName = implementation.Customer_Account__r?.Name;
    dto.partnerName = implementation.Primary_Partner__r?.Name;
    dto.implementationType = implementation.Implementation_Type__c;
    dto.status = implementation.Status__c;
    dto.health = implementation.Health__c;
    dto.plannedStartDate = implementation.Planned_Start_Date__c;
    dto.plannedCompletionDate = implementation.Planned_Completion_Date__c;
    dto.actualStartDate = implementation.Actual_Start_Date__c;
    dto.actualCompletionDate = implementation.Actual_Completion_Date__c;
    dto.versionNumber = implementation.Version_Number__c == null
      ? 0
      : Integer.valueOf(implementation.Version_Number__c);
    return dto;
  }
}
