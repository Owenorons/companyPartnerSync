/**
 * Response DTO for getDownloadUrl(), pairing the content Id with the
 * resolved download link the LWC opens.
 */
public with sharing class PartnerContentDownloadDTO {
  /**
   * Id of the underlying Partner_Content__c record.
   */
  @AuraEnabled
  public Id contentId { get; set; }
  /**
   * Resolved URL the LWC opens to download the content's file.
   */
  @AuraEnabled
  public String downloadUrl { get; set; }
}
