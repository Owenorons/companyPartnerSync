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
