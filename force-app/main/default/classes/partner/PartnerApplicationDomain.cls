/**
 * Validation and shaping logic for Partner_Application__c: submission-time
 * validation, building the initial record, and mapping the sObject to each
 * of the three DTO shapes the UI needs (result/list/detail). No DML or
 * queries here — PartnerApplicationService owns persistence.
 */
public with sharing class PartnerApplicationDomain {
  private static final Set<String> ALLOWED_TIERS = new Set<String>{
    'Silver',
    'Gold',
    'Platinum',
    'Strategic'
  };
  private static final Set<String> ALLOWED_PARTNER_TYPES = new Set<String>{
    'Distributor',
    'Reseller',
    'Agent',
    'Dealer',
    'Referral'
  };

  /**
   * Validates a partner application submission, throwing a handled
   * exception describing the first invalid or missing field found.
   *
   * @param request The submitted application payload to validate.
   */
  public static void validateForSubmit(PartnerApplicationRequestDTO request) {
    if (request == null) {
      throw new PartnerSyncHandledException(
        'Partner application request is required.'
      );
    }

    if (String.isBlank(request.companyName)) {
      throw new PartnerSyncHandledException('Company name is required.');
    }

    if (String.isBlank(request.businessEmail)) {
      throw new PartnerSyncHandledException('Business email is required.');
    }

    if (!isValidEmail(request.businessEmail)) {
      throw new PartnerSyncHandledException('Business email is invalid.');
    }

    if (String.isBlank(request.requestedTier)) {
      throw new PartnerSyncHandledException('Requested tier is required.');
    }

    if (!ALLOWED_TIERS.contains(request.requestedTier)) {
      throw new PartnerSyncHandledException('Requested tier is invalid.');
    }

    if (String.isBlank(request.partnerType)) {
      throw new PartnerSyncHandledException('Partner type is required.');
    }

    if (!ALLOWED_PARTNER_TYPES.contains(request.partnerType)) {
      throw new PartnerSyncHandledException('Partner type is invalid.');
    }

    if (String.isBlank(request.submittedByEmail)) {
      throw new PartnerSyncHandledException('Submitted by email is required.');
    }

    if (!isValidEmail(request.submittedByEmail)) {
      throw new PartnerSyncHandledException('Submitted by email is invalid.');
    }
  }

  // Stripped to lowercase alphanumeric only so duplicate detection catches
  // the same company submitted with different spacing/punctuation/casing
  // ("Acme, Inc." vs "acme inc" vs "ACME INC.") rather than requiring an
  // exact string match.
  /**
   * Normalizes a company name to lowercase alphanumeric characters only,
   * for use as a duplicate-detection key.
   *
   * @param value The raw company name to normalize.
   * @return The normalized company name, or null if value is blank.
   */
  public static String normalizeCompanyName(String value) {
    if (String.isBlank(value)) {
      return null;
    }

    return value.trim().toLowerCase().replaceAll('[^a-z0-9]', '');
  }

  /**
   * Builds a new Partner_Application__c record populated from a validated
   * submission, including derived normalization/duplicate-check keys.
   * Does not perform DML.
   *
   * @param request The submitted application payload.
   * @return A populated, unsaved Partner_Application__c record.
   */
  public static Partner_Application__c buildSubmittedRecord(
    PartnerApplicationRequestDTO request
  ) {
    validateForSubmit(request);

    String normalizedCompanyName = normalizeCompanyName(request.companyName);

    Partner_Application__c record = new Partner_Application__c();
    record.Name = request.companyName.trim();
    record.Company_Name__c = request.companyName.trim();
    record.Business_Email__c = normalizeEmail(request.businessEmail);
    record.Phone__c = String.isBlank(request.phone)
      ? null
      : request.phone.trim();
    record.Website__c = String.isBlank(request.website)
      ? null
      : request.website.trim();
    record.Country__c = String.isBlank(request.country)
      ? null
      : request.country.trim();
    record.Region__c = String.isBlank(request.region)
      ? null
      : request.region.trim();
    record.Requested_Tier__c = request.requestedTier;
    record.Partner_Type__c = request.partnerType;
    record.Submitted_By_Contact_Name__c = String.isBlank(
        request.submittedByContactName
      )
      ? null
      : request.submittedByContactName.trim();
    record.Submitted_By_Email__c = normalizeEmail(request.submittedByEmail);
    record.Application_Status__c = 'Submitted';
    record.Decision__c = 'Pending';
    record.Submitted_On__c = System.now();
    record.Source__c = 'Website';
    record.Normalized_Company_Name__c = normalizedCompanyName;
    record.Active_Company_Key__c = normalizedCompanyName;
    record.Active_Email_Key__c = normalizeEmail(request.businessEmail);
    record.Duplicate_Check_Key__c =
      normalizedCompanyName +
      ':' +
      normalizeEmail(request.businessEmail);

    return record;
  }

  /**
   * Maps a Partner_Application__c record to the minimal result shape
   * returned right after submission.
   *
   * @param record The Partner_Application__c record to map.
   * @return A PartnerApplicationResultDTO summarizing the record.
   */
  public static PartnerApplicationResultDTO toResultDTO(
    Partner_Application__c record
  ) {
    PartnerApplicationResultDTO dto = new PartnerApplicationResultDTO();
    dto.applicationId = record.Id;
    dto.applicationNumber = record.Application_Number__c;
    dto.status = record.Application_Status__c;
    return dto;
  }

  /**
   * Maps a Partner_Application__c record to the review queue list row
   * shape.
   *
   * @param record The Partner_Application__c record to map.
   * @return A PartnerApplicationListDTO summarizing the record.
   */
  public static PartnerApplicationListDTO toListDTO(
    Partner_Application__c record
  ) {
    PartnerApplicationListDTO dto = new PartnerApplicationListDTO();
    dto.applicationId = record.Id;
    dto.applicationNumber = record.Application_Number__c;
    dto.companyName = record.Company_Name__c;
    dto.requestedTier = record.Requested_Tier__c;
    dto.partnerType = record.Partner_Type__c;
    dto.status = record.Application_Status__c;
    dto.submittedOn = record.Submitted_On__c;
    return dto;
  }

  /**
   * Maps a Partner_Application__c record to the full reviewer detail
   * shape, including computed reviewer permission flags
   * (canClaim/canDecide/canRequestProvisioning) for the running user.
   *
   * @param record The Partner_Application__c record to map.
   * @return A PartnerApplicationDetailDTO describing the record and the
   * running user's available actions on it.
   */
  public static PartnerApplicationDetailDTO toDetailDTO(
    Partner_Application__c record
  ) {
    PartnerApplicationDetailDTO dto = new PartnerApplicationDetailDTO();
    dto.applicationId = record.Id;
    dto.applicationNumber = record.Application_Number__c;
    dto.companyName = record.Company_Name__c;
    dto.businessEmail = record.Business_Email__c;
    dto.phone = record.Phone__c;
    dto.website = record.Website__c;
    dto.country = record.Country__c;
    dto.region = record.Region__c;
    dto.requestedTier = record.Requested_Tier__c;
    dto.partnerType = record.Partner_Type__c;
    dto.submittedByContactName = record.Submitted_By_Contact_Name__c;
    dto.submittedByEmail = record.Submitted_By_Email__c;
    dto.status = record.Application_Status__c;
    dto.decision = record.Decision__c;
    dto.rejectionReason = record.Rejection_Reason__c;
    dto.approvalNotes = record.Approval_Notes__c;
    dto.submittedOn = record.Submitted_On__c;
    dto.assignedReviewerId = record.Assigned_Reviewer__c;
    dto.assignedReviewerName = record.Assigned_Reviewer__c == null
      ? null
      : record.Assigned_Reviewer__r.Name;
    dto.createdAccountId = record.Created_Account__c;
    dto.createdContactId = record.Created_Contact__c;
    dto.provisionedUserId = record.Provisioned_User__c;
    dto.provisioningStatus = record.Provisioning_Status__c;
    dto.provisioningError = record.Provisioning_Error__c;
    dto.provisionedOn = record.Provisioned_On__c;
    dto.isReviewable =
      record.Application_Status__c == 'Submitted' ||
      record.Application_Status__c == 'Under Review';
    Boolean hasReviewPermission = PartnerPermissionService.canApprovePartnerApplications();
    dto.isAssignedToCurrentUser =
      record.Assigned_Reviewer__c == UserInfo.getUserId();
    dto.canClaim =
      dto.isReviewable &&
      record.Assigned_Reviewer__c == null &&
      hasReviewPermission;
    dto.canDecide =
      dto.isReviewable &&
      dto.isAssignedToCurrentUser &&
      hasReviewPermission;
    dto.canRequestProvisioning =
      record.Application_Status__c == 'Approved' &&
      record.Created_Account__c != null &&
      record.Created_Contact__c != null &&
      record.Provisioned_User__c == null &&
      record.Provisioning_Status__c != 'Queued' &&
      hasReviewPermission;
    return dto;
  }

  private static String normalizeEmail(String value) {
    return String.isBlank(value) ? null : value.trim().toLowerCase();
  }

  private static Boolean isValidEmail(String value) {
    return !String.isBlank(value) &&
      Pattern.matches('^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$', value.trim());
  }
}
