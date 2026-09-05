/*
 * Verifies MDFDomain's validation and mapping: rejects a non-positive
 * requested amount, maps a submitted DTO onto MDF_Request__c fields, and
 * computes remaining budget correctly from annual/used amounts.
 */
@IsTest
private class MDFDomainTest {
  @IsTest
  static void validateSubmitRejectsNegativeAmount() {
    MDFRequestDTO request = validRequest();
    request.requestedAmount = -1;

    try {
      MDFDomain.validateSubmit(request);
      System.assert(false, 'Expected requested amount validation failure.');
    } catch (PartnerSyncHandledException ex) {
      System.assert(
        ex.getMessage().contains('greater than zero'),
        'Unexpected message: ' + ex.getMessage()
      );
    }
  }

  @IsTest
  static void buildRequestMapsMetadataFieldNames() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;

    MDF_Request__c record = MDFDomain.buildRequest(
      validRequest(),
      partner.Id,
      contact.Id
    );

    System.assertEquals(partner.Id, record.Partner_Account__c);
    System.assertEquals(contact.Id, record.Submitted_By__c);
    System.assertEquals('Webinar', record.Campaign_Type__c);
    System.assertEquals('Submitted', record.Status__c);
  }

  @IsTest
  static void budgetDtoCalculatesRemainingBudget() {
    Account account = new Account(
      Name = 'Partner',
      MDF_Annual_Budget__c = 10000,
      MDF_Used__c = 3500
    );

    MDFBudgetDTO dto = MDFDomain.toBudgetDTO(account);

    System.assertEquals(10000, dto.annualBudget);
    System.assertEquals(3500, dto.usedBudget);
    System.assertEquals(6500, dto.remainingBudget);
  }

  @IsTest
  static void validatesEverySubmissionAndDecisionBranch() {
    assertSubmitRejected(null, 'required');
    MDFRequestDTO request = validRequest();
    request.requestType = null;
    assertSubmitRejected(request, 'Request type');
    request = validRequest();
    request.campaignName = null;
    assertSubmitRejected(request, 'Campaign name');
    request = validRequest();
    request.endDate = request.startDate.addDays(-1);
    assertSubmitRejected(request, 'before start');

    assertDecisionRejected(null, 'invalid');
    MDFDecisionDTO decision = new MDFDecisionDTO();
    decision.requestId = UserInfo.getUserId();
    decision.decision = 'Pending';
    assertDecisionRejected(decision, 'Unsupported');
    decision.decision = 'Approved';
    assertDecisionRejected(decision, 'greater than zero');
    decision.decision = 'Rejected';
    decision.rejectionReason = null;
    assertDecisionRejected(decision, 'Rejection reason');
    decision.rejectionReason = 'Outside policy';
    MDFDomain.validateDecision(decision);
    decision.decision = 'Approved';
    decision.approvedAmount = 500;
    MDFDomain.validateDecision(decision);
  }

  @IsTest
  static void mapsCompleteRequestListAndDefaultBudget() {
    MDFRequestDTO request = validRequest();
    request.roiTarget = 40;
    MDF_Request__c record = MDFDomain.buildRequest(
      request,
      UserInfo.getUserId(),
      UserInfo.getUserId()
    );
    record.Name = 'MDF-1';
    record.Approved_Amount__c = 750;
    record.Partner_Account__r = new Account(Name = 'Partner');
    MDFListDTO dto = MDFDomain.toListDTO(record);
    Assert.areEqual('MDF-1', dto.requestNumber);
    Assert.areEqual('Partner', dto.partnerName);
    Assert.areEqual('Campaign', dto.campaignName);
    Assert.areEqual(750, dto.approvedAmount);
    Assert.areEqual(40, record.Expected_Leads__c);

    MDFListDTO noPartner = MDFDomain.toListDTO(new MDF_Request__c());
    Assert.isNull(noPartner.partnerName);
    MDFBudgetDTO emptyBudget = MDFDomain.toBudgetDTO(new Account());
    Assert.areEqual(0, emptyBudget.annualBudget);
    Assert.areEqual(0, emptyBudget.usedBudget);
    Assert.areEqual(0, emptyBudget.remainingBudget);
  }

  private static void assertSubmitRejected(
    MDFRequestDTO request,
    String expectedMessage
  ) {
    try {
      MDFDomain.validateSubmit(request);
      Assert.fail('Expected submission rejection.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains(expectedMessage));
    }
  }

  private static void assertDecisionRejected(
    MDFDecisionDTO request,
    String expectedMessage
  ) {
    try {
      MDFDomain.validateDecision(request);
      Assert.fail('Expected decision rejection.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains(expectedMessage));
    }
  }

  private static MDFRequestDTO validRequest() {
    MDFRequestDTO request = new MDFRequestDTO();
    request.requestType = 'Webinar';
    request.campaignName = 'Campaign';
    request.requestedAmount = 1000;
    request.startDate = Date.today();
    request.endDate = Date.today().addDays(5);
    return request;
  }
}
