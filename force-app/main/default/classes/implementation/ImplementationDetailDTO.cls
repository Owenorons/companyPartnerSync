/**
 * Partner-safe full detail view of a single Deal_Implementation__c -
 * summary fields plus its milestones/evidence/issues/acceptances/
 * participants, for both partnerImplementationWorkspace and the internal
 * implementationWorkbench's record drawer.
 */
public class ImplementationDetailDTO {
  @AuraEnabled
  public ImplementationSummaryDTO summary;
  @AuraEnabled
  public List<ImplementationMilestoneRowDTO> milestones = new List<ImplementationMilestoneRowDTO>();
  @AuraEnabled
  public List<ImplementationEvidenceRowDTO> evidenceItems = new List<ImplementationEvidenceRowDTO>();
  @AuraEnabled
  public List<ImplementationIssueRowDTO> issues = new List<ImplementationIssueRowDTO>();
  @AuraEnabled
  public List<ImplementationAcceptanceRowDTO> acceptances = new List<ImplementationAcceptanceRowDTO>();
  @AuraEnabled
  public List<ImplementationParticipantRowDTO> participants = new List<ImplementationParticipantRowDTO>();
}
