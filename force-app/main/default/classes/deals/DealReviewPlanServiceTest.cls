@IsTest
private class DealReviewPlanServiceTest {
  @IsTest
  static void generatesAndSupersedesDeterministicPlans() {
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = 'Under Review',
      Estimated_Revenue__c = 75000
    );
    insert deal;
    DealReviewPlanService.generate(new Set<Id>{ deal.Id });
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Deal_Review_Plan__c
        WHERE Deal__c = :deal.Id AND Current__c = TRUE
      ]
    );
    Assert.areEqual(
      2,
      [
        SELECT COUNT()
        FROM Deal_Review__c
        WHERE Deal__c = :deal.Id
      ]
    );
    DealReviewPlanService.generate(new Set<Id>{ deal.Id });
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Deal_Review_Plan__c
        WHERE Deal__c = :deal.Id AND Current__c = TRUE
      ]
    );
    Assert.areEqual(
      2,
      [
        SELECT COUNT()
        FROM Deal_Review_Plan__c
        WHERE Deal__c = :deal.Id
      ]
    );
    DealReviewPlanService.generate(new Set<Id>{ deal.Id });
    Deal_Review_Plan__c currentPlan = [
      SELECT Version_Number__c
      FROM Deal_Review_Plan__c
      WHERE Deal__c = :deal.Id AND Current__c = TRUE
      LIMIT 1
    ];
    Assert.areEqual(3, currentPlan.Version_Number__c);
  }

  @IsTest
  static void routesStepsToPermissionSetsNotIndividualUsers() {
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = 'Under Review',
      Estimated_Revenue__c = 75000
    );
    insert deal;

    DealReviewPlanService.generate(new Set<Id>{ deal.Id });

    Deal_Review__c channel = [
      SELECT
        Assigned_To__c,
        Approver_Permission_Set__c,
        Assignment_Source__c,
        Status__c
      FROM Deal_Review__c
      WHERE Deal__c = :deal.Id AND Review_Key__c = 'Channel_Review'
      LIMIT 1
    ];
    Assert.isNull(channel.Assigned_To__c);
    Assert.areEqual(
      'PartnerSync_Channel_Manager',
      channel.Approver_Permission_Set__c
    );
    Assert.areEqual('Rule: Permission Set', channel.Assignment_Source__c);
    Assert.areEqual('Ready', channel.Status__c);

    Deal_Review__c commercial = [
      SELECT
        Assigned_To__c,
        Approver_Permission_Set__c,
        Assignment_Source__c,
        Status__c
      FROM Deal_Review__c
      WHERE Deal__c = :deal.Id AND Review_Key__c = 'Commercial_Review'
      LIMIT 1
    ];
    Assert.isNull(commercial.Assigned_To__c);
    Assert.areEqual(
      'PartnerSync_Deal_Reviewer',
      commercial.Approver_Permission_Set__c
    );
    Assert.areEqual('Blocked', commercial.Status__c);
  }
}
