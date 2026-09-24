/*
 * Test coverage for PartnerSignatureProviderRouter's fallback-to-disabled
 * rules and provider-type resolution, relying on the org's shipped
 * Signature_Provider_Config__mdt records (Disabled ships Active__c =
 * true by default; DocuSign ships Active__c = false).
 */
@IsTest
private class PartnerSignatureProviderRouterTest {
  @IsTest
  static void defaultConfigurationReturnsDisabledProvider() {
    PartnerSignatureProvider provider = PartnerSignatureProviderRouter.getProvider();

    Assert.isTrue(
      provider instanceof DisabledSignatureProvider,
      'With only the Disabled config active by default, the router should return DisabledSignatureProvider.'
    );
    Assert.areEqual(
      'Disabled',
      PartnerSignatureProviderRouter.getActiveProviderName()
    );
  }

  @IsTest
  static void explicitTestConfigurationRoutesToDocuSign() {
    try {
      PartnerSignatureProviderRouter.providerConfigForTest = new Signature_Provider_Config__mdt(
        Active__c = true,
        Provider_Name__c = 'DocuSign',
        Provider_Type__c = 'DocuSign'
      );

      Assert.isTrue(
        PartnerSignatureProviderRouter.getProvider() instanceof DocuSignSignatureProvider
      );
      Assert.areEqual(
        'DocuSign',
        PartnerSignatureProviderRouter.getActiveProviderName()
      );
    } finally {
      PartnerSignatureProviderRouter.providerConfigForTest = null;
    }
  }

  @IsTest
  static void providerForRoutesByType() {
    Assert.isTrue(
      PartnerSignatureProviderRouter.providerFor(
        'DocuSign'
      ) instanceof DocuSignSignatureProvider,
      'DocuSign provider type should resolve to DocuSignSignatureProvider.'
    );
    Assert.isTrue(
      PartnerSignatureProviderRouter.providerFor(
        'SomethingElse'
      ) instanceof DisabledSignatureProvider,
      'Unrecognized provider types should resolve to DisabledSignatureProvider.'
    );
  }
}
