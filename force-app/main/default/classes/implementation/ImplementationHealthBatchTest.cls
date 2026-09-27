/*
 * Covers ImplementationHealthBatch: 200-implementation bulk evaluation
 * where a realistic minority have an overdue blocking milestone (health
 * changes) and the rest stay Healthy (no-op) - the aggregate queries and
 * the single bulk update stay within governor limits regardless of how
 * many of the 200 actually change.
 */
@IsTest
private class ImplementationHealthBatchTest {
  @IsTest
  static void evaluates200ImplementationsAndFlagsTheOverdueMinority() {
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Bulk Health Customer'
    );
    insert customer;

    List<Deal_Registration__c> deals = new List<Deal_Registration__c>();
    for (Integer index = 0; index < 200; index++) {
      deals.add(PartnerSyncTestDataFactory.deal(customer.Id, null, null, null));
    }
    insert deals;

    List<Deal_Implementation__c> implementations = new List<Deal_Implementation__c>();
    for (Deal_Registration__c deal : deals) {
      implementations.add(
        new Deal_Implementation__c(
          Deal__c = deal.Id,
          Implementation_Type__c = 'Initial Implementation',
          Status__c = 'In Progress',
          Health__c = 'Healthy',
          Version_Number__c = 0
        )
      );
    }
    insert implementations;

    List<Implementation_Milestone__c> overdueMilestones = new List<Implementation_Milestone__c>();
    for (Integer index = 0; index < 20; index++) {
      overdueMilestones.add(
        new Implementation_Milestone__c(
          Implementation__c = implementations[index].Id,
          Milestone_Type__c = 'Go-Live',
          Name__c = 'Go-Live',
          Status__c = 'In Progress',
          Blocking__c = true,
          Due_On__c = Date.today().addDays(-20),
          Version_Number__c = 0
        )
      );
    }
    insert overdueMilestones;

    Test.startTest();
    new ImplementationHealthBatch().execute(null, implementations);
    Test.stopTest();

    Assert.areEqual(
      20,
      [SELECT COUNT() FROM Deal_Implementation__c WHERE Health__c = 'Overdue']
    );
    Assert.areEqual(
      180,
      [SELECT COUNT() FROM Deal_Implementation__c WHERE Health__c = 'Healthy']
    );
  }
}
