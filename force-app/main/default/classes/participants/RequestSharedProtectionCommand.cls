/**
 * Request payload to link an Active Deal_Participant__c to the deal's
 * current Deal_Protection_Grant__c as a candidate shared-protection
 * participant. Requesting does not itself grant anything - see
 * ApproveSharedProtectionCommand.
 */
public class RequestSharedProtectionCommand {
  public Id dealId;
  public Id participantId;
  public String protectionRole;
  public Decimal sharePercentage;
  public Decimal contributionPercentage;
  public String reason;
}
