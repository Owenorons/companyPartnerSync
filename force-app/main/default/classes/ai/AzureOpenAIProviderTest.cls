/*
 * Test coverage for AzureOpenAIProvider, covering the success and
 * non-2xx-status paths via AIHttpCalloutMock.
 */
@IsTest
private class AzureOpenAIProviderTest {
  @IsTest
  static void generateReturnsParsedResponseOnSuccess() {
    Test.setMock(
      HttpCalloutMock.class,
      AIHttpCalloutMock.success(
        '45 - Moderate risk, missing qualification evidence.'
      )
    );

    AIProviderRequestDTO request = new AIProviderRequestDTO();
    request.prompt = 'Assess this deal.';

    Test.startTest();
    AIProviderResponseDTO response = new AzureOpenAIProvider()
      .generate(request);
    Test.stopTest();

    System.assertEquals(true, response.success);
    System.assertEquals('Azure OpenAI', response.providerName);
    System.assertEquals(
      '45 - Moderate risk, missing qualification evidence.',
      response.responseText
    );
  }

  @IsTest
  static void generateReturnsFailureOnNonSuccessStatus() {
    Test.setMock(
      HttpCalloutMock.class,
      AIHttpCalloutMock.failure(500, 'Internal error')
    );

    AIProviderRequestDTO request = new AIProviderRequestDTO();
    request.prompt = 'Assess this deal.';

    Test.startTest();
    AIProviderResponseDTO response = new AzureOpenAIProvider()
      .generate(request);
    Test.stopTest();

    System.assertEquals(false, response.success);
    System.assertEquals('HTTP_500', response.errorCode);
    System.assertEquals('Azure OpenAI request failed.', response.errorMessage);
  }

  @IsTest
  static void generateReturnsFailureWhenCalloutThrows() {
    Test.setMock(HttpCalloutMock.class, new ThrowingCalloutMock());
    AIProviderRequestDTO request = new AIProviderRequestDTO();
    request.prompt = 'Assess this deal.';
    request.temperature = 0.4;
    request.maxTokens = 100;
    AIProviderResponseDTO response = new AzureOpenAIProvider()
      .generate(request);
    Assert.isFalse(response.success);
    Assert.areEqual('Azure OpenAI', response.providerName);
    Assert.areEqual('CALLOUT_ERROR', response.errorCode);
  }

  private class ThrowingCalloutMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest request) {
      throw new CalloutException('Simulated outage');
    }
  }
}
