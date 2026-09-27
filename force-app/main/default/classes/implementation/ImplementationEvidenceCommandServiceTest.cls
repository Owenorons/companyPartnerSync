/*
 * Covers ImplementationEvidenceCommandService: submit, accept
 * auto-completes an In Progress gated milestone, and reject does not.
 */
@IsTest
private class ImplementationEvidenceCommandServiceTest {
  @IsTest
  static void submitCreatesAnEvidenceRecord() {
    Implementation_Milestone__c milestone = insertMilestone('In Progress');

    Test.startTest();
    Implementation_Evidence__c evidence = ImplementationEvidenceCommandService.submit(
      submitCommand(milestone.Implementation__c, milestone.Id)
    );
    Test.stopTest();

    Assert.isNotNull(evidence.Id);
    Assert.areEqual('Submitted', evidence.Status__c);
  }

  @IsTest
  static void acceptAutoCompletesAnInProgressGatedMilestone() {
    Implementation_Milestone__c milestone = insertMilestone('In Progress');
    Implementation_Evidence__c evidence = ImplementationEvidenceCommandService.submit(
      submitCommand(milestone.Implementation__c, milestone.Id)
    );

    User internalUser = internalUser();
    Test.startTest();
    System.runAs(internalUser) {
      ImplementationEvidenceCommandService.review(
        reviewCommand(evidence.Id, 'Accepted')
      );
    }
    Test.stopTest();

    Assert.areEqual(
      'Completed',
      [
        SELECT Status__c
        FROM Implementation_Milestone__c
        WHERE Id = :milestone.Id
      ]
      .Status__c
    );
  }

  @IsTest
  static void rejectDoesNotCompleteTheMilestone() {
    Implementation_Milestone__c milestone = insertMilestone('In Progress');
    Implementation_Evidence__c evidence = ImplementationEvidenceCommandService.submit(
      submitCommand(milestone.Implementation__c, milestone.Id)
    );

    User internalUser = internalUser();
    Test.startTest();
    System.runAs(internalUser) {
      ImplementationEvidenceCommandService.review(
        reviewCommand(evidence.Id, 'Rejected')
      );
    }
    Test.stopTest();

    Assert.areEqual(
      'In Progress',
      [
        SELECT Status__c
        FROM Implementation_Milestone__c
        WHERE Id = :milestone.Id
      ]
      .Status__c
    );
    Assert.areEqual(
      'Rejected',
      [SELECT Status__c FROM Implementation_Evidence__c WHERE Id = :evidence.Id]
      .Status__c
    );
  }

  // Concurrency pair (doc §40.53): review() has no Version_Number__c field
  // to compare (Adaptation note - Implementation_Evidence__c isn't part of
  // the optimistic-concurrency contract other aggregates use), so a second
  // reviewer's attempt is instead rejected by the FOR UPDATE row lock plus
  // the Status__c guard - once one reviewer's Accept commits, the record is
  // no longer Submitted/Under Review for the second reviewer's Reject.
  @IsTest
  static void secondConcurrentReviewIsRejectedByTheStatusGuard() {
    Implementation_Milestone__c milestone = insertMilestone('In Progress');
    Implementation_Evidence__c evidence = ImplementationEvidenceCommandService.submit(
      submitCommand(milestone.Implementation__c, milestone.Id)
    );

    User internalUser = internalUser();
    System.runAs(internalUser) {
      ImplementationEvidenceCommandService.review(
        reviewCommand(evidence.Id, 'Accepted')
      );

      try {
        ImplementationEvidenceCommandService.review(
          reviewCommand(evidence.Id, 'Rejected')
        );
        Assert.fail('Expected the second concurrent review to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('reviewed'));
      }
    }

    Assert.areEqual(
      'Accepted',
      [SELECT Status__c FROM Implementation_Evidence__c WHERE Id = :evidence.Id]
      .Status__c
    );
  }

  private static Implementation_Milestone__c insertMilestone(String status) {
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Evidence Customer'
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
      Status__c = 'Planned',
      Health__c = 'Healthy',
      Version_Number__c = 0
    );
    insert implementation;
    Implementation_Milestone__c milestone = new Implementation_Milestone__c(
      Implementation__c = implementation.Id,
      Milestone_Type__c = 'Data Migration',
      Name__c = 'Data Migration',
      Status__c = status,
      Required__c = false,
      Evidence_Required__c = true,
      Version_Number__c = 0
    );
    insert milestone;
    return milestone;
  }

  private static ImplementationEvidenceCommand submitCommand(
    Id implementationId,
    Id milestoneId
  ) {
    ImplementationEvidenceCommand command = new ImplementationEvidenceCommand();
    command.implementationId = implementationId;
    command.milestoneId = milestoneId;
    command.evidenceType = 'Data Migration Report';
    command.contentDocumentId = '069000000000000AAA';
    command.description = 'Migration completed with zero errors.';
    command.partnerVisible = true;
    return command;
  }

  private static ImplementationEvidenceCommand reviewCommand(
    Id evidenceId,
    String outcome
  ) {
    ImplementationEvidenceCommand command = new ImplementationEvidenceCommand();
    command.evidenceId = evidenceId;
    command.outcome = outcome;
    return command;
  }

  private static User internalUser() {
    User channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Review_Implementation_Evidence',
      true
    );
    return channelManager;
  }
}
