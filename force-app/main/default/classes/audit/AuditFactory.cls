public with sharing class AuditFactory {
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
