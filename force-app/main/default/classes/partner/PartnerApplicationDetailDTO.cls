/*
 * Full detail view of a single partner application for the reviewer screen
 * — a superset of PartnerApplicationListDTO, plus decision state and the
 * account/contact created once the application is approved.
 */
public with sharing class PartnerApplicationDetailDTO {
  @AuraEnabled
  public Id applicationId { get; set; }
  @AuraEnabled
  public String applicationNumber { get; set; }

  @AuraEnabled
  public String companyName { get; set; }
  @AuraEnabled
  public String businessEmail { get; set; }
  @AuraEnabled
  public String phone { get; set; }
  @AuraEnabled
  public String website { get; set; }
  @AuraEnabled
  public String country { get; set; }
  @AuraEnabled
  public String region { get; set; }

  @AuraEnabled
  public String requestedTier { get; set; }
  @AuraEnabled
  public String partnerType { get; set; }

  @AuraEnabled
  public String submittedByContactName { get; set; }
  @AuraEnabled
  public String submittedByEmail { get; set; }

  @AuraEnabled
  public String status { get; set; }
  @AuraEnabled
  public String decision { get; set; }
  @AuraEnabled
  public String rejectionReason { get; set; }
  @AuraEnabled
  public String approvalNotes { get; set; }
  @AuraEnabled
  public Datetime submittedOn { get; set; }
  @AuraEnabled
  public Id assignedReviewerId { get; set; }
  @AuraEnabled
  public String assignedReviewerName { get; set; }

  @AuraEnabled
  public Id createdAccountId { get; set; }
  @AuraEnabled
  public Id createdContactId { get; set; }
  @AuraEnabled
  public Id provisionedUserId { get; set; }
  @AuraEnabled
  public String provisioningStatus { get; set; }
  @AuraEnabled
  public String provisioningError { get; set; }
  @AuraEnabled
  public Datetime provisionedOn { get; set; }
  @AuraEnabled
  public Boolean canRequestProvisioning { get; set; }

  @AuraEnabled
  public Boolean isReviewable { get; set; }
  @AuraEnabled
  public Boolean canDecide { get; set; }
  @AuraEnabled
  public Boolean canClaim { get; set; }
  @AuraEnabled
  public Boolean isAssignedToCurrentUser { get; set; }
  @AuraEnabled
  public Boolean hasPotentialMatches { get; set; }
  @AuraEnabled
  public List<PartnerApplicationMatchDTO> potentialMatches { get; set; }
}
