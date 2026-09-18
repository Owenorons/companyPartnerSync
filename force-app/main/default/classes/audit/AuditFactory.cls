/**
 * Builds AuditLogRequestDTO instances with consistent severity/status
 * conventions (Info/Success vs. Error/Failed) so callers across the codebase
 * don't hand-roll inconsistent audit payloads. Pair with AuditService.log().
 */
public with sharing class AuditFactory {
  /**
   * Builds an audit request for a successful action, with severity Info and
   * status Success.
   *
   * @param objectName The name of the SObject the audited action was performed on.
   * @param recordId The id of the record the audited action was performed on.
   * @param action The action that was performed (e.g. Submit, Approve).
   * @return A populated AuditLogRequestDTO ready to pass to AuditService.log().
   */
  public static AuditLogRequestDTO createSuccess(
    String objectName,
    Id recordId,
    String action
  ) {
    AuditLogRequestDTO dto = new AuditLogRequestDTO();

    dto.objectName = objectName;
    dto.recordId = recordId;
    dto.action = action;

    dto.severity = 'Info';
    dto.status = 'Success';

    return dto;
  }

  /**
   * Builds an audit request for a failed action, with severity Error and
   * status Failed, capturing the failure message in metadataJson.
   *
   * @param objectName The name of the SObject the audited action was performed on.
   * @param recordId The id of the record the audited action was performed on.
   * @param action The action that was attempted (e.g. Submit, Approve).
   * @param message A description of why the action failed.
   * @return A populated AuditLogRequestDTO ready to pass to AuditService.log().
   */
  public static AuditLogRequestDTO createFailure(
    String objectName,
    Id recordId,
    String action,
    String message
  ) {
    AuditLogRequestDTO dto = new AuditLogRequestDTO();

    dto.objectName = objectName;
    dto.recordId = recordId;
    dto.action = action;

    dto.severity = 'Error';
    dto.status = 'Failed';

    dto.metadataJson = JSON.serialize(
      new Map<String, Object>{ 'message' => message }
    );

    return dto;
  }
}
