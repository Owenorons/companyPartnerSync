/**
 * Consistent Aura/LWC exception boundary for thin controllers. Expected
 * business denials retain their actionable message; unexpected failures are
 * logged and replaced with a controller-specific safe message.
 */
public class ControllerExceptionMapper {
  /**
   * Maps a caught exception to an AuraHandledException suitable for
   * rethrowing to the LWC/Aura layer. A PartnerSyncHandledException's
   * message is passed through as-is (it's already user-safe); any other
   * exception is logged via LoggingService and replaced with the given
   * safe message so internal details are never leaked to the client.
   *
   * @param component The name of the controller/component mapping the exception, for logging.
   * @param logMessage The message to log alongside unexpected exceptions.
   * @param safeMessage The user-safe message to surface for unexpected exceptions.
   * @param exceptionValue The exception that was caught.
   * @return An AuraHandledException ready to be thrown to the client.
   */
  public static AuraHandledException toAura(
    String component,
    String logMessage,
    String safeMessage,
    Exception exceptionValue
  ) {
    // AuraHandledException's constructor argument alone only reaches the
    // client (error.body.message in the LWC); getMessage() on the exception
    // itself returns a generic "Script-thrown exception" unless setMessage()
    // is also called. Tests that catch this exception in Apex and assert on
    // getMessage() need that explicit call as much as the client does.
    if (exceptionValue instanceof PartnerSyncHandledException) {
      AuraHandledException handled = new AuraHandledException(
        exceptionValue.getMessage()
      );
      handled.setMessage(exceptionValue.getMessage());
      return handled;
    }

    LoggingService.error(component, logMessage, exceptionValue);
    AuraHandledException safe = new AuraHandledException(safeMessage);
    safe.setMessage(safeMessage);
    return safe;
  }
}
