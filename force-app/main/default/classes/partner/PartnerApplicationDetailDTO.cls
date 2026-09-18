/**
 * Full detail view of a single partner application for the reviewer screen
 * — a superset of PartnerApplicationListDTO, plus decision state and the
 * account/contact created once the application is approved.
 */
public with sharing class PartnerApplicationDetailDTO {
  /**
   * Id of the Partner_Application__c record.
   */
  @AuraEnabled
  public Id applicationId { get; set; }
  /**
   * Human-readable application number.
   */
  @AuraEnabled
  public String applicationNumber { get; set; }

  /**
   * Name of the applying company.
   */
  @AuraEnabled
  public String companyName { get; set; }
  /**
   * Primary business email address for the applying company.
   */
  @AuraEnabled
  public String businessEmail { get; set; }
  /**
   * Contact phone number for the applying company.
   */
  @AuraEnabled
  public String phone { get; set; }
  /**
   * Website URL for the applying company.
   */
  @AuraEnabled
  public String website { get; set; }
  /**
   * Country the applying company is based in.
   */
  @AuraEnabled
  public String country { get; set; }
  /**
   * Region the applying company is based in.
   */
  @AuraEnabled
  public String region { get; set; }

  /**
   * Partner tier requested on the application.
   */
  @AuraEnabled
  public String requestedTier { get; set; }
  /**
   * Type of partner being applied for.
   */
  @AuraEnabled
  public String partnerType { get; set; }

  /**
   * Name of the contact who submitted the application.
   */
  @AuraEnabled
  public String submittedByContactName { get; set; }
  /**
   * Email address of the contact who submitted the application.
   */
  @AuraEnabled
  public String submittedByEmail { get; set; }

  /**
   * Current review status of the application.
   */
  @AuraEnabled
  public String status { get; set; }
  /**
   * Reviewer decision on the application (e.g. approved/rejected).
   */
  @AuraEnabled
  public String decision { get; set; }
  /**
   * Reason given if the application was rejected.
   */
  @AuraEnabled
  public String rejectionReason { get; set; }
  /**
   * Notes recorded if the application was approved.
   */
  @AuraEnabled
  public String approvalNotes { get; set; }
  /**
   * Date and time the application was submitted.
   */
  @AuraEnabled
  public Datetime submittedOn { get; set; }
  /**
   * Id of the user assigned to review the application.
   */
  @AuraEnabled
  public Id assignedReviewerId { get; set; }
  /**
   * Name of the user assigned to review the application.
   */
  @AuraEnabled
  public String assignedReviewerName { get; set; }

  /**
   * Id of the Account created once the application is approved.
   */
  @AuraEnabled
  public Id createdAccountId { get; set; }
  /**
   * Id of the Contact created once the application is approved.
   */
  @AuraEnabled
  public Id createdContactId { get; set; }
  /**
   * Id of the community User provisioned for the approved partner.
   */
  @AuraEnabled
  public Id provisionedUserId { get; set; }
  /**
   * Current status of the partner user provisioning process.
   */
  @AuraEnabled
  public String provisioningStatus { get; set; }
  /**
   * Error message from the provisioning process, if it failed.
   */
  @AuraEnabled
  public String provisioningError { get; set; }
  /**
   * Date and time the partner user was provisioned.
   */
  @AuraEnabled
  public Datetime provisionedOn { get; set; }
  /**
   * Whether provisioning can currently be requested for this application.
   */
  @AuraEnabled
  public Boolean canRequestProvisioning { get; set; }

  /**
   * Whether the application is currently in a reviewable state.
   */
  @AuraEnabled
  public Boolean isReviewable { get; set; }
  /**
   * Whether the running user can record a decision on the application.
   */
  @AuraEnabled
  public Boolean canDecide { get; set; }
  /**
   * Whether the running user can claim the application for review.
   */
  @AuraEnabled
  public Boolean canClaim { get; set; }
  /**
   * Whether the application is currently assigned to the running user.
   */
  @AuraEnabled
  public Boolean isAssignedToCurrentUser { get; set; }
  /**
   * Whether any potential duplicate matches were found for this
   * application.
   */
  @AuraEnabled
  public Boolean hasPotentialMatches { get; set; }
  /**
   * List of potential duplicate matches found for this application.
   */
  @AuraEnabled
  public List<PartnerApplicationMatchDTO> potentialMatches { get; set; }
}
