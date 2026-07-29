/*
 * Validation and shaping logic for Partner_Application__c: submission-time
 * validation, building the initial record, and mapping the sObject to each
 * of the three DTO shapes the UI needs (result/list/detail). No DML or
 * queries here — PartnerApplicationService owns persistence.
 */
public with sharing class PartnerApplicationDomain {
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

    if (String.isBlank(request.requestedTier)) {
      throw new PartnerSyncHandledException('Requested tier is required.');
    }

    if (String.isBlank(request.partnerType)) {
      throw new PartnerSyncHandledException('Partner type is required.');
    }

    if (String.isBlank(request.submittedByEmail)) {
      throw new PartnerSyncHandledException('Submitted by email is required.');
    }
  }

  // Stripped to lowercase alphanumeric only so duplicate detection catches
  // the same company submitted with different spacing/punctuation/casing
  // ("Acme, Inc." vs "acme inc" vs "ACME INC.") rather than requiring an
  // exact string match.
  public static String normalizeCompanyName(String value) {
    if (String.isBlank(value)) {
      return null;
    }

    return value.trim().toLowerCase().replaceAll('[^a-z0-9]', '');
  }

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
    record.Normalized_Company_Name__c = normalizedCompanyName;
    record.Duplicate_Check_Key__c =
      normalizedCompanyName +
      ':' +
      normalizeEmail(request.businessEmail);

    return record;
  }

  public static PartnerApplicationResultDTO toResultDTO(
    Partner_Application__c record
  ) {
    PartnerApplicationResultDTO dto = new PartnerApplicationResultDTO();
    dto.applicationId = record.Id;
    dto.applicationNumber = record.Application_Number__c;
    dto.status = record.Application_Status__c;
    return dto;
  }

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
    dto.createdAccountId = record.Created_Account__c;
    dto.createdContactId = record.Created_Contact__c;
    dto.isReviewable =
      record.Application_Status__c == 'Submitted' ||
      record.Application_Status__c == 'Under Review';
    dto.canDecide = PartnerPermissionService.canApprovePartnerApplications();
    return dto;
  }

  private static String normalizeEmail(String value) {
    return String.isBlank(value) ? null : value.trim().toLowerCase();
  }
}
