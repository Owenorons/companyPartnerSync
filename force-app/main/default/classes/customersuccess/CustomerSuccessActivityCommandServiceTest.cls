/*
 * Covers CustomerSuccessActivityCommandService.record: inserts a logged
 * activity, and requires an engagement, activity type, and summary.
 */
@IsTest
private class CustomerSuccessActivityCommandServiceTest {
  @IsTest
  static void recordInsertsAnActivityLoggedByTheRunningUser() {
    Customer_Success_Engagement__c engagement = createEngagement();
    User internalUser = TestUserFactory.createInternalUser();

    Customer_Success_Activity__c activity;
    System.runAs(internalUser) {
      CustomerSuccessActivityCommand command = new CustomerSuccessActivityCommand();
      command.engagementId = engagement.Id;
      command.activityType = 'Check-In Call';
      command.summary = 'Quarterly check-in, customer is happy with adoption.';
      activity = CustomerSuccessActivityCommandService.record(command);

      Assert.areEqual(internalUser.Id, activity.Logged_By__c);
    }

    Assert.areEqual(
      'Check-In Call',
      [
        SELECT Activity_Type__c
        FROM Customer_Success_Activity__c
        WHERE Id = :activity.Id
      ]
      .Activity_Type__c
    );
  }

  @IsTest
  static void recordRequiresASummary() {
    Customer_Success_Engagement__c engagement = createEngagement();
    User internalUser = TestUserFactory.createInternalUser();

    System.runAs(internalUser) {
      CustomerSuccessActivityCommand command = new CustomerSuccessActivityCommand();
      command.engagementId = engagement.Id;
      command.activityType = 'Check-In Call';

      try {
        CustomerSuccessActivityCommandService.record(command);
        Assert.fail('Expected a record without a summary to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('summary'));
      }
    }
  }

  private static Customer_Success_Engagement__c createEngagement() {
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Activity Test Customer'
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
