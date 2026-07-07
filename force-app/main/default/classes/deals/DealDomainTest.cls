@IsTest
private class DealDomainTest {
  @IsTest
  static void validateRejectsMissingOpportunity() {
    DealRegistrationRequestDTO request = new DealRegistrationRequestDTO();
    request.estimatedRevenue = 1000;

    try {
      DealRegistrationDomain.validate(request);
      System.assert(false, 'Expected missing opportunity validation failure.');
    } catch (PartnerSyncHandledException ex) {
      System.assert(
        ex.getMessage().contains('Opportunity Id'),
        'Unexpected message: ' + ex.getMessage()
      );
    }
  }

  @IsTest
  static void buildRecordMapsOpportunityAndRequestFields() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert new List<Account>{ partner, customer };

    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;

    Opportunity opportunity = PartnerSyncTestDataFactory.opportunity(
      customer.Id,
      partner.Id,
      contact.Id
    );
    insert opportunity;

    DealRegistrationRequestDTO request = new DealRegistrationRequestDTO();
    request.opportunityId = opportunity.Id;
    request.businessProblem = 'Problem';
    request.proposedSolution = 'Solution';
    request.estimatedRevenue = 25000;
    request.estimatedCloseDate = Date.today().addDays(20);
    request.implementationTimeline = 'This quarter';
    request.notes = 'Notes';

    Deal_Registration__c record = DealRegistrationDomain.buildRecord(
      opportunity,
      request
    );

    System.assertEquals(opportunity.Id, record.Opportunity__c);
    System.assertEquals(customer.Id, record.Customer_Account__c);
    System.assertEquals(partner.Id, record.Partner_Account__c);
    System.assertEquals(25000, record.Estimated_Revenue__c);
    System.assertEquals('Pending Analysis', record.Conflict_Status__c);
  }

  @IsTest
  static void validateReviewDecisionRequiresRejectionReason() {
    DealReviewDecisionDTO request = new DealReviewDecisionDTO();
    request.dealId = UserInfo.getUserId();
    request.decision = 'Rejected';

    try {
      DealReviewDomain.validateDecision(request);
      System.assert(false, 'Expected rejection reason validation failure.');
    } catch (PartnerSyncHandledException ex) {
      System.assert(
        ex.getMessage().contains('Rejection reason'),
        'Unexpected message: ' + ex.getMessage()
      );
    }
  }
}
