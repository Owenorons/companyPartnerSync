/**
 * Request to transfer a deal's primary/originating partner to a new
 * partner account - a governed operation (doc §38.41), not an ordinary
 * field edit.
 */
public class TransferDealOwnershipCommand {
  public Id dealId;
  public Id newPartnerAccountId;
  public Integer expectedDealVersion;
  public String reason;
}
