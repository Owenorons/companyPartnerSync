/*
 * Consistent Aura/LWC exception boundary for thin controllers. Expected
 * business denials retain their actionable message; unexpected failures are
 * logged and replaced with a controller-specific safe message.
 */
public class ControllerExceptionMapper {
  public static AuraHandledException toAura(
    String component,
    String logMessage,
    String safeMessage,
    Exception exceptionValue
  ) {
    if (exceptionValue instanceof PartnerSyncHandledException) {
      return new AuraHandledException(exceptionValue.getMessage());
    }

    LoggingService.error(component, logMessage, exceptionValue);
    return new AuraHandledException(safeMessage);
  }
}
