/**
 * Result payload returned by LeadConversionService.convertLead(), giving the
 * LWC layer the Ids of every record produced by the conversion (Opportunity,
 * Deal Registration, and the customer Account, which may be newly created).
 */
public with sharing class LeadConversionResultDTO {
  /**
   * Id of the Lead that was converted.
   */
  @AuraEnabled
  public Id leadId { get; set; }
  /**
   * Id of the Opportunity created by the conversion.
   */
  @AuraEnabled
  public Id opportunityId { get; set; }
  /**
   * Id of the Deal Registration created by the conversion.
   */
  @AuraEnabled
  public Id dealRegistrationId { get; set; }
  /**
   * Id of the customer Account associated with the conversion.
   */
  @AuraEnabled
  public Id customerAccountId { get; set; }
  /**
   * Whether the customer Account was newly created as part of the
   * conversion, as opposed to an existing Account being reused.
   */
  @AuraEnabled
  public Boolean customerAccountCreated { get; set; }
}
