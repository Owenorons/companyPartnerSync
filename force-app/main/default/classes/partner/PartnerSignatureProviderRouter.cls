/**
 * Central dispatcher to a live PartnerSignatureProvider instance.
 * Resolution is fail-safe by design: any missing/inactive/misconfigured
 * provider config routes to DisabledSignatureProvider rather than
 * throwing, so an incomplete e-signature setup degrades to a clear
 * "not configured" failure instead of an unhandled exception.
 */
public with sharing class PartnerSignatureProviderRouter {
  @TestVisible
  private static Signature_Provider_Config__mdt providerConfigForTest;

  /**
   * Resolves the currently active PartnerSignatureProvider, falling back
   * to DisabledSignatureProvider when no provider is configured active.
   *
   * @return The PartnerSignatureProvider implementation to use.
   */
  public static PartnerSignatureProvider getProvider() {
    return providerFor(activeConfigType());
  }

  /**
   * The display name of the currently active provider, for recording
   * against Partner_Agreement__c.Provider__c. Returns 'Disabled' when no
   * provider is configured active.
   *
   * @return The active provider's display name.
   */
  public static String getActiveProviderName() {
    Signature_Provider_Config__mdt config = activeConfig();
    return config == null || String.isBlank(config.Provider_Name__c)
      ? 'Disabled'
      : config.Provider_Name__c;
  }

  /**
   * Resolves a concrete PartnerSignatureProvider implementation for a
   * provider type, falling back to DisabledSignatureProvider for any
   * unrecognized type.
   *
   * @param providerType The provider type, e.g. 'DocuSign'.
   * @return The matching PartnerSignatureProvider implementation.
   */
  public static PartnerSignatureProvider providerFor(String providerType) {
    if (providerType == 'DocuSign') {
      return new DocuSignSignatureProvider();
    }

    return new DisabledSignatureProvider();
  }

  private static String activeConfigType() {
    Signature_Provider_Config__mdt config = activeConfig();
    return config == null ? 'Disabled' : config.Provider_Type__c;
  }

  private static Signature_Provider_Config__mdt activeConfig() {
    if (Test.isRunningTest() && providerConfigForTest != null) {
      return providerConfigForTest;
    }

    List<Signature_Provider_Config__mdt> configs = [
      SELECT
        DeveloperName,
        Provider_Name__c,
        Provider_Type__c,
        Active__c,
        Named_Credential__c
      FROM Signature_Provider_Config__mdt
      WHERE Active__c = TRUE
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    return configs.isEmpty() ? null : configs[0];
  }
}
