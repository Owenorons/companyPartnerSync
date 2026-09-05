/*
 * Test coverage for OpenAIProvider, covering the success and
 * non-2xx-status paths via AIHttpCalloutMock.
 */
@IsTest
private class OpenAIProviderTest {
  @IsTest
  static void generateReturnsParsedResponseOnSuccess() {
    Test.setMock(
      HttpCalloutMock.class,
      AIHttpCalloutMock.success(
        '82 - Strong fit based on industry and tier match.'
      )
    );

    AIProviderRequestDTO request = new AIProviderRequestDTO();
    request.prompt = 'Assess this lead.';

    Test.startTest();
    AIProviderResponseDTO response = new OpenAIProvider().generate(request);
    Test.stopTest();

    System.assertEquals(true, response.success);
    System.assertEquals('OpenAI', response.providerName);
    System.assertEquals(
      '82 - Strong fit based on industry and tier match.',
      response.responseText
    );
    System.assertEquals(42, response.tokensUsed);
    System.assertEquals(82, response.confidence);
    System.assertEquals(
      'Follow the recommended next step.',
      response.recommendation
    );
  }

  @IsTest
  static void generateReturnsFailureOnNonSuccessStatus() {
    Test.setMock(
      HttpCalloutMock.class,
      AIHttpCalloutMock.failure(429, 'Rate limited')
    );

    AIProviderRequestDTO request = new AIProviderRequestDTO();
    request.prompt = 'Assess this lead.';

    Test.startTest();
    AIProviderResponseDTO response = new OpenAIProvider().generate(request);
    Test.stopTest();

    System.assertEquals(false, response.success);
    System.assertEquals('HTTP_429', response.errorCode);
    System.assertEquals('OpenAI request failed.', response.errorMessage);
  }

  @IsTest
  static void generateReturnsFailureWhenCalloutThrows() {
    Test.setMock(HttpCalloutMock.class, new ThrowingCalloutMock());
    AIProviderRequestDTO request = new AIProviderRequestDTO();
    request.prompt = 'Assess this lead.';
    request.temperature = 0.2;
    request.maxTokens = 75;
    AIProviderResponseDTO response = new OpenAIProvider().generate(request);
    Assert.isFalse(response.success);
    Assert.areEqual('OpenAI', response.providerName);
    Assert.areEqual('CALLOUT_ERROR', response.errorCode);
  }

  private class ThrowingCalloutMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest request) {
      throw new CalloutException('Simulated outage');
    }
  }
}
