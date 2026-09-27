/**
 * Partner-safe row for one Implementation_Evidence__c, used in
 * ImplementationDetailDTO's evidenceItems list. Omits
 * Partner_Visible__c/Customer_Visible__c - those are internal display
 * flags this DTO's own presence already enforces (a row is only included
 * here when the caller is entitled to see it).
 */
public class ImplementationEvidenceRowDTO {
  @AuraEnabled
  public Id evidenceId;
  @AuraEnabled
  public Id milestoneId;
  @AuraEnabled
  public String evidenceType;
  @AuraEnabled
  public String status;
  @AuraEnabled
  public String contentDocumentId;
  @AuraEnabled
  public Datetime submittedOn;
  @AuraEnabled
  public Datetime reviewedOn;
  @AuraEnabled
  public String reviewOutcome;
  @AuraEnabled
  public String description;
}
