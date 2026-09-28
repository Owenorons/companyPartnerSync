/**
 * Request payload for CustomerSuccessActivityCommandService.record.
 */
public class CustomerSuccessActivityCommand {
  public Id engagementId;
  public String activityType;
  public String summary;
  public Datetime occurredOn;
}
