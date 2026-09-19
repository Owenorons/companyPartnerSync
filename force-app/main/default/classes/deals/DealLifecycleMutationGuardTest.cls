@IsTest
private class DealLifecycleMutationGuardTest {
  @IsTest
  static void blocksUncontrolledLifecycleControlFieldUpdate() {
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = 'Draft',
      Lifecycle_Phase__c = 'Registration',
      Version_Number__c = 0
    );
    insert deal;

    deal.Version_Number__c = 1;
    Database.SaveResult result = Database.update(deal, false);

    Assert.isFalse(result.isSuccess());
    Assert.isTrue(
      result.getErrors()[0].getMessage().contains('authorised deal command')
    );
  }

  @IsTest
  static void permitsBalancedControlledMutation() {
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = 'Draft',
      Lifecycle_Phase__c = 'Registration',
      Version_Number__c = 0
    );
    insert deal;

    deal.Version_Number__c = 1;
    DealLifecycleMutationContext.beginControlledMutation();
    try {
      update deal;
    } finally {
      DealLifecycleMutationContext.endControlledMutation();
    }

    Deal_Registration__c stored = [
      SELECT Version_Number__c
      FROM Deal_Registration__c
      WHERE Id = :deal.Id
    ];
    Assert.areEqual(1, stored.Version_Number__c);
    Assert.isFalse(DealLifecycleMutationContext.isControlledMutation());
  }
}
