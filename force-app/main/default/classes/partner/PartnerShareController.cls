/*
 * Aura-enabled entry points for the record-sharing panel (view/grant/revoke
 * access to a Deal Registration or MDF Request). All business logic lives
 * in PartnerShareService; this class only adapts its exceptions for the UI.
 * Note revokeExpiredAccess is intentionally NOT exposed here — that path is
 * for unattended cleanup only (see PartnerShareCleanupBatch), not interactive
 * use.
 */
public with sharing class PartnerShareController {
  @AuraEnabled(cacheable=true)
  public static List<PartnerShareListDTO> getActiveShares(Id targetRecordId) {
    try {
      return PartnerShareService.getActiveShares(targetRecordId);
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'PartnerShareController.getActiveShares',
        ex.getMessage(),
        ex
      );
      throw new AuraHandledException('Unable to load record shares.');
    }
  }

  @AuraEnabled
  public static Id grantAccess(PartnerShareDTO request) {
    try {
      return PartnerShareService.grantAccess(request);
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'PartnerShareController.grantAccess',
        ex.getMessage(),
        ex
      );
      throw new AuraHandledException('Unable to grant access.');
    }
  }

  @AuraEnabled
  public static void revokeAccess(Id partnerRecordShareId) {
    try {
      PartnerShareService.revokeAccess(partnerRecordShareId);
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'PartnerShareController.revokeAccess',
        ex.getMessage(),
        ex
      );
      throw new AuraHandledException('Unable to revoke access.');
    }
  }
}
