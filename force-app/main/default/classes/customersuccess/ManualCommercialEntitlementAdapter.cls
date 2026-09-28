/**
 * CommercialEntitlementAdapter for an internal user recording entitlement
 * dates directly (Known Adaptation #3 - no billing/subscription system
 * exists in this org, so a manual entry is a genuinely real source today,
 * not a placeholder, matching ManualRevenueAdapter's precedent).
 */
public class ManualCommercialEntitlementAdapter implements CommercialEntitlementAdapter {
  public Customer_Commercial_Entitlement__c buildCandidate(
    CommercialEntitlementCommand command
  ) {
    if (command.customerAccountId == null) {
      throw new PartnerSyncHandledException(
        'A customer account is required to record a commercial entitlement.'
      );
    }
    if (command.effectiveStartOn == null || command.effectiveEndOn == null) {
      throw new PartnerSyncHandledException(
        'An effective start and end date are required to record a commercial entitlement.'
      );
    }

    return new Customer_Commercial_Entitlement__c(
      Customer_Account__c = command.customerAccountId,
      Customer_Success_Engagement__c = command.customerSuccessEngagementId,
      Originating_Deal__c = command.originatingDealId,
      Originating_Opportunity__c = command.originatingOpportunityId,
      Product__c = command.product,
      Product_Family__c = command.productFamily,
      Entitlement_Type__c = command.entitlementType,
      Effective_Start_On__c = command.effectiveStartOn,
      Effective_End_On__c = command.effectiveEndOn,
      Quantity__c = command.quantity,
      Auto_Renew__c = command.autoRenew == true,
      Renewal_Notice_Days__c = command.renewalNoticeDays,
      Cancellation_Notice_Days__c = command.cancellationNoticeDays,
      External_Contract_Id__c = command.externalContractId,
      External_Subscription_Id__c = command.externalSubscriptionId,
      Source_System__c = 'PartnerSync',
      Status__c = 'Active',
      Version_Number__c = 0
    );
  }
}
