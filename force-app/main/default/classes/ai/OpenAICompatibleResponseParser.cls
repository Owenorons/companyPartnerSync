/*
 * Shared response parser for any OpenAI-compatible chat completions API.
 * Used by both OpenAIProvider and AzureOpenAIProvider since Azure's REST
 * shape mirrors OpenAI's (choices[].message.content, usage.total_tokens),
 * so the parsing logic only needs to live in one place.
 */
public with sharing class OpenAICompatibleResponseParser {
  public static AIProviderResponseDTO parse(
    HttpResponse res,
    String providerName,
    String fallbackModelName
  ) {
    AIProviderResponseDTO response = new AIProviderResponseDTO();
    response.providerName = providerName;
    response.modelName = fallbackModelName;

    if (res.getStatusCode() != 200) {
      response.success = false;
      response.errorMessage =
        providerName +
        ' request failed with status ' +
        res.getStatusCode() +
        ': ' +
        res.getBody();
      return response;
    }

    try {
      Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(
        res.getBody()
      );
      List<Object> choices = (List<Object>) body.get('choices');

      if (choices == null || choices.isEmpty()) {
        response.success = false;
        response.errorMessage =
          providerName + ' response contained no choices.';
        return response;
      }

      // Only the first choice is read: providers are always called with
      // the default n=1, so any additional choices are ignored.
      Map<String, Object> firstChoice = (Map<String, Object>) choices[0];
      Map<String, Object> message = (Map<String, Object>) firstChoice.get(
        'message'
      );

      response.success = true;
      response.responseText = message == null
        ? null
        : (String) message.get('content');

      if (body.get('model') != null) {
        response.modelName = (String) body.get('model');
      }

      Map<String, Object> usage = (Map<String, Object>) body.get('usage');
      if (usage != null && usage.get('total_tokens') != null) {
        response.tokensUsed = Integer.valueOf(usage.get('total_tokens'));
      }

      return response;
    } catch (Exception ex) {
      // JSON.deserializeUntyped/casts throw on any shape surprise (rate
      // limit bodies, HTML error pages, schema drift, etc.); caught here
      // so a malformed response becomes a normal failed
      // AIProviderResponseDTO instead of an unhandled exception.
      response.success = false;
      response.errorMessage =
        'Unable to parse ' +
        providerName +
        ' response: ' +
        ex.getMessage();
      return response;
    }
  }
}
