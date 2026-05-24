public with sharing class LoggingService {
  public static void info(String source, String message) {
    System.debug(LoggingLevel.INFO, format(source, message));
  }

  public static void warn(String source, String message) {
    System.debug(LoggingLevel.WARN, format(source, message));
  }

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
