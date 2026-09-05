@IsTest
private class DealReviewCommandServiceTest {
  @IsTest
  static void completesReviewAndReleasesDependency() {
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = 'Under Review',
      Estimated_Revenue__c = 75000
    );
    insert deal;
    DealReviewPlanService.generate(new Set<Id>{ deal.Id });
    Deal_Review__c channel = [
      SELECT Id, Status__c, Version_Number__c
      FROM Deal_Review__c
      WHERE Deal__c = :deal.Id AND Review_Key__c = 'Channel_Review'
      LIMIT 1
    ];
    DealReviewCommand start = command(channel, 'Start');
    DealReviewCommandService.execute(new List<DealReviewCommand>{ start });
    channel = [
      SELECT Id, Status__c, Version_Number__c
      FROM Deal_Review__c
      WHERE Id = :channel.Id
    ];
    Assert.areEqual('In Progress', channel.Status__c);
    DealReviewCommand complete = command(channel, 'Complete');
    complete.outcome = 'Approved';
    DealReviewCommandService.execute(new List<DealReviewCommand>{ complete });
    Deal_Review__c commercial = [
      SELECT Status__c
      FROM Deal_Review__c
      WHERE Deal__c = :deal.Id AND Review_Key__c = 'Commercial_Review'
      LIMIT 1
    ];
    Assert.areEqual('Ready', commercial.Status__c);
  }

  @IsTest
  static void governsInformationAndOptimisticLocking() {
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = 'Under Review',
      Estimated_Revenue__c = 1000
    );
    insert deal;
    DealReviewPlanService.generate(new Set<Id>{ deal.Id });
    Deal_Review__c review = [
      SELECT Id, Status__c, Version_Number__c
      FROM Deal_Review__c
      WHERE Deal__c = :deal.Id
      LIMIT 1
    ];
    DealReviewCommandService.execute(
      new List<DealReviewCommand>{ command(review, 'Start') }
    );
    review = [
      SELECT Id, Status__c, Version_Number__c
      FROM Deal_Review__c
      WHERE Id = :review.Id
    ];
    DealReviewCommand request = command(review, 'Request Info');
    request.question = 'Provide signed evidence';
    DealReviewCommandService.execute(new List<DealReviewCommand>{ request });
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Deal_Information_Request__c
        WHERE Review__c = :review.Id
      ]
    );
    try {
      DealReviewCommandService.execute(new List<DealReviewCommand>{ request });
      Assert.fail('Expected stale command rejection.');
    } catch (DealReviewCommandService.DealReviewCommandException expected) {
      Assert.isTrue(expected.getMessage().contains('changed'));
    }
  }

  @IsTest
  static void governsAdministrativeLifecycleCommands() {
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = 'Under Review',
      Estimated_Revenue__c = 1000
    );
    insert deal;
    DealReviewPlanService.generate(new Set<Id>{ deal.Id });
    Deal_Review__c review = [
      SELECT Id
      FROM Deal_Review__c
      WHERE Deal__c = :deal.Id
      LIMIT 1
    ];
    run(review.Id, 'Start');
    DealReviewCommand request = fresh(review.Id, 'Request Info');
    request.question = 'Clarify ownership';
    DealReviewCommandService.execute(new List<DealReviewCommand>{ request });
    run(review.Id, 'Resume');
    DealReviewCommand reassign = fresh(review.Id, 'Reassign');
    reassign.assigneeId = UserInfo.getUserId();
    DealReviewCommandService.execute(new List<DealReviewCommand>{ reassign });
    run(review.Id, 'Escalate');
    DealReviewCommand waive = fresh(review.Id, 'Waive');
    waive.reason = 'Governance exception approved';
    DealReviewCommandService.execute(new List<DealReviewCommand>{ waive });
    Deal_Review__c waived = [
      SELECT Status__c, Assignment_Source__c
      FROM Deal_Review__c
      WHERE Id = :review.Id
    ];
    Assert.areEqual('Waived', waived.Status__c);
    Assert.areEqual('Manual Reassignment', waived.Assignment_Source__c);

    Deal_Registration__c secondDeal = new Deal_Registration__c(
      Status__c = 'Under Review',
      Estimated_Revenue__c = 1000
    );
    insert secondDeal;
    DealReviewPlanService.generate(new Set<Id>{ secondDeal.Id });
    Deal_Review__c second = [
      SELECT Id
      FROM Deal_Review__c
      WHERE Deal__c = :secondDeal.Id
      LIMIT 1
    ];
    DealReviewCommand recuse = fresh(second.Id, 'Recuse');
    recuse.reason = 'Conflict of interest';
    DealReviewCommandService.execute(new List<DealReviewCommand>{ recuse });
    DealReviewCommand reassigned = fresh(second.Id, 'Reassign');
    reassigned.assigneeId = UserInfo.getUserId();
    DealReviewCommandService.execute(new List<DealReviewCommand>{ reassigned });
    run(second.Id, 'Cancel');
    Assert.areEqual(
      'Cancelled',
      [SELECT Status__c FROM Deal_Review__c WHERE Id = :second.Id].Status__c
    );
  }

  private static void run(Id reviewId, String action) {
    DealReviewCommandService.execute(
      new List<DealReviewCommand>{ fresh(reviewId, action) }
    );
  }

  private static DealReviewCommand fresh(Id reviewId, String action) {
    Deal_Review__c review = [
      SELECT Id, Version_Number__c
      FROM Deal_Review__c
      WHERE Id = :reviewId
    ];
    return command(review, action);
  }

  private static DealReviewCommand command(
    Deal_Review__c review,
    String action
  ) {
    DealReviewCommand result = new DealReviewCommand();
    result.reviewId = review.Id;
    result.action = action;
    result.expectedVersion = Integer.valueOf(review.Version_Number__c);
    return result;
  }
}
