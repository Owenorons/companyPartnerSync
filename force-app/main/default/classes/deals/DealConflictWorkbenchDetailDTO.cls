/**
 * Full detail shape for a single deal conflict finding on the conflict
 * workbench, including the fields the command layer already populates
 * (evidence, resolution, waiver) but which no UI has surfaced until now.
 */
public with sharing class DealConflictWorkbenchDetailDTO {
  @AuraEnabled
  public Id conflictId { get; set; }
  @AuraEnabled
  public Id dealId { get; set; }
  @AuraEnabled
  public String dealLabel { get; set; }
  @AuraEnabled
  public Id matchedDealId { get; set; }
  @AuraEnabled
  public String matchedDealLabel { get; set; }

  @AuraEnabled
  public String type { get; set; }
  @AuraEnabled
  public String subtype { get; set; }
  @AuraEnabled
  public String severity { get; set; }
  @AuraEnabled
  public Decimal confidence { get; set; }
  @AuraEnabled
  public Decimal matchScore { get; set; }
  @AuraEnabled
  public Boolean blocking { get; set; }
  @AuraEnabled
  public String ruleVersion { get; set; }

  @AuraEnabled
  public String status { get; set; }
  @AuraEnabled
  public Id assignedToId { get; set; }
  @AuraEnabled
  public Datetime detectedOn { get; set; }
  @AuraEnabled
  public Datetime investigationStartedOn { get; set; }
  @AuraEnabled
  public Datetime escalatedOn { get; set; }
  @AuraEnabled
  public Datetime slaDue { get; set; }

  /**
   * Free-text evidence summary captured at detection time by the analysis engine.
   */
  @AuraEnabled
  public String evidenceSummary { get; set; }
  @AuraEnabled
  public Datetime evidenceRequestedOn { get; set; }
  @AuraEnabled
  public Datetime evidenceSubmittedOn { get; set; }
  /**
   * Reviewer-entered evidence notes, captured via Submit Evidence or Waive Conflict.
   */
  @AuraEnabled
  public String reviewedEvidence { get; set; }

  @AuraEnabled
  public String resolution { get; set; }
  @AuraEnabled
  public String resolutionReason { get; set; }
  @AuraEnabled
  public Id resolvedById { get; set; }
  @AuraEnabled
  public Datetime resolvedOn { get; set; }

  @AuraEnabled
  public Id waivedById { get; set; }
  @AuraEnabled
  public Datetime waivedOn { get; set; }
  @AuraEnabled
  public String waiverReason { get; set; }
  @AuraEnabled
  public String waiverConditions { get; set; }
  @AuraEnabled
  public Datetime waiverExpiresOn { get; set; }

  @AuraEnabled
  public String partnerMessage { get; set; }
  @AuraEnabled
  public String partnerClassification { get; set; }

  /**
   * Optimistic-concurrency version to round-trip back on a command.
   */
  @AuraEnabled
  public Integer expectedVersion { get; set; }

  /**
   * Whether the running user holds the extra authority required to waive a
   * Critical-severity finding. A UI hide/disable hint only -
   * DealConflictCommandService.validateWaiver() re-checks authority when a
   * waiver is actually submitted.
   */
  @AuraEnabled
  public Boolean canWaiveCritical { get; set; }
}
