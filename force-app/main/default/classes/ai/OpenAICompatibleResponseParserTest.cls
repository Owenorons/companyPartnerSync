/**
 * Tests for OpenAICompatibleResponseParser
 */

@IsTest
private class OpenAICompatibleResponseParserTest {
  @IsTest
  static void parsesStructuredSuccessAndUsage() {
    HttpResponse response = httpResponse(
      200,
      '{"model":"model-a","usage":{"total_tokens":12},"choices":[{"message":{"content":"{\\"summary\\":\\"Summary\\",\\"recommendation\\":\\"Act\\",\\"rationale\\":\\"Because\\",\\"confidence\\":75}"}}]}'
    );
    AIProviderResponseDTO parsed = OpenAICompatibleResponseParser.parse(
      response,
      'Provider',
      'fallback-model'
    );
    Assert.isTrue(parsed.success);
    Assert.areEqual('Summary', parsed.responseText);
    Assert.areEqual('Act', parsed.recommendation);
    Assert.areEqual(75, parsed.confidence);
    Assert.areEqual('model-a', parsed.modelName);
    Assert.areEqual(12, parsed.tokensUsed);
  }

  @IsTest
  static void rejectsEmptyChoicesMalformedJsonAndNonSuccess() {
    AIProviderResponseDTO noChoices = OpenAICompatibleResponseParser.parse(
      httpResponse(200, '{"choices":[]}'),
      'Provider',
      'model'
    );
    Assert.isFalse(noChoices.success);
    Assert.isTrue(noChoices.errorMessage.contains('no choices'));

    AIProviderResponseDTO malformed = OpenAICompatibleResponseParser.parse(
      httpResponse(200, 'not-json'),
      'Provider',
      'model'
    );
    Assert.isFalse(malformed.success);
    Assert.areEqual('INVALID_RESPONSE', malformed.errorCode);
    Assert.areEqual(
      'Provider returned an invalid response.',
      malformed.errorMessage
    );

    AIProviderResponseDTO failed = OpenAICompatibleResponseParser.parse(
      httpResponse(503, 'Unavailable'),
      'Provider',
      'model'
    );
    Assert.isFalse(failed.success);
    Assert.areEqual('HTTP_503', failed.errorCode);
  }

  private static HttpResponse httpResponse(Integer statusCode, String body) {
    HttpResponse response = new HttpResponse();
    response.setStatusCode(statusCode);
    response.setBody(body);
    return response;
  }
}
