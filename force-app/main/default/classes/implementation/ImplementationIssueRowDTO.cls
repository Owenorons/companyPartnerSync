/**
 * Partner-safe row for one Implementation_Issue__c, used in
 * ImplementationDetailDTO's issues list. Omits Commercial_Impact__c and
 * Partner_Account__c - commercial detail isn't partner-facing.
 */
public class ImplementationIssueRowDTO {
  @AuraEnabled
  public Id issueId;
  @AuraEnabled
  public String title;
  @AuraEnabled
  public String issueType;
  @AuraEnabled
  public String severity;
  @AuraEnabled
  public String status;
  @AuraEnabled
  public Datetime raisedOn;
  @AuraEnabled
  public Datetime resolvedOn;
  @AuraEnabled
  public Date targetResolutionOn;
  @AuraEnabled
  public Boolean customerImpact;
}
