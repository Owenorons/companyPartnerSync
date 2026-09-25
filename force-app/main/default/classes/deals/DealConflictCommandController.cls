/**
 * Aura/LWC-facing controller for the deal conflict workbench: lists and
 * loads findings, and deserialises/executes deal conflict lifecycle
 * commands submitted from the UI.
 */
public with sharing class DealConflictCommandController {
  /**
   * Loads every current, non-terminal conflict finding for the workbench queue.
   *
   * @return Row shapes for the workbench queue.
   */
  @AuraEnabled(cacheable=true)
  public static List<DealConflictWorkbenchListDTO> getPendingConflicts() {
    try {
      return DealConflictWorkbenchService.getPendingConflicts();
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }

  /**
   * Loads the full detail for a single conflict finding.
   *
   * @param conflictId Id of the conflict finding to load.
   * @return The full detail DTO for the finding.
   */
  @AuraEnabled(cacheable=true)
  public static DealConflictWorkbenchDetailDTO getConflictDetail(
    Id conflictId
  ) {
    try {
      return DealConflictWorkbenchService.getConflictDetail(conflictId);
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }

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
