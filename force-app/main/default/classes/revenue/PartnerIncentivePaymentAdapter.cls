/**
 * Would integrate incentive payment with an external payment system/ERP
 * (doc Sprint 41 §41.40). Interface-only, zero real implementations
 * (Known Adaptation #3) - no payment system exists in this org, unlike
 * RevenueSourceAdapter which has two real sources today. Defined now so a
 * future integration is a clean addition rather than a retrofit.
 */
public interface PartnerIncentivePaymentAdapter {
  /**
   * Submits a payment for processing and returns its resulting status.
   *
   * @param payment The Partner_Incentive_Payment__c record to submit.
   * @return The resulting Status__c value.
   */
  String submitPayment(Partner_Incentive_Payment__c payment);
}
