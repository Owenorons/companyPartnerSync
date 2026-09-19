/**
 * Contract for a handler that validates and executes one type of deal lifecycle command.
 * Implementations are dispatched to by DealCommandService based on the command's aggregate type
 * and command type.
 */
public interface DealCommandHandler {
  /**
   * Validates that the command in context is allowed to execute, throwing if it is not.
   *
   * @param context The command execution context to validate.
   */
  void validate(DealCommandContext context);
  /**
   * Executes the command in context, applying its lifecycle transition and side effects.
   *
   * @param context The command execution context to execute.
   */
  void execute(DealCommandContext context);
}
