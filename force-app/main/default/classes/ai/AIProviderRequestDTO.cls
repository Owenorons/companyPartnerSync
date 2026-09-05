/*
 * DTO carrying a normalized generation request (prompt, context, model
 * params) into an AIProvider implementation, independent of which
 * backend ultimately serves it.
 */
public with sharing class AIProviderRequestDTO {
  public String featureName;
  public String prompt;
  public String modelOverride;
  public Map<String, Object> contextData;
  public Decimal temperature;
  public Integer maxTokens;
}
