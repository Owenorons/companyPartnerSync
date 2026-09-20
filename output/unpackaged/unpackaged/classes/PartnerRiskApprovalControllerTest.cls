@IsTest
private class PartnerRiskApprovalControllerTest {
  @IsTest
  static void getApprovalQueueReturnsRowsForAuthorizedReviewer() {
    User reviewer = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      reviewer.Id,
      'PartnerSync_Onboarding_Risk_Reviewer'
    );
    Partner_Onboarding__c onboarding = onboarding();
    PartnerRiskApprovalService.initialise(onboarding.Id);

    System.runAs(reviewer) {
      List<PartnerApprovalStepListDTO> queue = PartnerRiskApprovalController.getApprovalQueue();
      Assert.areEqual(6, queue.size());
      Assert.isNotNull(queue[0].partnerName);
      Assert.areEqual('Pending', queue[0].status);
      Assert.isTrue(queue[0].canDecide);
    }
  }

  @IsTest
  static void getApprovalQueueThrowsForUnauthorizedUser() {
    User unpermissioned = TestUserFactory.createInternalUser();
    PartnerRiskApprovalService.initialise(onboarding().Id);

    System.runAs(unpermissioned) {
      try {
        PartnerRiskApprovalController.getApprovalQueue();
        Assert.fail('Expected approval-step decision permission guard.');
      } catch (AuraHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('authority'));
      }
    }
  }

  @IsTest
  static void decideStepDelegatesToServiceAndUpdatesStatus() {
    User reviewer = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      reviewer.Id,
      'PartnerSync_Onboarding_Risk_Reviewer'
    );
    Partner_Onboarding__c onboarding = onboarding();
    Partner_Approval_Plan__c plan = PartnerRiskApprovalService.initialise(
      onboarding.Id
    );
    Partner_Approval_Step__c step = [
      SELECT Id
      FROM Partner_Approval_Step__c
      WHERE Plan__c = :plan.Id
      LIMIT 1
    ];

    System.runAs(reviewer) {
      PartnerApprovalStepDecisionDTO request = new PartnerApprovalStepDecisionDTO();
      request.stepId = step.Id;
      request.decision = 'Approved';
      PartnerRiskApprovalController.decideStep(request);
    }

    Assert.areEqual(
      'Approved',
      [SELECT Status__c FROM Partner_Approval_Step__c WHERE Id = :step.Id]
      .Status__c
    );
  }

  @IsTest
  static void decideStepSurfacesHandledExceptionMessage() {
    User otherUser = TestUserFactory.createInternalUser();
    User reviewer = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      reviewer.Id,
      'PartnerSync_Onboarding_Risk_Reviewer'
    );
    Partner_Onboarding__c onboarding = onboarding();
    Partner_Approval_Plan__c plan = PartnerRiskApprovalService.initialise(
      onboarding.Id
    );
    Partner_Approval_Step__c step = [
      SELECT Id, Assigned_To__c
      FROM Partner_Approval_Step__c
      WHERE Plan__c = :plan.Id
      LIMIT 1
    ];
    step.Assigned_To__c = otherUser.Id;
    update step;

    System.runAs(reviewer) {
      PartnerApprovalStepDecisionDTO request = new PartnerApprovalStepDecisionDTO();
      request.stepId = step.Id;
      request.decision = 'Approved';
      try {
        PartnerRiskApprovalController.decideStep(request);
        Assert.fail('Expected assigned-approver guard.');
      } catch (AuraHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('assigned approver'));
      }
    }
  }

  private static Partner_Onboarding__c onboarding() {
    Account partnerAccount = PartnerSyncTestDataFactory.partnerAccount(
      'Risk Controller Partner'
    );
    insert partnerAccount;
    Partner_Application__c application = new Partner_Application__c(
      Name = 'Risk Controller Applicant',
      Company_Name__c = 'Risk Controller Applicant',
      Business_Email__c = 'risk-controller-' +
        System.now().getTime() +
        '@example.com',
      Application_Status__c = 'Approved'
    );
    insert application;
    Partner_Onboarding__c onboarding = new Partner_Onboarding__c(
      Application__c = application.Id,
      Onboarding_Key__c = String.valueOf(application.Id),
      Partner_Account__c = partnerAccount.Id,
      Status__c = 'Onboarding',
      Current_Stage__c = 'Risk Review',
      Activation_Gate_Status__c = 'Blocked',
      Version_Number__c = 1
    );
    insert onboarding;
    return onboarding;
  }
}
