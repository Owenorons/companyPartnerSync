/**
 * Null-object implementation of AIProvider: returned by AIProviderRouter
 * whenever a feature or its provider is unconfigured, inactive, or
 * disabled. Always returns a well-formed success=false response so
 * callers (AIInsightGeneratorService, AIConnectionTestService, etc.)
 * never need a separate "no provider available" branch.
 */
public with sharing class DisabledAIProvider implements AIProvider {
  /**
   * Always returns a well-formed, unsuccessful response; never performs
   * a callout.
   *
   * @param request The normalized generation request (ignored).
   * @return A response with success=false and a "AI provider disabled" error message.
   */
  public AIProviderResponseDTO generate(AIProviderRequestDTO request) {
    AIProviderResponseDTO response = new AIProviderResponseDTO();
    response.success = false;
    response.providerName = 'Disabled';
    response.errorMessage = 'AI provider disabled';

    return response;
  }
}
