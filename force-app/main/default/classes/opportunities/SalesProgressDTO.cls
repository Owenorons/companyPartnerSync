/**
 * Partner-safe summary of a deal's sales progress (Sprint 39 §39.36-39.38).
 * Matches, not exceeds, this org's actual pre-existing partner-facing
 * Opportunity exposure baseline (EligibleOpportunityDTO already shows
 * Amount/Name/StageName/CloseDate pre-registration) - explicitly excludes
 * forecast notes, margin, competitor intel, and discounts, none of which
 * any existing DTO exposes today either. Compare to
 * DealRegistrationDetailDTO, the equivalent full-deal detail shape.
 */
public class SalesProgressDTO {
  @AuraEnabled
  public Id dealId;
  @AuraEnabled
  public String stage;
  @AuraEnabled
  public Boolean isWon;
  @AuraEnabled
  public Boolean isClosed;
  @AuraEnabled
  public Decimal amount;
  @AuraEnabled
  public Date closeDate;
  @AuraEnabled
  public Integer opportunityCount;
}
