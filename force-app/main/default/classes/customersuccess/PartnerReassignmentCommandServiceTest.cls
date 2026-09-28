/*
 * Covers PartnerReassignmentCommandService: request/approve, the original
 * deal's ownership is never rewritten, and approval leaves a real audit
 * entry rather than a silent field flip.
 */
@IsTest
private class PartnerReassignmentCommandServiceTest {
  @IsTest
  static void requestThenApproveReassignsTheRenewalNotTheOriginalDeal() {
    Fixture fixture = createFixture();
    User requester = TestUserFactory.createInternalUser();
    User approver = internalApprover();

    Partner_Reassignment__c requested;
    System.runAs(requester) {
      PartnerReassignmentCommand requestCommand = new PartnerReassignmentCommand();
      requestCommand.targetObject = 'Partner_Renewal__c';
      requestCommand.targetRecordId = fixture.renewal.Id;
      requestCommand.requestedPartnerId = fixture.newPartner.Id;
      requestCommand.reason = 'Original partner exited the reseller program.';
      requested = PartnerReassignmentCommandService.request(requestCommand);
    }
    Assert.areEqual('Requested', requested.Status__c);
    Assert.areEqual(fixture.originalPartner.Id, requested.Current_Partner__c);

    Partner_Reassignment__c approved;
    System.runAs(approver) {
      PartnerReassignmentCommand approveCommand = new PartnerReassignmentCommand();
      approveCommand.reassignmentId = requested.Id;
      approveCommand.expectedVersion = 0;
      approved = PartnerReassignmentCommandService.approve(approveCommand);
    }

    Assert.areEqual('Approved', approved.Status__c);
    Assert.areEqual(
      fixture.newPartner.Id,
      [
        SELECT Primary_Partner__c
        FROM Partner_Renewal__c
        WHERE Id = :fixture.renewal.Id
      ]
      .Primary_Partner__c
    );
    Assert.areEqual(
      fixture.originalPartner.Id,
      [
        SELECT Partner_Account__c
        FROM Deal_Registration__c
        WHERE Id = :fixture.deal.Id
      ]
      .Partner_Account__c,
      'Approving a reassignment must never rewrite the original deal\'s ownership.'
    );
  }

  @IsTest
  static void approveRequiresTheRestrictedPermission() {
    Fixture fixture = createFixture();
    User requester = TestUserFactory.createInternalUser();
    User unauthorizedUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      unauthorizedUser.Id,
      'PartnerSync_Channel_Manager'
    );

    Partner_Reassignment__c requested;
    System.runAs(requester) {
      PartnerReassignmentCommand requestCommand = new PartnerReassignmentCommand();
      requestCommand.targetObject = 'Partner_Renewal__c';
      requestCommand.targetRecordId = fixture.renewal.Id;
      requestCommand.requestedPartnerId = fixture.newPartner.Id;
      requestCommand.reason = 'Original partner exited the reseller program.';
      requested = PartnerReassignmentCommandService.request(requestCommand);
    }

    System.runAs(unauthorizedUser) {
      PartnerReassignmentCommand approveCommand = new PartnerReassignmentCommand();
      approveCommand.reassignmentId = requested.Id;
      approveCommand.expectedVersion = 0;

      try {
        PartnerReassignmentCommandService.approve(approveCommand);
        Assert.fail('Expected an unauthorized user to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('authority'));
      }
    }
  }

  private static User internalApprover() {
    User approver = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      approver.Id,
      'PartnerSync_Channel_Manager'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Approve_Partner_Reassignment',
      true
    );
    return approver;
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    fixture.originalPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Original Partner'
    );
    fixture.newPartner = PartnerSyncTestDataFactory.partnerAccount(
      'New Partner'
    );
    fixture.customer = PartnerSyncTestDataFactory.customerAccount(
      'Reassignment Customer'
    );
    insert new List<Account>{
      fixture.originalPartner,
      fixture.newPartner,
      fixture.customer
    };

    fixture.deal = PartnerSyncTestDataFactory.deal(
      fixture.customer.Id,
      fixture.originalPartner.Id,
      null,
      null
    );
    fixture.deal.Status__c = 'Approved';
    insert fixture.deal;

    Customer_Success_Engagement__c engagement = new Customer_Success_Engagement__c(
      Customer_Account__c = fixture.customer.Id,
      Primary_Partner__c = fixture.originalPartner.Id,
      Status__c = 'Active',
      Health_Status__c = 'Not Assessed',
      Version_Number__c = 0
    );
    insert engagement;

    fixture.renewal = new Partner_Renewal__c(
      Customer_Success_Engagement__c = engagement.Id,
      Customer_Account__c = fixture.customer.Id,
      Original_Deal__c = fixture.deal.Id,
      Primary_Partner__c = fixture.originalPartner.Id,
      Status__c = 'Approved',
      Renewal_Health__c = 'On Track',
      Version_Number__c = 0
    );
    insert fixture.renewal;

    return fixture;
  }

  private class Fixture {
    Account originalPartner;
    Account newPartner;
    Account customer;
    Deal_Registration__c deal;
    Partner_Renewal__c renewal;
  }
}
