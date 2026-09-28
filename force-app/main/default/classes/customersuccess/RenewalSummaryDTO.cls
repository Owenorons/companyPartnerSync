/**
 * Partner-safe summary of a Partner_Renewal__c, for
 * CustomerSuccessController.
 */
public class RenewalSummaryDTO {
  @AuraEnabled
  public Id renewalId;
  @AuraEnabled
  public Id engagementId;
  @AuraEnabled
  public String status;
  @AuraEnabled
  public String renewalHealth;
  @AuraEnabled
  public Date targetDecisionOn;
  @AuraEnabled
  public Id primaryPartnerId;
  @AuraEnabled
  public Integer versionNumber;
}
