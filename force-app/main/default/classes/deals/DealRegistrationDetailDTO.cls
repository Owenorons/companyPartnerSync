/**
 * Row shape for a single deal registration's detail view (the "View"
 * drill-down from psDealList). Compare to DealRegistrationListDTO, the
 * lighter row shape used for the "My Deals" list itself.
 */
public with sharing class DealRegistrationDetailDTO {
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
   * Attribution classification (Partner-Sourced or Co-Sell).
   */
  @AuraEnabled
  public String attributionType { get; set; }

  /**
   * Estimated revenue value of the deal.
   */
  @AuraEnabled
  public Decimal dealValue { get; set; }
  /**
   * Estimated close date of the deal.
   */
  @AuraEnabled
  public Date estimatedCloseDate { get; set; }
  /**
   * Date the deal's protection window ends, if any.
   */
  @AuraEnabled
  public Date protectionEndDate { get; set; }

  /**
   * The customer's business problem, as submitted by the partner.
   */
  @AuraEnabled
  public String businessProblem { get; set; }
  /**
   * The partner's proposed solution.
   */
  @AuraEnabled
  public String proposedSolution { get; set; }
  /**
   * Free-text notes on the registration.
   */
  @AuraEnabled
  public String notes { get; set; }

  /**
   * Current lifecycle phase (e.g. Registration, Review, Protection, Sales Execution).
   */
  @AuraEnabled
  public String lifecyclePhase { get; set; }
  /**
   * Current lifecycle health (e.g. Healthy, At Risk, Blocked, Overdue).
   */
  @AuraEnabled
  public String lifecycleHealth { get; set; }
  /**
   * Description of the action currently required to move the deal forward, if any.
   */
  @AuraEnabled
  public String currentActionRequired { get; set; }
  /**
   * Date/time the next action is due, if any.
   */
  @AuraEnabled
  public Datetime nextActionDue { get; set; }

  /**
   * Date/time the deal registration record was created.
   */
  @AuraEnabled
  public Datetime createdDate { get; set; }

  /**
   * The deal's partner-visible lifecycle events, most recent first.
   */
  @AuraEnabled
  public List<DealTimelineEventDTO> events { get; set; }
}
