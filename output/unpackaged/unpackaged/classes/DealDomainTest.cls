/*
 * Unit tests for the domain-layer build/validate logic shared by the
 * registration side (DealRegistrationDomain) and the internal review side
 * (DealReviewDomain). Kept together because both domains' validation rules
 * are exercised against the same underlying Deal_Registration__c shape.
 */
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
    System.assertEquals('None', record.Conflict_Status__c);
  }

  @IsTest
  static void buildRecordCopiesSourceLeadFromOpportunity() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert new List<Account>{ partner, customer };

    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;

    Lead sourceLead = PartnerSyncTestDataFactory.lead(partner.Id, contact.Id);
    insert sourceLead;

    Opportunity opportunity = PartnerSyncTestDataFactory.opportunity(
      customer.Id,
      partner.Id,
      contact.Id
    );
    opportunity.Source_Lead__c = sourceLead.Id;
    insert opportunity;

    DealRegistrationRequestDTO request = new DealRegistrationRequestDTO();
    request.opportunityId = opportunity.Id;
    request.estimatedRevenue = 25000;

    Deal_Registration__c record = DealRegistrationDomain.buildRecord(
      opportunity,
      request
    );

    System.assertEquals(
      sourceLead.Id,
      record.Source_Lead__c,
      'A deal registered against an opportunity that came from a lead should carry that lineage.'
    );
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

  @IsTest
  static void validatesRegistrationAndAllReviewDecisionBranches() {
    assertRegistrationRejected(null, 'request is required');
    DealRegistrationRequestDTO registration = new DealRegistrationRequestDTO();
    registration.opportunityId = UserInfo.getUserId();
    assertRegistrationRejected(registration, 'Estimated revenue');
    registration.estimatedRevenue = 100;
    DealRegistrationDomain.validate(registration);

    assertReviewRejected(null, 'invalid');
    DealReviewDecisionDTO review = new DealReviewDecisionDTO();
    review.dealId = UserInfo.getUserId();
    review.decision = 'Unknown';
    assertReviewRejected(review, 'Unsupported');
    review.decision = 'Protection Extended';
    assertReviewRejected(review, 'greater than zero');
    review.protectionExtensionDays = 15;
    DealReviewDomain.validateDecision(review);
    review.decision = 'Rejected';
    review.rejectionReason = 'Outside policy';
    DealReviewDomain.validateDecision(review);
    review.decision = 'Approved';
    DealReviewDomain.validateDecision(review);
  }

  @IsTest
  static void mapsRegistrationReviewDetailListAndConflicts() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert new List<Account>{ partner, customer };
    Opportunity opportunity = new Opportunity(
      Name = 'Opportunity',
      AccountId = customer.Id,
      Partner_Account__c = partner.Id,
      StageName = 'Qualification',
      CloseDate = Date.today().addDays(30),
      Amount = 5000
    );
    insert opportunity;
    Deal_Registration__c deal = new Deal_Registration__c(
      Opportunity__c = opportunity.Id,
      Customer_Account__c = customer.Id,
      Partner_Account__c = partner.Id,
      Status__c = 'Submitted',
      Conflict_Status__c = 'Potential Conflict',
      Estimated_Revenue__c = 5000,
      Estimated_Close_Date__c = Date.today().addDays(30),
      Business_Problem__c = 'Problem',
      Proposed_Solution__c = 'Solution',
      Implementation_Timeline__c = 'Quarter',
      Notes__c = 'Notes',
      Approval_Notes__c = 'Review',
      Rejection_Reason__c = 'None',
      Conflict_Resolution_Notes__c = 'Pending',
      Submitted_On__c = System.now()
    );
    Deal_Registration__c conflict = new Deal_Registration__c(
      Customer_Account__c = customer.Id,
      Partner_Account__c = partner.Id,
      Status__c = 'Approved',
      Conflict_Status__c = 'None',
      Estimated_Revenue__c = 2500
    );
    insert new List<Deal_Registration__c>{ deal, conflict };
    deal = selectDeal(deal.Id);
    conflict = selectDeal(conflict.Id);

    DealRegistrationResultDTO result = DealRegistrationDomain.toDTO(deal);
    Assert.areEqual(deal.Id, result.dealRegistrationId);
    Assert.areEqual('Submitted', result.status);
    DealRegistrationListDTO registrationList = DealRegistrationDomain.toListDTO(
      deal
    );
    Assert.areEqual('Customer', registrationList.customerName);
    Assert.areEqual('Partner', registrationList.partnerName);
    Assert.areEqual('Qualification', registrationList.stage);

    DealReviewListDTO reviewList = DealReviewDomain.toListDTO(deal);
    Assert.areEqual('Customer', reviewList.customerName);
    Assert.areEqual('Partner', reviewList.partnerName);
    DealReviewDetailDTO detail = DealReviewDomain.toDetailDTO(
      deal,
      new List<Deal_Registration__c>{ conflict }
    );
    Assert.areEqual(1, detail.conflicts.size());
    Assert.areEqual('Partner', detail.conflicts[0].partnerName);
    Assert.isNotNull(detail.riskScore);

    Deal_Registration__c noParents = new Deal_Registration__c();
    Assert.isNull(DealReviewDomain.toListDTO(noParents).customerName);
    Assert.isNull(DealReviewDomain.toConflictDTO(noParents).partnerName);
  }

  private static Deal_Registration__c selectDeal(Id dealId) {
    return [
      SELECT
        Id,
        Name,
        Opportunity__c,
        Opportunity__r.StageName,
        Customer_Account__c,
        Customer_Account__r.Name,
        Partner_Account__c,
        Partner_Account__r.Name,
        Estimated_Revenue__c,
        Estimated_Close_Date__c,
        Business_Problem__c,
        Proposed_Solution__c,
        Implementation_Timeline__c,
        Notes__c,
        Status__c,
        Conflict_Status__c,
        Protection_End_Date__c,
        Submitted_On__c,
        Approval_Notes__c,
        Rejection_Reason__c,
        Conflict_Resolution_Notes__c,
        CreatedDate
      FROM Deal_Registration__c
      WHERE Id = :dealId
    ];
  }

  private static void assertRegistrationRejected(
    DealRegistrationRequestDTO request,
    String expectedMessage
  ) {
    try {
      DealRegistrationDomain.validate(request);
      Assert.fail('Expected invalid registration rejection.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains(expectedMessage));
    }
  }

  private static void assertReviewRejected(
    DealReviewDecisionDTO request,
    String expectedMessage
  ) {
    try {
      DealReviewDomain.validateDecision(request);
      Assert.fail('Expected invalid review rejection.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains(expectedMessage));
    }
  }
}
