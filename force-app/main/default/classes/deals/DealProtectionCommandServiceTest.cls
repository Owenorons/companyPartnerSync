@IsTest
private class DealProtectionCommandServiceTest {
  @IsTest
  static void activatesIdempotentlyExtendsAndReleases() {
    Deal_Registration__c deal = approvedDeal(false);
    DealProtectionCommand activationCommand = command(
      deal.Id,
      'Activate Protection',
      'activate-1',
      null
    );
    Deal_Protection_Grant__c grant = DealProtectionCommandService.execute(
      activationCommand
    );
    Deal_Protection_Grant__c duplicate = DealProtectionCommandService.execute(
      activationCommand
    );
    Assert.areEqual(grant.Id, duplicate.Id);
    Assert.areEqual(
      1,
      [SELECT COUNT() FROM Deal_Protection_Grant__c WHERE Deal__c = :deal.Id]
    );
    DealProtectionCommand extend = command(
      deal.Id,
      'Extend Protection',
      'extend-1',
      0
    );
    extend.extensionDays = 15;
    extend.reason = 'Active opportunity requires additional time';
    grant = DealProtectionCommandService.execute(extend);
    Assert.areEqual(1, grant.Extension_Count__c);
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Deal_Protection_Extension__c
        WHERE Grant__c = :grant.Id
      ]
    );
    DealProtectionCommand release = command(
      deal.Id,
      'Release Protection',
      'release-1',
      1
    );
    release.reason = 'Partner withdrew protection';
    DealProtectionCommandService.execute(release);
    grant = [
      SELECT Status__c, Current__c
      FROM Deal_Protection_Grant__c
      WHERE Id = :grant.Id
    ];
    Assert.areEqual('Released', grant.Status__c);
    Assert.isFalse(grant.Current__c);
  }

  @IsTest
  static void blocksActivationForOpenProtectionCondition() {
    Deal_Registration__c deal = approvedDeal(true);
    try {
      DealProtectionCommandService.execute(
        command(deal.Id, 'Activate Protection', 'blocked-1', null)
      );
      Assert.fail('Expected protection condition to block activation.');
    } catch (DealProtectionCommandService.ProtectionCommandException expected) {
      Assert.isTrue(expected.getMessage().contains('conditions'));
    }
  }

  @IsTest
  static void expiresPastGrant() {
    Deal_Registration__c deal = approvedDeal(false);
    Deal_Protection_Grant__c grant = DealProtectionCommandService.execute(
      command(deal.Id, 'Activate Protection', 'activate-expiry', null)
    );
    grant.End_Date__c = Date.today().addDays(-1);
    update grant;
    DealProtectionCommandService.execute(
      command(deal.Id, 'Expire Protection', 'expire-1', 0)
    );
    Assert.areEqual(
      'Expired',
      [SELECT Status__c FROM Deal_Registration__c WHERE Id = :deal.Id].Status__c
    );
  }

  private static Deal_Registration__c approvedDeal(Boolean blockingCondition) {
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = blockingCondition ? 'Approved with Conditions' : 'Approved',
      Estimated_Revenue__c = 10000,
      Version_Number__c = 1
    );
    insert deal;
    Deal_Approval_Plan__c plan = new Deal_Approval_Plan__c(
      Deal__c = deal.Id,
      Current__c = true,
      Current_Plan_Key__c = String.valueOf(deal.Id),
      Version_Number__c = 1,
      Deal_Version__c = 1,
      Status__c = blockingCondition ? 'Approved with Conditions' : 'Approved',
      Approval_Model__c = 'Sequential'
    );
    insert plan;
    if (blockingCondition)
      insert new Deal_Approval_Condition__c(
        Deal__c = deal.Id,
        Plan__c = plan.Id,
        Condition_Type__c = 'Protection Blocking',
        Description__c = 'Signed confirmation required',
        Status__c = 'Open'
      );
    return deal;
  }

  private static DealProtectionCommand command(
    Id dealId,
    String action,
    String key,
    Integer version
  ) {
    DealProtectionCommand result = new DealProtectionCommand();
    result.dealId = dealId;
    result.action = action;
    result.commandKey = key;
    result.expectedVersion = version;
    return result;
  }
}
