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
}
