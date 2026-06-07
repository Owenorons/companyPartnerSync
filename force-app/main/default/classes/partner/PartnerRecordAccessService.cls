public with sharing class PartnerRecordAccessService {
  public static void assertPartnerAccessToAccount(Id partnerAccountId) {
    if (PartnerAccessService.isInternalUser()) {
      return;
    }

    Id currentPartnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    if (
      partnerAccountId == null ||
      partnerAccountId != currentPartnerAccountId
    ) {
      throw new PartnerSyncHandledException('Record not accessible.');
    }
  }

  public static void assertPartnerAccessToLead(Id leadId) {
    if (PartnerAccessService.isInternalUser()) {
      return;
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    List<Lead> rows = [
      SELECT Id
      FROM Lead
      WHERE Id = :leadId AND Partner_Account__c = :partnerAccountId
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Lead not accessible.');
    }
  }

  public static void assertPartnerAccessToDeal(Id dealId) {
    if (PartnerAccessService.isInternalUser()) {
      return;
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    List<Deal_Registration__c> rows = [
      SELECT Id
      FROM Deal_Registration__c
      WHERE Id = :dealId AND Partner_Account__c = :partnerAccountId
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Deal not accessible.');
    }
  }

  public static void assertPartnerAccessToMdf(Id requestId) {
    if (PartnerAccessService.isInternalUser()) {
      return;
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    List<MDF_Request__c> rows = [
      SELECT Id
      FROM MDF_Request__c
      WHERE Id = :requestId AND Partner_Account__c = :partnerAccountId
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('MDF request not accessible.');
    }
  }

  public static void assertPartnerAccessToNotification(Id notificationId) {
    if (PartnerAccessService.isInternalUser()) {
      return;
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();
    Id userId = UserInfo.getUserId();

    List<Partner_Notification__c> rows = [
      SELECT Id
      FROM Partner_Notification__c
      WHERE
        Id = :notificationId
        AND Partner_Account__c = :partnerAccountId
        AND Recipient_User__c = :userId
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Notification not accessible.');
    }
  }
}
