/**
 * Data carrier describing the outcome of executing (or attempting to execute) a DealCommand:
 * whether it was accepted/completed, the resulting lifecycle state and version, and a
 * human-readable message.
 */
public class DealCommandResult {
  @AuraEnabled
  public Boolean accepted;
  @AuraEnabled
  public Boolean completed;
  @AuraEnabled
  public Boolean duplicateCommand;
  @AuraEnabled
  public Boolean retryable;
  @AuraEnabled
  public String outcome;
  @AuraEnabled
  public Id dealId;
  @AuraEnabled
  public Id aggregateId;
  @AuraEnabled
  public Id eventId;
  @AuraEnabled
  public String commandKey;
  @AuraEnabled
  public String previousState;
  @AuraEnabled
  public String newState;
  @AuraEnabled
  public Integer resultingVersion;
  @AuraEnabled
  public String message;

  /**
   * Builds a result representing a command that executed successfully and produced an event.
   *
   * @param context The command execution context the command completed under.
   * @param eventId Id of the Deal_Event__c record created for this command.
   * @return A completed, non-duplicate, non-retryable result.
   */
  public static DealCommandResult completed(
    DealCommandContext context,
    Id eventId
  ) {
    DealCommandResult result = new DealCommandResult();
    result.accepted = true;
    result.completed = true;
    result.duplicateCommand = false;
    result.retryable = false;
    result.outcome = DealLifecycleConstants.OUTCOME_COMPLETED;
    result.dealId = context.command.dealId;
    result.aggregateId = context.command.aggregateId;
    result.eventId = eventId;
    result.commandKey = context.command.commandKey;
    result.previousState = context.previousState;
    result.newState = context.newState;
    result.resultingVersion = context.newVersion;
    result.message = 'Command completed successfully.';
    return result;
  }

  /**
   * Builds a result representing a command that is already being processed by another,
   * concurrent execution of the same command key.
   *
   * @param command The command that is already in progress.
   * @return An accepted, duplicate, retryable, not-yet-completed result.
   */
  public static DealCommandResult inProgress(DealCommand command) {
    DealCommandResult result = new DealCommandResult();
    result.accepted = true;
    result.completed = false;
    result.duplicateCommand = true;
    result.retryable = true;
    result.outcome = DealLifecycleConstants.OUTCOME_COMMAND_IN_PROGRESS;
    result.dealId = command.dealId;
    result.aggregateId = command.aggregateId;
    result.commandKey = command.commandKey;
    result.message = 'The same command is already being processed.';
    return result;
  }
}
