/**
 * Validation and shaping logic for Partner_Record_Share__c grants — the
 * allowed target objects/access levels/reasons, and the mapping from this
 * app's access-level vocabulary down to Salesforce's native Read/Edit share
 * levels. No DML or queries; PartnerShareService owns persistence.
 */
public with sharing class PartnerShareDomain {
  private static final Set<String> SUPPORTED_TARGETS = new Set<String>{
    'Deal Registration',
    'MDF Request'
  };
  private static final Set<String> ACCESS_LEVELS = new Set<String>{
    'Read',
    'Edit',
    'Review',
    'Approve'
  };
  private static final Set<String> SHARE_REASONS = new Set<String>{
    'Co-Sell',
    'Distributor',
    'Regional Manager',
    'Escalation',
    'Deal Conflict Review',
    'MDF Review',
    'Multi-Account Access'
  };

  /**
   * Validates a share grant request, throwing a handled exception
   * describing the first invalid or missing field found (including a
   * target-record/target-object type mismatch).
   *
   * @param request The share grant request to validate.
   */
  public static void validateGrant(PartnerShareDTO request) {
    if (request == null) {
      throw new PartnerSyncHandledException('Share request is required.');
    }

    if (request.targetRecordId == null) {
      throw new PartnerSyncHandledException('Target record is required.');
    }

    if (String.isBlank(request.targetObject)) {
      throw new PartnerSyncHandledException('Target object is required.');
    }

    if (request.partnerAccountId == null) {
      throw new PartnerSyncHandledException('Partner account is required.');
    }

    if (String.isBlank(request.accessLevel)) {
      throw new PartnerSyncHandledException('Access level is required.');
    }

    if (String.isBlank(request.shareReason)) {
      throw new PartnerSyncHandledException('Share reason is required.');
    }

    if (!SUPPORTED_TARGETS.contains(request.targetObject)) {
      throw new PartnerSyncHandledException(
        'Sharing is not supported for target object: ' + request.targetObject
      );
    }

    // Guards against a caller declaring one target object (e.g. "MDF
    // Request") while actually passing the Id of the other kind of record —
    // without this, the mismatch would only surface later as a confusing
    // failure inside PartnerShareService's object-specific share creation.
    Schema.SObjectType expectedType = request.targetObject ==
      'Deal Registration'
      ? Deal_Registration__c.SObjectType
      : MDF_Request__c.SObjectType;
    if (request.targetRecordId.getSObjectType() != expectedType) {
      throw new PartnerSyncHandledException(
        'Target record does not match target object: ' + request.targetObject
      );
    }

    if (!ACCESS_LEVELS.contains(request.accessLevel)) {
      throw new PartnerSyncHandledException('Invalid access level.');
    }

    if (!SHARE_REASONS.contains(request.shareReason)) {
      throw new PartnerSyncHandledException('Invalid share reason.');
    }

    if (request.expiryDate != null && request.expiryDate <= Date.today()) {
      throw new PartnerSyncHandledException(
        'Expiry date must be later than today.'
      );
    }
  }

  /**
   * Builds a new Partner_Record_Share__c record from a validated grant
   * request, populated with the granting user and timestamp. Does not
   * perform DML.
   *
   * @param request The share grant request.
   * @return A populated, unsaved Partner_Record_Share__c record.
   */
  public static Partner_Record_Share__c buildRegistryRecord(
    PartnerShareDTO request
  ) {
    validateGrant(request);

    Partner_Record_Share__c share = new Partner_Record_Share__c();
    share.Target_Record_Id__c = String.valueOf(request.targetRecordId);
    share.Target_Object__c = request.targetObject;
    share.Partner_Account__c = request.partnerAccountId;
    share.Access_Level__c = request.accessLevel;
    share.Share_Reason__c = request.shareReason;
    share.Expiry_Date__c = request.expiryDate;
    share.Active__c = true;
    share.Granted_By__c = UserInfo.getUserId();
    share.Granted_On__c = System.now();

    return share;
  }

  /**
   * Maps this app's access-level vocabulary (Read/Edit/Review/Approve)
   * down to Salesforce's native Read/Edit sharing access levels.
   *
   * @param accessLevel The app-level access level to map.
   * @return "Edit" for Edit/Review/Approve, otherwise "Read".
   */
  public static String toSalesforceAccessLevel(String accessLevel) {
    if (
      accessLevel == 'Edit' ||
      accessLevel == 'Review' ||
      accessLevel == 'Approve'
    ) {
      return 'Edit';
    }

    return 'Read';
  }

  /**
   * Maps a Partner_Record_Share__c record to the "who has access" list
   * row shape.
   *
   * @param record The Partner_Record_Share__c record to map.
   * @return A PartnerShareListDTO summarizing the record.
   */
  public static PartnerShareListDTO toListDTO(Partner_Record_Share__c record) {
    PartnerShareListDTO dto = new PartnerShareListDTO();

    dto.shareId = record.Id;
    dto.targetObject = record.Target_Object__c;
    dto.partnerAccountId = record.Partner_Account__c;
    dto.partnerAccountName = record.Partner_Account__r?.Name;
    dto.accessLevel = record.Access_Level__c;
    dto.shareReason = record.Share_Reason__c;
    dto.expiryDate = record.Expiry_Date__c;
    dto.grantedByName = record.Granted_By__r?.Name;
    dto.grantedOn = record.Granted_On__c;

    return dto;
  }
}
