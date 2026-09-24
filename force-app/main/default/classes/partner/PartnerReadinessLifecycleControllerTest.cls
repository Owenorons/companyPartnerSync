@IsTest
private class PartnerReadinessLifecycleControllerTest {
  private static Partner_Onboarding__c onboarding() {
    Partner_Application__c application = new Partner_Application__c(
      Name = 'Exception Panel Applicant',
      Company_Name__c = 'Exception Panel Applicant',
      Business_Email__c = 'exception-panel-' +
        System.now().getTime() +
        '@example.com',
      Application_Status__c = 'Approved',
      Requested_Tier__c = 'Gold',
      Partner_Type__c = 'Reseller',
      Country__c = 'Australia'
    );
    insert application;
    Partner_Onboarding__c onboarding = new Partner_Onboarding__c(
      Application__c = application.Id,
      Onboarding_Key__c = String.valueOf(application.Id),
      Status__c = 'Onboarding',
      Current_Stage__c = 'Readiness',
      Activation_Gate_Status__c = 'Blocked',
      Version_Number__c = 1
    );
    insert onboarding;
    return onboarding;
  }

  @IsTest
  static void grantListAndRevokeExceptionThroughTheController() {
    Partner_Onboarding__c onboarding = onboarding();
    PartnerReadinessLifecycleService.testLifecycleAuthority = true;

    PartnerExceptionGrantDTO request = new PartnerExceptionGrantDTO();
    request.onboardingId = onboarding.Id;
    request.gate = 'training';
    request.reason = 'Training platform outage.';
    request.effectiveOn = Date.today();

    Partner_Exception__c granted = PartnerReadinessLifecycleController.grantException(
      request
    );
    Assert.areEqual('Active', granted.Status__c);

    List<Partner_Exception__c> listed = PartnerReadinessLifecycleController.getExceptions(
      onboarding.Id
    );
    Assert.areEqual(1, listed.size());

    Partner_Exception__c revoked = PartnerReadinessLifecycleController.revokeException(
      granted.Id,
      'Training platform restored.'
    );
    Assert.areEqual('Revoked', revoked.Status__c);
  }

  @IsTest
  static void grantExceptionWrapsValidationFailureAsAuraHandled() {
    Partner_Onboarding__c onboarding = onboarding();
    PartnerReadinessLifecycleService.testLifecycleAuthority = true;

    PartnerExceptionGrantDTO request = new PartnerExceptionGrantDTO();
    request.onboardingId = onboarding.Id;
    request.gate = 'not-a-real-gate';
    request.reason = 'Reason';
    request.effectiveOn = Date.today();

    try {
      PartnerReadinessLifecycleController.grantException(request);
      Assert.fail('Expected an AuraHandledException.');
    } catch (AuraHandledException expected) {
      Assert.isTrue(true);
    }
  }
}
