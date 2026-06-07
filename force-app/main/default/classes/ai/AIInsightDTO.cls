public with sharing class AIInsightDTO {
  @AuraEnabled
  public Id insightId;

  @AuraEnabled
  public String insightType;

  @AuraEnabled
  public Decimal score;

  @AuraEnabled
  public Decimal confidence;

  @AuraEnabled
  public String recommendation;

  @AuraEnabled
  public String summary;

  @AuraEnabled
  public Datetime generatedOn;
}
