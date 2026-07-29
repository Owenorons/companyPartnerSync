/*
 * Admin-triggered "test connection" flow for a configured AI provider.
 * Runs a minimal live callout through AIProviderRouter and persists the
 * outcome onto AI_Configuration__c so the provider admin UI can show
 * connection health without re-running a callout on every page load.
 */
public with sharing class AIConnectionTestService {
  public static AIProviderResponseDTO testConnection(
    String providerDeveloperName
  ) {
    PartnerPermissionService.assertCanConfigureAI();

    AI_Provider_Config__mdt config = AI_Provider_Config__mdt.getInstance(
      providerDeveloperName
    );

    AIProviderResponseDTO response;

    if (config == null) {
      response = new AIProviderResponseDTO();
      response.success = false;
      response.errorMessage = 'Unknown AI provider: ' + providerDeveloperName;
    } else {
      AIProvider provider = AIProviderRouter.providerFor(
        config.Provider_Type__c
      );

      // Minimal prompt/token budget: this call exists only to prove the
      // callout succeeds, not to produce a usable AI response.
      AIProviderRequestDTO request = new AIProviderRequestDTO();
      request.featureName = 'ConnectionTest';
      request.prompt = 'Respond with OK';
      request.maxTokens = 5;

      response = provider.generate(request);
    }

    recordResult(providerDeveloperName, response);

    return response;
  }

  private static void recordResult(
    String providerDeveloperName,
    AIProviderResponseDTO response
  ) {
    List<AI_Configuration__c> existing = [
      SELECT Id
      FROM AI_Configuration__c
      WHERE Name = :providerDeveloperName
      WITH USER_MODE
      LIMIT 1
    ];

    // Upsert by provider name: AI_Configuration__c has no external ID, so
    // re-testing the same provider must update this existing row rather
    // than insert a duplicate status record.
    AI_Configuration__c record = existing.isEmpty()
      ? new AI_Configuration__c(Name = providerDeveloperName)
      : existing[0];

    record.Provider__c = providerDeveloperName;
    record.Connection_Status__c = response.success ? 'Connected' : 'Failed';
    record.Last_Test_Date__c = System.now();
    record.Last_Test_Result__c = response.success
      ? 'Connection successful.'
      : response.errorMessage;

    if (existing.isEmpty()) {
      SecurityUtil.assertCreateable(AI_Configuration__c.SObjectType);
      insert SecurityUtil.stripForCreate(new List<SObject>{ record });
    } else {
      SecurityUtil.assertUpdateable(AI_Configuration__c.SObjectType);
      update SecurityUtil.stripForUpdate(new List<SObject>{ record });
    }
  }
}
