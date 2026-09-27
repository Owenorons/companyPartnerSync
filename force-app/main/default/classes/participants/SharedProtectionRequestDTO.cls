/**
 * A row in the internal "Shared Protection Requests" workbench view.
 */
public class SharedProtectionRequestDTO {
  @AuraEnabled
  public Id protectionParticipantId;
  @AuraEnabled
  public Id dealId;
  @AuraEnabled
  public String participantOrganisationName;
  @AuraEnabled
  public String protectionRole;
  @AuraEnabled
  public Decimal sharePercentage;
  @AuraEnabled
  public Datetime requestedOn;
  @AuraEnabled
  public Integer grantVersionNumber;
}
