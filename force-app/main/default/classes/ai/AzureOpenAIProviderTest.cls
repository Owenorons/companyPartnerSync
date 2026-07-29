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
    System.assert(response.errorMessage.contains('500'));
  }
}
