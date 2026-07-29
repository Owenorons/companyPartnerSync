/*
 * Central dispatcher from a feature name to a live AIProvider instance.
 * Resolution is fail-safe by design: any missing/disabled feature config
 * or inactive/misconfigured provider config routes to DisabledAIProvider
 * rather than throwing, so a bad or incomplete AI setup degrades a
 * feature instead of breaking the calling flow.
 */
public with sharing class AIProviderRouter {
  public static AIProvider getProvider(String featureName) {
    AI_Feature_Config__mdt feature = AI_Feature_Config__mdt.getInstance(
      featureName
    );

    if (feature == null || !feature.Enabled__c) {
      return new DisabledAIProvider();
    }

    AI_Provider_Config__mdt provider = AI_Provider_Config__mdt.getInstance(
      feature.Provider_Name__c
    );

    // Feature enabled but its provider inactive/missing: still fail
    // closed to disabled rather than calling out with a stale/unverified
    // provider config.
    if (provider == null || !provider.Active__c) {
      return new DisabledAIProvider();
    }

    return providerFor(provider.Provider_Type__c);
  }

  public static AIProvider providerFor(String providerType) {
    if (providerType == 'OpenAI') {
      return new OpenAIProvider();
    }

    if (providerType == 'AzureOpenAI') {
      return new AzureOpenAIProvider();
    }

    return new DisabledAIProvider();
  }
}
