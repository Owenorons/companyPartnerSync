/**
 * Common contract for all AI backend adapters (OpenAIProvider,
 * AzureOpenAIProvider, DisabledAIProvider). AIProviderRouter selects an
 * implementation at runtime based on AI_Feature_Config__mdt /
 * AI_Provider_Config__mdt; callers only ever depend on this interface.
 */
public interface AIProvider {
  /**
   * Generates a response from this AI backend for the given request.
   * Implementations must not throw for ordinary callout/response
   * failures; they should instead return a DTO with success=false and
   * an errorMessage/errorCode describing the failure.
   *
   * @param request The normalized generation request (prompt, context, model params).
   * @return The normalized generation result, with success indicating whether generation succeeded.
   */
  AIProviderResponseDTO generate(AIProviderRequestDTO request);
}
