/*
 * AIProvider implementation adapting the Azure OpenAI chat completions
 * API. Distinct from OpenAIProvider: the model is fixed by the Azure
 * deployment behind Named_Credential__c/Base_URL__c rather than a
 * request-body "model" field, and every call must carry an api-version
 * query parameter.
 */
public with sharing class AzureOpenAIProvider implements AIProvider {
  public AIProviderResponseDTO generate(AIProviderRequestDTO request) {
    AI_Provider_Config__mdt config = AI_Provider_Config__mdt.getInstance(
      'AzureOpenAI'
    );

    if (config == null || String.isBlank(config.Named_Credential__c)) {
      AIProviderResponseDTO unconfigured = new AIProviderResponseDTO();
      unconfigured.success = false;
      unconfigured.providerName = 'Azure OpenAI';
      unconfigured.errorMessage = 'Azure OpenAI provider is not configured.';
      return unconfigured;
    }

    try {
      String apiVersion = String.isBlank(config.Api_Version__c)
        ? '2024-06-01'
        : config.Api_Version__c;

      HttpRequest req = new HttpRequest();
      req.setEndpoint(
        'callout:' +
          config.Named_Credential__c +
          (String.isBlank(config.Base_URL__c) ? '' : config.Base_URL__c) +
          '?api-version=' +
          EncodingUtil.urlEncode(apiVersion, 'UTF-8')
      );
      req.setMethod('POST');
      req.setHeader('Content-Type', 'application/json');
      req.setTimeout(timeoutMillis(config));
      req.setBody(JSON.serialize(buildPayload(request, config)));

      HttpResponse res = new Http().send(req);

      return OpenAICompatibleResponseParser.parse(
        res,
        'Azure OpenAI',
        config.Model_Name__c
      );
    } catch (Exception ex) {
      // Callout exceptions (timeout, DNS, cert, malformed named
      // credential, etc.) are caught here so a provider hiccup surfaces
      // as a normal unsuccessful AIProviderResponseDTO instead of an
      // unhandled exception propagating out of the caller.
      AIProviderResponseDTO response = new AIProviderResponseDTO();
      response.success = false;
      response.providerName = 'Azure OpenAI';
      response.modelName = config.Model_Name__c;
      response.errorMessage = ex.getMessage();
      return response;
    }
  }

  private Map<String, Object> buildPayload(
    AIProviderRequestDTO request,
    AI_Provider_Config__mdt config
  ) {
    Map<String, Object> payload = new Map<String, Object>{
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
