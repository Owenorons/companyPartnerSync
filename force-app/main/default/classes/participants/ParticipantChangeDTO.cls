/**
 * A row in the internal "Participant Changes" workbench view, sourced from
 * Audit_Log__c entries AuditEventConsumerService writes for participant
 * lifecycle events.
 */
public class ParticipantChangeDTO {
  @AuraEnabled
  public Id dealId;
  @AuraEnabled
  public String action;
  @AuraEnabled
  public String performedByName;
  @AuraEnabled
  public Datetime performedOn;
}
