@IsTest
private class PartnerRiskApprovalServiceTest {
  @IsTest
  static void initialiseIsIdempotentAndCreatesAssessmentsAndSteps() {
    Partner_Onboarding__c onboarding = onboarding();
    Partner_Approval_Plan__c first = PartnerRiskApprovalService.initialise(
      onboarding.Id
    );
    Partner_Approval_Plan__c repeated = PartnerRiskApprovalService.initialise(
      onboarding.Id
    );
    Assert.areEqual(first.Id, repeated.Id);
    Assert.areEqual(
      4,
      [
        SELECT COUNT()
        FROM Partner_Assessment__c
        WHERE Onboarding__c = :onboarding.Id
      ]
    );
    Assert.areEqual(
      6,
      [
        SELECT COUNT()
        FROM Partner_Approval_Step__c
        WHERE Plan__c = :first.Id
      ]
    );
  }

  @IsTest
  static void findingValidationAndUpsertAreIdempotent() {
    Partner_Approval_Plan__c plan = PartnerRiskApprovalService.initialise(
      onboarding().Id
    );
    Partner_Assessment__c assessment = [
      SELECT Id
      FROM Partner_Assessment__c
      WHERE Onboarding__c = :plan.Onboarding__c
      LIMIT 1
    ];
    assertFindingRejected(null, 'Description');
    Partner_Assessment_Finding__c first = PartnerRiskApprovalService.addFinding(
      assessment.Id,
      'SANCTIONS:1',
      'High',
      true,
      'Potential sanctions match.'
    );
    Partner_Assessment_Finding__c repeated = PartnerRiskApprovalService.addFinding(
      assessment.Id,
      'SANCTIONS:1',
      'Medium',
      false,
      'Cleared after review.'
    );
    Assert.areEqual(first.Id, repeated.Id);
  }

  @IsTest
  static void decisionsExerciseEveryPlanStatusAndValidation() {
    Partner_Approval_Plan__c plan = PartnerRiskApprovalService.initialise(
      onboarding().Id
    );
    List<Partner_Approval_Step__c> steps = [
      SELECT Id
      FROM Partner_Approval_Step__c
      WHERE Plan__c = :plan.Id
      ORDER BY Sequence__c
    ];
    assertDecisionRejected(steps[0].Id, 'Unknown', null, 'Unsupported');
    assertDecisionRejected(steps[0].Id, 'Rejected', null, 'reason is required');
    Assert.areEqual(
      'Rejected',
      PartnerRiskApprovalService.decideStep(
          steps[0].Id,
          'Rejected',
          'Business criteria not met.'
        )
        .Status__c
    );
    PartnerRiskApprovalService.decideStep(
      steps[1].Id,
      'More Information Required',
      'Provide evidence.'
    );
    Assert.areEqual(
      'More Information Required',
      PartnerRiskApprovalService.decideStep(steps[0].Id, 'Approved', null)
        .Status__c
    );
    PartnerRiskApprovalService.decideStep(
      steps[1].Id,
      'Conditionally Approved',
      'Complete training.'
    );
    for (Integer index = 2; index < steps.size(); index++) {
      PartnerRiskApprovalService.decideStep(steps[index].Id, 'Approved', null);
    }
    Partner_Approval_Plan__c conditional = [
      SELECT Status__c
      FROM Partner_Approval_Plan__c
      WHERE Id = :plan.Id
    ];
    Assert.areEqual('Conditionally Approved', conditional.Status__c);
    Assert.areEqual(
      'Ready for Final Approval',
      PartnerRiskApprovalService.decideStep(steps[1].Id, 'Approved', null)
        .Status__c
    );
  }

  @IsTest
  static void assignedApproverAndFinalisationGuardsAreEnforced() {
    User otherUser = TestUserFactory.createInternalUser();
    User unprivilegedUser = TestUserFactory.createInternalUser();
    Partner_Approval_Plan__c plan = PartnerRiskApprovalService.initialise(
      onboarding().Id
    );
    Partner_Approval_Step__c step = [
      SELECT Id, Assigned_To__c
      FROM Partner_Approval_Step__c
      WHERE Plan__c = :plan.Id
      LIMIT 1
    ];
    step.Assigned_To__c = otherUser.Id;
    update step;
    System.runAs(unprivilegedUser) {
      try {
        PartnerRiskApprovalService.decideStep(step.Id, 'Approved', null);
        Assert.fail('Expected assigned-approver guard.');
      } catch (PartnerRiskApprovalService.PartnerRiskApprovalException expected) {
        Assert.isTrue(expected.getMessage().contains('assigned approver'));
      }
      try {
        PartnerRiskApprovalService.finalise(plan.Id);
        Assert.fail('Expected final approval authority guard.');
      } catch (PartnerRiskApprovalService.PartnerRiskApprovalException expected) {
        Assert.isTrue(expected.getMessage().contains('authority'));
      }
    }
  }

  @IsTest
  static void authorisedFinalisationBlocksFindingsThenCompletes() {
    User authority = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      authority.Id,
      'PartnerSync_Onboarding_Approval_Authority'
    );
    System.runAs(authority) {
      Partner_Approval_Plan__c plan = PartnerRiskApprovalService.initialise(
        onboarding().Id
      );
      try {
        PartnerRiskApprovalService.finalise(plan.Id);
        Assert.fail('Expected incomplete-plan guard.');
      } catch (PartnerRiskApprovalService.PartnerRiskApprovalException expected) {
        Assert.isTrue(expected.getMessage().contains('dimension'));
      }
      for (Partner_Approval_Step__c step : [
        SELECT Id
        FROM Partner_Approval_Step__c
        WHERE Plan__c = :plan.Id
      ]) {
        PartnerRiskApprovalService.decideStep(step.Id, 'Approved', null);
      }
      Partner_Assessment__c assessment = [
        SELECT Id
        FROM Partner_Assessment__c
        WHERE Onboarding__c = :plan.Onboarding__c
        LIMIT 1
      ];
      Partner_Assessment_Finding__c blocker = PartnerRiskApprovalService.addFinding(
        assessment.Id,
        'BLOCKER:1',
        'Critical',
        true,
        'Blocking compliance issue.'
      );
      try {
        PartnerRiskApprovalService.finalise(plan.Id);
        Assert.fail('Expected blocking-finding guard.');
      } catch (PartnerRiskApprovalService.PartnerRiskApprovalException expected) {
        Assert.isTrue(expected.getMessage().contains('Blocking'));
      }
      blocker.Status__c = 'Resolved';
      update blocker;
      Assert.areEqual(
        'Approved for Contracting',
        PartnerRiskApprovalService.finalise(plan.Id).Status__c
      );
    }
  }

  private static Partner_Onboarding__c onboarding() {
    Partner_Application__c application = new Partner_Application__c(
      Name = 'Risk Applicant',
      Company_Name__c = 'Risk Applicant',
      Business_Email__c = 'risk-' + System.now().getTime() + '@example.com',
      Application_Status__c = 'Approved'
    );
    insert application;
    Partner_Onboarding__c onboarding = new Partner_Onboarding__c(
      Application__c = application.Id,
      Onboarding_Key__c = String.valueOf(application.Id),
      Status__c = 'Onboarding',
      Current_Stage__c = 'Risk Review',
      Activation_Gate_Status__c = 'Blocked',
      Version_Number__c = 1
    );
    insert onboarding;
    return onboarding;
  }

  private static void assertFindingRejected(
    String findingKey,
    String description
  ) {
    try {
      PartnerRiskApprovalService.addFinding(
        null,
        findingKey,
        'High',
        true,
        description
      );
      Assert.fail('Expected invalid finding rejection.');
    } catch (IllegalArgumentException expected) {
      Assert.isTrue(expected.getMessage().contains('required'));
    }
  }

  private static void assertDecisionRejected(
    Id stepId,
    String decision,
    String reason,
    String expectedMessage
  ) {
    try {
      PartnerRiskApprovalService.decideStep(stepId, decision, reason);
      Assert.fail('Expected invalid decision rejection.');
    } catch (IllegalArgumentException expected) {
      Assert.isTrue(expected.getMessage().contains(expectedMessage));
    }
  }
}
