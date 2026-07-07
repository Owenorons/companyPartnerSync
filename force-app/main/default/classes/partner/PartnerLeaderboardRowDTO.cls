public with sharing class PartnerLeaderboardRowDTO {
  @AuraEnabled
  public Id partnerAccountId;
  @AuraEnabled
  public String partnerName;
  @AuraEnabled
  public String partnerTier;
  @AuraEnabled
  public String partnerStatus;

  @AuraEnabled
  public Integer acceptedLeads;
  @AuraEnabled
  public Integer approvedDeals;
  @AuraEnabled
  public Integer wonDeals;

  @AuraEnabled
  public Decimal revenue;
  @AuraEnabled
  public Decimal conversionRate;
  @AuraEnabled
  public Decimal score;
}
