/**
 * Partner-safe summary of a Deal_Participant__c row (doc §38.24 - no
 * internal Deal_Conflict__c/Deal_Review__c/Deal_Approval__c fields ever
 * appear here), for both the partner-facing deal team card and the
 * internal co-sell workbench.
 */
public class DealParticipantSummaryDTO {
  @AuraEnabled
  public Id participantId;
  @AuraEnabled
  public Id dealId;
  @AuraEnabled
  public String organisationName;
  @AuraEnabled
  public String participantType;
  @AuraEnabled
  public String participantRole;
  @AuraEnabled
  public String status;
  @AuraEnabled
  public String accessLevel;
  @AuraEnabled
  public Boolean isOwnOrganisation;
  @AuraEnabled
  public Boolean canAccept;
  @AuraEnabled
  public Boolean canDecline;
  @AuraEnabled
  public Datetime invitedOn;
  @AuraEnabled
  public Datetime respondBy;
  @AuraEnabled
  public Datetime effectiveFrom;
  @AuraEnabled
  public Integer versionNumber;
}
