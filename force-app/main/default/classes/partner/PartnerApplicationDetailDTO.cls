/*
 * Full detail view of a single partner application for the reviewer screen
 * — a superset of PartnerApplicationListDTO, plus decision state and the
 * account/contact created once the application is approved.
 */
public with sharing class PartnerApplicationDetailDTO {
  @AuraEnabled
  public Id applicationId;
  @AuraEnabled
  public String applicationNumber;

  @AuraEnabled
  public String companyName;
  @AuraEnabled
  public String businessEmail;
  @AuraEnabled
  public String phone;
  @AuraEnabled
  public String website;
  @AuraEnabled
  public String country;
  @AuraEnabled
  public String region;

  @AuraEnabled
  public String requestedTier;
  @AuraEnabled
  public String partnerType;

  @AuraEnabled
  public String submittedByContactName;
  @AuraEnabled
  public String submittedByEmail;

  @AuraEnabled
  public String status;
  @AuraEnabled
  public String decision;
  @AuraEnabled
  public String rejectionReason;
  @AuraEnabled
  public String approvalNotes;
  @AuraEnabled
  public Datetime submittedOn;

  @AuraEnabled
  public Id createdAccountId;
  @AuraEnabled
  public Id createdContactId;

  @AuraEnabled
  public Boolean isReviewable;
  @AuraEnabled
  public Boolean canDecide;
}
