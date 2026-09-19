/**
 * Aura/LWC entry point for the internal "Partner 360" single-partner detail
 * view. Thin boundary that delegates to Partner360Service and translates
 * exceptions into AuraHandledException.
 */
public with sharing class Partner360Controller {
  @TestVisible
  private static Boolean simulateUnexpectedFailure = false;

  /**
   * Loads the Partner 360 summary for a given partner account.
   *
   * @param partnerAccountId Id of the partner Account to summarize.
   * @return The assembled Partner 360 DTO.
   */
  @AuraEnabled(cacheable=true)
  public static Partner360DTO getSummary(Id partnerAccountId) {
    try {
      if (Test.isRunningTest() && simulateUnexpectedFailure) {
        throw new Partner360ControllerException(
          'Simulated unexpected failure.'
        );
      }
      return Partner360Service.getSummary(partnerAccountId);
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'Partner360Controller',
        'Unable to load Partner 360.',
        ex
      );
      throw new AuraHandledException('Unable to load Partner 360.');
    }
  }

  private class Partner360ControllerException extends Exception {
  }
}
