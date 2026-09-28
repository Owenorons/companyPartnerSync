/**
 * Request payload shared by record/reverse on
 * IncentivePaymentCommandService.
 */
public class IncentivePaymentCommand {
  public Id paymentId;
  public Id incentiveId;
  public String action;
  public Integer expectedVersion;
  public String reason;

  // Record-only fields.
  public Decimal amount;
  public String paymentReference;
  public String paymentSystem;
}
