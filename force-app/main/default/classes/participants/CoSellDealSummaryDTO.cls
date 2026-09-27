/**
 * Partner-safe summary row for the internal "Active Co-Sell Deals"
 * workbench view - no internal conflict/review/approval fields.
 */
public class CoSellDealSummaryDTO {
  @AuraEnabled
  public Id dealId;
  @AuraEnabled
  public String customerName;
  @AuraEnabled
  public String originatingPartnerName;
  @AuraEnabled
  public String coSellStatus;
  @AuraEnabled
  public Integer activeParticipantCount;
}
