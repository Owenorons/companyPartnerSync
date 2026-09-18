/**
 * Factory that resolves a configured Apex class name to a DealCommandHandler
 * instance for a deal lifecycle transition.
 */
public class DealCommandHandlerFactory {
  /**
   * Instantiates the DealCommandHandler implementation with the given fully
   * qualified class name.
   *
   * @param className Fully qualified name of the DealCommandHandler implementation to instantiate.
   * @return The instantiated command handler.
   */
  public static DealCommandHandler getHandler(String className) {
    if (String.isBlank(className)) {
      throw new DealLifecycleException('No command handler is configured.');
    }
    Type handlerType = Type.forName(className);
    if (handlerType == null) {
      throw new DealLifecycleException(
        'Configured command handler was not found: ' + className
      );
    }
    Object instance = handlerType.newInstance();
    if (!(instance instanceof DealCommandHandler)) {
      throw new DealLifecycleException(
        className + ' does not implement DealCommandHandler.'
      );
    }
    return (DealCommandHandler) instance;
  }
}
