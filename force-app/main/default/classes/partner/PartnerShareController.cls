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
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerShareController.getActiveShares',
        ex.getMessage(),
        'Unable to load record shares.',
        ex
      );
    }
  }

  @AuraEnabled
  public static Id grantAccess(PartnerShareDTO request) {
    try {
      return PartnerShareService.grantAccess(request);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerShareController.grantAccess',
        ex.getMessage(),
        'Unable to grant access.',
        ex
      );
    }
  }

  @AuraEnabled
  public static void revokeAccess(Id partnerRecordShareId) {
    try {
      PartnerShareService.revokeAccess(partnerRecordShareId);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerShareController.revokeAccess',
        ex.getMessage(),
        'Unable to revoke access.',
        ex
      );
    }
  }
}
