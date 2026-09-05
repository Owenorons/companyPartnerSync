/*
 * AIProvider implementation adapting the standard OpenAI chat
 * completions API. Unlike AzureOpenAIProvider, the model name travels
 * in the request body ("model") rather than being implied by the
 * endpoint/deployment, and there is no api-version query parameter.
 */
public with sharing class OpenAIProvider implements AIProvider {
  public AIProviderResponseDTO generate(AIProviderRequestDTO request) {
    AI_Provider_Config__mdt config = AI_Provider_Config__mdt.getInstance(
      'OpenAI'
    );

    if (config == null || String.isBlank(config.Named_Credential__c)) {
      AIProviderResponseDTO unconfigured = new AIProviderResponseDTO();
      unconfigured.success = false;
      unconfigured.providerName = 'OpenAI';
      unconfigured.errorMessage = 'OpenAI provider is not configured.';
      return unconfigured;
    }

    String modelName = !String.isBlank(request.modelOverride)
      ? request.modelOverride
      : (String.isBlank(config.Model_Name__c) ? 'gpt-5' : config.Model_Name__c);

    try {
      HttpRequest req = new HttpRequest();
      req.setEndpoint(
        'callout:' +
          config.Named_Credential__c +
          (String.isBlank(config.Base_URL__c) ? '' : config.Base_URL__c)
      );
      req.setMethod('POST');
      req.setHeader('Content-Type', 'application/json');
      req.setTimeout(timeoutMillis(config));
      req.setBody(JSON.serialize(buildPayload(request, config, modelName)));

      HttpResponse res = new Http().send(req);

      return OpenAICompatibleResponseParser.parse(res, 'OpenAI', modelName);
    } catch (Exception ex) {
      // Callout exceptions are caught here so a provider outage surfaces
      // as a normal unsuccessful AIProviderResponseDTO rather than an
      // unhandled exception propagating out of the caller.
      AIProviderResponseDTO response = new AIProviderResponseDTO();
      response.success = false;
      response.providerName = 'OpenAI';
      response.modelName = modelName;
      response.errorMessage = ex.getMessage();
      response.errorCode = 'CALLOUT_ERROR';
      return response;
    }
  }

  private Map<String, Object> buildPayload(
    AIProviderRequestDTO request,
    AI_Provider_Config__mdt config,
    String modelName
  ) {
    Map<String, Object> payload = new Map<String, Object>{
      'model' => modelName,
      'messages' => new List<Object>{
        new Map<String, Object>{ 'role' => 'user', 'content' => request.prompt }
      }
    };

    Decimal temperature = request.temperature != null
      ? request.temperature
      : config.Temperature__c;
    if (temperature != null) {
      payload.put('temperature', temperature);
    }

    Integer maxTokens = request.maxTokens != null
      ? request.maxTokens
      : (config.Max_Tokens__c == null
          ? null
          : Integer.valueOf(config.Max_Tokens__c));
    if (maxTokens != null) {
      payload.put('max_tokens', maxTokens);
    }

    return payload;
  }

  private Integer timeoutMillis(AI_Provider_Config__mdt config) {
    Integer seconds = config.Timeout_Seconds__c == null
      ? 30
      : Integer.valueOf(config.Timeout_Seconds__c);
    return seconds * 1000;
  }
}
