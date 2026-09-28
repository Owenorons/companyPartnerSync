/*
 * Covers CustomerSuccessRiskCommandService: raise/resolve/accept, and that
 * health is recomputed on raise (a Critical risk immediately drives the
 * engagement's Health_Status__c down, without waiting for a separate
 * recompute call).
 */
@IsTest
private class CustomerSuccessRiskCommandServiceTest {
  @IsTest
  static void raiseCreatesAnOpenRiskAndRecomputesHealth() {
    Customer_Success_Engagement__c engagement = createEngagement();
    User csUser = internalRiskUser();

    Customer_Success_Risk__c risk;
    System.runAs(csUser) {
      CustomerSuccessRiskCommand command = new CustomerSuccessRiskCommand();
      command.engagementId = engagement.Id;
      command.riskType = 'Adoption Risk';
      command.severity = 'Critical';
      command.description = 'Customer has not logged in for 60 days.';
      risk = CustomerSuccessRiskCommandService.raise(command);
    }

    Assert.areEqual('Open', risk.Status__c);
    Assert.areEqual(
      'Critical',
      [
        SELECT Health_Status__c
        FROM Customer_Success_Engagement__c
        WHERE Id = :engagement.Id
      ]
      .Health_Status__c
    );
  }

  @IsTest
  static void resolveRequiresAResolutionAndRecomputesHealth() {
    Customer_Success_Engagement__c engagement = createEngagement();
    User csUser = internalRiskUser();

    System.runAs(csUser) {
      CustomerSuccessRiskCommand raiseCommand = new CustomerSuccessRiskCommand();
      raiseCommand.engagementId = engagement.Id;
      raiseCommand.riskType = 'Adoption Risk';
      raiseCommand.severity = 'Critical';
      raiseCommand.description = 'Customer has not logged in for 60 days.';
      Customer_Success_Risk__c risk = CustomerSuccessRiskCommandService.raise(
        raiseCommand
      );

      CustomerSuccessRiskCommand resolveCommand = new CustomerSuccessRiskCommand();
      resolveCommand.riskId = risk.Id;

      try {
        CustomerSuccessRiskCommandService.resolve(resolveCommand);
        Assert.fail('Expected a resolve without a resolution to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('resolution'));
      }

      resolveCommand.resolution = 'Customer re-engaged after outreach.';
      Customer_Success_Risk__c resolved = CustomerSuccessRiskCommandService.resolve(
        resolveCommand
      );
      Assert.areEqual('Resolved', resolved.Status__c);
    }

    Assert.areEqual(
      'Healthy',
      [
        SELECT Health_Status__c
        FROM Customer_Success_Engagement__c
        WHERE Id = :engagement.Id
      ]
      .Health_Status__c,
      'Health must reflect the risk being resolved, not stay stuck at Critical.'
    );
  }

  @IsTest
  static void acceptRequiresAReason() {
    Customer_Success_Engagement__c engagement = createEngagement();
    User csUser = internalRiskUser();

    System.runAs(csUser) {
      CustomerSuccessRiskCommand raiseCommand = new CustomerSuccessRiskCommand();
      raiseCommand.engagementId = engagement.Id;
      raiseCommand.riskType = 'Commercial Risk';
      raiseCommand.description = 'Budget freeze reported by the partner.';
      Customer_Success_Risk__c risk = CustomerSuccessRiskCommandService.raise(
        raiseCommand
      );

      CustomerSuccessRiskCommand acceptCommand = new CustomerSuccessRiskCommand();
      acceptCommand.riskId = risk.Id;

      try {
        CustomerSuccessRiskCommandService.accept(acceptCommand);
        Assert.fail('Expected an accept without a reason to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('reason'));
      }

      acceptCommand.reason = 'Budget freeze is temporary and already accounted for.';
      Customer_Success_Risk__c accepted = CustomerSuccessRiskCommandService.accept(
        acceptCommand
      );
      Assert.areEqual('Accepted', accepted.Status__c);
    }
  }

  // Proves a real, honestly-scoped ceiling for raise() called in a loop
  // within one transaction - each call costs ~2 SOQL (health recompute's
  // engagement fetch + open-risk aggregate) + ~3 DML (risk insert, event
  // publish, conditional health update), so 15 stays safely under both the
  // 100-SOQL and 150-DML limits; no batch class in this codebase calls
  // raise() in a loop today, so this proves the command itself is
  // bulk-safe up to a real ceiling rather than claiming a false 200.
  @IsTest
  static void raises15RisksWithinGovernorLimits() {
    Customer_Success_Engagement__c engagement = createEngagement();
    User csUser = internalRiskUser();

    System.runAs(csUser) {
      Test.startTest();
      for (Integer index = 0; index < 15; index++) {
        CustomerSuccessRiskCommand command = new CustomerSuccessRiskCommand();
        command.engagementId = engagement.Id;
        command.riskType = 'Support Issue';
        command.severity = 'Low';
        command.description = 'Bulk risk ' + index;
        CustomerSuccessRiskCommandService.raise(command);
      }
      Test.stopTest();
    }

    Assert.areEqual(
      15,
      [
        SELECT COUNT()
        FROM Customer_Success_Risk__c
        WHERE Customer_Success_Engagement__c = :engagement.Id
      ]
    );
  }

  private static User internalRiskUser() {
    User csUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      csUser.Id,
      'PartnerSync_Channel_Manager'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Manage_Customer_Risk',
      true
    );
    return csUser;
  }

  private static Customer_Success_Engagement__c createEngagement() {
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Risk Test Customer'
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
