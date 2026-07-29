/*
 * Test coverage for AIProviderRouter's fallback-to-disabled rules and
 * provider-type resolution, relying on the org's AI_Feature_Config__mdt
 * / AI_Provider_Config__mdt records (see per-test comments for the
 * specific records assumed).
 */
@IsTest
private class AIProviderRouterTest {
  @IsTest
  static void unknownFeatureReturnsDisabledProvider() {
    AIProvider provider = AIProviderRouter.getProvider('NotARealFeature');

    System.assert(
      provider instanceof DisabledAIProvider,
      'Unknown feature should route to the disabled provider.'
    );
  }

  @IsTest
  static void disabledFeatureReturnsDisabledProvider() {
    AIProvider provider = AIProviderRouter.getProvider('ContentRecommendation');

    System.assert(
      provider instanceof DisabledAIProvider,
      'A feature with Enabled__c = false should route to the disabled provider.'
    );
  }

  @IsTest
  static void enabledFeatureWithInactiveProviderReturnsDisabledProvider() {
    AIProvider provider = AIProviderRouter.getProvider('LeadFitScoring');

    System.assert(
      provider instanceof DisabledAIProvider,
      'LeadFitScoring is enabled but its OpenAI provider record ships Active__c = false, so it should still route to the disabled provider until an admin activates it.'
    );
  }

  @IsTest
  static void providerForRoutesByType() {
    System.assert(
      AIProviderRouter.providerFor('OpenAI') instanceof OpenAIProvider,
      'OpenAI provider type should resolve to OpenAIProvider.'
    );
    System.assert(
      AIProviderRouter.providerFor(
        'AzureOpenAI'
      ) instanceof AzureOpenAIProvider,
      'AzureOpenAI provider type should resolve to AzureOpenAIProvider.'
    );
    System.assert(
      AIProviderRouter.providerFor(
        'SomethingElse'
      ) instanceof DisabledAIProvider,
      'Unrecognized provider types should resolve to DisabledAIProvider.'
    );
  }
}
