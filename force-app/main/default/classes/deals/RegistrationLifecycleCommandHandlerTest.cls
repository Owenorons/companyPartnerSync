@IsTest
private class RegistrationLifecycleCommandHandlerTest {
  @IsTest
  static void runsSubmitInformationResubmitAndApprovalLifecycle() {
    Account customer = new Account(Name = 'Lifecycle Customer');
    insert customer;
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = 'Draft',
      Conflict_Status__c = 'None',
      Customer_Account__c = customer.Id,
      Customer_Name__c = 'Lifecycle Customer',
      Estimated_Revenue__c = 10000,
      Lifecycle_Phase__c = 'Registration',
      Version_Number__c = 0
    );
    insert deal;
    execute(
      deal.Id,
      DealRegistrationLifecycleConstants.SUBMIT,
      0,
      '34b-submit',
      null
    );
    assertState(deal.Id, 'Submitted', 1);

    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Reject_Deal',
      true
    );
    execute(
      deal.Id,
      DealRegistrationLifecycleConstants.REQUEST_INFORMATION,
      1,
      '34b-request-info',
      'Please correct the customer details.'
    );
    assertState(deal.Id, 'Needs Information', 2);

    execute(
      deal.Id,
      DealRegistrationLifecycleConstants.RESUBMIT,
      2,
      '34b-resubmit',
      null
    );
    assertState(deal.Id, 'Submitted', 3);

    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Approve_Deal',
      true
    );
    // No manual ApprovalPlanService.generate() call here - RESUBMIT above
    // already auto-generated the current plan via routeSubmission(), which is
    // exactly the production code path this test is proving works end to end.
    Approval__c approval = [
      SELECT Id, Version_Number__c
      FROM Approval__c
      WHERE
        Object_Name__c = 'Deal_Registration__c'
        AND Target_Record_Id__c = :deal.Id
        AND Plan__r.Current__c = TRUE
      LIMIT 1
    ];
    ApprovalCommand approvalCommand = new ApprovalCommand();
    approvalCommand.approvalId = approval.Id;
    approvalCommand.expectedVersion = Integer.valueOf(
      approval.Version_Number__c
    );
    approvalCommand.decision = 'Approved';

    User channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );
    System.runAs(channelManager) {
      ApprovalCommandService.complete(approvalCommand);
    }

    // FINALISE_APPROVAL also requires the deal's blocking review checklist
    // to be complete (RegistrationLifecycleCommandHandler
    // .assertNoBlockingReviews) - a real gate now that
    // DealReviewPlanService.generate() actually runs on submission. This
    // deal's $10,000 value is below Commercial_Review's $50,000 minimum, so
    // only the Channel_Review step (routed to the same
    // PartnerSync_Channel_Manager permission set) needs completing.
    Deal_Review__c channelReview = [
      SELECT Id, Version_Number__c
      FROM Deal_Review__c
      WHERE
        Deal__c = :deal.Id
        AND Review_Key__c = 'Channel_Review'
        AND Plan__r.Current__c = TRUE
      LIMIT 1
    ];
    System.runAs(channelManager) {
      DealReviewCommandService.execute(
        new List<DealReviewCommand>{ reviewCommand(channelReview, 'Start') }
      );
    }
    channelReview = [
      SELECT Id, Version_Number__c
      FROM Deal_Review__c
      WHERE Id = :channelReview.Id
    ];
    DealReviewCommand completeReview = reviewCommand(channelReview, 'Complete');
    completeReview.outcome = 'Approved';
    System.runAs(channelManager) {
      DealReviewCommandService.execute(
        new List<DealReviewCommand>{ completeReview }
      );
    }

    DealCommand command = command(
      deal.Id,
      DealRegistrationLifecycleConstants.FINALISE_APPROVAL,
      3,
      '34b-approve',
      null
    );
    command.parameters.put('approvalNotes', 'Approved by test reviewer.');
    DealCommandService.execute(command);
    Deal_Registration__c approved = [
      SELECT
        Status__c,
        Version_Number__c,
        Protection_Start_Date__c,
        Protection_End_Date__c,
        Approval_Notes__c
      FROM Deal_Registration__c
      WHERE Id = :deal.Id
    ];
    Assert.areEqual('Approved', approved.Status__c);
    Assert.areEqual(4, approved.Version_Number__c);
    Assert.isNotNull(
      approved.Protection_Start_Date__c,
      'Final approval should activate protection via DealProtectionCommandService.'
    );
    Assert.areEqual(
      approved.Protection_Start_Date__c.addDays(30),
      approved.Protection_End_Date__c
    );
    Assert.areEqual('Approved by test reviewer.', approved.Approval_Notes__c);
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Deal_Protection_Grant__c
        WHERE Deal__c = :deal.Id AND Current__c = TRUE
      ]
    );
    Deal_Participant__c originatingParticipant = [
      SELECT Participant_Type__c, Participant_Role__c, Status__c
      FROM Deal_Participant__c
      WHERE Deal__c = :deal.Id AND Participant_Type__c = 'Originating Partner'
    ];
    Assert.areEqual('Deal Owner', originatingParticipant.Participant_Role__c);
    Assert.areEqual('Active', originatingParticipant.Status__c);
    DealLifecyclePermissionService.clearTestPermissions();
  }

  // A blocking Protection-Blocking condition should not fail final
  // approval itself - the deal still finalises to Approved with Conditions,
  // and DealCommandService.activateProtection() simply defers activation
  // (catching DealProtectionCommandService.ProtectionCommandException),
  // matching Sprint 37's "Pending Conditions" outcome rather than treating
  // it as a finalisation error.
  @IsTest
  static void deferProtectionActivationWhenABlockingConditionIsOpen() {
    Account customer = new Account(Name = 'Deferred Protection Customer');
    insert customer;
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = 'Under Review',
      Conflict_Status__c = 'None',
      Customer_Account__c = customer.Id,
      Customer_Name__c = 'Deferred Protection Customer',
      Estimated_Revenue__c = 10000,
      Version_Number__c = 0
    );
    insert deal;
    Approval_Plan__c plan = new Approval_Plan__c(
      Object_Name__c = 'Deal_Registration__c',
      Target_Record_Id__c = deal.Id,
      Current__c = true,
      Current_Plan_Key__c = 'Deal_Registration__c:' + deal.Id,
      Version_Number__c = 1,
      Target_Version__c = 0,
      Status__c = 'Approved with Conditions',
      Approval_Model__c = 'Sequential'
    );
    insert plan;
    insert new Approval__c(
      Object_Name__c = 'Deal_Registration__c',
      Target_Record_Id__c = deal.Id,
      Plan__c = plan.Id,
      Status__c = 'Completed',
      Authority_Snapshot__c = 'Test Reviewer',
      Sequence__c = 1,
      Version_Number__c = 0
    );
    insert new Approval_Condition__c(
      Object_Name__c = 'Deal_Registration__c',
      Target_Record_Id__c = deal.Id,
      Plan__c = plan.Id,
      Condition_Type__c = 'Protection Blocking',
      Description__c = 'Signed customer confirmation required',
      Status__c = 'Open'
    );

    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Approve_Deal',
      true
    );
    execute(
      deal.Id,
      DealRegistrationLifecycleConstants.FINALISE_APPROVAL,
      0,
      '37-deferred-protection',
      null
    );
    DealLifecyclePermissionService.clearTestPermissions();

    Deal_Registration__c finalised = [
      SELECT Status__c, Protection_Start_Date__c, Protection_End_Date__c
      FROM Deal_Registration__c
      WHERE Id = :deal.Id
    ];
    Assert.areEqual('Approved with Conditions', finalised.Status__c);
    Assert.isNull(finalised.Protection_Start_Date__c);
    Assert.isNull(finalised.Protection_End_Date__c);
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM Deal_Protection_Grant__c WHERE Deal__c = :deal.Id]
    );
  }

  @IsTest
  static void routesConflictAndSupportsRejectAndCancel() {
    Account customer = new Account(Name = 'Conflict Customer');
    insert customer;
    insert new Deal_Registration__c(
      Status__c = 'Submitted',
      Conflict_Status__c = 'None',
      Customer_Account__c = customer.Id,
      Customer_Name__c = 'Conflict Customer'
    );
    Deal_Registration__c conflictDeal = new Deal_Registration__c(
      Status__c = 'Draft',
      Conflict_Status__c = 'None',
      Customer_Account__c = customer.Id,
      Customer_Name__c = 'Conflict Customer',
      Estimated_Revenue__c = 10000,
      Version_Number__c = 0
    );
    Deal_Registration__c cancelDeal = new Deal_Registration__c(
      Status__c = 'Draft',
      Conflict_Status__c = 'None',
      Version_Number__c = 0
    );
    insert new List<Deal_Registration__c>{ conflictDeal, cancelDeal };

    execute(
      conflictDeal.Id,
      DealRegistrationLifecycleConstants.SUBMIT,
      0,
      '34b-conflict',
      null
    );
    assertState(conflictDeal.Id, 'Under Review', 1);
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Reject_Deal',
      true
    );
    execute(
      conflictDeal.Id,
      DealRegistrationLifecycleConstants.REJECT,
      1,
      '34b-reject',
      'Registration does not meet policy.'
    );
    assertState(conflictDeal.Id, 'Rejected', 2);

    execute(
      cancelDeal.Id,
      DealRegistrationLifecycleConstants.CANCEL,
      0,
      null,
      'Partner withdrew the registration.'
    );
    assertState(cancelDeal.Id, 'Cancelled', 1);
    DealLifecyclePermissionService.clearTestPermissions();
  }

  @IsTest
  static void preventsApprovalWithUnresolvedConflict() {
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = 'Under Review',
      Conflict_Status__c = 'Potential Conflict',
      Version_Number__c = 0
    );
    insert deal;
    insert new Deal_Conflict__c(
      Deal__c = deal.Id,
      Type__c = 'Existing Registration',
      Severity__c = 'Critical',
      Blocking__c = true,
      Current__c = true,
      Status__c = 'Open'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Approve_Deal',
      true
    );
    try {
      execute(
        deal.Id,
        DealRegistrationLifecycleConstants.FINALISE_APPROVAL,
        0,
        '34b-invalid-approval',
        null
      );
      Assert.fail('Expected unresolved conflict to block approval.');
    } catch (DealLifecycleException ex) {
      Assert.isTrue(ex.getMessage().contains('blocking conflict'));
    }
    DealLifecyclePermissionService.clearTestPermissions();
  }

  @IsTest
  static void persistsBlockingFindingsWithoutThrowing() {
    Account customer = new Account(Name = 'Finding Customer');
    insert customer;
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = 'Draft',
      Customer_Account__c = customer.Id,
      Version_Number__c = 0
    );
    insert deal;

    DealCommandResult result = execute(
      deal.Id,
      DealRegistrationLifecycleConstants.SUBMIT,
      0,
      '35a-blocking-findings',
      null
    );
    Assert.isTrue(result.completed);
    Assert.areEqual('Needs Information', result.newState);
    List<Deal_Validation_Finding__c> findings = [
      SELECT Rule_Key__c, Blocking__c, Partner_Message__c, Status__c
      FROM Deal_Validation_Finding__c
      WHERE Deal__c = :deal.Id AND Status__c = 'Current'
    ];
    Assert.isTrue(findings.size() >= 1);
    Assert.isTrue(findings[0].Blocking__c);
    Assert.isNotNull(findings[0].Partner_Message__c);
  }

  @IsTest
  static void classifiesAttributionTypeUsingLinkedOpportunityAgeOnSubmit() {
    Account customer = new Account(Name = 'Attribution Customer');
    insert customer;
    Opportunity opportunity = new Opportunity(
      Name = 'Attribution Opportunity',
      AccountId = customer.Id,
      StageName = 'Qualification',
      CloseDate = Date.today().addDays(30),
      Amount = 50000
    );
    insert opportunity;
    Test.setCreatedDate(opportunity.Id, Datetime.now().addDays(-30));

    Deal_Registration__c coSellDeal = new Deal_Registration__c(
      Status__c = 'Draft',
      Conflict_Status__c = 'None',
      Customer_Account__c = customer.Id,
      Customer_Name__c = 'Attribution Customer',
      Estimated_Revenue__c = 10000,
      Opportunity__c = opportunity.Id,
      Version_Number__c = 0
    );
    Deal_Registration__c partnerSourcedDeal = new Deal_Registration__c(
      Status__c = 'Draft',
      Conflict_Status__c = 'None',
      Customer_Account__c = customer.Id,
      Customer_Name__c = 'Attribution Customer',
      Estimated_Revenue__c = 10000,
      Version_Number__c = 0
    );
    insert new List<Deal_Registration__c>{ coSellDeal, partnerSourcedDeal };

    execute(
      coSellDeal.Id,
      DealRegistrationLifecycleConstants.SUBMIT,
      0,
      '34b-attribution-cosell',
      null
    );
    execute(
      partnerSourcedDeal.Id,
      DealRegistrationLifecycleConstants.SUBMIT,
      0,
      '34b-attribution-sourced',
      null
    );

    Map<Id, Deal_Registration__c> stored = new Map<Id, Deal_Registration__c>(
      [
        SELECT Attribution_Type__c
        FROM Deal_Registration__c
        WHERE Id IN (:coSellDeal.Id, :partnerSourcedDeal.Id)
      ]
    );
    Assert.areEqual(
      DealAttributionEngine.CO_SELL,
      stored.get(coSellDeal.Id).Attribution_Type__c
    );
    Assert.areEqual(
      DealAttributionEngine.PARTNER_SOURCED,
      stored.get(partnerSourcedDeal.Id).Attribution_Type__c
    );
  }

  private static DealCommandResult execute(
    Id dealId,
    String action,
    Integer version,
    String key,
    String reason
  ) {
    return DealRegistrationCommandFacade.execute(
      dealId,
      action,
      version,
      key,
      reason,
      null
    );
  }

  private static DealCommand command(
    Id dealId,
    String action,
    Integer version,
    String key,
    String reason
  ) {
    DealCommand command = new DealCommand();
    command.dealId = dealId;
    command.aggregateId = dealId;
    command.aggregateType = DealLifecycleConstants.AGGREGATE_REGISTRATION;
    command.lifecycleDimension = DealLifecycleConstants.DIMENSION_REGISTRATION;
    command.commandType = action;
    command.commandKey = key;
    command.expectedVersion = version;
    command.reason = reason;
    command.source = 'Apex Test';
    return command;
  }

  private static DealReviewCommand reviewCommand(
    Deal_Review__c review,
    String action
  ) {
    DealReviewCommand result = new DealReviewCommand();
    result.reviewId = review.Id;
    result.action = action;
    result.expectedVersion = Integer.valueOf(review.Version_Number__c);
    return result;
  }

  private static void assertState(Id dealId, String status, Integer version) {
    Deal_Registration__c stored = [
      SELECT Status__c, Version_Number__c
      FROM Deal_Registration__c
      WHERE Id = :dealId
    ];
    Assert.areEqual(status, stored.Status__c);
    Assert.areEqual(version, stored.Version_Number__c);
  }
}
