/**
 * Backward-compatible facade over DealCommandService for the registration lifecycle dimension:
 * builds a DealCommand from simple scalar arguments so older callers can keep issuing
 * create-and-submit style calls without constructing a DealCommand themselves.
 */
public with sharing class DealRegistrationCommandFacade {
  /**
   * Builds and executes a registration-dimension DealCommand for the given deal.
   *
   * @param dealId Id of the deal registration the command applies to.
   * @param action Command/action type to execute.
   * @param expectedVersion Version the caller expects the deal aggregate to currently be at.
   * @param commandKey Idempotency key; a key is generated when blank.
   * @param reason Optional reason associated with the command (e.g. rejection reason).
   * @param parameters Optional command-specific parameters; an empty map is used when null.
   * @return The result of executing the command.
   */
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

  /**
   * Generates a deterministic-format, unique idempotency key for a command when the caller
   * didn't supply one, hashing the deal Id, action, and current timestamp.
   *
   * @param dealId Id of the deal registration the command applies to.
   * @param action Command/action type being executed.
   * @return A SHA-256 hex digest suitable for use as a command key.
   */
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
