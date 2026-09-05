@IsTest
private class DealRiskScoringServiceTest {
  @IsTest
  static void scoresEveryRiskBandAndCapsAtOneHundred() {
    Deal_Registration__c low = completeDeal();
    Assert.areEqual(0, DealRiskScoringService.score(low));
    Assert.areEqual('Low', DealRiskScoringService.level(0));

    Deal_Registration__c medium = completeDeal();
    medium.Conflict_Status__c = 'Potential Conflict';
    medium.Estimated_Revenue__c = 50000;
    medium.Estimated_Close_Date__c = Date.today().addDays(10);
    Decimal mediumScore = DealRiskScoringService.score(medium, null);
    Assert.areEqual(49, mediumScore);
    Assert.areEqual('Medium', DealRiskScoringService.level(mediumScore));

    Deal_Registration__c high = completeDeal();
    high.Conflict_Status__c = 'Confirmed Conflict';
    high.Estimated_Revenue__c = 250000;
    high.Estimated_Close_Date__c = Date.today().addDays(-1);
    high.Business_Problem__c = null;
    high.Status__c = 'Rejected';
    List<Deal_Registration__c> conflicts = new List<Deal_Registration__c>();
    for (Integer index = 0; index < 4; index++) {
      conflicts.add(new Deal_Registration__c());
    }
    Assert.areEqual(100, DealRiskScoringService.score(high, conflicts));
    Assert.areEqual('High', DealRiskScoringService.level(100));

    Deal_Registration__c large = completeDeal();
    large.Estimated_Revenue__c = 100000;
    Assert.areEqual(12, DealRiskScoringService.score(large));
  }

  @IsTest
  static void explainsSignalsAndEveryRecommendationBranch() {
    Deal_Registration__c safe = completeDeal();
    Assert.isTrue(
      DealRiskScoringService.summary(safe, new List<Deal_Registration__c>(), 0)
        .contains('no material risk signals')
    );
    Assert.isTrue(
      DealRiskScoringService.recommendation(safe, null, 0).contains('Proceed')
    );

    Deal_Registration__c risky = completeDeal();
    risky.Conflict_Status__c = 'Potential Conflict';
    risky.Estimated_Revenue__c = 150000;
    risky.Estimated_Close_Date__c = Date.today().addDays(-2);
    risky.Proposed_Solution__c = null;
    String summary = DealRiskScoringService.summary(
      risky,
      new List<Deal_Registration__c>{ new Deal_Registration__c() },
      90
    );
    Assert.isTrue(summary.contains('Potential Conflict'));
    Assert.isTrue(summary.contains('related active'));
    Assert.isTrue(summary.contains('high estimated revenue'));
    Assert.isTrue(summary.contains('has passed'));
    Assert.isTrue(summary.contains('incomplete'));
    Assert.isTrue(
      DealRiskScoringService.recommendation(risky, null, 90)
        .contains('Investigate')
    );
    Assert.isTrue(
      DealRiskScoringService.recommendation(risky, null, 40).contains('Review')
    );

    risky.Estimated_Close_Date__c = Date.today().addDays(20);
    Assert.isTrue(
      DealRiskScoringService.summary(risky, null, 40).contains('within 30 days')
    );
    risky.Status__c = 'Rejected';
    risky.Rejection_Reason__c = null;
    Assert.isTrue(
      DealRiskScoringService.recommendation(risky, null, 100)
        .contains('rejection decision')
    );
    risky.Rejection_Reason__c = 'Duplicate customer opportunity';
    Assert.areEqual(
      'Duplicate customer opportunity',
      DealRiskScoringService.recommendation(risky, null, 100)
    );
  }

  private static Deal_Registration__c completeDeal() {
    return new Deal_Registration__c(
      Status__c = 'Submitted',
      Conflict_Status__c = 'None',
      Estimated_Revenue__c = 1000,
      Estimated_Close_Date__c = Date.today().addDays(60),
      Business_Problem__c = 'Problem',
      Proposed_Solution__c = 'Solution'
    );
  }
}
