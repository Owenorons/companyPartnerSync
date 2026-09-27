/*
 * Covers ImplementationStatusProjectionService.recompute(): Not Required
 * with no implementations, Planned with only a planned implementation, In
 * Progress once one is in progress, At Risk once an active one is
 * unhealthy, and Completed once all implementations reach a terminal
 * state.
 */
@IsTest
private class ImplementationStatusProjectionServiceTest {
  @IsTest
  static void noImplementationsProjectsNotRequired() {
    Deal_Registration__c deal = createDeal();

    ImplementationStatusProjectionService.recompute(deal.Id);

    Assert.areEqual('Not Required', implementationStatus(deal.Id));
  }

  @IsTest
  static void onlyPlannedImplementationProjectsPlanned() {
    Deal_Registration__c deal = createDeal();
    insertImplementation(deal.Id, 'Planned', 'Healthy');

    ImplementationStatusProjectionService.recompute(deal.Id);

    Assert.areEqual('Planned', implementationStatus(deal.Id));
  }

  @IsTest
  static void inProgressImplementationProjectsInProgress() {
    Deal_Registration__c deal = createDeal();
    insertImplementation(deal.Id, 'In Progress', 'Healthy');

    ImplementationStatusProjectionService.recompute(deal.Id);

    Assert.areEqual('In Progress', implementationStatus(deal.Id));
  }

  @IsTest
  static void unhealthyActiveImplementationProjectsAtRisk() {
    Deal_Registration__c deal = createDeal();
    insertImplementation(deal.Id, 'In Progress', 'Blocked');

    ImplementationStatusProjectionService.recompute(deal.Id);

    Assert.areEqual('At Risk', implementationStatus(deal.Id));
  }

  @IsTest
  static void allTerminalImplementationsProjectCompleted() {
    Deal_Registration__c deal = createDeal();
    insertImplementation(deal.Id, 'Completed', 'Healthy');

    ImplementationStatusProjectionService.recompute(deal.Id);

    Assert.areEqual('Completed', implementationStatus(deal.Id));
  }

  private static Deal_Registration__c createDeal() {
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Implementation Status Customer'
    );
    insert customer;
    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      null,
      null,
      null
    );
    insert deal;
    return deal;
  }

  private static void insertImplementation(
    Id dealId,
    String status,
    String health
  ) {
    insert new Deal_Implementation__c(
      Deal__c = dealId,
      Implementation_Type__c = 'Initial Implementation',
      Status__c = status,
      Health__c = health,
      Version_Number__c = 0
    );
  }

  private static String implementationStatus(Id dealId) {
    return [
      SELECT Implementation_Status__c
      FROM Deal_Registration__c
      WHERE Id = :dealId
    ]
    .Implementation_Status__c;
  }
}
