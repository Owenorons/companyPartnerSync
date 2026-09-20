/**
 * Inbound DTO for a reviewer's decision on a submitted document
 * (PartnerDocumentReviewController.reviewDocument).
 */
public with sharing class PartnerDocumentReviewDecisionDTO {
  /**
   * Id of the Partner_Document__c record being reviewed.
   */
  @AuraEnabled
  public Id documentId { get; set; }
  /**
   * The review outcome: 'Accepted', 'Rejected', or 'Replacement Required'.
   */
  @AuraEnabled
  public String outcome { get; set; }
  /**
   * Explanation for the outcome; required unless outcome is 'Accepted'.
   */
  @AuraEnabled
  public String reason { get; set; }
}
