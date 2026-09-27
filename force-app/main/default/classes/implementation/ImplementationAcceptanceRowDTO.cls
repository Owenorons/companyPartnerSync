/**
 * Partner-safe row for one Implementation_Acceptance__c, used in
 * ImplementationDetailDTO's acceptances list.
 */
public class ImplementationAcceptanceRowDTO {
  @AuraEnabled
  public Id acceptanceId;
  @AuraEnabled
  public String acceptanceType;
  @AuraEnabled
  public String status;
  @AuraEnabled
  public String acceptanceMethod;
  @AuraEnabled
  public Datetime requestedOn;
  @AuraEnabled
  public Datetime acceptedOn;
  @AuraEnabled
  public String acceptedByName;
}
