/** Risk and approval orchestration. Step decisions never finalise onboarding. */
public without sharing class PartnerRiskApprovalService {
  private static final List<String> DIMENSIONS = new List<String>{
    'Business',
    'Compliance',
    'Legal',
    'Security and Privacy',
    'Finance',
    'Programme'
  };

  public static Partner_Approval_Plan__c initialise(Id onboardingId) {
    Partner_Onboarding__c onboarding = [
      SELECT Id, Onboarding_Key__c
      FROM Partner_Onboarding__c
      WHERE Id = :onboardingId
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    ensureAssessments(onboarding.Id);
    String planKey = String.valueOf(onboarding.Id) + ':APPROVAL:1';
    List<Partner_Approval_Plan__c> existing = [
      SELECT Id, Status__c, Version_Number__c
      FROM Partner_Approval_Plan__c
      WHERE Plan_Key__c = :planKey
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    Partner_Approval_Plan__c plan;
    if (existing.isEmpty()) {
      plan = new Partner_Approval_Plan__c(
        Onboarding__c = onboarding.Id,
        Plan_Key__c = planKey,
        Version_Number__c = 1,
        Current__c = true,
        Status__c = 'Pending',
        Generated_On__c = System.now()
      );
      Database.insert(plan, AccessLevel.SYSTEM_MODE);
    } else {
      plan = existing[0];
    }
    List<Partner_Approval_Step__c> steps = new List<Partner_Approval_Step__c>();
    for (Integer index = 0; index < DIMENSIONS.size(); index++) {
      steps.add(
        new Partner_Approval_Step__c(
          Plan__c = plan.Id,
          Step_Key__c = planKey + ':' + DIMENSIONS[index],
          Dimension__c = DIMENSIONS[index],
          Sequence__c = index + 1,
          Status__c = 'Pending'
        )
      );
    }
    Database.upsert(
      steps,
      Partner_Approval_Step__c.Fields.Step_Key__c,
      AccessLevel.SYSTEM_MODE
    );
    return plan;
  }

  public static Partner_Assessment_Finding__c addFinding(
    Id assessmentId,
    String findingKey,
    String severity,
    Boolean blocking,
    String description
  ) {
    if (String.isBlank(findingKey) || String.isBlank(description)) {
      throw new IllegalArgumentException(
        'Finding key and description are required.'
      );
    }
    Partner_Assessment_Finding__c finding = new Partner_Assessment_Finding__c(
      Assessment__c = assessmentId,
      Finding_Key__c = findingKey,
      Severity__c = severity,
      Blocking__c = blocking,
      Status__c = 'Open',
      Description__c = description
    );
    Database.upsert(
      finding,
      Partner_Assessment_Finding__c.Fields.Finding_Key__c,
      AccessLevel.SYSTEM_MODE
    );
    return finding;
  }

  public static Partner_Approval_Plan__c decideStep(
    Id stepId,
    String decision,
    String reason
  ) {
    if (
      !new Set<String>{
          'Approved',
          'Conditionally Approved',
          'Rejected',
          'More Information Required'
        }
        .contains(decision)
    ) {
      throw new IllegalArgumentException('Unsupported approval decision.');
    }
    if (decision != 'Approved' && String.isBlank(reason)) {
      throw new IllegalArgumentException(
        'A reason is required for this decision.'
      );
    }
    Partner_Approval_Step__c step = [
      SELECT Id, Plan__c, Assigned_To__c, Status__c
      FROM Partner_Approval_Step__c
      WHERE Id = :stepId
      WITH SYSTEM_MODE
      LIMIT 1
      FOR UPDATE
    ];
    if (
      step.Assigned_To__c != null &&
      step.Assigned_To__c != UserInfo.getUserId()
    ) {
      throw new PartnerRiskApprovalException(
        'Only the assigned approver can decide this step.'
      );
    }
    step.Status__c = decision;
    step.Decision_By__c = UserInfo.getUserId();
    step.Decision_On__c = System.now();
    step.Decision_Reason__c = reason;
    Database.update(step, AccessLevel.SYSTEM_MODE);
    return recalculate(step.Plan__c);
  }

  public static Partner_Approval_Plan__c finalise(Id planId) {
    if (
      !FeatureManagement.checkPermission(
        'PartnerSync_Finalise_Partner_Approval'
      )
    ) {
      throw new PartnerRiskApprovalException(
        'Final partner approval authority is required.'
      );
    }
    Partner_Approval_Plan__c plan = [
      SELECT Id, Onboarding__c, Status__c
      FROM Partner_Approval_Plan__c
      WHERE Id = :planId
      WITH SYSTEM_MODE
      LIMIT 1
      FOR UPDATE
    ];
    if (plan.Status__c != 'Ready for Final Approval') {
      throw new PartnerRiskApprovalException(
        'Every approval dimension must be complete before final approval.'
      );
    }
    Integer blockers = [
      SELECT COUNT()
      FROM Partner_Assessment_Finding__c
      WHERE
        Assessment__r.Onboarding__c = :plan.Onboarding__c
        AND Blocking__c = TRUE
        AND Status__c = 'Open'
      WITH SYSTEM_MODE
    ];
    if (blockers > 0)
      throw new PartnerRiskApprovalException(
        'Blocking risk findings remain open.'
      );
    plan.Status__c = 'Approved for Contracting';
    plan.Completed_On__c = System.now();
    Database.update(plan, AccessLevel.SYSTEM_MODE);
    return plan;
  }

  private static void ensureAssessments(Id onboardingId) {
    List<Partner_Assessment__c> records = new List<Partner_Assessment__c>();
    for (
      String typeName : new List<String>{
        'Corporate Registration',
        'Sanctions',
        'Credit',
        'Security and Privacy'
      }
    ) {
      records.add(
        new Partner_Assessment__c(
          Onboarding__c = onboardingId,
          Assessment_Key__c = String.valueOf(onboardingId) + ':' + typeName,
          Assessment_Type__c = typeName,
          Status__c = 'Pending',
          Blocking__c = true,
          Due_On__c = Date.today().addDays(14)
        )
      );
    }
    Database.upsert(
      records,
      Partner_Assessment__c.Fields.Assessment_Key__c,
      AccessLevel.SYSTEM_MODE
    );
  }

  private static Partner_Approval_Plan__c recalculate(Id planId) {
    Boolean pending = false,
      rejected = false,
      information = false,
      conditional = false;
    for (Partner_Approval_Step__c step : [
      SELECT Status__c
      FROM Partner_Approval_Step__c
      WHERE Plan__c = :planId
      WITH SYSTEM_MODE
    ]) {
      pending = pending || step.Status__c == 'Pending';
      rejected = rejected || step.Status__c == 'Rejected';
      information =
        information || step.Status__c == 'More Information Required';
      conditional = conditional || step.Status__c == 'Conditionally Approved';
    }
    String status = rejected
      ? 'Rejected'
      : information
          ? 'More Information Required'
          : pending
              ? 'Pending'
              : conditional
                  ? 'Conditionally Approved'
                  : 'Ready for Final Approval';
    Partner_Approval_Plan__c plan = new Partner_Approval_Plan__c(
      Id = planId,
      Status__c = status
    );
    Database.update(plan, AccessLevel.SYSTEM_MODE);
    return plan;
  }

  public class PartnerRiskApprovalException extends Exception {
  }
}
