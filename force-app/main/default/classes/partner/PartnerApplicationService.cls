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

    PartnerApplicationDomain.validateForSubmit(request);

    String normalizedCompanyName = PartnerApplicationDomain.normalizeCompanyName(
      request.companyName
    );

    String businessEmail = String.isBlank(request.businessEmail)
      ? null
      : request.businessEmail.trim().toLowerCase();

    List<Partner_Application__c> duplicates = PartnerApplicationSubmissionSelector.findPotentialDuplicates(
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

    try {
      // The public form maps a fixed DTO into package-owned fields. Persist
      // that trusted command independently of guest/profile CRUD so a core
      // package install doesn't require subscriber guest-profile mutation.
      Database.insert(record, AccessLevel.SYSTEM_MODE);
    } catch (DmlException ex) {
      if (
        ex.getNumDml() > 0 &&
        String.valueOf(ex.getDmlStatusCode(0)) == 'DUPLICATE_VALUE'
      ) {
        throw new PartnerSyncHandledException(
          'A partner application already exists for this company or email.'
        );
      }

      throw ex;
    }

    Partner_Application__c insertedRecord = record;

    // Re-query rather than reuse the DML result: fields like the
    // auto-number Application_Number__c are only populated by the platform
    // after insert and aren't reflected on the in-memory sObject.
    insertedRecord = PartnerApplicationSubmissionSelector.selectById(
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

    PartnerApplicationDetailDTO detail = PartnerApplicationDomain.toDetailDTO(
      application
    );
    detail.potentialMatches = PartnerApplicationMatchSelector.findPotentialMatches(
      application
    );
    detail.hasPotentialMatches = !detail.potentialMatches.isEmpty();
    return detail;
  }

  public static void claimApplication(Id applicationId) {
    PartnerPermissionService.assertCanApprovePartnerApplications();
    SecurityUtil.assertUpdateable(Partner_Application__c.SObjectType);

    Partner_Application__c application = PartnerApplicationSelector.selectForDecisionById(
      applicationId
    );

    if (
      application.Application_Status__c == 'Approved' ||
      application.Application_Status__c == 'Rejected'
    ) {
      throw new PartnerSyncHandledException(
        'This application has already been decided.'
      );
    }

    if (
      application.Assigned_Reviewer__c != null &&
      application.Assigned_Reviewer__c != UserInfo.getUserId()
    ) {
      throw new PartnerSyncHandledException(
        'This application is already assigned to another reviewer.'
      );
    }

    application.Assigned_Reviewer__c = UserInfo.getUserId();
    application.Application_Status__c = 'Under Review';
    update SecurityUtil.stripForUpdate(new List<SObject>{ application });
  }
}
