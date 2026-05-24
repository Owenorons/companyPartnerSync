public with sharing class CustomerAccountMatchDTO {
  @AuraEnabled
  public Id accountId;
  @AuraEnabled
  public String accountName;
  @AuraEnabled
  public Boolean created;
}
