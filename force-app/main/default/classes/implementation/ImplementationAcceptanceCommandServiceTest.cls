/*
 * Covers ImplementationAcceptanceCommandService: request, record (via
 * the Salesforce-hosted adapter), reject (which doesn't erase the prior
 * request), and that ImplementationCommandService.complete() is blocked
 * until every requested acceptance reaches Accepted.
 */
@IsTest
private class ImplementationAcceptanceCommandServiceTest {
  @IsTest
  static void requestCreatesAPendingAcceptanceAndUpdatesTheImplementation() {
    Deal_Implementation__c implementation = createImplementation();

    Test.startTest();
    Implementation_Acceptance__c acceptance = ImplementationAcceptanceCommandService.request(
      requestCommand(implementation.Id)
    );
    Test.stopTest();

    Assert.areEqual('Requested', acceptance.Status__c);
    Assert.areEqual(
      'Pending Customer Acceptance',
      [
        SELECT Status__c
        FROM Deal_Implementation__c
        WHERE Id = :implementation.Id
      ]
      .Status__c
    );
  }

  @IsTest
  static void recordAcceptsViaTheSalesforceHostedAdapter() {
    Deal_Implementation__c implementation = createImplementation();
    Implementation_Acceptance__c acceptance = ImplementationAcceptanceCommandService.request(
      requestCommand(implementation.Id)
    );

    Test.startTest();
    ImplementationAcceptanceCommand recordCommand = new ImplementationAcceptanceCommand();
    recordCommand.acceptanceId = acceptance.Id;
    recordCommand.expectedVersion = 0;
    recordCommand.acceptedByName = 'Jordan Customer';
    recordCommand.acceptedByEmail = 'jordan@customer.example';
    ImplementationAcceptanceCommandService.record(recordCommand);
    Test.stopTest();

    Implementation_Acceptance__c refreshed = [
      SELECT Status__c, Acceptance_Method__c, Accepted_By_Name__c
      FROM Implementation_Acceptance__c
      WHERE Id = :acceptance.Id
    ];
    Assert.areEqual('Accepted', refreshed.Status__c);
    Assert.areEqual('Salesforce Hosted', refreshed.Acceptance_Method__c);
    Assert.areEqual('Jordan Customer', refreshed.Accepted_By_Name__c);
    Assert.areEqual(
      'Customer Accepted',
      [
        SELECT Status__c
        FROM Deal_Implementation__c
        WHERE Id = :implementation.Id
      ]
      .Status__c
    );
  }

  @IsTest
  static void rejectRequiresAReasonAndDoesNotEraseTheRequest() {
    Deal_Implementation__c implementation = createImplementation();
    Implementation_Acceptance__c acceptance = ImplementationAcceptanceCommandService.request(
      requestCommand(implementation.Id)
    );

    Test.startTest();
    ImplementationAcceptanceCommand rejectCommand = new ImplementationAcceptanceCommand();
    rejectCommand.acceptanceId = acceptance.Id;
    rejectCommand.expectedVersion = 0;
    try {
      ImplementationAcceptanceCommandService.reject(rejectCommand);
      Assert.fail('Expected a rejection without a reason to be rejected.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains('reason'));
    }

    rejectCommand.reason = 'Configuration does not match agreed scope.';
    ImplementationAcceptanceCommandService.reject(rejectCommand);
    Test.stopTest();

    Implementation_Acceptance__c refreshed = [
      SELECT Status__c, Acceptance_Type__c, Rejection_Reason__c
      FROM Implementation_Acceptance__c
      WHERE Id = :acceptance.Id
    ];
    Assert.areEqual('Rejected', refreshed.Status__c);
    Assert.areEqual('Milestone Sign-Off', refreshed.Acceptance_Type__c);
    Assert.areEqual(
      'Configuration does not match agreed scope.',
      refreshed.Rejection_Reason__c
    );
  }

  @IsTest
  static void completeIsBlockedUntilAllRequiredAcceptancesAreAccepted() {
    // Inserted directly (not via request()) so the implementation stays
    // In Progress throughout - request() also flips Deal_Implementation__c
    // to Pending Customer Acceptance, which would trip Complete's status
    // guard before ever reaching the acceptance guard this test targets.
    Deal_Implementation__c implementation = createImplementation();
    Implementation_Acceptance__c acceptance = new Implementation_Acceptance__c(
      Implementation__c = implementation.Id,
      Acceptance_Type__c = 'Milestone Sign-Off',
      Status__c = 'Requested',
      Requested_On__c = System.now(),
      Version_Number__c = 0
    );
    insert acceptance;

    User internalUser = internalUser();
    System.runAs(internalUser) {
      ImplementationCommand completeCommand = new ImplementationCommand();
      completeCommand.implementationId = implementation.Id;
      completeCommand.action = 'Complete';
      completeCommand.expectedVersion = 0;
      try {
        ImplementationCommandService.execute(completeCommand);
        Assert.fail(
          'Expected completion to be blocked by an unaccepted required acceptance.'
        );
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('acceptances'));
      }
    }

    ImplementationAcceptanceCommand recordCommand = new ImplementationAcceptanceCommand();
    recordCommand.acceptanceId = acceptance.Id;
    recordCommand.expectedVersion = 0;
    recordCommand.acceptedByName = 'Jordan Customer';
    ImplementationAcceptanceCommandService.record(recordCommand);

    Integer currentVersion = [
        SELECT Version_Number__c
        FROM Deal_Implementation__c
        WHERE Id = :implementation.Id
      ]
      .Version_Number__c
      .intValue();

    System.runAs(internalUser) {
      ImplementationCommand completeCommand = new ImplementationCommand();
      completeCommand.implementationId = implementation.Id;
      completeCommand.action = 'Complete';
      completeCommand.expectedVersion = currentVersion;
      ImplementationCommandService.execute(completeCommand);
    }

    Assert.areEqual(
      'Completed',
      [
        SELECT Status__c
        FROM Deal_Implementation__c
        WHERE Id = :implementation.Id
      ]
      .Status__c
    );
  }

  private static Deal_Implementation__c createImplementation() {
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Acceptance Customer'
    );
    insert customer;
    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      null,
      null,
      null
    );
    insert deal;
    Deal_Implementation__c implementation = new Deal_Implementation__c(
      Deal__c = deal.Id,
      Implementation_Type__c = 'Initial Implementation',
      Status__c = 'In Progress',
      Health__c = 'Healthy',
      Version_Number__c = 0
    );
    insert implementation;
    return implementation;
  }

  private static ImplementationAcceptanceCommand requestCommand(
    Id implementationId
  ) {
    ImplementationAcceptanceCommand command = new ImplementationAcceptanceCommand();
    command.implementationId = implementationId;
    command.acceptanceType = 'Milestone Sign-Off';
    return command;
  }

  private static User internalUser() {
    User channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Manage_Implementation',
      true
    );
    return channelManager;
  }
}
