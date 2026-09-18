/**
 * A single potential duplicate match surfaced when reviewing a partner
 * application, pointing at an existing Account or Lead that may already
 * represent the same company or contact.
 */
public with sharing class PartnerApplicationMatchDTO {
  /**
   * Id of the matching Account or Lead record.
   */
  @AuraEnabled
  public Id recordId { get; set; }
  /**
   * The matched record's SObject type (e.g. "Account" or "Lead").
   */
  @AuraEnabled
  public String recordType { get; set; }
  /**
   * Display name of the matched record.
   */
  @AuraEnabled
  public String name { get; set; }
  /**
   * The email address or website that matched, shown to help the reviewer
   * judge whether it is a genuine duplicate.
   */
  @AuraEnabled
  public String emailOrWebsite { get; set; }
  /**
   * Human-readable explanation of why this record was flagged as a
   * potential match.
   */
  @AuraEnabled
  public String matchReason { get; set; }
}
