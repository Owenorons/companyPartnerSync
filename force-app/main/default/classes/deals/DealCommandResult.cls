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
