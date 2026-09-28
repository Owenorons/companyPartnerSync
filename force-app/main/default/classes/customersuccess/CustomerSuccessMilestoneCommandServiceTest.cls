/*
 * Covers CustomerSuccessMilestoneCommandService: create, complete, and
 * skip requiring a reason.
 */
@IsTest
private class CustomerSuccessMilestoneCommandServiceTest {
  @IsTest
  static void createInsertsANotStartedMilestone() {
    Customer_Success_Engagement__c engagement = createEngagement();
    User internalUser = TestUserFactory.createInternalUser();

    Customer_Success_Milestone__c milestone;
    System.runAs(internalUser) {
      CustomerSuccessMilestoneCommand command = new CustomerSuccessMilestoneCommand();
      command.engagementId = engagement.Id;
      command.milestoneType = 'Onboarding Kickoff';
      command.targetOn = Date.today().addDays(7);
      milestone = CustomerSuccessMilestoneCommandService.create(command);
    }

    Assert.areEqual('Not Started', milestone.Status__c);
  }

  @IsTest
  static void completeSetsCompletedOn() {
    Customer_Success_Engagement__c engagement = createEngagement();
    User internalUser = TestUserFactory.createInternalUser();

    System.runAs(internalUser) {
      CustomerSuccessMilestoneCommand createCommand = new CustomerSuccessMilestoneCommand();
      createCommand.engagementId = engagement.Id;
      createCommand.milestoneType = 'First Value Realized';
      Customer_Success_Milestone__c milestone = CustomerSuccessMilestoneCommandService.create(
        createCommand
      );

      CustomerSuccessMilestoneCommand completeCommand = new CustomerSuccessMilestoneCommand();
      completeCommand.milestoneId = milestone.Id;
      Customer_Success_Milestone__c completed = CustomerSuccessMilestoneCommandService.complete(
        completeCommand
      );

      Assert.areEqual('Completed', completed.Status__c);
      Assert.areEqual(Date.today(), completed.Completed_On__c);
    }
  }

  @IsTest
  static void skipRequiresAReason() {
    Customer_Success_Engagement__c engagement = createEngagement();
    User internalUser = TestUserFactory.createInternalUser();

    System.runAs(internalUser) {
      CustomerSuccessMilestoneCommand createCommand = new CustomerSuccessMilestoneCommand();
      createCommand.engagementId = engagement.Id;
      createCommand.milestoneType = 'Health Check';
      Customer_Success_Milestone__c milestone = CustomerSuccessMilestoneCommandService.create(
        createCommand
      );

      CustomerSuccessMilestoneCommand skipCommand = new CustomerSuccessMilestoneCommand();
      skipCommand.milestoneId = milestone.Id;

      try {
        CustomerSuccessMilestoneCommandService.skip(skipCommand);
        Assert.fail('Expected a skip without a reason to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('reason'));
      }

      skipCommand.notes = 'Customer opted out of this checkpoint.';
      Customer_Success_Milestone__c skipped = CustomerSuccessMilestoneCommandService.skip(
        skipCommand
      );
      Assert.areEqual('Skipped', skipped.Status__c);
    }
  }

  private static Customer_Success_Engagement__c createEngagement() {
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Milestone Test Customer'
    );
    insert customer;

    Customer_Success_Engagement__c engagement = new Customer_Success_Engagement__c(
      Customer_Account__c = customer.Id,
      Status__c = 'Active',
      Health_Status__c = 'Not Assessed',
      Version_Number__c = 0
    );
    insert engagement;
    return engagement;
  }
}
