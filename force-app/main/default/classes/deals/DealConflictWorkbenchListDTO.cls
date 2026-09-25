/**
 * Row shape for the deal conflict workbench queue (see
 * DealConflictSelector.selectPendingConflicts). Distinct from
 * DealConflictDTO (coarse partner-facing has-conflict summary) and
 * DealConflictDetailDTO (competing-deal summary embedded in the deal
 * review screen) - this DTO is the investigation work item itself.
 */
public with sharing class DealConflictWorkbenchListDTO {
  /**
   * Id of the Deal_Conflict__c finding.
   */
  @AuraEnabled
  public Id conflictId { get; set; }
  /**
   * Id of the deal this finding was raised against.
   */
  @AuraEnabled
  public Id dealId { get; set; }
  /**
   * Denormalized display label for the deal.
   */
  @AuraEnabled
  public String dealLabel { get; set; }
  /**
   * Id of the competing deal this finding matched, if any.
   */
  @AuraEnabled
  public Id matchedDealId { get; set; }
  /**
   * Denormalized display label for the matched deal.
   */
  @AuraEnabled
  public String matchedDealLabel { get; set; }

  /**
   * Conflict type (e.g. Existing Registration).
   */
  @AuraEnabled
  public String type { get; set; }
  /**
   * Conflict subtype (e.g. Same Customer Account, Identity Fingerprint).
   */
  @AuraEnabled
  public String subtype { get; set; }
  /**
   * Severity of the finding (e.g. Critical, High).
   */
  @AuraEnabled
  public String severity { get; set; }
  /**
   * Confidence score of the match.
   */
  @AuraEnabled
  public Decimal confidence { get; set; }
  /**
   * Numeric match score the finding was scored at.
   */
  @AuraEnabled
  public Decimal matchScore { get; set; }
  /**
   * Whether this finding blocks deal approval until resolved.
   */
  @AuraEnabled
  public Boolean blocking { get; set; }

  /**
   * Current investigation status (e.g. Open, Assigned, Investigating).
   */
  @AuraEnabled
  public String status { get; set; }
  /**
   * User the finding is currently assigned to, if any.
   */
  @AuraEnabled
  public Id assignedToId { get; set; }
  /**
   * Date/time this finding was detected.
   */
  @AuraEnabled
  public Datetime detectedOn { get; set; }
  /**
   * Date/time this finding was escalated, if any.
   */
  @AuraEnabled
  public Datetime escalatedOn { get; set; }

  /**
   * Optimistic-concurrency version to round-trip back on a command.
   */
  @AuraEnabled
  public Integer expectedVersion { get; set; }
}
