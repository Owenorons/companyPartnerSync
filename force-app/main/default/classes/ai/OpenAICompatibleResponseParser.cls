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
      response.errorCode = 'HTTP_' + res.getStatusCode();
      response.errorMessage = providerName + ' request failed.';
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

      String content = message == null ? null : (String) message.get('content');
      if (String.isBlank(content)) {
        response.success = false;
        response.errorCode = 'EMPTY_RESPONSE';
        response.errorMessage = providerName + ' returned an empty response.';
        return response;
      }

      Map<String, Object> structured = parseStructuredContent(content);
      response.responseText = (String) structured.get('summary');
      response.recommendation = (String) structured.get('recommendation');
      response.explanation = (String) structured.get('rationale');
      response.confidence = Decimal.valueOf(
        String.valueOf(structured.get('confidence'))
      );
      if (response.confidence < 0 || response.confidence > 100) {
        throw new AIResponseValidationException('confidence must be 0-100');
      }
      response.success = true;

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
      response.errorCode = 'INVALID_RESPONSE';
      response.errorMessage = providerName + ' returned an invalid response.';
      return response;
    }
  }

  private static Map<String, Object> parseStructuredContent(String content) {
    String normalized = content.trim();
    if (normalized.startsWith('```')) {
      normalized = normalized.replaceFirst('^```(?:json)?\\s*', '');
      normalized = normalized.replaceFirst('\\s*```$', '');
    }
    Map<String, Object> value = (Map<String, Object>) JSON.deserializeUntyped(
      normalized
    );
    if (
      value == null ||
      String.isBlank((String) value.get('summary')) ||
      String.isBlank((String) value.get('recommendation')) ||
      String.isBlank((String) value.get('rationale')) ||
      value.get('confidence') == null
    ) {
      throw new AIResponseValidationException('required fields are missing');
    }
    return value;
  }

  private class AIResponseValidationException extends Exception {
  }
}
