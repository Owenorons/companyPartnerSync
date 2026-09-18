/**
 * Aura/LWC-facing controller that deserialises and executes deal lifecycle
 * commands submitted from the UI.
 */
public with sharing class DealCommandController {
  /**
   * Deserialises the given JSON payload into a DealCommand and executes it,
   * translating known lifecycle failures into user-facing AuraHandledExceptions.
   *
   * @param requestJson JSON-serialised DealCommand to execute.
   * @return The result of executing the command.
   */
  @AuraEnabled
  public static DealCommandResult executeCommand(String requestJson) {
    try {
      if (String.isBlank(requestJson)) {
        throw new DealLifecycleException('A command request is required.');
      }
      DealCommand command = (DealCommand) JSON.deserialize(
        requestJson,
        DealCommand.class
      );
      return DealCommandService.execute(command);
    } catch (DealLifecycleException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'DealCommandController',
        'Unable to execute deal command.',
        ex
      );
      throw new AuraHandledException('The deal action could not be completed.');
    }
  }
}
