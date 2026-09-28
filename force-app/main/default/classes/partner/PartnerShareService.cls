/**
 * Grants/revokes a partner account's manual access to a single Deal
 * Registration or MDF Request record, keeping the Partner_Record_Share__c
 * registry in sync with the actual Salesforce __Share row underneath it.
 * Validation lives in PartnerShareDomain and queries in PartnerShareSelector
 * — this class owns the sequencing between the registry and the platform
 * share, and the permission gating around interactive use.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class PartnerShareService {
  /**
   * Grants a partner account manual access to a Deal Registration or MDF
   * Request record, creating the registry row and the underlying Salesforce
   * share together inside a savepoint so a failure on either side rolls
   * back both.
   *
   * @param request The grant details (target record, partner account, access level).
   * @return The Id of the newly created Partner_Record_Share__c registry row.
   */
  public static Id grantAccess(PartnerShareDTO request) {
    PartnerPermissionService.assertCanManageRecordShares();

    return grantAccessInternal(request);
  }

  /**
   * Entry point for automated access materialization when a
   * Deal_Participant__c becomes Active. grantAccess() gates on
   * assertCanManageRecordShares(), an interactive-admin permission set the
   * accepting external co-sell partner user does not and should not hold.
   * Authorization here instead comes from the caller (DealParticipantSharingService)
   * already having validated the Deal_Participant__c's own state (Active,
   * correct partner, version-checked) - mirrors revokeExpiredAccess()'s
   * reasoning for why interactive gating is wrong for a system-authorized
   * transition.
   *
   * @param request The grant details (target record, partner account, access level).
   * @return The Id of the newly created Partner_Record_Share__c registry row.
   */
  public static Id grantParticipantAccess(PartnerShareDTO request) {
    return grantAccessInternal(request);
  }

  /**
   * Bulk counterpart to grantParticipantAccess(): grants many shares in a
   * single pass (one query for existing grants, one for partner group
   * mappings, bulk DML for the registry and platform share rows), instead
   * of the per-request SOQL/DML grantParticipantAccess() does. Requests
   * that already have an active grant are silently skipped (this is a
   * reconciliation path, not an interactive one-off action, so a
   * duplicate isn't an error); requests for a partner with no access
   * group configured are skipped and logged rather than failing the
   * whole batch.
   *
   * @param requests The grants to create.
   * @return Ids of the newly created Partner_Record_Share__c registry rows (skipped requests are omitted).
   */
  public static List<Id> grantParticipantAccessBulk(
    List<PartnerShareDTO> requests
  ) {
    if (requests == null || requests.isEmpty()) {
      return new List<Id>();
    }

    for (PartnerShareDTO request : requests) {
      PartnerShareDomain.validateGrant(request);
    }

    SecurityUtil.assertCreateable(Partner_Record_Share__c.SObjectType);

    Set<Id> targetRecordIds = new Set<Id>();
    Set<Id> partnerAccountIds = new Set<Id>();
    for (PartnerShareDTO request : requests) {
      targetRecordIds.add(request.targetRecordId);
      partnerAccountIds.add(request.partnerAccountId);
    }

    Set<String> existingKeys = PartnerShareSelector.selectActiveGrantKeys(
      targetRecordIds,
      partnerAccountIds
    );
    Map<Id, Id> groupIdByPartnerAccount = resolvePartnerGroupIdsBulk(
      partnerAccountIds
    );

    List<Partner_Record_Share__c> registriesToInsert = new List<Partner_Record_Share__c>();
    for (PartnerShareDTO request : requests) {
      String key =
        String.valueOf(request.targetRecordId) +
        '|' +
        request.partnerAccountId;
      if (existingKeys.contains(key)) {
        continue;
      }
      if (!groupIdByPartnerAccount.containsKey(request.partnerAccountId)) {
        LoggingService.warn(
          'PartnerShareService',
          'No partner access group configured for partner ' +
            request.partnerAccountId +
            ' - skipping bulk grant.'
        );
        continue;
      }

      Partner_Record_Share__c registry = PartnerShareDomain.buildRegistryRecord(
        request
      );
      registry.Partner_Group_Id__c = String.valueOf(
        groupIdByPartnerAccount.get(request.partnerAccountId)
      );
      registriesToInsert.add(registry);
    }

    if (registriesToInsert.isEmpty()) {
      return new List<Id>();
    }

    Savepoint bulkGrantSavepoint = Database.setSavepoint();
    try {
      List<SObject> sanitizedRegistries = SecurityUtil.stripForCreate(
        registriesToInsert
      );
      insert sanitizedRegistries;
      for (Integer i = 0; i < registriesToInsert.size(); i++) {
        registriesToInsert[i].Id = sanitizedRegistries[i].Id;
      }

      Map<Id, Id> salesforceShareIdByRegistryId = createSalesforceSharesBulk(
        registriesToInsert
      );

      List<AuditLogRequestDTO> audits = new List<AuditLogRequestDTO>();
      for (Partner_Record_Share__c registry : registriesToInsert) {
        Id salesforceShareId = salesforceShareIdByRegistryId.get(registry.Id);
        registry.Salesforce_Share_Id__c = salesforceShareId == null
          ? null
          : String.valueOf(salesforceShareId);

        AuditLogRequestDTO audit = AuditFactory.createSuccess(
          'Partner_Record_Share__c',
          registry.Id,
          'Grant'
        );
        audit.partnerAccountId = registry.Partner_Account__c;
        audits.add(audit);
      }
      update SecurityUtil.stripForUpdate(registriesToInsert);
      AuditService.logBulk(audits);

      List<Id> results = new List<Id>();
      for (Partner_Record_Share__c registry : registriesToInsert) {
        results.add(registry.Id);
      }
      return results;
    } catch (Exception ex) {
      Database.rollback(bulkGrantSavepoint);
      throw ex;
    }
  }

  private static Id grantAccessInternal(PartnerShareDTO request) {
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

  /**
   * Lists the currently active manual record shares for a Deal Registration
   * or MDF Request record.
   *
   * @param targetRecordId Id of the Deal Registration or MDF Request record.
   * @return The active Partner_Record_Share__c rows for the record, as list DTOs.
   */
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

  /**
   * Revokes a partner account's manual access to the record represented by
   * a Partner_Record_Share__c registry row, for interactive admin use.
   *
   * @param partnerRecordShareId Id of the Partner_Record_Share__c registry row to revoke.
   */
  public static void revokeAccess(Id partnerRecordShareId) {
    PartnerPermissionService.assertCanManageRecordShares();
    revokeAccessInternal(PartnerShareSelector.selectById(partnerRecordShareId));
  }

  /**
   * Entry point for unattended expiry enforcement (e.g. PartnerShareCleanupBatch).
   * revokeAccess() gates on assertCanManageRecordShares(), a permission-set
   * check meant for an interactive admin action. A scheduled/batch job runs
   * as whoever scheduled it, who may not hold that permission set, so gating
   * this path the same way silently breaks expiry cleanup. Authorization here
   * instead comes from the record actually being past its Expiry_Date__c.
   *
   * @param partnerRecordShareId Id of the Partner_Record_Share__c registry row to revoke.
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

  /**
   * Entry point for automated access removal when a Deal_Participant__c's
   * access no longer warrants a share (suspended, removed, or downgraded
   * to Internal Only) - the non-interactive counterpart to revokeAccess(),
   * same reasoning as grantParticipantAccess().
   *
   * @param partnerRecordShareId Id of the Partner_Record_Share__c registry row to revoke.
   */
  public static void revokeParticipantAccess(Id partnerRecordShareId) {
    revokeAccessInternal(PartnerShareSelector.selectById(partnerRecordShareId));
  }

  /**
   * Bulk counterpart to revokeParticipantAccess(): revokes many shares in
   * a single pass instead of the per-Id SOQL/DML revokeParticipantAccess()
   * does. Registry rows with no stored Salesforce_Share_Id__c (pre-dating
   * that field being populated) are skipped for the platform-share
   * deletion step and logged - the per-row query-based fallback
   * revokeAccessInternal() uses for that legacy case isn't bulk-safe, and
   * every share this bulk path itself creates always has the Id stored.
   *
   * @param partnerRecordShareIds Ids of the Partner_Record_Share__c registry rows to revoke.
   */
  public static void revokeParticipantAccessBulk(
    List<Id> partnerRecordShareIds
  ) {
    if (partnerRecordShareIds == null || partnerRecordShareIds.isEmpty()) {
      return;
    }

    List<Partner_Record_Share__c> registries = PartnerShareSelector.selectByIds(
      partnerRecordShareIds
    );
    if (registries.isEmpty()) {
      return;
    }

    deleteSalesforceSharesBulk(registries);

    List<AuditLogRequestDTO> audits = new List<AuditLogRequestDTO>();
    for (Partner_Record_Share__c registry : registries) {
      registry.Active__c = false;
      registry.Revoked_On__c = System.now();

      AuditLogRequestDTO audit = AuditFactory.createSuccess(
        'Partner_Record_Share__c',
        registry.Id,
        'Revoke'
      );
      audit.partnerAccountId = registry.Partner_Account__c;
      audits.add(audit);
    }
    updateRegistriesAsSystemBulk(registries);
    AuditService.logBulk(audits);
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

  @SuppressWarnings('PMD.ApexCRUDViolation')
  private static void updateRegistriesAsSystemBulk(
    List<Partner_Record_Share__c> registries
  ) {
    update registries;
  }

  private static Map<Id, Id> resolvePartnerGroupIdsBulk(
    Set<Id> partnerAccountIds
  ) {
    Map<Id, Id> groupIdByPartnerAccount = new Map<Id, Id>();
    for (Partner_Access_Group__c mapping : [
      SELECT Partner_Account__c, Group_Id__c, Active__c
      FROM Partner_Access_Group__c
      WHERE Partner_Account__c IN :partnerAccountIds
      WITH USER_MODE
      ORDER BY Partner_Account__c, Active__c DESC, CreatedDate DESC
    ]) {
      if (
        mapping.Active__c == true &&
        !groupIdByPartnerAccount.containsKey(mapping.Partner_Account__c)
      ) {
        groupIdByPartnerAccount.put(
          mapping.Partner_Account__c,
          (Id) mapping.Group_Id__c
        );
      }
    }
    return groupIdByPartnerAccount;
  }

  /*
   * Bulk counterpart to createSalesforceShare(): one insert per target
   * object type instead of one per registry. Uses partial-success DML
   * (allOrNone=false) so one bad row doesn't block the rest of the batch,
   * mirroring createDealShare()/createMdfShare()'s per-row
   * INVALID_FIELD_FOR_INSERT_UPDATE tolerance (a target object that
   * doesn't support Apex sharing in this org).
   */
  @SuppressWarnings('PMD.ApexCRUDViolation')
  private static Map<Id, Id> createSalesforceSharesBulk(
    List<Partner_Record_Share__c> registries
  ) {
    List<Deal_Registration__Share> dealShares = new List<Deal_Registration__Share>();
    List<Id> dealShareRegistryIds = new List<Id>();
    List<MDF_Request__Share> mdfShares = new List<MDF_Request__Share>();
    List<Id> mdfShareRegistryIds = new List<Id>();
    List<Deal_Implementation__Share> implementationShares = new List<Deal_Implementation__Share>();
    List<Id> implementationShareRegistryIds = new List<Id>();
    List<Customer_Success_Engagement__Share> customerSuccessShares = new List<Customer_Success_Engagement__Share>();
    List<Id> customerSuccessShareRegistryIds = new List<Id>();

    for (Partner_Record_Share__c registry : registries) {
      if (registry.Target_Object__c == 'Deal Registration') {
        Deal_Registration__Share share = new Deal_Registration__Share();
        share.ParentId = (Id) registry.Target_Record_Id__c;
        share.UserOrGroupId = (Id) registry.Partner_Group_Id__c;
        share.AccessLevel = PartnerShareDomain.toSalesforceAccessLevel(
          registry.Access_Level__c
        );
        share.RowCause = Schema.Deal_Registration__Share.RowCause.Partner_Record_Share__c;
        dealShares.add(share);
        dealShareRegistryIds.add(registry.Id);
      } else if (registry.Target_Object__c == 'MDF Request') {
        MDF_Request__Share share = new MDF_Request__Share();
        share.ParentId = (Id) registry.Target_Record_Id__c;
        share.UserOrGroupId = (Id) registry.Partner_Group_Id__c;
        share.AccessLevel = PartnerShareDomain.toSalesforceAccessLevel(
          registry.Access_Level__c
        );
        share.RowCause = Schema.MDF_Request__Share.RowCause.Partner_Record_Share__c;
        mdfShares.add(share);
        mdfShareRegistryIds.add(registry.Id);
      } else if (registry.Target_Object__c == 'Deal Implementation') {
        Deal_Implementation__Share share = new Deal_Implementation__Share();
        share.ParentId = (Id) registry.Target_Record_Id__c;
        share.UserOrGroupId = (Id) registry.Partner_Group_Id__c;
        share.AccessLevel = PartnerShareDomain.toSalesforceAccessLevel(
          registry.Access_Level__c
        );
        share.RowCause = Schema.Deal_Implementation__Share.RowCause.Partner_Record_Share__c;
        implementationShares.add(share);
        implementationShareRegistryIds.add(registry.Id);
      } else if (registry.Target_Object__c == 'Customer Success Engagement') {
        Customer_Success_Engagement__Share share = new Customer_Success_Engagement__Share();
        share.ParentId = (Id) registry.Target_Record_Id__c;
        share.UserOrGroupId = (Id) registry.Partner_Group_Id__c;
        share.AccessLevel = PartnerShareDomain.toSalesforceAccessLevel(
          registry.Access_Level__c
        );
        share.RowCause = Schema.Customer_Success_Engagement__Share.RowCause.Partner_Record_Share__c;
        customerSuccessShares.add(share);
        customerSuccessShareRegistryIds.add(registry.Id);
      } else {
        throw new PartnerSyncHandledException(
          'Sharing is not yet supported for target object: ' +
          registry.Target_Object__c
        );
      }
    }

    Map<Id, Id> shareIdByRegistryId = new Map<Id, Id>();

    if (!dealShares.isEmpty()) {
      List<Database.SaveResult> results = Database.insert(dealShares, false);
      for (Integer i = 0; i < results.size(); i++) {
        if (results[i].isSuccess()) {
          shareIdByRegistryId.put(dealShareRegistryIds[i], results[i].getId());
        } else if (!isInvalidFieldError(results[i])) {
          throw new PartnerSyncHandledException(
            results[i].getErrors()[0].getMessage()
          );
        }
      }
    }

    if (!mdfShares.isEmpty()) {
      List<Database.SaveResult> results = Database.insert(mdfShares, false);
      for (Integer i = 0; i < results.size(); i++) {
        if (results[i].isSuccess()) {
          shareIdByRegistryId.put(mdfShareRegistryIds[i], results[i].getId());
        } else if (!isInvalidFieldError(results[i])) {
          throw new PartnerSyncHandledException(
            results[i].getErrors()[0].getMessage()
          );
        }
      }
    }

    if (!implementationShares.isEmpty()) {
      List<Database.SaveResult> results = Database.insert(
        implementationShares,
        false
      );
      for (Integer i = 0; i < results.size(); i++) {
        if (results[i].isSuccess()) {
          shareIdByRegistryId.put(
            implementationShareRegistryIds[i],
            results[i].getId()
          );
        } else if (!isInvalidFieldError(results[i])) {
          throw new PartnerSyncHandledException(
            results[i].getErrors()[0].getMessage()
          );
        }
      }
    }

    if (!customerSuccessShares.isEmpty()) {
      List<Database.SaveResult> results = Database.insert(
        customerSuccessShares,
        false
      );
      for (Integer i = 0; i < results.size(); i++) {
        if (results[i].isSuccess()) {
          shareIdByRegistryId.put(
            customerSuccessShareRegistryIds[i],
            results[i].getId()
          );
        } else if (!isInvalidFieldError(results[i])) {
          throw new PartnerSyncHandledException(
            results[i].getErrors()[0].getMessage()
          );
        }
      }
    }

    return shareIdByRegistryId;
  }

  private static Boolean isInvalidFieldError(Database.SaveResult result) {
    for (Database.Error dmlError : result.getErrors()) {
      if (
        dmlError.getStatusCode() == StatusCode.INVALID_FIELD_FOR_INSERT_UPDATE
      ) {
        return true;
      }
    }
    return false;
  }

  // Bulk counterpart to deleteSalesforceShare(): only handles registries
  // with a stored Salesforce_Share_Id__c (every row this service creates
  // has one) - the per-row query-based fallback for legacy rows without
  // one isn't bulk-safe, so those are skipped here and logged rather than
  // looping a query per row.
  @SuppressWarnings('PMD.ApexCRUDViolation')
  private static void deleteSalesforceSharesBulk(
    List<Partner_Record_Share__c> registries
  ) {
    List<Id> dealShareIds = new List<Id>();
    List<Id> mdfShareIds = new List<Id>();
    List<Id> implementationShareIds = new List<Id>();
    List<Id> customerSuccessShareIds = new List<Id>();

    for (Partner_Record_Share__c registry : registries) {
      if (String.isBlank(registry.Salesforce_Share_Id__c)) {
        LoggingService.warn(
          'PartnerShareService',
          'Registry ' +
            registry.Id +
            ' has no stored Salesforce_Share_Id__c - skipping bulk platform-share deletion.'
        );
        continue;
      }
      if (registry.Target_Object__c == 'Deal Registration') {
        dealShareIds.add((Id) registry.Salesforce_Share_Id__c);
      } else if (registry.Target_Object__c == 'MDF Request') {
        mdfShareIds.add((Id) registry.Salesforce_Share_Id__c);
      } else if (registry.Target_Object__c == 'Deal Implementation') {
        implementationShareIds.add((Id) registry.Salesforce_Share_Id__c);
      } else if (registry.Target_Object__c == 'Customer Success Engagement') {
        customerSuccessShareIds.add((Id) registry.Salesforce_Share_Id__c);
      }
    }

    if (!dealShareIds.isEmpty()) {
      Database.delete(dealShareIds, false);
    }
    if (!mdfShareIds.isEmpty()) {
      Database.delete(mdfShareIds, false);
    }
    if (!implementationShareIds.isEmpty()) {
      Database.delete(implementationShareIds, false);
    }
    if (!customerSuccessShareIds.isEmpty()) {
      Database.delete(customerSuccessShareIds, false);
    }
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
    } else if (registry.Target_Object__c == 'Deal Implementation') {
      return createImplementationShare(registry);
    } else if (registry.Target_Object__c == 'Customer Success Engagement') {
      return createCustomerSuccessShare(registry);
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
  private static Id createImplementationShare(
    Partner_Record_Share__c registry
  ) {
    Deal_Implementation__Share share = new Deal_Implementation__Share();
    share.ParentId = (Id) registry.Target_Record_Id__c;
    share.UserOrGroupId = (Id) registry.Partner_Group_Id__c;
    share.AccessLevel = PartnerShareDomain.toSalesforceAccessLevel(
      registry.Access_Level__c
    );
    share.RowCause = Schema.Deal_Implementation__Share.RowCause.Partner_Record_Share__c;

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
  private static Id createCustomerSuccessShare(
    Partner_Record_Share__c registry
  ) {
    Customer_Success_Engagement__Share share = new Customer_Success_Engagement__Share();
    share.ParentId = (Id) registry.Target_Record_Id__c;
    share.UserOrGroupId = (Id) registry.Partner_Group_Id__c;
    share.AccessLevel = PartnerShareDomain.toSalesforceAccessLevel(
      registry.Access_Level__c
    );
    share.RowCause = Schema.Customer_Success_Engagement__Share.RowCause.Partner_Record_Share__c;

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
      } else if (registry.Target_Object__c == 'Deal Implementation') {
        delete new Deal_Implementation__Share(
          Id = (Id) registry.Salesforce_Share_Id__c
        );
        return;
      } else if (registry.Target_Object__c == 'Customer Success Engagement') {
        delete new Customer_Success_Engagement__Share(
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
    } else if (registry.Target_Object__c == 'Deal Implementation') {
      delete [
        SELECT Id
        FROM Deal_Implementation__Share
        WHERE
          ParentId = :((Id) registry.Target_Record_Id__c)
          AND UserOrGroupId = :partnerGroupId
          AND RowCause = :Schema.Deal_Implementation__Share.RowCause.Partner_Record_Share__c
      ];
    } else if (registry.Target_Object__c == 'Customer Success Engagement') {
      delete [
        SELECT Id
        FROM Customer_Success_Engagement__Share
        WHERE
          ParentId = :((Id) registry.Target_Record_Id__c)
          AND UserOrGroupId = :partnerGroupId
          AND RowCause = :Schema.Customer_Success_Engagement__Share.RowCause.Partner_Record_Share__c
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
