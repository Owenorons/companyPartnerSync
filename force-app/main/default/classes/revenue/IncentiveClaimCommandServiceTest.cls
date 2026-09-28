/*
 * Covers IncentiveClaimCommandService: submit/approve/reject, and the
 * approved amount stays separate from the calculated amount (doc §41.32).
 */
@IsTest
private class IncentiveClaimCommandServiceTest {
  @IsTest
  static void submitCreatesAClaimAndMovesTheIncentiveUnderReview() {
    Fixture fixture = createFixture('Claim Required');

    IncentiveClaimCommand command = new IncentiveClaimCommand();
    command.incentiveId = fixture.incentive.Id;
    command.claimedAmount = 4000;
    command.claimReason = 'Q3 co-sell commission.';

    Partner_Incentive_Claim__c claim = IncentiveClaimCommandService.submit(
      command
    );

    Assert.isNotNull(claim.Id);
    Assert.areEqual('Submitted', claim.Status__c);
    Assert.areEqual(
      'Under Review',
      [
        SELECT Status__c
        FROM Partner_Incentive__c
        WHERE Id = :fixture.incentive.Id
      ]
      .Status__c
    );
  }

  @IsTest
  static void approveSetsTheApprovedAmountSeparateFromCalculated() {
    Fixture fixture = createFixture('Claim Required');
    fixture.incentive.Calculated_Amount__c = 5000;
    update fixture.incentive;

    IncentiveClaimCommand submitCommand = new IncentiveClaimCommand();
    submitCommand.incentiveId = fixture.incentive.Id;
    submitCommand.claimedAmount = 4500;
    Partner_Incentive_Claim__c claim = IncentiveClaimCommandService.submit(
      submitCommand
    );

    User approver = internalApprover();
    System.runAs(approver) {
      IncentiveClaimCommand approveCommand = new IncentiveClaimCommand();
      approveCommand.claimId = claim.Id;
      approveCommand.expectedVersion = 0;
      IncentiveClaimCommandService.approve(approveCommand);
    }

    Partner_Incentive__c refreshed = [
      SELECT Status__c, Calculated_Amount__c, Approved_Amount__c
      FROM Partner_Incentive__c
      WHERE Id = :fixture.incentive.Id
    ];
    Assert.areEqual('Approved', refreshed.Status__c);
    Assert.areEqual(5000, refreshed.Calculated_Amount__c);
    Assert.areEqual(4500, refreshed.Approved_Amount__c);
  }

  @IsTest
  static void approvingAtAnOverriddenAmountRequiresTheOverridePermission() {
    Fixture fixture = createFixture('Claim Required');
    fixture.incentive.Calculated_Amount__c = 5000;
    update fixture.incentive;

    IncentiveClaimCommand submitCommand = new IncentiveClaimCommand();
    submitCommand.incentiveId = fixture.incentive.Id;
    submitCommand.claimedAmount = 4500;
    Partner_Incentive_Claim__c claim = IncentiveClaimCommandService.submit(
      submitCommand
    );

    User approverWithoutOverride = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      approverWithoutOverride.Id,
      'PartnerSync_Channel_Manager'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Approve_Partner_Incentive',
      true
    );

    System.runAs(approverWithoutOverride) {
      IncentiveClaimCommand approveCommand = new IncentiveClaimCommand();
      approveCommand.claimId = claim.Id;
      approveCommand.expectedVersion = 0;
      try {
        IncentiveClaimCommandService.approve(approveCommand);
        Assert.fail(
          'Expected approval at an overridden amount to require PartnerSync_Approve_Incentive_Override.'
        );
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('overridden amount'));
      }
    }
  }

  @IsTest
  static void rejectRequiresAReason() {
    Fixture fixture = createFixture('Claim Required');
    IncentiveClaimCommand submitCommand = new IncentiveClaimCommand();
    submitCommand.incentiveId = fixture.incentive.Id;
    Partner_Incentive_Claim__c claim = IncentiveClaimCommandService.submit(
      submitCommand
    );

    User approver = internalApprover();
    System.runAs(approver) {
      IncentiveClaimCommand rejectCommand = new IncentiveClaimCommand();
      rejectCommand.claimId = claim.Id;
      rejectCommand.expectedVersion = 0;
      try {
        IncentiveClaimCommandService.reject(rejectCommand);
        Assert.fail('Expected a reject without a reason to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('reason'));
      }

      rejectCommand.reason = 'Duplicate claim already paid.';
      IncentiveClaimCommandService.reject(rejectCommand);
    }

    Assert.areEqual(
      'Rejected',
      [SELECT Status__c FROM Partner_Incentive_Claim__c WHERE Id = :claim.Id]
      .Status__c
    );
  }

  private static User internalApprover() {
    User approver = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      approver.Id,
      'PartnerSync_Channel_Manager'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Approve_Partner_Incentive',
      true
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Approve_Incentive_Override',
      true
    );
    return approver;
  }

  private static Fixture createFixture(String incentiveStatus) {
    Fixture fixture = new Fixture();
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Claim Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Claim Customer'
    );
    insert new List<Account>{ partner, customer };

    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      partner.Id,
      null,
      null
    );
    deal.Status__c = 'Approved';
    insert deal;

    fixture.incentive = new Partner_Incentive__c(
      Deal__c = deal.Id,
      Partner_Account__c = partner.Id,
      Incentive_Type__c = 'Commission',
      Status__c = incentiveStatus,
      Eligible_Base_Amount__c = 50000,
      Version_Number__c = 0
    );
    insert fixture.incentive;

    return fixture;
  }

  private class Fixture {
    Partner_Incentive__c incentive;
  }
}
