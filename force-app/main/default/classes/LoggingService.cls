/**
 * Thin wrapper around System.debug for consistent, source-tagged log lines
 * (e.g. "[PartnerSync][ServiceName] message"). Not a persisted audit trail —
 * see AuditService / Audit_Log__c for that. Intended for debugging and log
 * analyzer queries, not for business-facing history.
 */
public with sharing class LoggingService {
  /**
   * Writes an INFO-level, source-tagged debug log line.
   *
   * @param source The name of the class/service emitting the log line.
   * @param message The message to log.
   */
  public static void info(String source, String message) {
    System.debug(LoggingLevel.INFO, format(source, message));
  }

  /**
   * Writes a WARN-level, source-tagged debug log line.
   *
   * @param source The name of the class/service emitting the log line.
   * @param message The message to log.
   */
  public static void warn(String source, String message) {
    System.debug(LoggingLevel.WARN, format(source, message));
  }

  /**
   * Writes an ERROR-level, source-tagged debug log line, appending the
   * exception message when one is provided.
   *
   * @param source The name of the class/service emitting the log line.
   * @param message The message to log.
   * @param ex The exception associated with the error, or null if none.
   */
  public static void error(String source, String message, Exception ex) {
    String output = format(source, message);

    if (ex != null) {
      output += ' | Exception: ' + ex.getMessage();
    }

    System.debug(LoggingLevel.ERROR, output);
  }

  private static String format(String source, String message) {
    return '[PartnerSync][' + source + '] ' + message;
  }
}
