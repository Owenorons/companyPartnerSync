@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class DealConflictCommandService {
  private static final String RESOLVE_PERMISSION = 'PartnerSync_Resolve_Deal_Conflict';
  private static final String CRITICAL_WAIVER_PERMISSION = 'PartnerSync_Waive_Critical_Conflict';

  public static DealConflictCommandResult execute(DealConflictCommand command) {
    command.validate();
    assertAuthority();
    DealConflictCommandResult prior = completedResult(command.commandKey);
    if (prior != null)
      return prior;

    Deal_Conflict__c conflict = [
      SELECT
        Id,
        Deal__c,
        Status__c,
        Severity__c,
        Version_Number__c,
        Blocking__c,
        Current__c,
        Analysis_Run__c
      FROM Deal_Conflict__c
      WHERE Id = :command.conflictId
      FOR UPDATE
    ];
    Integer version = conflict.Version_Number__c == null
      ? 0
      : Integer.valueOf(conflict.Version_Number__c);
    if (command.expectedVersion == null || command.expectedVersion != version) {
      throw new DealLifecycleException(
        'The conflict changed. Refresh before retrying.'
      );
    }
    String previous = conflict.Status__c;
    Boolean appliedBeforeReservation = command.action != 'Reanalyse Deal';
    if (appliedBeforeReservation)
      apply(command, conflict);

    Deal_Command_Execution__c execution = reserve(command, conflict.Deal__c);
    if (execution == null) {
      prior = completedResult(command.commandKey);
      if (prior != null)
        return prior;
      throw new DealLifecycleException(
        'The same conflict command is already processing.'
      );
    }

    if (!appliedBeforeReservation)
      apply(command, conflict);
    conflict.Version_Number__c = version + 1;
    Database.update(conflict, AccessLevel.SYSTEM_MODE);

    Id eventId = createEvent(command, conflict, previous);
    DealConflictCommandResult result = new DealConflictCommandResult();
    result.completed = true;
    result.duplicateCommand = false;
    result.conflictId = conflict.Id;
    result.previousStatus = previous;
    result.newStatus = conflict.Status__c;
    result.resultingVersion = version + 1;
    result.eventId = eventId;
    execution.Status__c = 'Completed';
    execution.Completed_On__c = System.now();
    execution.Resulting_Version__c = result.resultingVersion;
    execution.Result_Payload__c = JSON.serialize(result);
    Database.update(execution, AccessLevel.SYSTEM_MODE);
    return result;
  }

  private static void apply(
    DealConflictCommand command,
    Deal_Conflict__c conflict
  ) {
    String action = command.action;
    if (action == 'Assign Conflict') {
      requireStatus(conflict, new Set<String>{ 'Open', 'Escalated' });
      if (command.assigneeId == null)
        throw new DealLifecycleException('An assignee is required.');
      conflict.Assigned_To__c = command.assigneeId;
      conflict.Status__c = 'Assigned';
    } else if (action == 'Start Investigation') {
      requireStatus(
        conflict,
        new Set<String>{ 'Open', 'Assigned', 'Escalated' }
      );
      conflict.Status__c = 'Investigating';
      conflict.Investigation_Started_On__c = System.now();
    } else if (action == 'Request Evidence') {
      requireStatus(conflict, new Set<String>{ 'Investigating' });
      conflict.Status__c = 'Evidence Requested';
      conflict.Evidence_Requested_On__c = System.now();
    } else if (action == 'Submit Evidence') {
      requireStatus(conflict, new Set<String>{ 'Evidence Requested' });
      if (String.isBlank(command.reviewedEvidence))
        throw new DealLifecycleException('Evidence is required.');
      conflict.Reviewed_Evidence__c = command.reviewedEvidence;
      conflict.Evidence_Submitted_On__c = System.now();
      conflict.Status__c = 'Investigating';
    } else if (action == 'Confirm Conflict') {
      requireStatus(
        conflict,
        new Set<String>{ 'Open', 'Assigned', 'Investigating', 'Escalated' }
      );
      conflict.Status__c = 'Confirmed';
    } else if (action == 'Resolve Conflict') {
      requireStatus(conflict, new Set<String>{ 'Confirmed', 'Investigating' });
      finish(conflict, command, 'Resolved');
    } else if (action == 'Waive Conflict') {
      requireStatus(
        conflict,
        new Set<String>{ 'Confirmed', 'Investigating', 'Escalated' }
      );
      validateWaiver(conflict, command);
      conflict.Waiver_Reason__c = command.reason;
      conflict.Waiver_Conditions__c = command.waiverConditions;
      conflict.Waiver_Expires_On__c = command.waiverExpiresOn;
      conflict.Waived_By__c = UserInfo.getUserId();
      conflict.Waived_On__c = System.now();
      conflict.Reviewed_Evidence__c = command.reviewedEvidence;
      finish(conflict, command, 'Waived');
    } else if (action == 'Mark False Positive') {
      requireStatus(
        conflict,
        new Set<String>{ 'Open', 'Assigned', 'Investigating', 'Escalated' }
      );
      finish(conflict, command, 'False Positive');
    } else if (action == 'Escalate Conflict') {
      requireStatus(
        conflict,
        new Set<String>{ 'Open', 'Assigned', 'Investigating' }
      );
      conflict.Status__c = 'Escalated';
      conflict.Escalated_On__c = System.now();
    } else if (action == 'Reanalyse Deal') {
      reanalyse(conflict.Deal__c);
    } else {
      throw new DealLifecycleException(
        'Unsupported conflict action: ' + action
      );
    }
  }

  private static void finish(
    Deal_Conflict__c conflict,
    DealConflictCommand command,
    String status
  ) {
    if (String.isBlank(command.reason))
      throw new DealLifecycleException('A reason is required.');
    conflict.Status__c = status;
    conflict.Resolution__c = command.reason;
    conflict.Resolution_Reason__c = command.reason;
    conflict.Resolved_By__c = UserInfo.getUserId();
    conflict.Resolved_On__c = System.now();
  }

  private static void validateWaiver(
    Deal_Conflict__c conflict,
    DealConflictCommand command
  ) {
    if (
      conflict.Severity__c == 'Critical' &&
      !DealLifecyclePermissionService.hasPermission(CRITICAL_WAIVER_PERMISSION)
    ) {
      throw new DealLifecycleException(
        'Critical conflict waiver permission is required.'
      );
    }
    if (
      String.isBlank(command.reason) ||
      String.isBlank(command.reviewedEvidence) ||
      command.waiverExpiresOn == null ||
      String.isBlank(command.waiverConditions)
    ) {
      throw new DealLifecycleException(
        'Waiver reason, expiry, conditions, and reviewed evidence are required.'
      );
    }
  }

  private static void reanalyse(Id dealId) {
    Deal_Registration__c deal = [
      SELECT
        Id,
        Customer_Account__c,
        Opportunity__c,
        Customer_Identity_Fingerprint__c
      FROM Deal_Registration__c
      WHERE Id = :dealId
    ];
    DealConflictContext context = new DealConflictContext();
    context.deal = deal;
    context.identity = new DealCustomerIdentity();
    context.identity.fingerprint = deal.Customer_Identity_Fingerprint__c;
    context.validationFindings = new List<DealValidationFinding>();
    DealConflictAnalysisService.analyze(context);
  }

  private static void requireStatus(
    Deal_Conflict__c conflict,
    Set<String> allowed
  ) {
    if (!allowed.contains(conflict.Status__c)) {
      throw new DealLifecycleException(
        'Action is not allowed while conflict is ' + conflict.Status__c + '.'
      );
    }
  }

  private static void assertAuthority() {
    if (!DealLifecyclePermissionService.hasPermission(RESOLVE_PERMISSION)) {
      throw new DealLifecycleException(
        'Conflict resolution permission is required.'
      );
    }
  }

  private static Deal_Command_Execution__c reserve(
    DealConflictCommand command,
    Id dealId
  ) {
    Deal_Command_Execution__c row = new Deal_Command_Execution__c(
      Command_Key__c = command.commandKey,
      Deal__c = dealId,
      Aggregate_Type__c = 'Deal Conflict',
      Aggregate_Id__c = String.valueOf(command.conflictId),
      Command_Type__c = command.action,
      Status__c = 'Processing',
      Expected_Version__c = command.expectedVersion,
      Requested_On__c = System.now(),
      Request_Payload__c = JSON.serialize(command)
    );
    Database.SaveResult result = Database.insert(
      row,
      false,
      AccessLevel.SYSTEM_MODE
    );
    if (result.isSuccess()) {
      row.Id = result.getId();
      return row;
    }
    for (Database.Error error : result.getErrors()) {
      if (error.getStatusCode() == StatusCode.DUPLICATE_VALUE)
        return null;
    }
    throw new DealLifecycleException(result.getErrors()[0].getMessage());
  }

  private static DealConflictCommandResult completedResult(String key) {
    List<Deal_Command_Execution__c> rows = [
      SELECT Result_Payload__c
      FROM Deal_Command_Execution__c
      WHERE Command_Key__c = :key AND Status__c = 'Completed'
      LIMIT 1
    ];
    if (rows.isEmpty() || String.isBlank(rows[0].Result_Payload__c))
      return null;
    DealConflictCommandResult result = (DealConflictCommandResult) JSON.deserialize(
      rows[0].Result_Payload__c,
      DealConflictCommandResult.class
    );
    result.duplicateCommand = true;
    return result;
  }

  private static Id createEvent(
    DealConflictCommand command,
    Deal_Conflict__c conflict,
    String previous
  ) {
    Deal_Event__c eventRecord = new Deal_Event__c(
      Deal__c = conflict.Deal__c,
      Aggregate_Type__c = 'Deal Conflict',
      Aggregate_Id__c = String.valueOf(conflict.Id),
      Event_Type__c = command.action.replace(' ', ''),
      Lifecycle_Dimension__c = 'Conflict',
      Previous_State__c = previous,
      New_State__c = conflict.Status__c,
      Action__c = command.action,
      Actor_User__c = UserInfo.getUserId(),
      Source__c = 'Conflict Command',
      Command_Key__c = command.commandKey,
      Occurred_On__c = System.now(),
      Summary__c = command.action +
        ': ' +
        previous +
        ' to ' +
        conflict.Status__c,
      Partner_Visible__c = false
    );
    Database.insert(eventRecord, AccessLevel.SYSTEM_MODE);
    Database.insert(
      new Deal_Event_Outbox__c(
        Event__c = eventRecord.Id,
        Status__c = 'Pending',
        Attempt_Count__c = 0,
        Next_Attempt_On__c = System.now()
      ),
      AccessLevel.SYSTEM_MODE
    );
    return eventRecord.Id;
  }
}
