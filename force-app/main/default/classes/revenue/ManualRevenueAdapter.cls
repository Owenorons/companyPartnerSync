/**
 * RevenueSourceAdapter for an internal user logging a revenue event
 * directly (Adaptation #2 - no ERP/Revenue Cloud integration exists in
 * this org, so a manual entry is a genuinely real source today, not a
 * placeholder). Any Revenue_Type__c is permitted, since a manual entry is
 * exactly the escape hatch doc §41.11's "Manual" Source_Type__c is for
 * (explicitly requiring additional authorization - see
 * RevenueCommandService's permission check on the Create action).
 */
public class ManualRevenueAdapter implements RevenueSourceAdapter {
  public Deal_Revenue__c buildCandidate(RevenueImportRequest request) {
    if (String.isBlank(request.revenueType)) {
      throw new PartnerSyncHandledException(
        'A revenue type is required for a manual revenue entry.'
      );
    }
    if (request.grossAmount == null) {
      throw new PartnerSyncHandledException(
        'A gross amount is required for a manual revenue entry.'
      );
    }

    Deal_Revenue__c revenue = new Deal_Revenue__c(
      Deal__c = request.explicitDealId,
      Opportunity__c = request.opportunityId,
      Implementation__c = request.implementationId,
      Revenue_Type__c = request.revenueType,
      Source_Type__c = 'Manual',
      Status__c = 'Pending',
      Gross_Amount__c = request.grossAmount,
      Net_Amount__c = request.netAmount,
      Eligible_Amount__c = request.eligibleAmount,
      CurrencyIsoCode = String.isBlank(request.currencyIsoCode)
        ? 'USD'
        : request.currencyIsoCode,
      Revenue_Date__c = request.revenueDate == null
        ? Date.today()
        : request.revenueDate,
      Accounting_Period__c = request.accountingPeriod,
      Quantity__c = request.quantity,
      Unit_Value__c = request.unitValue,
      Source_System__c = 'PartnerSync',
      Source_Record_Type__c = request.sourceRecordType,
      Source_Record_Id__c = request.sourceRecordId,
      Source_Transaction_Id__c = request.sourceTransactionId,
      Source_Event_Id__c = request.sourceEventId,
      Source_Effective_On__c = request.sourceEffectiveOn == null
        ? System.now()
        : request.sourceEffectiveOn,
      External_Revenue_Key__c = request.externalRevenueKey,
      Tax_Amount__c = request.taxAmount,
      Tax_Inclusive__c = request.taxInclusive == true,
      Imported_On__c = System.now(),
      Version_Number__c = 0
    );
    return revenue;
  }
}
