/**
 * Repository for the Deal_Command_Execution__c idempotency ledger, which records commands as
 * they're reserved and completed so a retried command key can be recognized and short-circuited.
 * Runs without sharing since it's an internal idempotency boundary meant to be called through
 * DealCommandService, not queried/updated directly by end users.
 */
public without sharing class DealCommandRepository {
  /**
   * Finds a command execution ledger row by its command key.
   *
   * @param commandKey Idempotency key to look up.
   * @return The matching Deal_Command_Execution__c row, or null if none exists.
   */
  @SuppressWarnings('PMD.ApexCRUDViolation')
  public static Deal_Command_Execution__c findByKey(String commandKey) {
    // The ledger is an internal idempotency boundary. Callers are authorised by
    // DealCommandService and must not require direct object access. NOPMD
    List<Deal_Command_Execution__c> rows = [
      SELECT Id, Command_Key__c, Status__c, Result_Payload__c
      FROM Deal_Command_Execution__c
      WHERE Command_Key__c = :commandKey
      LIMIT 1
    ];
    return rows.isEmpty() ? null : rows[0];
  }

  /**
   * Loads the previously stored result for a command that already completed, so a retried
   * request can be answered from the ledger instead of re-executing the command.
   *
   * @param commandKey Idempotency key to look up.
   * @return The deserialized result marked as a duplicate command, or null if no completed
   * execution with a result payload exists for the key.
   */
  public static DealCommandResult completedResult(String commandKey) {
    Deal_Command_Execution__c row = findByKey(commandKey);
    if (
      row == null ||
      row.Status__c != 'Completed' ||
      String.isBlank(row.Result_Payload__c)
    ) {
      return null;
    }
    DealCommandResult result = (DealCommandResult) JSON.deserialize(
      row.Result_Payload__c,
      DealCommandResult.class
    );
    result.duplicateCommand = true;
    return result;
  }

  /**
   * Inserts a new ledger row reserving a command's key as "Processing", so a concurrent or
   * retried request with the same key can be detected via the resulting duplicate-value error.
   *
   * @param command Command whose key/aggregate/version details should be reserved.
   * @return The inserted ledger row, or null if a row for this command key was already reserved
   * by another execution.
   */
  public static Deal_Command_Execution__c reserve(DealCommand command) {
    Deal_Command_Execution__c execution = new Deal_Command_Execution__c(
      Command_Key__c = command.commandKey,
      Deal__c = command.dealId,
      Aggregate_Type__c = command.aggregateType,
      Aggregate_Id__c = String.valueOf(command.aggregateId),
      Command_Type__c = command.commandType,
      Status__c = 'Processing',
      Expected_Version__c = command.expectedVersion,
      Requested_On__c = System.now(),
      Request_Payload__c = JSON.serialize(command)
    );
    Database.SaveResult[] results = Database.insert(
      new List<Deal_Command_Execution__c>{ execution },
      false,
      AccessLevel.SYSTEM_MODE
    );
    if (results[0].isSuccess()) {
      execution.Id = results[0].getId();
      return execution;
    }
    for (Database.Error error : results[0].getErrors()) {
      if (error.getStatusCode() == StatusCode.DUPLICATE_VALUE) {
        return null;
      }
    }
    throw new DealLifecycleException(
      'The command could not be reserved: ' +
      results[0].getErrors()[0].getMessage()
    );
  }

  /**
   * Marks a reserved ledger row as completed and stores its result payload for future
   * idempotent lookups.
   *
   * @param execution Ledger row to mark completed (updated in place).
   * @param result Result to serialize and store on the ledger row.
   */
  public static void complete(
    Deal_Command_Execution__c execution,
    DealCommandResult result
  ) {
    execution.Status__c = 'Completed';
    execution.Completed_On__c = System.now();
    execution.Resulting_Version__c = result.resultingVersion;
    execution.Result_Payload__c = JSON.serialize(result);
    Database.update(execution, AccessLevel.SYSTEM_MODE);
  }
}
