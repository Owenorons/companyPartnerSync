/**
 * Request payload to approve a Proposed Deal_Protection_Participant__c,
 * activating its share of the deal's current protection grant.
 */
public class ApproveSharedProtectionCommand {
  public Id protectionParticipantId;
  public Integer expectedGrantVersion;
  public String reason;
}
