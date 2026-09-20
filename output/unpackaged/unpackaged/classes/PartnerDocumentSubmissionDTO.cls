/**
 * Inbound DTO for a partner's document submission
 * (PartnerDocumentController.submitDocument).
 */
public with sharing class PartnerDocumentSubmissionDTO {
  /**
   * Id of the Partner_Document_Requirement__c this submission satisfies.
   */
  @AuraEnabled
  public Id requirementId { get; set; }
  /**
   * Id of the ContentDocument holding the file uploaded via lightning-file-upload.
   */
  @AuraEnabled
  public Id contentDocumentId { get; set; }
  /**
   * Confidentiality level for the document; defaults to 'Partner' when blank.
   */
  @AuraEnabled
  public String confidentiality { get; set; }
}
