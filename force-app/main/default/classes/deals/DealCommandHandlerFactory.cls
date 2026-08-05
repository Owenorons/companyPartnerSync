public class DealCommandHandlerFactory {
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
