/**
 * Partner-safe summary of a Customer_Success_Engagement__c, for
 * CustomerSuccessController.
 */
public class CustomerSuccessSummaryDTO {
  @AuraEnabled
  public Id engagementId;
  @AuraEnabled
  public Id customerAccountId;
  @AuraEnabled
  public String status;
  @AuraEnabled
  public String healthStatus;
  @AuraEnabled
  public Decimal healthScore;
  @AuraEnabled
  public Id primaryPartnerId;
  @AuraEnabled
  public Id currentRenewalId;
}
