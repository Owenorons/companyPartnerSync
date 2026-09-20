@IsTest
private class CustomerAccountServiceTest {
  @IsTest
  static void createsCustomerWhenNoMatchExists() {
    CustomerAccountMatchDTO result = CustomerAccountService.findOrCreateCustomerAccount(
      'New Customer',
      'buyer@new-customer.example'
    );

    System.assertEquals(
      true,
      result.created,
      'A new customer should be created.'
    );
    System.assertEquals(
      'New Customer',
      result.accountName,
      'The customer name should be preserved.'
    );
    Account created = [
      SELECT Is_Partner__c
      FROM Account
      WHERE Id = :result.accountId
    ];
    System.assertEquals(
      false,
      created.Is_Partner__c,
      'Customer accounts must not be partners.'
    );
  }

  @IsTest
  static void reusesExistingCustomerByName() {
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Existing Customer'
    );
    insert customer;

    CustomerAccountMatchDTO result = CustomerAccountService.findOrCreateCustomerAccount(
      'Existing Customer',
      null
    );

    System.assertEquals(
      false,
      result.created,
      'An exact match should be reused.'
    );
    System.assertEquals(
      customer.Id,
      result.accountId,
      'The existing customer should be returned.'
    );
  }

  @IsTest
  static void leadOverloadReusesExplicitCustomer() {
    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;
    Lead lead = new Lead(
      LastName = 'Buyer',
      Company = 'Different Company',
      Customer_Account__c = customer.Id
    );

    CustomerAccountMatchDTO result = CustomerAccountService.findOrCreateCustomerAccount(
      lead
    );

    System.assertEquals(
      false,
      result.created,
      'An explicit lookup should be reused.'
    );
    System.assertEquals(
      customer.Id,
      result.accountId,
      'The explicit customer should be returned.'
    );
  }

  @IsTest
  static void rejectsBlankCompanyAndPartnerLookup() {
    try {
      CustomerAccountService.findOrCreateCustomerAccount(null, null);
      System.assert(false, 'Blank company input must fail.');
    } catch (PartnerSyncHandledException ex) {
      System.assert(
        ex.getMessage().contains('Company name'),
        'The error should identify company name.'
      );
    }

    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;
    Lead lead = new Lead(
      LastName = 'Buyer',
      Company = 'Partner',
      Customer_Account__c = partner.Id
    );
    try {
      CustomerAccountService.findOrCreateCustomerAccount(lead);
      System.assert(false, 'A partner account cannot be used as a customer.');
    } catch (PartnerSyncHandledException ex) {
      System.assert(
        ex.getMessage().contains('not found'),
        'Partner accounts must be rejected as customers.'
      );
    }
  }

  @IsTest
  static void leadOverloadCreatesAndMatchesCustomers() {
    Lead newCustomerLead = new Lead(
      LastName = 'Buyer',
      Company = 'Lead Customer',
      Email = 'buyer@lead-customer.example'
    );
    CustomerAccountMatchDTO created = CustomerAccountService.findOrCreateCustomerAccount(
      newCustomerLead
    );
    Assert.isTrue(created.created);
    Assert.areEqual('Lead Customer', created.accountName);

    Lead matchingLead = new Lead(
      LastName = 'Second Buyer',
      Company = 'Lead Customer',
      Email = 'invalid-email'
    );
    CustomerAccountMatchDTO matched = CustomerAccountService.findOrCreateCustomerAccount(
      matchingLead
    );
    Assert.isFalse(matched.created);
    Assert.areEqual(created.accountId, matched.accountId);
  }

  @IsTest
  static void leadOverloadRejectsMissingInput() {
    assertLeadRejected(null, 'Lead is required');
    assertLeadRejected(
      new Lead(LastName = 'Buyer'),
      'Lead company is required'
    );
  }

  private static void assertLeadRejected(Lead lead, String expectedMessage) {
    try {
      CustomerAccountService.findOrCreateCustomerAccount(lead);
      Assert.fail('Expected invalid lead input to be rejected.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains(expectedMessage));
    }
  }
}
