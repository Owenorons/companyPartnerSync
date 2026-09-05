/**
 * Creates the durable onboarding aggregate and append-only lifecycle history.
 * This controlled engine runs only behind already-authorised application services
 * or migration jobs; callers remain responsible for business authorisation.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class PartnerOnboardingLifecycleService {
  public static Partner_Onboarding__c initialise(
    Partner_Application__c application,
    String outcome
  ) {
    if (application == null || application.Id == null) {
      throw new IllegalArgumentException(
        'A persisted partner application is required.'
      );
    }

    Boolean rejected = outcome == 'Rejected';
    Partner_Onboarding__c onboarding = new Partner_Onboarding__c(
      Application__c = application.Id,
      Onboarding_Key__c = String.valueOf(application.Id),
      Status__c = rejected ? 'Closed' : 'Onboarding',
      Current_Stage__c = rejected ? 'Closed' : 'Partner Enablement',
      Activation_Gate_Status__c = 'Blocked',
      Gate_Summary__c = rejected
        ? 'Application rejected; onboarding closed.'
        : 'Business approval recorded. Contract, Salesforce partner enablement, provisioning and readiness gates remain outstanding.',
      Version_Number__c = 1
    );
    Database.upsert(
      onboarding,
      Partner_Onboarding__c.Fields.Onboarding_Key__c,
      AccessLevel.SYSTEM_MODE
    );

    recordEvent(onboarding.Id, application.Id, outcome);
    if (!rejected) {
      ensurePartnerEnablementTask(onboarding.Id);
      PartnerDocumentService.generateRequirements(onboarding.Id);
      PartnerRiskApprovalService.initialise(onboarding.Id);
    }
    return onboarding;
  }

  private static void recordEvent(
    Id onboardingId,
    Id applicationId,
    String outcome
  ) {
    String eventType = outcome == 'Rejected'
      ? 'Application Rejected'
      : 'Business Approval Recorded';
    Partner_Lifecycle_Event__c lifecycleEvent = new Partner_Lifecycle_Event__c(
      Onboarding__c = onboardingId,
      Event_Type__c = eventType,
      Stage__c = outcome == 'Rejected' ? 'Closed' : 'Approval',
      Summary__c = outcome == 'Rejected'
        ? 'The partner application was rejected.'
        : 'Business approval completed; activation remains blocked by downstream gates.',
      Occurred_On__c = System.now(),
      Actor__c = UserInfo.getUserId(),
      Idempotency_Key__c = String.valueOf(applicationId) + ':' + eventType
    );
    Database.upsert(
      lifecycleEvent,
      Partner_Lifecycle_Event__c.Fields.Idempotency_Key__c,
      AccessLevel.SYSTEM_MODE
    );
  }

  private static void ensurePartnerEnablementTask(Id onboardingId) {
    List<Partner_Onboarding_Task__c> existing = [
      SELECT Id
      FROM Partner_Onboarding_Task__c
      WHERE Onboarding__c = :onboardingId AND Task_Type__c = 'Enablement'
      LIMIT 1
    ];
    if (!existing.isEmpty()) {
      return;
    }

    Database.insert(
      new Partner_Onboarding_Task__c(
        Onboarding__c = onboardingId,
        Task_Type__c = 'Enablement',
        Title__c = 'Enable Account as a Salesforce Partner',
        Status__c = 'Not Started',
        Blocking__c = true,
        Due_On__c = System.now().addDays(2)
      ),
      AccessLevel.SYSTEM_MODE
    );
  }
}
