public with sharing class DealRegistrationCommandFacade {
  public static DealCommandResult execute(
    Id dealId,
    String action,
    Integer expectedVersion,
    String commandKey,
    String reason,
    Map<String, Object> parameters
  ) {
    DealCommand command = new DealCommand();
    command.dealId = dealId;
    command.aggregateId = dealId;
    command.aggregateType = DealLifecycleConstants.AGGREGATE_REGISTRATION;
    command.lifecycleDimension = DealLifecycleConstants.DIMENSION_REGISTRATION;
    command.commandType = action;
    command.commandKey = String.isBlank(commandKey)
      ? generateCommandKey(dealId, action)
      : commandKey;
    command.expectedVersion = expectedVersion;
    command.reason = reason;
    command.source = 'Legacy Facade';
    command.parameters = parameters == null
      ? new Map<String, Object>()
      : parameters;
    return DealCommandService.execute(command);
  }

  public static String generateCommandKey(Id dealId, String action) {
    String seed =
      String.valueOf(dealId) +
      ':' +
      action +
      ':' +
      String.valueOf(System.now().getTime());
    return EncodingUtil.convertToHex(
      Crypto.generateDigest('SHA-256', Blob.valueOf(seed))
    );
  }
}
