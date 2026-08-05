public with sharing class DealCommandController {
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
