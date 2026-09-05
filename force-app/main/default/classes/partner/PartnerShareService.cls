/*
 * Grants/revokes a partner account's manual access to a single Deal
 * Registration or MDF Request record, keeping the Partner_Record_Share__c
 * registry in sync with the actual Salesforce __Share row underneath it.
 * Validation lives in PartnerShareDomain and queries in PartnerShareSelector
 * — this class owns the sequencing between the registry and the platform
 * share, and the permission gating around interactive use.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class PartnerShareService {
  public static Id grantAccess(PartnerShareDTO request) {
    PartnerPermissionService.assertCanManageRecordShares();

    PartnerShareDomain.validateGrant(request);

    SecurityUtil.assertCreateable(Partner_Record_Share__c.SObjectType);
    if (
      PartnerShareSelector.hasActiveGrant(
        request.targetRecordId,
        request.partnerAccountId
      )
    ) {
      throw new PartnerSyncHandledException(
        'This partner already has active access to the record.'
      );
    }

    Savepoint grantSavepoint = Database.setSavepoint();
    try {
      Partner_Record_Share__c registry = PartnerShareDomain.buildRegistryRecord(
        request
      );
      registry.Partner_Group_Id__c = String.valueOf(
        resolvePartnerGroupId(registry.Partner_Account__c)
      );

      List<SObject> sanitizedRegistry = SecurityUtil.stripForCreate(
        new List<SObject>{ registry }
      );
      insert sanitizedRegistry;
      registry.Id = sanitizedRegistry[0].Id;

      Id salesforceShareId = createSalesforceShare(registry);
      registry.Salesforce_Share_Id__c = salesforceShareId == null
        ? null
        : String.valueOf(salesforceShareId);
      update SecurityUtil.stripForUpdate(new List<SObject>{ registry });

      AuditLogRequestDTO audit = AuditFactory.createSuccess(
        'Partner_Record_Share__c',
        registry.Id,
        'Grant'
      );
      audit.partnerAccountId = registry.Partner_Account__c;
      AuditService.log(audit);

      return registry.Id;
    } catch (Exception ex) {
      Database.rollback(grantSavepoint);
      throw ex;
    }
  }

  public static List<PartnerShareListDTO> getActiveShares(Id targetRecordId) {
    PartnerPermissionService.assertCanManageRecordShares();

    List<PartnerShareListDTO> results = new List<PartnerShareListDTO>();

    for (
      Partner_Record_Share__c record : PartnerShareSelector.selectActiveSharesForRecord(
        targetRecordId
      )
    ) {
      results.add(PartnerShareDomain.toListDTO(record));
    }

    return results;
  }

  public static void revokeAccess(Id partnerRecordShareId) {
    PartnerPermissionService.assertCanManageRecordShares();
    revokeAccessInternal(PartnerShareSelector.selectById(partnerRecordShareId));
  }

  /*
   * Entry point for unattended expiry enforcement (e.g. PartnerShareCleanupBatch).
   * revokeAccess() gates on assertCanManageRecordShares(), a permission-set
   * check meant for an interactive admin action. A scheduled/batch job runs
   * as whoever scheduled it, who may not hold that permission set, so gating
   * this path the same way silently breaks expiry cleanup. Authorization here
   * instead comes from the record actually being past its Expiry_Date__c.
   */
  public static void revokeExpiredAccess(Id partnerRecordShareId) {
    Partner_Record_Share__c registry = PartnerShareSelector.selectById(
      partnerRecordShareId
    );

    if (
      registry.Expiry_Date__c == null ||
      registry.Expiry_Date__c >= Date.today()
    ) {
      throw new PartnerSyncHandledException(
        'Partner record share is not expired: ' + partnerRecordShareId
      );
    }

    revokeAccessInternal(registry);
  }

  private static void revokeAccessInternal(Partner_Record_Share__c registry) {
    // Delete the actual Salesforce share first: if the target object isn't
    // supported, this throws and the registry below is never touched, so a
    // failed revoke can't be left recorded as if access was actually removed.
    deleteSalesforceShare(registry);

    registry.Active__c = false;
    registry.Revoked_On__c = System.now();

    updateRegistryAsSystem(registry);

    AuditLogRequestDTO audit = AuditFactory.createSuccess(
      'Partner_Record_Share__c',
      registry.Id,
      'Revoke'
    );
    audit.partnerAccountId = registry.Partner_Account__c;
    AuditService.log(audit);
  }

  // Interactive revokes are permission-gated and expiry revokes are invoked
  // by trusted cleanup automation. Both must update the registry regardless
  // of the scheduler's profile-level FLS.
  @SuppressWarnings('PMD.ApexCRUDViolation')
  private static void updateRegistryAsSystem(Partner_Record_Share__c registry) {
    update registry;
  }

  /*
   * Apex-managed share rows are privileged platform records and don't follow
   * normal custom-object CRUD. The public entry point is protected by
   * assertCanManageRecordShares(), validates the target and group, and builds
   * every share field internally. System-mode DML is therefore intentional.
   */
  @SuppressWarnings('PMD.ApexCRUDViolation')
  private static Id createSalesforceShare(Partner_Record_Share__c registry) {
    if (registry.Target_Object__c == 'Deal Registration') {
      return createDealShare(registry);
    } else if (registry.Target_Object__c == 'MDF Request') {
      return createMdfShare(registry);
    } else {
      throw new PartnerSyncHandledException(
        'Sharing is not yet supported for target object: ' +
        registry.Target_Object__c
      );
    }
  }

  @SuppressWarnings('PMD.ApexCRUDViolation')
  private static Id createDealShare(Partner_Record_Share__c registry) {
    Deal_Registration__Share share = new Deal_Registration__Share();
    share.ParentId = (Id) registry.Target_Record_Id__c;
    share.UserOrGroupId = (Id) registry.Partner_Group_Id__c;
    share.AccessLevel = PartnerShareDomain.toSalesforceAccessLevel(
      registry.Access_Level__c
    );
    share.RowCause = Schema.Deal_Registration__Share.RowCause.Partner_Record_Share__c;

    try {
      insert share;
    } catch (DmlException ex) {
      if (ex.getDmlStatusCode(0) == 'INVALID_FIELD_FOR_INSERT_UPDATE')
        return null;
      throw ex;
    }
    return share.Id;
  }

  @SuppressWarnings('PMD.ApexCRUDViolation')
  private static Id createMdfShare(Partner_Record_Share__c registry) {
    MDF_Request__Share share = new MDF_Request__Share();
    share.ParentId = (Id) registry.Target_Record_Id__c;
    share.UserOrGroupId = (Id) registry.Partner_Group_Id__c;
    share.AccessLevel = PartnerShareDomain.toSalesforceAccessLevel(
      registry.Access_Level__c
    );
    share.RowCause = Schema.MDF_Request__Share.RowCause.Partner_Record_Share__c;

    try {
      insert share;
    } catch (DmlException ex) {
      if (ex.getDmlStatusCode(0) == 'INVALID_FIELD_FOR_INSERT_UPDATE')
        return null;
      throw ex;
    }
    return share.Id;
  }

  @SuppressWarnings('PMD.ApexCRUDViolation')
  private static void deleteSalesforceShare(Partner_Record_Share__c registry) {
    // A record can be shared with more than one partner using the same Apex
    // sharing reason. Scope the delete to the group for this registry entry;
    // filtering only by ParentId and RowCause would revoke every partner.
    if (String.isNotBlank(registry.Salesforce_Share_Id__c)) {
      if (registry.Target_Object__c == 'Deal Registration') {
        delete new Deal_Registration__Share(
          Id = (Id) registry.Salesforce_Share_Id__c
        );
        return;
      } else if (registry.Target_Object__c == 'MDF Request') {
        delete new MDF_Request__Share(
          Id = (Id) registry.Salesforce_Share_Id__c
        );
        return;
      }
    }

    // Legacy registry rows created before share identity was persisted still
    // use the original group where available, then fall back to the mapping.
    Id partnerGroupId = String.isNotBlank(registry.Partner_Group_Id__c)
      ? (Id) registry.Partner_Group_Id__c
      : resolvePartnerGroupId(registry.Partner_Account__c, false);

    if (registry.Target_Object__c == 'Deal Registration') {
      delete [
        SELECT Id
        FROM Deal_Registration__Share
        WHERE
          ParentId = :((Id) registry.Target_Record_Id__c)
          AND UserOrGroupId = :partnerGroupId
          AND RowCause = :Schema.Deal_Registration__Share.RowCause.Partner_Record_Share__c
      ];
    } else if (registry.Target_Object__c == 'MDF Request') {
      delete [
        SELECT Id
        FROM MDF_Request__Share
        WHERE
          ParentId = :((Id) registry.Target_Record_Id__c)
          AND UserOrGroupId = :partnerGroupId
          AND RowCause = :Schema.MDF_Request__Share.RowCause.Partner_Record_Share__c
      ];
    } else {
      throw new PartnerSyncHandledException(
        'Sharing is not yet supported for target object: ' +
        registry.Target_Object__c
      );
    }
  }

  private static Id resolvePartnerGroupId(Id partnerAccountId) {
    return resolvePartnerGroupId(partnerAccountId, true);
  }

  private static Id resolvePartnerGroupId(
    Id partnerAccountId,
    Boolean requireActive
  ) {
    List<Partner_Access_Group__c> mappings = [
      SELECT Group_Id__c, Active__c
      FROM Partner_Access_Group__c
      WHERE Partner_Account__c = :partnerAccountId
      WITH USER_MODE
      ORDER BY Active__c DESC, CreatedDate DESC
      LIMIT 1
    ];

    if (
      mappings.isEmpty() || (requireActive && mappings[0].Active__c != true)
    ) {
      throw new PartnerSyncHandledException(
        'No partner access group configured for this partner.'
      );
    }

    return (Id) mappings[0].Group_Id__c;
  }
}
