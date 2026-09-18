/**
 * Aura-enabled entry points for the record-sharing panel (view/grant/revoke
 * access to a Deal Registration or MDF Request). All business logic lives
 * in PartnerShareService; this class only adapts its exceptions for the UI.
 * Note revokeExpiredAccess is intentionally NOT exposed here — that path is
 * for unattended cleanup only (see PartnerShareCleanupBatch), not interactive
 * use.
 */
public with sharing class PartnerShareController {
  /**
   * Lists the currently active manual record shares for a Deal Registration
   * or MDF Request record, for display in the record-sharing panel.
   *
   * @param targetRecordId Id of the Deal Registration or MDF Request record.
   * @return The active record shares for the record, as list DTOs.
   */
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

  /**
   * Grants a partner account manual access to a Deal Registration or MDF
   * Request record from the record-sharing panel.
   *
   * @param request The grant details (target record, partner account, access level).
   * @return The Id of the newly created record share.
   */
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

  /**
   * Revokes a partner account's manual access to a record from the
   * record-sharing panel.
   *
   * @param partnerRecordShareId Id of the Partner_Record_Share__c registry row to revoke.
   */
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
