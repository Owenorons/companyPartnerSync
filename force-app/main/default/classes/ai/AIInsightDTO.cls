public with sharing class AIInsightDTO {
  @AuraEnabled
  public Id insightId;

  @AuraEnabled
  public String insightType;

  @AuraEnabled
  public String provider;

  @AuraEnabled
  public Decimal confidence;

  @AuraEnabled
  public String recommendation;

  @AuraEnabled
  public String summary;

  @AuraEnabled
  public String reason;

  @AuraEnabled
  public String status;

  @AuraEnabled
  public Datetime generatedOn;
}
