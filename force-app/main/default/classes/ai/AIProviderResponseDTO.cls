/*
 * DTO carrying a normalized generation result back out of an AIProvider
 * implementation. success=false with errorMessage set represents a
 * handled failure (misconfiguration, callout error, disabled provider)
 * rather than a thrown exception - callers branch on success, not
 * try/catch.
 */
public with sharing class AIProviderResponseDTO {
  public Boolean success;
  public String providerName;
  public String modelName;
  public String responseText;
  public String recommendation;
  public Decimal confidence;
  public String explanation;
  public Integer tokensUsed;
  public String errorMessage;
  public String errorCode;
}
