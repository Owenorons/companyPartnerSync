/**
 * Result payload returned to the LWC layer after a partner application is
 * submitted — just enough to confirm what was created and its resulting
 * status, without exposing the full application record.
 */
public with sharing class PartnerApplicationResultDTO {
  /**
   * Id of the newly created Partner_Application__c record.
   */
  @AuraEnabled
  public Id applicationId { get; set; }
  /**
   * Human-readable application number assigned to the submitted application.
   */
  @AuraEnabled
  public String applicationNumber { get; set; }
  /**
   * The application's status immediately after submission.
   */
  @AuraEnabled
  public String status { get; set; }
}
