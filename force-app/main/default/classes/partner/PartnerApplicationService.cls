/*
 * Application-layer orchestration for the partner onboarding flow: submit a
 * new application, list pending ones, and view a single application's
 * detail. Validation/shaping logic lives in PartnerApplicationDomain and
 * PartnerApplicationSelector; this class sequences those calls and owns the
 * feature-flag/duplicate/permission gates around them.
 */
public with sharing class PartnerApplicationService {
  public static PartnerApplicationResultDTO submitApplication(
    PartnerApplicationRequestDTO request
  ) {
    if (!TenantConfigService.isOnboardingEnabled()) {
      throw new PartnerSyncHandledException(
        'Partner onboarding is currently disabled.'
      );
    }

    SecurityUtil.assertCreateable(Partner_Application__c.SObjectType);

    PartnerApplicationDomain.validateForSubmit(request);

    String normalizedCompanyName = PartnerApplicationDomain.normalizeCompanyName(
      request.companyName
    );

    String businessEmail = String.isBlank(request.businessEmail)
      ? null
      : request.businessEmail.trim().toLowerCase();

    List<Partner_Application__c> duplicates = PartnerApplicationSelector.findPotentialDuplicates(
      normalizedCompanyName,
      businessEmail
    );

    if (!duplicates.isEmpty()) {
      throw new PartnerSyncHandledException(
        'A partner application already exists for this company or email.'
      );
    }

    Partner_Application__c record = PartnerApplicationDomain.buildSubmittedRecord(
      request
    );

    List<SObject> sanitized = SecurityUtil.stripForCreate(
      new List<SObject>{ record }
    );

    Database.insert(sanitized, AccessLevel.USER_MODE);

    Partner_Application__c insertedRecord = (Partner_Application__c) sanitized[0];

    // Re-query rather than reuse the DML result: fields like the
    // auto-number Application_Number__c are only populated by the platform
    // after insert and aren't reflected on the in-memory sObject.
    insertedRecord = PartnerApplicationSelector.selectSubmissionResultById(
      insertedRecord.Id
    );

    LoggingService.info(
      'PartnerApplicationService',
      'Partner application submitted: ' + insertedRecord.Id
    );

    return PartnerApplicationDomain.toResultDTO(insertedRecord);
  }

  public static List<PartnerApplicationListDTO> getPendingApplications() {
    PartnerPermissionService.assertCanApprovePartnerApplications();

    List<PartnerApplicationListDTO> results = new List<PartnerApplicationListDTO>();

    for (
      Partner_Application__c application : PartnerApplicationSelector.selectPendingApplications()
    ) {
      results.add(PartnerApplicationDomain.toListDTO(application));
    }

    return results;
  }

  public static PartnerApplicationDetailDTO getApplicationDetail(
    Id applicationId
  ) {
    PartnerPermissionService.assertCanApprovePartnerApplications();

    Partner_Application__c application = PartnerApplicationSelector.selectById(
      applicationId
    );

    return PartnerApplicationDomain.toDetailDTO(application);
  }
}
