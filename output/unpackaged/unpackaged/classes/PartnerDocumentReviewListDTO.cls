/**
 * Row shape for the internal document review queue, spanning all partners
 * (see PartnerDocumentService.getReviewQueue).
 */
public with sharing class PartnerDocumentReviewListDTO {
  /**
   * Id of the submitted document record.
   */
  @AuraEnabled
  public Id documentId { get; set; }
  /**
   * Id of the owning document requirement.
   */
  @AuraEnabled
  public Id requirementId { get; set; }
  /**
   * Id of the owning onboarding aggregate.
   */
  @AuraEnabled
  public Id onboardingId { get; set; }
  /**
   * Id of the ContentDocument holding the uploaded file.
   */
  @AuraEnabled
  public Id contentDocumentId { get; set; }

  /**
   * Name of the partner account the onboarding belongs to.
   */
  @AuraEnabled
  public String partnerName { get; set; }
  /**
   * Type of document required.
   */
  @AuraEnabled
  public String documentType { get; set; }
  /**
   * Version number of this submission.
   */
  @AuraEnabled
  public Integer version { get; set; }
  /**
   * Current status of the document.
   */
  @AuraEnabled
  public String status { get; set; }
  /**
   * Confidentiality level of the document.
   */
  @AuraEnabled
  public String confidentiality { get; set; }
  /**
   * Date/time the document was submitted.
   */
  @AuraEnabled
  public Datetime submittedOn { get; set; }
}
