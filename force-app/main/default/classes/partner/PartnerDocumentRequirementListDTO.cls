/**
 * Row shape for a partner's own document requirement, including their
 * latest submitted version if any (see PartnerDocumentService.getMyRequirements).
 */
public with sharing class PartnerDocumentRequirementListDTO {
  /**
   * Id of the document requirement record.
   */
  @AuraEnabled
  public Id requirementId { get; set; }

  /**
   * Type of document required (e.g. Certificate of Incorporation, Tax Registration).
   */
  @AuraEnabled
  public String documentType { get; set; }
  /**
   * Whether the requirement is Mandatory, Conditional, or Optional.
   */
  @AuraEnabled
  public String requirementLevel { get; set; }
  /**
   * Current status of the requirement.
   */
  @AuraEnabled
  public String status { get; set; }
  /**
   * Whether this requirement blocks onboarding progression until satisfied.
   */
  @AuraEnabled
  public Boolean blocking { get; set; }
  /**
   * Date the requirement is due.
   */
  @AuraEnabled
  public Date dueOn { get; set; }

  /**
   * Id of the latest submitted document version, if any.
   */
  @AuraEnabled
  public Id latestDocumentId { get; set; }
  /**
   * Version number of the latest submitted document, if any.
   */
  @AuraEnabled
  public Integer latestVersion { get; set; }
  /**
   * Status of the latest submitted document, if any.
   */
  @AuraEnabled
  public String latestDocumentStatus { get; set; }
  /**
   * Date/time the latest version was submitted, if any.
   */
  @AuraEnabled
  public Datetime submittedOn { get; set; }
}
