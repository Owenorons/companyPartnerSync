/*
 * Covers ImplementationHealthService.computeHealth()'s pure threshold
 * branches: a critical issue triggers Blocked, overdue-days at/above the
 * red threshold triggers Overdue, at/above the amber threshold or enough
 * high issues triggers At Risk, and otherwise Healthy.
 */
@IsTest
private class ImplementationHealthServiceTest {
  @IsTest
  static void criticalIssueTriggersBlocked() {
    Assert.areEqual(
      'Blocked',
      ImplementationHealthService.computeHealth(policy(), 1, 0, 0)
    );
  }

  @IsTest
  static void overdueAtRedThresholdTriggersOverdue() {
    Assert.areEqual(
      'Overdue',
      ImplementationHealthService.computeHealth(policy(), 0, 0, 15)
    );
  }

  @IsTest
  static void overdueAtAmberThresholdTriggersAtRisk() {
    Assert.areEqual(
      'At Risk',
      ImplementationHealthService.computeHealth(policy(), 0, 0, 5)
    );
  }

  @IsTest
  static void enoughHighIssuesTriggersAtRisk() {
    Assert.areEqual(
      'At Risk',
      ImplementationHealthService.computeHealth(policy(), 0, 2, 0)
    );
  }

  @IsTest
  static void noSignalsIsHealthy() {
    Assert.areEqual(
      'Healthy',
      ImplementationHealthService.computeHealth(policy(), 0, 1, 2)
    );
  }

  private static Implementation_Health_Policy__mdt policy() {
    Implementation_Health_Policy__mdt policy = new Implementation_Health_Policy__mdt();
    policy.Overdue_Amber_Days__c = 5;
    policy.Overdue_Red_Days__c = 15;
    policy.High_Issue_Amber_Threshold__c = 2;
    policy.Critical_Issue_Triggers_Red__c = true;
    return policy;
  }
}
