@IsTest
private class DealConflictCommandServiceTest {
  @IsTest
  static void executesInvestigationAndResolutionLifecycleIdempotently() {
    Deal_Conflict__c conflict = createConflict('High', 'Open');
    authorize();
    DealConflictCommand command = build(
      conflict.Id,
      'Assign Conflict',
      0,
      'assign'
    );
    command.assigneeId = UserInfo.getUserId();
    execute(command, 'Assigned', 1);
    execute(
      build(conflict.Id, 'Start Investigation', 1, 'start'),
      'Investigating',
      2
    );
    execute(
      build(conflict.Id, 'Request Evidence', 2, 'request'),
      'Evidence Requested',
      3
    );
    command = build(conflict.Id, 'Submit Evidence', 3, 'evidence');
    command.reviewedEvidence = 'Customer ownership documents reviewed.';
    execute(command, 'Investigating', 4);
    execute(
      build(conflict.Id, 'Confirm Conflict', 4, 'confirm'),
      'Confirmed',
      5
    );
    command = build(conflict.Id, 'Resolve Conflict', 5, 'resolve');
    command.reason = 'Ownership was agreed by both parties.';
    DealConflictCommandResult resolved = execute(command, 'Resolved', 6);
    DealConflictCommandResult duplicate = DealConflictCommandService.execute(
      command
    );
    Assert.isTrue(duplicate.duplicateCommand);
    Assert.areEqual(resolved.eventId, duplicate.eventId);
    DealLifecyclePermissionService.clearTestPermissions();
  }

  @IsTest
  static void enforcesCriticalWaiverAuthorityAndAudit() {
    Deal_Conflict__c conflict = createConflict('Critical', 'Confirmed');
    authorize();
    DealConflictCommand command = build(
      conflict.Id,
      'Waive Conflict',
      0,
      'waive'
    );
    command.reason = 'Executive exception';
    command.reviewedEvidence = 'Signed exception approval';
    command.waiverConditions = 'Review again in 30 days';
    command.waiverExpiresOn = System.now().addDays(30);
    try {
      DealConflictCommandService.execute(command);
      Assert.fail('Expected critical waiver permission failure.');
    } catch (DealLifecycleException ex) {
      Assert.isTrue(ex.getMessage().contains('Critical conflict waiver'));
    }
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Waive_Critical_Conflict',
      true
    );
    execute(command, 'Waived', 1);
    Deal_Conflict__c stored = [
      SELECT
        Waived_By__c,
        Waived_On__c,
        Waiver_Expires_On__c,
        Waiver_Conditions__c
      FROM Deal_Conflict__c
      WHERE Id = :conflict.Id
    ];
    Assert.isNotNull(stored.Waived_By__c);
    Assert.isNotNull(stored.Waived_On__c);
    Assert.isNotNull(stored.Waiver_Expires_On__c);
    Assert.isNotNull(stored.Waiver_Conditions__c);
    DealLifecyclePermissionService.clearTestPermissions();
  }

  @IsTest
  static void supportsEscalationFalsePositiveReanalysisAndGuards() {
    Deal_Conflict__c escalated = createConflict('High', 'Open');
    Deal_Conflict__c reanalysis = createConflict('High', 'Open');
    authorize();
    execute(
      build(escalated.Id, 'Escalate Conflict', 0, 'escalate'),
      'Escalated',
      1
    );
    DealConflictCommand falsePositive = build(
      escalated.Id,
      'Mark False Positive',
      1,
      'false-positive'
    );
    falsePositive.reason = 'Candidate was a different legal entity.';
    execute(falsePositive, 'False Positive', 2);
    execute(build(reanalysis.Id, 'Reanalyse Deal', 0, 'reanalyse'), 'Open', 1);
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Deal_Conflict_Analysis_Run__c
        WHERE Deal__c = :reanalysis.Deal__c AND Current__c = TRUE
      ]
    );

    try {
      DealConflictCommandService.execute(
        build(escalated.Id, 'Start Investigation', 1, 'stale')
      );
      Assert.fail('Expected stale version failure.');
    } catch (DealLifecycleException ex) {
      Assert.isTrue(ex.getMessage().contains('changed'));
    }
    DealLifecyclePermissionService.clearTestPermissions();
  }

  @IsTest
  static void coversControllerAndCommandContract() {
    DealConflictCommand invalid = new DealConflictCommand();
    try {
      invalid.validate();
      Assert.fail('Expected command validation failure.');
    } catch (DealLifecycleException ex) {
      Assert.isTrue(ex.getMessage().contains('required'));
    }
    invalid.conflictId = UserInfo.getUserId();
    invalid.action = 'Start Investigation';
    try {
      invalid.validate();
      Assert.fail('Expected command key validation failure.');
    } catch (DealLifecycleException ex) {
      Assert.isTrue(ex.getMessage().contains('command key'));
    }

    Deal_Conflict__c conflict = createConflict('High', 'Open');
    authorize();
    DealConflictCommand command = build(
      conflict.Id,
      'Start Investigation',
      0,
      'controller'
    );
    DealConflictCommandResult result = DealConflictCommandController.executeCommand(
      JSON.serialize(command)
    );
    Assert.isTrue(result.completed);
    Assert.areEqual('Investigating', result.newStatus);
    DealLifecyclePermissionService.clearTestPermissions();
  }

  @IsTest
  static void controllerTranslatesLifecycleFailures() {
    try {
      DealConflictCommandController.executeCommand('{}');
      Assert.fail('Expected controller failure.');
    } catch (AuraHandledException expected) {
      Assert.isNotNull(expected.getMessage());
    }
  }

  private static Deal_Conflict__c createConflict(
    String severity,
    String status
  ) {
    Account customer = new Account(
      Name = 'Command Customer ' + severity + status
    );
    insert customer;
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = 'Under Review',
      Customer_Account__c = customer.Id,
      Customer_Name__c = customer.Name,
      Customer_Identity_Fingerprint__c = 'fp-' + severity + status
    );
    insert deal;
    Deal_Conflict__c conflict = new Deal_Conflict__c(
      Deal__c = deal.Id,
      Type__c = 'Existing Registration',
      Severity__c = severity,
      Blocking__c = true,
      Current__c = true,
      Status__c = status,
      Version_Number__c = 0
    );
    insert conflict;
    return conflict;
  }

  private static void authorize() {
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Resolve_Deal_Conflict',
      true
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Waive_Critical_Conflict',
      false
    );
  }

  private static DealConflictCommand build(
    Id conflictId,
    String action,
    Integer version,
    String key
  ) {
    DealConflictCommand command = new DealConflictCommand();
    command.conflictId = conflictId;
    command.action = action;
    command.expectedVersion = version;
    command.commandKey = '35b-' + key;
    return command;
  }

  private static DealConflictCommandResult execute(
    DealConflictCommand command,
    String status,
    Integer version
  ) {
    DealConflictCommandResult result = DealConflictCommandService.execute(
      command
    );
    Assert.isTrue(result.completed);
    Assert.areEqual(status, result.newStatus);
    Assert.areEqual(version, result.resultingVersion);
    return result;
  }
}
