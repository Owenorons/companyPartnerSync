/**
 * Result shape returned by CustomerAccountService's find-or-create flows to
 * the LWC/Aura layer. `created` lets the caller distinguish "matched an
 * existing customer account" from "provisioned a new one" so the UI can
 * message the outcome differently.
 */
public with sharing class CustomerAccountMatchDTO {
  /** The Id of the matched or newly created customer account. */
  @AuraEnabled
  public Id accountId { get; set; }
  /** The name of the matched or newly created customer account. */
  @AuraEnabled
  public String accountName { get; set; }
  /** True if a new customer account was created; false if an existing one was matched. */
  @AuraEnabled
  public Boolean created { get; set; }
}
