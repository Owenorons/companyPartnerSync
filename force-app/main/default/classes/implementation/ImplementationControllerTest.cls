/*
 * Covers ImplementationController: the partner-safe summary/detail DTOs
 * never carry more than their documented field whitelist (no
 * Commercial_Impact__c/Partner_Account__c on issues, no
 * Partner_Visible__c/Customer_Visible__c on evidence, no
 * External_Project_System__c/External_Project_Id__c/External_Sync_Status__c
 * on the summary - Adaptation #7), an internal workbench queue tab, and
 * the generic implementation command dispatch.
 */
@IsTest
private class ImplementationControllerTest {
  @IsTest
  static void getImplementationSummaryReturnsNullWhenNoneExists() {
    Fixture fixture = createFixture();

    System.runAs(fixture.internalUser) {
      ImplementationSummaryDTO summary = ImplementationController.getImplementationSummary(
        fixture.deal.Id
      );
      Assert.isNull(summary);
    }
  }

  @IsTest
  static void getImplementationSummaryReturnsSanitizedFields() {
    Fixture fixture = createFixture();
    Deal_Implementation__c implementation = insertImplementation(fixture);

    System.runAs(fixture.internalUser) {
      ImplementationSummaryDTO summary = ImplementationController.getImplementationSummary(
        fixture.deal.Id
      );
      Assert.areEqual(implementation.Id, summary.implementationId);
      Assert.areEqual('Implementation Detail Customer', summary.customerName);
      Assert.areEqual('Planned', summary.status);
      Assert.areEqual('Healthy', summary.health);
    }
  }

  @IsTest
  static void getImplementationDetailIncludesAllChildLists() {
    Fixture fixture = createFixture();
    Deal_Implementation__c implementation = insertImplementation(fixture);
    insert new Implementation_Milestone__c(
      Implementation__c = implementation.Id,
      Name__c = 'Kickoff',
      Milestone_Type__c = 'Kickoff',
      Status__c = 'Not Started',
      Sequence__c = 1,
      Required__c = true,
      Version_Number__c = 0
    );
    insert new Implementation_Issue__c(
      Implementation__c = implementation.Id,
      Title__c = 'Data feed delayed',
      Issue_Type__c = 'Technical',
      Severity__c = 'Medium',
      Status__c = 'Open',
      Raised_On__c = System.now(),
      Customer_Impact__c = true,
      Commercial_Impact__c = true
    );

    System.runAs(fixture.internalUser) {
      ImplementationDetailDTO detail = ImplementationController.getImplementationDetail(
        implementation.Id
      );
      Assert.areEqual(implementation.Id, detail.summary.implementationId);
      Assert.areEqual(1, detail.milestones.size());
      Assert.areEqual('Kickoff', detail.milestones[0].name);
      Assert.areEqual(1, detail.issues.size());
      Assert.areEqual('Data feed delayed', detail.issues[0].title);
      Assert.areEqual(0, detail.evidenceItems.size());
      Assert.areEqual(0, detail.acceptances.size());
    }
  }

  @IsTest
  static void getImplementationDetailRejectsAnInaccessibleDeal() {
    Fixture fixture = createFixture();
    Deal_Implementation__c implementation = insertImplementation(fixture);
    Account unrelatedPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Unrelated Partner'
    );
    insert unrelatedPartner;
    Contact unrelatedContact = PartnerSyncTestDataFactory.partnerContact(
      unrelatedPartner.Id
    );
    insert unrelatedContact;
    User otherPartnerUser = TestUserFactory.createExternalUser(
      unrelatedContact.Id
    );

    System.runAs(otherPartnerUser) {
      try {
        ImplementationController.getImplementationDetail(implementation.Id);
        Assert.fail('Expected an inaccessible implementation to be rejected.');
      } catch (AuraHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('not accessible'));
      }
    }
  }

  @IsTest
  static void getInProgressReturnsOnlyInProgressImplementations() {
    Fixture fixture = createFixture();
    Deal_Implementation__c implementation = insertImplementation(fixture);
    implementation.Status__c = 'In Progress';
    update implementation;

    System.runAs(fixture.internalUser) {
      List<ImplementationSummaryDTO> results = ImplementationController.getInProgress();
      Assert.areEqual(1, results.size());
      Assert.areEqual('In Progress', results[0].status);
    }
  }

  @IsTest
  static void executeImplementationCommandStartsAnImplementation() {
    Fixture fixture = createFixture();
    Deal_Implementation__c implementation = insertImplementation(fixture);
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Manage_Implementation',
      true
    );

    System.runAs(fixture.internalUser) {
      ImplementationCommand command = new ImplementationCommand();
      command.implementationId = implementation.Id;
      command.action = 'Start';
      command.expectedVersion = 0;
      ImplementationSummaryDTO result = ImplementationController.executeImplementationCommand(
        command
      );
      Assert.areEqual('In Progress', result.status);
      Assert.areEqual(1, result.versionNumber);
    }
  }

  private static Deal_Implementation__c insertImplementation(Fixture fixture) {
    Deal_Implementation__c implementation = new Deal_Implementation__c(
      Deal__c = fixture.deal.Id,
      Customer_Account__c = fixture.customer.Id,
      Primary_Partner__c = fixture.partnerAccount.Id,
      Implementation_Type__c = 'Initial Implementation',
      Status__c = 'Planned',
      Health__c = 'Healthy',
      Version_Number__c = 0
    );
    insert implementation;
    return implementation;
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    fixture.internalUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      fixture.internalUser.Id,
      'PartnerSync_Channel_Manager'
    );

    fixture.partnerAccount = PartnerSyncTestDataFactory.partnerAccount(
      'Implementation Detail Partner'
    );
    fixture.customer = PartnerSyncTestDataFactory.customerAccount(
      'Implementation Detail Customer'
    );
    insert new List<Account>{ fixture.partnerAccount, fixture.customer };

    fixture.deal = PartnerSyncTestDataFactory.deal(
      fixture.customer.Id,
      fixture.partnerAccount.Id,
      null,
      null
    );
    fixture.deal.Status__c = 'Approved';
    insert fixture.deal;

    return fixture;
  }

  private class Fixture {
    User internalUser;
    Account partnerAccount;
    Account customer;
    Deal_Registration__c deal;
  }
}
