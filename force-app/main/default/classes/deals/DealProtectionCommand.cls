/**
 * Request payload for a deal protection lifecycle command, describing the
 * target deal, the action, and any protection-extension details.
 */
public class DealProtectionCommand {
  public Id dealId;
  public String action;
  public String commandKey;
  public Integer expectedVersion;
  public Integer extensionDays;
  public String reason;
}
