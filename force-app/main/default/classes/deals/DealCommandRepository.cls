public without sharing class DealCommandRepository {
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
