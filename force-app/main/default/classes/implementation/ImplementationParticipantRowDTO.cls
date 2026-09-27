/**
 * Partner-safe row for one Implementation_Participant__c, used in
 * ImplementationDetailDTO's participants list. "role" here is the
 * delivery role (§40's own naming-collision note - see
 * ImplementationParticipantSharingService's class comment), distinct
 * from Deal_Participant__c.Participant_Role__c.
 */
public class ImplementationParticipantRowDTO {
  @AuraEnabled
  public Id implementationParticipantId;
  @AuraEnabled
  public Id dealParticipantId;
  @AuraEnabled
  public String partnerAccountName;
  @AuraEnabled
  public String role;
  @AuraEnabled
  public String status;
  @AuraEnabled
  public Boolean isPrimary;
}
