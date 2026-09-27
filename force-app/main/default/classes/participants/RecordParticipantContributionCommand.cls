/**
 * Request to record a participant's contribution along one dimension
 * (Origination/Sales/Technical/etc.) - independent of protection and
 * revenue share (doc §38.31).
 */
public class RecordParticipantContributionCommand {
  public Id participantId;
  public String contributionType;
  public Decimal percentage;
  public String source;
  public String reason;
}
