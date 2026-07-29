/*
 * Common contract for all AI backend adapters (OpenAIProvider,
 * AzureOpenAIProvider, DisabledAIProvider). AIProviderRouter selects an
 * implementation at runtime based on AI_Feature_Config__mdt /
 * AI_Provider_Config__mdt; callers only ever depend on this interface.
 */
public interface AIProvider {
  AIProviderResponseDTO generate(AIProviderRequestDTO request);
}
