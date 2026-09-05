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
    DealApprovalPlanService.generate(new Set<Id>{ deal.Id });
    Deal_Approval__c approval = [
      SELECT Id, Version_Number__c
      FROM Deal_Approval__c
      WHERE Deal__c = :deal.Id
      LIMIT 1
    ];
    DealApprovalCommand approvalCommand = new DealApprovalCommand();
    approvalCommand.approvalId = approval.Id;
    approvalCommand.expectedVersion = Integer.valueOf(
      approval.Version_Number__c
    );
    approvalCommand.decision = 'Approved';
    DealApprovalCommandService.complete(approvalCommand);
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
    Assert.isNull(approved.Protection_Start_Date__c);
    Assert.isNull(approved.Protection_End_Date__c);
    Assert.areEqual('Approved by test reviewer.', approved.Approval_Notes__c);
    DealLifecyclePermissionService.clearTestPermissions();
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
