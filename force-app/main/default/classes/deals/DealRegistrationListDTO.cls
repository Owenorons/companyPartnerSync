/**
 * Row shape for a partner's own "My Deals" list. Scoped to a single
 * partner's registrations (see DealRegistrationSelector.selectPartnerDeals);
 * compare to DealReviewListDTO, the equivalent row shape used by internal
 * reviewers to see deals across all partners.
 */
public with sharing class DealRegistrationListDTO {
  /**
   * Id of the deal registration record.
   */
  @AuraEnabled
  public Id dealId { get; set; }
  /**
   * Display name/number of the deal registration record.
   */
  @AuraEnabled
  public String dealNumber { get; set; }

  /**
   * Name of the customer account associated with the deal.
   */
  @AuraEnabled
  public String customerName { get; set; }
  /**
   * Name of the partner account that submitted the deal.
   */
  @AuraEnabled
  public String partnerName { get; set; }

  /**
   * Estimated revenue value of the deal.
   */
  @AuraEnabled
  public Decimal dealValue { get; set; }
  /**
   * Stage of the underlying opportunity.
   */
  @AuraEnabled
  public String stage { get; set; }

  /**
   * Current status of the deal registration (e.g. Submitted, Approved, Rejected).
   */
  @AuraEnabled
  public String status { get; set; }
  /**
   * Current conflict status of the deal registration.
   */
  @AuraEnabled
  public String conflictStatus { get; set; }

  /**
   * Date the deal's protection window ends, if any.
   */
  @AuraEnabled
  public Date protectionEndDate { get; set; }
  /**
   * Date/time the deal registration record was created.
   */
  @AuraEnabled
  public Datetime createdDate { get; set; }
}
