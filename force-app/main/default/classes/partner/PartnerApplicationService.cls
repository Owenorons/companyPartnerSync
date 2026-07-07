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

    insert sanitized;

    Partner_Application__c insertedRecord = (Partner_Application__c) sanitized[0];

    insertedRecord = PartnerApplicationSelector.selectSubmissionResultById(
      insertedRecord.Id
    );

    LoggingService.info(
      'PartnerApplicationService',
      'Partner application submitted: ' + insertedRecord.Id
    );

    return PartnerApplicationDomain.toResultDTO(insertedRecord);
  }

  public static List<PartnerApplicationResultDTO> getPendingApplications() {
    PartnerAccessService.assertInternalUser();

    List<PartnerApplicationResultDTO> results = new List<PartnerApplicationResultDTO>();

    for (
      Partner_Application__c application : PartnerApplicationSelector.selectPendingApplications()
    ) {
      results.add(PartnerApplicationDomain.toResultDTO(application));
    }

    return results;
  }
}
