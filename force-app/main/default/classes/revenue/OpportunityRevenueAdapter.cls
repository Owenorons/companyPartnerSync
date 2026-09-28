/**
 * RevenueSourceAdapter for the Opportunity itself at Closed Won (Adaptation
 * #2). Deliberately produces a 'Booking' revenue event only, never
 * 'Recognised Revenue' - doc §41.13's core invariant is that
 * Opportunity.Amount is not proof of recognised revenue, so this adapter
 * must not be used to fabricate one. A real ERP/Revenue Cloud integration
 * would eventually supply Recognised Revenue events separately.
 */
public without sharing class OpportunityRevenueAdapter implements RevenueSourceAdapter {
  public Deal_Revenue__c buildCandidate(RevenueImportRequest request) {
    if (request.opportunityId == null) {
      throw new PartnerSyncHandledException(
        'An opportunity is required to book revenue from it.'
      );
    }

    List<Opportunity> opportunities = [
      SELECT Id, Amount, CloseDate, IsWon, IsClosed
      FROM Opportunity
      WHERE Id = :request.opportunityId
      WITH SYSTEM_MODE
    ];
    if (opportunities.isEmpty()) {
      throw new PartnerSyncHandledException('Opportunity not found.');
    }
    Opportunity opportunity = opportunities[0];
    if (opportunity.IsClosed != true || opportunity.IsWon != true) {
      throw new PartnerSyncHandledException(
        'Only a Closed Won opportunity can be booked as revenue.'
      );
    }
    if (opportunity.Amount == null) {
      throw new PartnerSyncHandledException(
        'The opportunity has no amount to book.'
      );
    }

    return new Deal_Revenue__c(
      Deal__c = request.explicitDealId,
      Opportunity__c = opportunity.Id,
      Implementation__c = request.implementationId,
      Revenue_Type__c = 'Booking',
      Source_Type__c = 'Opportunity',
      Status__c = 'Pending',
      Gross_Amount__c = opportunity.Amount,
      Net_Amount__c = opportunity.Amount,
      CurrencyIsoCode = String.isBlank(request.currencyIsoCode)
        ? 'USD'
        : request.currencyIsoCode,
      Revenue_Date__c = opportunity.CloseDate,
      Source_System__c = 'Salesforce Opportunity',
      Source_Record_Type__c = 'Opportunity',
      Source_Record_Id__c = opportunity.Id,
      Source_Effective_On__c = System.now(),
      External_Revenue_Key__c = 'OPPORTUNITY|BOOKING|' + opportunity.Id,
      Imported_On__c = System.now(),
      Version_Number__c = 0
    );
  }
}
