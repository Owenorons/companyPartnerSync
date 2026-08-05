/*
 * Result shape returned by CustomerAccountService's find-or-create flows to
 * the LWC/Aura layer. `created` lets the caller distinguish "matched an
 * existing customer account" from "provisioned a new one" so the UI can
 * message the outcome differently.
 */
public with sharing class CustomerAccountMatchDTO {
  @AuraEnabled
  public Id accountId { get; set; }
  @AuraEnabled
  public String accountName { get; set; }
  @AuraEnabled
  public Boolean created { get; set; }
}
