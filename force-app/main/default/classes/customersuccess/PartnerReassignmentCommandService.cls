/**
 * Executes Partner_Reassignment__c commands: request, approve (restricted,
 * PartnerSync_Approve_Partner_Reassignment). Reassignment changes only
 * which partner a renewal or expansion is associated with going forward -
 * it never rewrites Deal_Registration__c.Partner_Account__c on the
 * original deal (doc section 42.40), and is recorded as a real,
 * auditable row rather than a silent field flip.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class PartnerReassignmentCommandService {
  /**
   * Requests a reassignment of a renewal or expansion to a different
   * partner.
   *
   * @param command targetObject + targetRecordId + requestedPartnerId + reason.
   * @return The inserted reassignment request.
   */
  public static Partner_Reassignment__c request(
    PartnerReassignmentCommand command
  ) {
    PartnerAccessService.assertInternalUser();
    if (
      (command.targetObject != 'Partner_Renewal__c' &&
      command.targetObject != 'Partner_Expansion__c') ||
      command.targetRecordId == null ||
      command.requestedPartnerId == null
    ) {
      throw new PartnerSyncHandledException(
        'A target renewal or expansion, and a requested partner, are required.'
      );
    }
    if (String.isBlank(command.reason)) {
      throw new PartnerSyncHandledException(
        'A reason is required to request a partner reassignment.'
      );
    }

    Id currentPartnerId = resolveCurrentPartner(
      command.targetObject,
      command.targetRecordId
    );

    Partner_Reassignment__c reassignment = new Partner_Reassignment__c(
      Target_Object__c = command.targetObject,
      Target_Record_Id__c = command.targetRecordId,
      Current_Partner__c = currentPartnerId,
      Requested_Partner__c = command.requestedPartnerId,
      Reason__c = command.reason,
      Status__c = 'Requested',
      Requested_By__c = UserInfo.getUserId(),
      Version_Number__c = 0
    );
    Database.insert(reassignment, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'PartnerReassignmentRequested',
      reassignment.Id,
      'Partner_Reassignment__c',
      currentPartnerId,
      'A partner reassignment was requested.',
      'Info'
    );

    return reassignment;
  }

  /**
   * Approves a requested reassignment, applying the new partner to the
   * target renewal or expansion record only - never to the originating
   * deal itself.
   *
   * @param command reassignmentId + expectedVersion.
   * @return The updated reassignment.
   */
  public static Partner_Reassignment__c approve(
    PartnerReassignmentCommand command
  ) {
    if (
      !PartnerAccessService.isInternalUser() ||
      !DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Approve_Partner_Reassignment'
      )
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to approve a partner reassignment.'
      );
    }
    if (command.reassignmentId == null) {
      throw new PartnerSyncHandledException(
        'A reassignment is required for this command.'
      );
    }
    Partner_Reassignment__c reassignment = PartnerReassignmentSelector.selectForUpdate(
      command.reassignmentId
    );
    if (
      command.expectedVersion != null &&
      coalesceVersion(reassignment) != command.expectedVersion
    ) {
      throw new PartnerSyncHandledException(
        'This reassignment has changed since it was loaded - refresh and try again.'
      );
    }
    if (reassignment.Status__c != 'Requested') {
      throw new PartnerSyncHandledException(
        'Only a Requested reassignment can be approved.'
      );
    }

    applyToTarget(reassignment);

    reassignment.Status__c = 'Approved';
    reassignment.Approved_By__c = UserInfo.getUserId();
    reassignment.Approved_On__c = System.now();
    reassignment.Version_Number__c = coalesceVersion(reassignment) + 1;
    Database.update(reassignment, AccessLevel.SYSTEM_MODE);

    AuditLogRequestDTO audit = AuditFactory.createSuccess(
      reassignment.Target_Object__c,
      (Id) reassignment.Target_Record_Id__c,
      'Partner Reassignment'
    );
    audit.partnerAccountId = reassignment.Requested_Partner__c;
    AuditService.log(audit);

    PlatformEventPublisherService.publish(
      'PartnerReassigned',
      reassignment.Id,
      'Partner_Reassignment__c',
      reassignment.Requested_Partner__c,
      'A partner reassignment was approved.',
      'Info'
    );

    return reassignment;
  }

  private static void applyToTarget(Partner_Reassignment__c reassignment) {
    if (reassignment.Target_Object__c == 'Partner_Renewal__c') {
      Database.update(
        new Partner_Renewal__c(
          Id = (Id) reassignment.Target_Record_Id__c,
          Primary_Partner__c = reassignment.Requested_Partner__c
        ),
        AccessLevel.SYSTEM_MODE
      );
      reconcileEngagementSharingForRenewal(
        (Id) reassignment.Target_Record_Id__c
      );
    } else if (reassignment.Target_Object__c == 'Partner_Expansion__c') {
      Database.update(
        new Partner_Expansion__c(
          Id = (Id) reassignment.Target_Record_Id__c,
          Primary_Partner__c = reassignment.Requested_Partner__c
        ),
        AccessLevel.SYSTEM_MODE
      );
    }
  }

  private static void reconcileEngagementSharingForRenewal(Id renewalId) {
    List<Partner_Renewal__c> rows = [
      SELECT Customer_Success_Engagement__c
      FROM Partner_Renewal__c
      WHERE Id = :renewalId
      WITH SYSTEM_MODE
    ];
    if (!rows.isEmpty() && rows[0].Customer_Success_Engagement__c != null) {
      CustomerSuccessSharingService.reconcileForEngagement(
        rows[0].Customer_Success_Engagement__c
      );
    }
  }

  private static Id resolveCurrentPartner(
    String targetObject,
    Id targetRecordId
  ) {
    if (targetObject == 'Partner_Renewal__c') {
      List<Partner_Renewal__c> rows = [
        SELECT Primary_Partner__c
        FROM Partner_Renewal__c
        WHERE Id = :targetRecordId
        WITH SYSTEM_MODE
      ];
      return rows.isEmpty() ? null : rows[0].Primary_Partner__c;
    }
    List<Partner_Expansion__c> rows = [
      SELECT Primary_Partner__c
      FROM Partner_Expansion__c
      WHERE Id = :targetRecordId
      WITH SYSTEM_MODE
    ];
    return rows.isEmpty() ? null : rows[0].Primary_Partner__c;
  }

  private static Integer coalesceVersion(Partner_Reassignment__c reassignment) {
    return reassignment.Version_Number__c == null
      ? 0
      : Integer.valueOf(reassignment.Version_Number__c);
  }
}
