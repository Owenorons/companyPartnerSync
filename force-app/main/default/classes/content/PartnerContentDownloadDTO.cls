/*
 * Response DTO for getDownloadUrl(), pairing the content Id with the
 * resolved download link the LWC opens.
 */
public with sharing class PartnerContentDownloadDTO {
  @AuraEnabled
  public Id contentId;
  @AuraEnabled
  public String downloadUrl;
}
