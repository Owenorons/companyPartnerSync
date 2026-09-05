public with sharing class DealConflictCommandController {
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
