/**
 * Aura/LWC-facing controller that deserialises and executes deal conflict
 * lifecycle commands submitted from the UI.
 */
public with sharing class DealConflictCommandController {
  /**
   * Deserialises the given JSON payload into a DealConflictCommand and
   * executes it, translating lifecycle failures into user-facing
   * AuraHandledExceptions.
   *
   * @param requestJson JSON-serialised DealConflictCommand to execute.
   * @return The result of executing the command.
   */
  @AuraEnabled
  public static DealConflictCommandResult executeCommand(String requestJson) {
    try {
      return DealConflictCommandService.execute(
        (DealConflictCommand) JSON.deserialize(
          requestJson,
          DealConflictCommand.class
        )
      );
    } catch (DealLifecycleException ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }
}
