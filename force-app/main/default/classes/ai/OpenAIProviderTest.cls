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
    System.assert(response.errorMessage.contains('429'));
  }
}
