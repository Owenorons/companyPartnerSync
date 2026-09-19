@IsTest
private class DealCustomerIdentityServiceTest {
  @IsTest
  static void derivesDeterministicCountryAwareIdentity() {
    Account account = new Account(
      Name = 'Acme Pty Ltd',
      Tradestyle = 'ACME Cloud',
      Website = 'https://www.acme.example/path',
      Phone = '+61 (03) 9999 0000',
      BillingStreet = '1 Main Street',
      BillingCity = 'Melbourne',
      BillingState = 'VIC',
      BillingPostalCode = '3000',
      BillingCountry = 'Australia',
      AccountNumber = 'REG-12345678'
    );
    insert account;

    DealCustomerIdentity first = DealCustomerIdentityService.derive(account.Id);
    DealCustomerIdentity second = DealCustomerIdentityService.derive(
      account.Id
    );
    Assert.areEqual('acme', first.normalizedLegalName);
    Assert.areEqual('acme cloud', first.normalizedTradingName);
    Assert.areEqual('acme.example', first.normalizedDomain);
    Assert.areEqual('610399990000', first.normalizedPhone);
    Assert.areEqual('australia', first.country);
    Assert.areEqual('****5678', first.maskedRegistrationId);
    Assert.areEqual(64, first.fingerprint.length());
    Assert.areEqual(first.fingerprint, second.fingerprint);
  }

  @IsTest
  static void representsMissingIdentityComponentsExplicitly() {
    DealCustomerIdentity identity = DealCustomerIdentityService.derive(null);
    Assert.areEqual('v1', identity.schemaVersion);
    Assert.areEqual(64, identity.fingerprint.length());
  }
}
